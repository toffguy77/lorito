import Foundation
import TelemetryDeck
import Domain

/// Delivers Lorito's anonymous events to TelemetryDeck. The SDK salts and
/// hashes its anonymous user identifier on device; payloads are the closed
/// `AnalyticsEvent` parameters only (enums, ints, bools).
struct TelemetryDeckSink: AnalyticsSink {
    init(appID: String) {
        TelemetryDeck.initialize(config: TelemetryDeck.Config(appID: appID))
    }

    func send(_ batch: [AnalyticsRecord]) async throws {
        for record in batch {
            TelemetryDeck.signal(record.name, parameters: record.parameters)
        }
    }
}
