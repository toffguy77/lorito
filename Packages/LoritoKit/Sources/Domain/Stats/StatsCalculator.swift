import Foundation

/// A snapshot of the learner's study habits, derived from the study log.
public struct StudyStats: Equatable, Sendable {
    public let currentStreak: Int
    public let bestStreak: Int
    public let studiedToday: Int
    public let studiedThisWeek: Int
    public let studiedAllTime: Int

    public init(currentStreak: Int, bestStreak: Int, studiedToday: Int, studiedThisWeek: Int, studiedAllTime: Int) {
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.studiedToday = studiedToday
        self.studiedThisWeek = studiedThisWeek
        self.studiedAllTime = studiedAllTime
    }

    public static let empty = StudyStats(currentStreak: 0, bestStreak: 0, studiedToday: 0, studiedThisWeek: 0, studiedAllTime: 0)
}

/// Pure, deterministic streak/count math over the `StudyLog`. No I/O, no ambient
/// clock — "today" and the day calendar are injected.
public enum StatsCalculator {

    public static func compute(
        events: [StudyEvent],
        today: Date,
        calendar: Calendar = .learningDay
    ) -> StudyStats {
        guard !events.isEmpty else { return .empty }

        // Streaks replay the log with freezes and revival (streak-protection).
        let streak = streak(events: events, today: today, calendar: calendar)
        let currentStreak = streak.current
        let bestStreak = streak.best

        // Counts speak about cards; the streak counts any study activity.
        let cardEvents = events.filter(\.isCard)
        let studiedToday = cardEvents.filter { calendar.isDate($0.date, inSameDayAs: today) }.count
        // Weeks run Monday–Sunday everywhere (weekly-recap-and-milestones).
        let week = calendar.mondayWeeks.dateInterval(of: .weekOfYear, for: today)
        let studiedThisWeek = week.map { iv in cardEvents.filter { iv.contains($0.date) }.count } ?? 0

        return StudyStats(
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            studiedToday: studiedToday,
            studiedThisWeek: studiedThisWeek,
            studiedAllTime: cardEvents.count
        )
    }
}
