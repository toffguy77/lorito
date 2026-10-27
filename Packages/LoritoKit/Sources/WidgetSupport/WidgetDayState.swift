import Foundation
import Domain

/// What a widget shows at a given moment, derived from the last snapshot.
/// Uses the app's day boundary (`Calendar.utcDay`) so widgets agree with the
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

    public static func make(snapshot: WidgetSnapshot, now: Date) -> WidgetDayState {
        let cal = Calendar.utcDay
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

    /// Timeline refresh points: the next local midnight and the next app day
    /// (UTC) start, whichever come first, sorted.
    public static func nextRefreshDates(after now: Date, localCalendar: Calendar = .current) -> [Date] {
        let local = localCalendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0, second: 0),
                                           matchingPolicy: .nextTime)
        let utc = Calendar.utcDay.date(byAdding: .day, value: 1, to: Calendar.utcDay.startOfDay(for: now))
        return Array(Set([local, utc].compactMap { $0 })).filter { $0 > now }.sorted()
    }
}
