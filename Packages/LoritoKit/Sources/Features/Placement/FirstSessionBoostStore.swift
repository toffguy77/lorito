import Foundation
import Domain

/// Device-local storage of the one-off first-session boost (placement-test):
/// written when onboarding completes, read by the daily plan on that learning
/// day only, and dropped afterwards.
public struct FirstSessionBoostStore: @unchecked Sendable {
    static let key = "firstSession.boost"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public static let shared = FirstSessionBoostStore()

    public func save(_ boost: FirstSessionBoost) {
        defaults.set(try? JSONEncoder().encode(boost), forKey: Self.key)
    }

    /// The boost when it belongs to `today`'s learning day; a stale one is removed.
    public func current(today: Date = Date(), calendar: Calendar = .learningDay) -> FirstSessionBoost? {
        guard let data = defaults.data(forKey: Self.key),
              let boost = try? JSONDecoder().decode(FirstSessionBoost.self, from: data) else { return nil }
        guard boost.applies(on: today, calendar: calendar) else {
            clear()
            return nil
        }
        return boost
    }

    public func clear() {
        defaults.removeObject(forKey: Self.key)
    }
}
