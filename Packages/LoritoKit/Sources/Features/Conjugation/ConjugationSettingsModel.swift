import Foundation
import Observation
import Domain

/// Settings «Тренажёр спряжений»: on/off and the daily quota (0–20); enabling
/// sets the default of 3. Free for everyone.
@MainActor
@Observable
public final class ConjugationSettingsModel {
    private let store: UserDataStore
    public private(set) var settings: UserSettings

    public init(store: UserDataStore) {
        self.store = store
        self.settings = (try? store.loadSettings()) ?? .default
    }

    public var isEnabled: Bool {
        get { settings.dailyConjugationCount > 0 }
        set { update { $0.dailyConjugationCount = newValue ? UserSettings.conjugationDefaultWhenEnabled : 0 } }
    }

    public var quota: Int {
        get { settings.dailyConjugationCount }
        set {
            let r = UserSettings.conjugationRange
            update { $0.dailyConjugationCount = min(max(newValue, r.lowerBound), r.upperBound) }
        }
    }

    /// «Новых вопросов CCSE в день» (exam-path-dele-ccse): 0 turns CCSE introductions off.
    public var ccseDailyNewLimit: Int {
        get { settings.ccseDailyNewLimit }
        set { update { $0.ccseDailyNewLimit = min(max(newValue, 0), 20) } }
    }

    private func update(_ change: (inout UserSettings) -> Void) {
        var s = (try? store.loadSettings()) ?? .default
        change(&s)
        try? store.saveSettings(s)
        settings = s
    }
}
