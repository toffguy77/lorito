import Foundation
import TelemetryDeck
import Domain

/// Delivers Lorito's anonymous events to TelemetryDeck. The SDK is set up
/// lazily on the first send — which `AnalyticsService` only does with consent
/// granted — with its automatic session signals off, and torn down on opt-out,
/// so nothing reaches TelemetryDeck without this device's consent. The SDK
/// salts and hashes its anonymous user identifier on device; payloads are the
/// closed `AnalyticsEvent` parameters only (enums, ints, bools).
final class TelemetryDeckSink: AnalyticsSink, @unchecked Sendable {
    private let appID: String
    private let lock = NSLock()
    private var started = false

    init(appID: String) {
        self.appID = appID
    }

    func send(_ batch: [AnalyticsRecord]) async throws {
        startIfNeeded()
        for record in batch {
            TelemetryDeck.signal(record.name, parameters: record.parameters)
        }
    }

    func stop() async {
        lock.withLock {
            guard started else { return }
            TelemetryDeck.terminate()
            started = false
        }
    }

    private func startIfNeeded() {
        lock.withLock {
            guard !started else { return }
            let config = TelemetryDeck.Config(appID: appID)
            config.sendNewSessionBeganSignal = false   // only Lorito's own events
            config.sessionStatsEnabled = false
            TelemetryDeck.initialize(config: config)
            started = true
        }
    }
}
