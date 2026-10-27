import Foundation
import Observation
import Domain

/// Settings «Целевая запоминаемость»: the FSRS desired retention, persisted as
/// a synced user setting. Only intervals computed afterwards change.
@MainActor
@Observable
public final class RetentionSettingsModel {
    /// Offered values, in percent.
    public static let options = [80, 85, 90, 95]

    private let store: UserDataStore
    public private(set) var settings: UserSettings

    public init(store: UserDataStore) {
        self.store = store
        self.settings = (try? store.loadSettings()) ?? .default
    }

    /// The current retention in whole percent (nearest offered value).
    public var percent: Int {
        get {
            let value = settings.desiredRetention * 100
            return Self.options.min { abs(Double($0) - value) < abs(Double($1) - value) } ?? 90
        }
        set {
            // Load fresh, change, save — so other settings written elsewhere survive.
            var s = (try? store.loadSettings()) ?? .default
            s.desiredRetention = Double(newValue) / 100
            try? store.saveSettings(s)
            settings = s
        }
    }
}
