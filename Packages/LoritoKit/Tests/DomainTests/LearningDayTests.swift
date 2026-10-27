import Foundation
import Testing
@testable import Domain

@Suite("Learning day")
struct LearningDayTests {
    static let buenosAires = Calendar.learningDay(in: TimeZone(identifier: "America/Argentina/Buenos_Aires")!)
    static let utc = Calendar.learningDay(in: TimeZone(identifier: "UTC")!)

    static func local(_ cal: Calendar, _ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int = 0) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    @Test("22:00 in UTC−3 counts for the local date, not the next UTC date")
    func eveningInBuenosAires() {
        let evening = Self.local(Self.buenosAires, 2026, 10, 27, 22)          // 01:00 UTC on the 28th
        #expect(Self.utc.component(.day, from: evening) == 28)
        let events = [StudyEvent(cardID: "A1-01", date: evening, grade: "good")]
        let stats = StatsCalculator.compute(events: events, today: evening, calendar: Self.buenosAires)
        #expect(stats.studiedToday == 1)
        let series = StatsCalculator.dailyActivity(events: events, days: 2, today: evening, calendar: Self.buenosAires)
        #expect(Self.buenosAires.component(.day, from: series.last!.day) == 27)
        #expect(series.last!.count == 1)
    }

    @Test("Due today means local today")
    func dueLocalToday() {
        let now = Self.local(Self.buenosAires, 2026, 10, 27, 22)
        // Scheduled locally for the 27th (local midnight = 03:00 UTC).
        let dueDate = Self.buenosAires.startOfDay(for: now)
        let state = ReviewState(cardID: "A1-01", interval: 1, repetitions: 1, dueDate: dueDate, status: .review)
        #expect(DueSelection.isDue(state, on: now, calendar: Self.buenosAires))
        // A card due on the local 28th is not due yet at 22:00 on the 27th, although UTC is already the 28th.
        let tomorrow = Self.buenosAires.date(byAdding: .day, value: 1, to: dueDate)!
        let later = ReviewState(cardID: "A1-02", interval: 1, repetitions: 1, dueDate: tomorrow, status: .review)
        #expect(!DueSelection.isDue(later, on: now, calendar: Self.buenosAires))
    }

    @Test("Scheduler places due dates at local midnight + interval days")
    func schedulerLocal() {
        let now = Self.local(Self.buenosAires, 2026, 10, 27, 22)
        let next = SpacedRepetitionScheduler.schedule(state: ReviewState(cardID: "A1-01"), grade: .good,
                                                      today: now, calendar: Self.buenosAires)
        #expect(next.dueDate == Self.local(Self.buenosAires, 2026, 10, 28, 0))
    }

    @Test("DST transition day is still one learning day")
    func dst() {
        let madrid = Calendar.learningDay(in: TimeZone(identifier: "Europe/Madrid")!)
        // 2026-10-25: clocks go back at 03:00 → the day lasts 25 hours.
        let early = Self.local(madrid, 2026, 10, 25, 0, 30)
        let late = Self.local(madrid, 2026, 10, 25, 23, 30)
        #expect(madrid.isDate(early, inSameDayAs: late))
        let events = [StudyEvent(cardID: "A1-01", date: early, grade: "good"),
                      StudyEvent(cardID: "A1-02", date: late, grade: "good")]
        let stats = StatsCalculator.compute(events: events, today: late, calendar: madrid)
        #expect(stats.studiedToday == 2)
        #expect(stats.currentStreak == 1)
        let next = SpacedRepetitionScheduler.dueDate(from: late, interval: 1, calendar: madrid)
        #expect(next == Self.local(madrid, 2026, 10, 26, 0))
    }

    @Test("Introduction ledger buckets by the learning day")
    func ledgerLocal() {
        let evening = Self.local(Self.buenosAires, 2026, 10, 27, 22)
        let ledger = IntroductionLedger(events: [StudyEvent(cardID: "A1-01", date: evening, grade: "good")],
                                        day: Self.local(Self.buenosAires, 2026, 10, 27, 9), calendar: Self.buenosAires)
        #expect(ledger.count(of: .card) == 1)
    }
}
