import Foundation

public extension Calendar {
    /// The app's day-boundary calendar (UTC gregorian), shared so "today",
    /// streaks, and "graded today" all agree.
    static let utcDay: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()
}

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
        calendar: Calendar = .utcDay
    ) -> StudyStats {
        guard !events.isEmpty else { return .empty }

        let today0 = calendar.startOfDay(for: today)
        // Distinct study days as day-offsets from today (0 = today, 1 = yesterday…).
        let dayStarts = Set(events.map { calendar.startOfDay(for: $0.date) })

        let currentStreak = currentStreakLength(dayStarts: dayStarts, today0: today0, calendar: calendar)
        let bestStreak = bestStreakLength(dayStarts: dayStarts, calendar: calendar)

        let studiedToday = events.filter { calendar.isDate($0.date, inSameDayAs: today) }.count
        let week = calendar.dateInterval(of: .weekOfYear, for: today)
        let studiedThisWeek = week.map { iv in events.filter { iv.contains($0.date) }.count } ?? 0

        return StudyStats(
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            studiedToday: studiedToday,
            studiedThisWeek: studiedThisWeek,
            studiedAllTime: events.count
        )
    }

    /// Consecutive study days ending at today (if studied) or yesterday.
    private static func currentStreakLength(dayStarts: Set<Date>, today0: Date, calendar: Calendar) -> Int {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today0)!
        var anchor: Date
        if dayStarts.contains(today0) {
            anchor = today0
        } else if dayStarts.contains(yesterday) {
            anchor = yesterday
        } else {
            return 0
        }
        var count = 0
        var day = anchor
        while dayStarts.contains(day) {
            count += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }

    /// Longest run of consecutive study days anywhere in the history.
    private static func bestStreakLength(dayStarts: Set<Date>, calendar: Calendar) -> Int {
        let sorted = dayStarts.sorted()
        var best = 0, run = 0
        var prev: Date?
        for day in sorted {
            if let p = prev, calendar.date(byAdding: .day, value: 1, to: p) == day {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
            prev = day
        }
        return best
    }
}
