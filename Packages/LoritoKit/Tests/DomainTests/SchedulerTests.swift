import Testing
import Foundation
@testable import Domain

private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    return cal.date(from: DateComponents(year: y, month: m, day: d))!
}

private func daysBetween(_ a: Date, _ b: Date) -> Int {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    return cal.dateComponents([.day], from: a, to: b).day ?? 0
}

@Suite("SRS scheduler")
struct SchedulerTests {
    let today = day(2026, 1, 1)

    @Test("Same inputs produce identical output")
    func deterministic() {
        let s = ReviewState(cardID: "X", interval: 10, repetitions: 2, status: .review)
        let a = SpacedRepetitionScheduler.schedule(state: s, grade: .good, today: today)
        let b = SpacedRepetitionScheduler.schedule(state: s, grade: .good, today: today)
        #expect(a == b)
    }

    @Test("Grade is recorded as lastGrade")
    func recordsGrade() {
        let s = ReviewState(cardID: "X")
        #expect(SpacedRepetitionScheduler.schedule(state: s, grade: .easy, today: today).lastGrade == "easy")
    }

    @Test("New + good: reps 1, leaves new, short interval")
    func newGood() {
        let s = ReviewState(cardID: "X", status: .new)
        let r = SpacedRepetitionScheduler.schedule(state: s, grade: .good, today: today)
        #expect(r.repetitions == 1)
        #expect(r.status != .new)
        #expect(r.interval >= 1 && r.interval <= 2)
    }

    @Test("New + easy interval exceeds new + good")
    func newEasyLongerThanGood() {
        let s = ReviewState(cardID: "X", status: .new)
        let good = SpacedRepetitionScheduler.schedule(state: s, grade: .good, today: today)
        let easy = SpacedRepetitionScheduler.schedule(state: s, grade: .easy, today: today)
        #expect(easy.interval > good.interval)
    }

    @Test("New + again enters relearning")
    func newAgain() {
        let s = ReviewState(cardID: "X", status: .new)
        let r = SpacedRepetitionScheduler.schedule(state: s, grade: .again, today: today)
        #expect(r.status == .learning)
        #expect(r.repetitions == 0)
    }

    @Test("Again on a review card resets and lowers ease")
    func againLapses() {
        let s = ReviewState(cardID: "X", easeFactor: 2.5, interval: 20, repetitions: 4, status: .review)
        let r = SpacedRepetitionScheduler.schedule(state: s, grade: .again, today: today)
        #expect(r.repetitions == 0)
        #expect(r.status == .learning)
        #expect(r.easeFactor < 2.5)
        #expect(daysBetween(today, r.dueDate) <= 1)
    }

    @Test("Ease never drops below the floor")
    func easeFloor() {
        var s = ReviewState(cardID: "X", easeFactor: 1.4, interval: 5, repetitions: 3, status: .review)
        for _ in 0..<10 {
            s = SpacedRepetitionScheduler.schedule(state: s, grade: .again, today: today)
        }
        #expect(s.easeFactor >= 1.3)
    }

    @Test("Learning graduates to review on good")
    func learningGraduates() {
        let s = ReviewState(cardID: "X", interval: 1, repetitions: 1, status: .learning)
        let r = SpacedRepetitionScheduler.schedule(state: s, grade: .good, today: today)
        #expect(r.status == .review)
        #expect(r.repetitions == 2)
    }

    @Test("Learning never returns to new")
    func learningNeverNew() {
        let s = ReviewState(cardID: "X", interval: 1, repetitions: 1, status: .learning)
        for g in Grade.allCases {
            #expect(SpacedRepetitionScheduler.schedule(state: s, grade: g, today: today).status != .new)
        }
    }

    @Test("Review + good multiplies interval by ease and increments reps")
    func reviewGood() {
        let s = ReviewState(cardID: "X", easeFactor: 2.5, interval: 10, repetitions: 3, status: .review)
        let r = SpacedRepetitionScheduler.schedule(state: s, grade: .good, today: today)
        #expect(r.interval == 25)              // 10 * 2.5
        #expect(r.repetitions == 4)
        #expect(r.easeFactor == 2.5)           // good does not decrease ease
        #expect(daysBetween(today, r.dueDate) == 25)
    }

    @Test("Hard < good interval and lowers ease; easy > good and raises ease")
    func hardEasyVsGood() {
        let s = ReviewState(cardID: "X", easeFactor: 2.5, interval: 10, repetitions: 3, status: .review)
        let good = SpacedRepetitionScheduler.schedule(state: s, grade: .good, today: today)
        let hard = SpacedRepetitionScheduler.schedule(state: s, grade: .hard, today: today)
        let easy = SpacedRepetitionScheduler.schedule(state: s, grade: .easy, today: today)
        #expect(hard.interval < good.interval)
        #expect(hard.easeFactor < s.easeFactor)
        #expect(easy.interval > good.interval)
        #expect(easy.easeFactor > s.easeFactor)
    }

    @Test("Suspended card is a no-op")
    func suspendedNoOp() {
        let s = ReviewState(cardID: "X", easeFactor: 2.0, interval: 7, repetitions: 2,
                            dueDate: day(2026, 1, 5), lastGrade: "good", status: .suspended)
        for g in Grade.allCases {
            #expect(SpacedRepetitionScheduler.schedule(state: s, grade: g, today: today) == s)
        }
    }

    @Test("DueDate = today + interval (whole days)")
    func dueDateMath() {
        let s = ReviewState(cardID: "X", easeFactor: 2.5, interval: 10, repetitions: 1, status: .review)
        let r = SpacedRepetitionScheduler.schedule(state: s, grade: .good, today: today)
        #expect(r.dueDate == day(2026, 1, 26))  // Jan 1 + 25
    }

    @Test("Clock injection shifts dueDate by the today difference")
    func clockInjection() {
        let s = ReviewState(cardID: "X", easeFactor: 2.5, interval: 10, repetitions: 1, status: .review)
        let r1 = SpacedRepetitionScheduler.schedule(state: s, grade: .good, today: day(2026, 1, 1))
        let r2 = SpacedRepetitionScheduler.schedule(state: s, grade: .good, today: day(2026, 1, 8))
        #expect(daysBetween(r1.dueDate, r2.dueDate) == 7)
    }
}
