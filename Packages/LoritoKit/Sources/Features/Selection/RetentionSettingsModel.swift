import Foundation
import Observation
import Domain

/// Settings «Повторение»: the FSRS desired retention (only intervals computed
/// afterwards change) and new cards per day, persisted as synced user settings.
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

    /// «Новых карточек в день» (1–10), within the daily new-introduction budget.
    public var cardsPerDay: Int {
        get { settings.dailyNewCardCount }
        set {
            let r = OnboardingSetupModel.cardsRange
            var s = (try? store.loadSettings()) ?? .default
            s.dailyNewCardCount = min(max(newValue, r.lowerBound), r.upperBound)
            try? store.saveSettings(s)
            settings = s
        }
    }

    /// Re-read after another screen saved settings (a setup re-run).
    public func reload() { settings = (try? store.loadSettings()) ?? .default }
}
