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
    /// Consent gate, flipped synchronously by `AnalyticsService`; off until set.
    private var deliveryEnabled = false

    init(appID: String) {
        self.appID = appID
    }

    func setDeliveryEnabled(_ enabled: Bool) {
        lock.withLock { deliveryEnabled = enabled }
    }

    func send(_ batch: [AnalyticsRecord]) async throws {
        for record in batch {
            // Check consent, start the SDK and signal under one lock, per record.
            let delivered = lock.withLock { () -> Bool in
                guard deliveryEnabled else { return false }
                if !started {
                    let config = TelemetryDeck.Config(appID: appID)
                    config.sendNewSessionBeganSignal = false   // only Lorito's own events
                    config.sessionStatsEnabled = false
                    TelemetryDeck.initialize(config: config)
                    started = true
                }
                TelemetryDeck.signal(record.name, parameters: record.parameters)
                return true
            }
            if !delivered { return }
        }
    }

    func stop() async {
        lock.withLock {
            deliveryEnabled = false
            guard started else { return }
            TelemetryDeck.terminate()
            started = false
        }
    }
}
