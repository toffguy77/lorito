import Foundation
import Domain

/// Today's streak-protection banner.
public enum StreakBanner: Equatable, Sendable {
    /// «Серия спасена заморозкой» — once, on the first visit after a frozen day.
    case frozen
    /// Revival in progress: `daysLeft` study days restore a `lost`-day streak.
    case revival(lost: Int, daysLeft: Int)

    public var title: String {
        switch self {
        case .frozen: "Серия спасена заморозкой"
        case .revival(let lost, _): "Серию \(lost) \(RussianPlural.form(lost, one: "день", few: "дня", many: "дней")) можно вернуть"
        }
    }

    public var detail: String {
        switch self {
        case .frozen: "Вчера пропуск засчитала заморозка — серия не прервалась."
        case .revival(let lost, let left):
            "Ещё \(left) \(RussianPlural.form(left, one: "день", few: "дня", many: "дней")) занятий подряд — и серия \(lost) \(RussianPlural.form(lost, one: "день", few: "дня", many: "дней")) вернётся."
        }
    }
}

/// Decides the banner; remembers (device-local) the day the freeze banner was seen.
public struct StreakBannerLedger: @unchecked Sendable {
    static let key = "streak.frozenBannerShownFor"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func reset() { defaults.removeObject(forKey: Self.key) }

    /// `keepFrozen`: already shown during this visit (keeps showing until the screen goes away).
    public func banner(events: [StudyEvent], today: Date, keepFrozen: Bool,
                       calendar: Calendar = .learningDay) -> StreakBanner? {
        let report = StatsCalculator.streak(events: events, today: today, calendar: calendar)
        if case .inProgress(let done, _, let lost) = report.revival {
            return .revival(lost: lost, daysLeft: StreakConstants.revivalDays - done)
        }
        guard report.frozenYesterday else { return nil }
        if keepFrozen { return .frozen }
        return defaults.string(forKey: Self.key) == Self.dayKey(today, calendar) ? nil : .frozen
    }

    /// Called when Today actually appears with the freeze banner — not from
    /// `refresh`, which also runs for throwaway model instances.
    public func markFrozenShown(today: Date, calendar: Calendar = .learningDay) {
        let key = Self.dayKey(today, calendar)
        if defaults.string(forKey: Self.key) != key { defaults.set(key, forKey: Self.key) }
    }

    static func dayKey(_ day: Date, _ calendar: Calendar) -> String {
        String(Int(calendar.startOfDay(for: day).timeIntervalSince1970))
    }
}
