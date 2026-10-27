import Foundation
import Observation
import Domain

/// Where emit points send events (lets tests inject a recorder).
@MainActor
public protocol AnalyticsRecording: AnyObject {
    func record(_ event: AnalyticsEvent)
}

/// Device-local analytics consent (`UserDefaults`, never synced).
public enum AnalyticsConsent: String, Sendable {
    case granted, denied

    public static let key = "analytics.consent"
}

/// Records product events into a bounded on-device queue and flushes them in
/// batches through the injected sink, never blocking the UI. Nothing is
/// recorded until this device's consent is set; opting out purges the queue.
@MainActor
@Observable
public final class AnalyticsService: AnalyticsRecording {
    /// The app-wide instance; a no-op until the app target calls `configure`.
    public static var shared = AnalyticsService(sink: NoOpAnalyticsSink(), defaults: nil, queueURL: nil)

    /// Replace the shared service (app launch).
    public static func configure(_ service: AnalyticsService) { shared = service }

    private let sink: AnalyticsSink
    private let defaults: UserDefaults?
    private let queueURL: URL?
    private let now: () -> Date
    /// UI tests keep events queued to observe them.
    private let flushEnabled: Bool

    public private(set) var queue: EventQueue
    public private(set) var consent: AnalyticsConsent?
    private let writer: QueueFileWriter
    private var failures = 0
    private var nextAttempt: Date = .distantPast
    private var flushing = false

    public static let batchSize = 50
    private static let lastStreakKey = "analytics.lastReportedStreak"

    public init(sink: AnalyticsSink, defaults: UserDefaults?, queueURL: URL?,
                flushEnabled: Bool = true, now: @escaping () -> Date = { Date() }) {
        self.sink = sink
        self.defaults = defaults
        self.queueURL = queueURL
        self.flushEnabled = flushEnabled
        self.now = now
        self.writer = QueueFileWriter(url: queueURL)
        let consent = defaults?.string(forKey: AnalyticsConsent.key).flatMap(AnalyticsConsent.init(rawValue:))
        self.consent = consent
        if consent == .denied {
            // Opted out on this device: never resurrect a saved queue.
            if let queueURL { try? FileManager.default.removeItem(at: queueURL) }
            self.queue = EventQueue()
        } else {
            let stored = queueURL.flatMap { try? Data(contentsOf: $0) }
                .flatMap { try? JSONDecoder().decode(EventQueue.self, from: $0) }
            self.queue = stored ?? EventQueue()
        }
    }

    /// The default queue file in Application Support.
    public static var defaultQueueURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("analytics-queue.json")
    }

    // MARK: Consent

    /// First launch: on by default, written before any event is recorded.
    public func resolveConsentOnFirstLaunch() {
        guard consent == nil, let defaults else { return }
        setConsent(true, defaults: defaults)
    }

    public var isEnabled: Bool { consent == .granted }

    public func setEnabled(_ enabled: Bool) {
        guard let defaults else { return }
        setConsent(enabled, defaults: defaults)
    }

    private func setConsent(_ granted: Bool, defaults: UserDefaults) {
        consent = granted ? .granted : .denied
        defaults.set(consent?.rawValue, forKey: AnalyticsConsent.key)
        if !granted {
            // Purge now: drop the queue, cancel pending writes, delete the file
            // synchronously, and tear down the provider.
            queue.removeAll()
            writer.purge()
            let sink = sink
            Task { await sink.stop() }
        }
    }

    // MARK: Recording

    public func record(_ event: AnalyticsEvent) {
        record(event, experiment: nil, variant: nil)
    }

    public func record(_ event: AnalyticsEvent, experiment: Experiment?, variant: ExperimentVariant?) {
        guard consent == .granted else { return }
        queue.append(AnalyticsRecord(event: event, date: now(), experiment: experiment, variant: variant))
        persist()
    }

    /// Streak extended: emitted when the computed streak grows past the last reported value.
    public func noteStreak(_ current: Int) {
        guard let defaults else { return }
        let last = defaults.object(forKey: Self.lastStreakKey) as? Int
        if current > (last ?? 0) {
            record(.streakExtended(length: current))
        }
        defaults.set(current, forKey: Self.lastStreakKey)
    }

    /// On launch: a positive → 0 drop of the computed streak emits `streakLost` once.
    public func checkStreakOnLaunch(_ current: Int) {
        guard let defaults else { return }
        let last = defaults.object(forKey: Self.lastStreakKey) as? Int
        let result = StreakLossDetector.check(lastReported: last, current: current)
        if let event = result.event { record(event) }
        defaults.set(result.report, forKey: Self.lastStreakKey)
    }

    // MARK: Delivery

    /// Send queued events in batches; failures back off exponentially (30 s → 1 h).
    public func flush() async {
        guard flushEnabled, consent == .granted, !flushing, now() >= nextAttempt else { return }
        flushing = true
        defer { flushing = false }
        queue.discardExpired(now: now())
        while !queue.records.isEmpty {
            let batch = queue.nextBatch(size: Self.batchSize)
            do {
                try await sink.send(batch)
                guard consent == .granted else { return }   // opted out mid-flight: already purged
                queue.removeFirst(batch.count)
                failures = 0
            } catch {
                failures += 1
                nextAttempt = now().addingTimeInterval(min(3600, 30 * pow(2, Double(failures - 1))))
                break
            }
        }
        persist()
    }

    /// Queue persistence happens off the main thread, in order.
    private func persist() {
        guard consent == .granted, let data = try? JSONEncoder().encode(queue) else { return }
        writer.write(data)
    }
}

/// Writes queue snapshots on one serial background queue, in order. Each
/// snapshot carries a version; a write older than the latest request (or than
/// a purge) is skipped, so a stale snapshot can never land after an opt-out.
final class QueueFileWriter: @unchecked Sendable {
    private let url: URL?
    private let io = DispatchQueue(label: "lorito.analytics.queue-writer", qos: .utility)
    private let lock = NSLock()
    private var version = 0

    init(url: URL?) {
        self.url = url
    }

    func write(_ data: Data) {
        guard let url else { return }
        let mine = bump()
        io.async { [self] in
            guard current == mine else { return }   // superseded or purged
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? data.write(to: url, options: .atomic)
        }
    }

    /// Cancel pending writes and delete the file now (synchronously).
    func purge() {
        _ = bump()
        guard let url else { return }
        io.sync { try? FileManager.default.removeItem(at: url) }
    }

    private func bump() -> Int {
        lock.lock(); defer { lock.unlock() }
        version += 1
        return version
    }

    private var current: Int {
        lock.lock(); defer { lock.unlock() }
        return version
    }
}
