import Testing
import Foundation
@testable import Domain

private let cal = Calendar.utcDay
private func day(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12) -> Date {
    cal.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
}
private func ev(_ date: Date) -> StudyEvent { StudyEvent(cardID: "A1-01", date: date, grade: "good") }

private let today = day(2026, 6, 24)

@Suite("Stats calculator")
struct StatsCalculatorTests {
    @Test("No history → all zero")
    func empty() {
        #expect(StatsCalculator.compute(events: [], today: today) == .empty)
    }

    @Test("Studied today extends streak through today")
    func studiedTodayStreak() {
        let events = (0...4).map { ev(day(2026, 6, 24 - $0)) }  // today + 4 prior
        let s = StatsCalculator.compute(events: events, today: today)
        #expect(s.currentStreak == 5)
    }

    @Test("Not today but yesterday → streak still counts (today savable)")
    func yesterdayStreak() {
        let events = [ev(day(2026, 6, 23)), ev(day(2026, 6, 22)), ev(day(2026, 6, 21))]
        let s = StatsCalculator.compute(events: events, today: today)
        #expect(s.currentStreak == 3)
    }

    @Test("Gap of more than a day resets current streak")
    func gapResets() {
        let events = [ev(day(2026, 6, 21)), ev(day(2026, 6, 20))]  // last studied 3 days ago
        let s = StatsCalculator.compute(events: events, today: today)
        #expect(s.currentStreak == 0)
    }

    @Test("Best streak is the longest historical run")
    func bestStreak() {
        // A 7-day run in May, then a 2-day current run.
        var events: [StudyEvent] = []
        for d in 1...7 { events.append(ev(day(2026, 5, d))) }
        events.append(ev(day(2026, 6, 24))); events.append(ev(day(2026, 6, 23)))
        let s = StatsCalculator.compute(events: events, today: today)
        #expect(s.bestStreak == 7)
        #expect(s.currentStreak == 2)
    }

    @Test("Multiple events same day count once for streak, many for counts")
    func sameDayMultiple() {
        let events = [ev(day(2026, 6, 24, 9)), ev(day(2026, 6, 24, 10)), ev(day(2026, 6, 24, 11))]
        let s = StatsCalculator.compute(events: events, today: today)
        #expect(s.currentStreak == 1)
        #expect(s.studiedToday == 3)
        #expect(s.studiedAllTime == 3)
    }

    @Test("Counts: today, this week, all-time")
    func counts() {
        // today (Wed 2026-06-24): 3 today, plus 2 earlier this week, plus 5 long ago.
        var events = [ev(day(2026, 6, 24)), ev(day(2026, 6, 24)), ev(day(2026, 6, 24))]
        events += [ev(day(2026, 6, 22)), ev(day(2026, 6, 23))]            // same week (week starts Sun 6/21)
        events += (1...5).map { ev(day(2026, 1, $0)) }                     // all-time only
        let s = StatsCalculator.compute(events: events, today: today)
        #expect(s.studiedToday == 3)
        #expect(s.studiedThisWeek == 5)
        #expect(s.studiedAllTime == 10)
    }

    @Test("Deterministic regardless of event order")
    func determinism() {
        let events = [ev(day(2026, 6, 24)), ev(day(2026, 6, 22)), ev(day(2026, 6, 23))]
        let a = StatsCalculator.compute(events: events, today: today)
        let b = StatsCalculator.compute(events: events.reversed(), today: today)
        #expect(a == b)
    }
}
