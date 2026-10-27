import Foundation
import Domain

/// What a widget shows at a given moment, derived from the last snapshot.
/// Uses the learning day (`Calendar.learningDay`) so widgets agree with the
/// app; when the day has moved on since the snapshot, today's counts are
/// unknown and the streak is kept only if the snapshot day was studied.
public struct WidgetDayState: Equatable, Sendable {
    public let streak: Int
    public let studiedToday: Bool
    /// Cards left today; nil when the snapshot is from an earlier day.
    public let remainingToday: Int?
    /// Streak > 0 and not yet extended today.
    public let streakAtRisk: Bool

    public init(streak: Int, studiedToday: Bool, remainingToday: Int?, streakAtRisk: Bool) {
        self.streak = streak
        self.studiedToday = studiedToday
        self.remainingToday = remainingToday
        self.streakAtRisk = streakAtRisk
    }

    public static func make(snapshot: WidgetSnapshot, now: Date, calendar: Calendar = .learningDay) -> WidgetDayState {
        let cal = calendar
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: snapshot.day), to: cal.startOfDay(for: now)).day ?? 0
        if days <= 0 {
            return WidgetDayState(streak: snapshot.currentStreak, studiedToday: snapshot.studiedToday,
                                  remainingToday: snapshot.remainingToday,
                                  streakAtRisk: snapshot.currentStreak > 0 && !snapshot.studiedToday)
        }
        // A day later the streak survives only if the snapshot day was studied.
        let streak = days == 1 && snapshot.studiedToday ? snapshot.currentStreak : 0
        return WidgetDayState(streak: streak, studiedToday: false, remainingToday: nil, streakAtRisk: streak > 0)
    }

    /// Timeline refresh point: the next learning-day boundary (local midnight).
    public static func nextRefreshDates(after now: Date, calendar: Calendar = .learningDay) -> [Date] {
        let next = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0, second: 0),
                                     matchingPolicy: .nextTime)
        return [next].compactMap { $0 }.filter { $0 > now }
    }
}
