import Testing
import Foundation
@testable import Domain

private let utc: Calendar = Calendar.learningDay(in: TimeZone(identifier: "UTC")!)

private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
    utc.date(from: DateComponents(year: y, month: m, day: d))!
}

private func days(_ a: Date, _ b: Date) -> Int {
    utc.dateComponents([.day], from: utc.startOfDay(for: a), to: utc.startOfDay(for: b)).day ?? 0
}

private func schedule(_ s: ReviewState, _ g: Grade, today: Date, retention: Double = 0.9) -> ReviewState {
    FSRSScheduler.schedule(state: s, grade: g, today: today, retention: retention, calendar: utc)
}

/// A review card with a valid FSRS memory state, last reviewed `elapsed` days before `today`.
private func reviewCard(stability: Double, difficulty: Double = 5, elapsed: Int, today: Date,
                        repetitions: Int = 4) -> ReviewState {
    let last = utc.date(byAdding: .day, value: -elapsed, to: today)!
    let due = utc.date(byAdding: .day, value: Int(stability.rounded()), to: last)!
    return ReviewState(cardID: "X", interval: Int(stability.rounded()), repetitions: repetitions, dueDate: due,
                       lastGrade: "good", status: .review, stability: stability, difficulty: difficulty,
                       lastReviewDate: last, schedulerVersion: FSRSScheduler.version, fsrsDueDate: due)
}

@Suite("FSRS parameters")
struct FSRSParametersTests {
    @Test("Pinned FSRS-6 defaults (py-fsrs 6.3.2) and maximum interval")
    func pinned() {
        #expect(FSRSParameters.defaults.w == [
            0.212, 1.2931, 2.3065, 8.2956, 6.4133, 0.8334, 3.0194, 0.001, 1.8722, 0.1666, 0.796,
            1.4835, 0.0614, 0.2629, 1.6483, 0.6014, 1.8729, 0.5425, 0.0912, 0.0658, 0.1542,
        ])
        #expect(FSRSParameters.maxInterval == 365)
    }

    @Test("Retrievability is 90 % at t = S")
    func curve() {
        #expect(abs(FSRSScheduler.retrievability(elapsedDays: 12, stability: 12) - 0.9) < 1e-12)
        #expect(FSRSScheduler.retrievability(elapsedDays: 0, stability: 12) == 1)
    }
}

@Suite("FSRS scheduler")
struct FSRSSchedulerTests {
    let today = day(2026, 3, 10)

    @Test("Same inputs produce identical output")
    func deterministic() {
        let s = reviewCard(stability: 10, elapsed: 8, today: today)
        #expect(schedule(s, .good, today: today) == schedule(s, .good, today: today))
    }

    @Test("Grade is recorded; four grades give four distinct states")
    func distinct() {
        let s = reviewCard(stability: 10, elapsed: 8, today: today)
        let out = Grade.allCases.map { schedule(s, $0, today: today) }
        for (g, r) in zip(Grade.allCases, out) { #expect(r.lastGrade == g.rawValue) }
        #expect(Set(out).count == 4)
    }

    @Test("New card: memory initialised from defaults, easy > good ≥ hard, reps 1")
    func newCard() {
        let s = ReviewState(cardID: "X")
        #expect(s.stability == nil && s.difficulty == nil && s.lastReviewDate == nil)
        let hard = schedule(s, .hard, today: today)
        let good = schedule(s, .good, today: today)
        let easy = schedule(s, .easy, today: today)
        #expect(good.repetitions == 1 && good.status != .new)
        #expect(good.stability == 2.3065)
        #expect(good.difficulty != nil && good.lastReviewDate == today)
        #expect(easy.interval > good.interval && good.interval >= hard.interval && hard.interval >= 1)
        #expect(days(today, good.dueDate) == good.interval)
        #expect(good.interval <= 3)
    }

    @Test("New card graded again enters relearning, due today")
    func newAgain() {
        let r = schedule(ReviewState(cardID: "X"), .again, today: today)
        #expect(r.status == .learning && r.repetitions == 0 && r.interval == 0)
        #expect(days(today, r.dueDate) == 0)
    }

    @Test("Again on a review card: reps 0, learning, due today, lower S, higher D ≤ 10")
    func lapse() {
        let s = reviewCard(stability: 30, difficulty: 6, elapsed: 30, today: today)
        let r = schedule(s, .again, today: today)
        #expect(r.repetitions == 0 && r.status == .learning && r.interval == 0)
        #expect(days(today, r.dueDate) == 0)
        #expect(r.stability! < 30 && r.difficulty! > 6 && r.difficulty! <= 10)
        let maxed = schedule(reviewCard(stability: 30, difficulty: 10, elapsed: 30, today: today), .again, today: today)
        #expect(maxed.difficulty! <= 10)
    }

    @Test("Learning + hard stays learning, reps unchanged, ≥ 1 day")
    func learningHard() {
        let learning = schedule(ReviewState(cardID: "X"), .again, today: day(2026, 3, 9))
        let r = schedule(learning, .hard, today: today)
        #expect(r.status == .learning && r.repetitions == learning.repetitions)
        #expect(days(today, r.dueDate) >= 1)
    }

    @Test("Learning + good/easy graduates to review, reps + 1")
    func learningGraduates() {
        let learning = schedule(ReviewState(cardID: "X"), .again, today: day(2026, 3, 9))
        for g in [Grade.good, .easy] {
            let r = schedule(learning, g, today: today)
            #expect(r.status == .review && r.repetitions == learning.repetitions + 1)
        }
    }

    @Test("Retention 0.9 → interval == round(stability); 0.95 ≤ 0.9")
    func retention() {
        #expect(FSRSScheduler.interval(stability: 12.0, retention: 0.9) == 12)
        #expect(FSRSScheduler.interval(stability: 12.4, retention: 0.9) == 12)
        let s = reviewCard(stability: 10, elapsed: 10, today: today)
        let r90 = schedule(s, .good, today: today)
        let r95 = schedule(s, .good, today: today, retention: 0.95)
        #expect(r90.interval == Int(r90.stability!.rounded()))
        #expect(r95.interval <= r90.interval)
        #expect(r90.repetitions == s.repetitions + 1)
    }

    @Test("Elapsed days come from lastReviewDate; today becomes lastReviewDate")
    func elapsed() {
        let s = reviewCard(stability: 10, elapsed: 10, today: today)
        let r = schedule(s, .good, today: today)
        let R = FSRSScheduler.retrievability(elapsedDays: 10, stability: 10)
        let expected = FSRSScheduler.nextRecallStability(difficulty: 5, stability: 10, retrievability: R, grade: .good)
        #expect(abs(r.stability! - expected) < 1e-9)
        #expect(r.lastReviewDate == today)
        // A longer gap (lower R) grows stability more on a pass.
        let later = schedule(reviewCard(stability: 10, elapsed: 20, today: today), .good, today: today)
        #expect(later.stability! > r.stability!)
    }

    @Test("Ordered below the cap: again ≤ hard ≤ good < easy", arguments: [1.0, 3, 12, 40, 150])
    func ordered(stability: Double) {
        let s = reviewCard(stability: stability, difficulty: 8, elapsed: Int(stability.rounded()), today: today)
        let i = Dictionary(uniqueKeysWithValues: Grade.allCases.map { ($0, schedule(s, $0, today: today).interval) })
        #expect(i[.again]! <= i[.hard]! && i[.hard]! <= i[.good]!)
        if i[.good]! < FSRSParameters.maxInterval { #expect(i[.easy]! > i[.good]!) }
    }

    @Test("At the cap good and easy are both 365; captions equal")
    func cap() {
        let s = reviewCard(stability: 300, difficulty: 2, elapsed: 300, today: today)
        let good = schedule(s, .good, today: today)
        let easy = schedule(s, .easy, today: today)
        #expect(good.interval == 365 && easy.interval == 365)
        let captions = IntervalPreview.captions(for: s, today: today, retention: 0.9, calendar: utc)
        #expect(captions[.good] == captions[.easy])
    }

    @Test("Maximum interval clamps a 900-day result")
    func maxClamp() {
        #expect(FSRSScheduler.interval(stability: 900, retention: 0.9) == 365)
    }

    @Test("Suspended card is a no-op")
    func suspended() {
        var s = reviewCard(stability: 10, elapsed: 3, today: today)
        s.status = .suspended
        for g in Grade.allCases { #expect(schedule(s, g, today: today) == s) }
    }

    @Test("FSRS writes version 2 and fsrsDueDate == dueDate; keeps easeFactor")
    func bookkeeping() {
        var s = reviewCard(stability: 10, elapsed: 10, today: today)
        s.easeFactor = 2.1
        let r = schedule(s, .good, today: today)
        #expect(r.schedulerVersion == 2 && r.fsrsDueDate == r.dueDate && r.easeFactor == 2.1)
        #expect(days(today, r.dueDate) == r.interval)
    }
}

@Suite("FSRS cross-check with py-fsrs")
struct FSRSReferenceTests {
    struct Step: Decodable { let day: Int; let rating: Int; let stability: Double; let difficulty: Double }
    struct Fixture: Decodable { let parameters: [Double]; let histories: [[Step]] }

    static func fixture() throws -> Fixture {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("Fixtures/fsrs6_reference.json")
        return try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
    }

    @Test("Stability and difficulty match the reference within 1e-3")
    func matches() throws {
        let f = try Self.fixture()
        #expect(f.parameters == FSRSParameters.defaults.w)
        #expect(f.histories.count >= 3)
        let start = day(2026, 1, 1)
        for history in f.histories {
            var s = ReviewState(cardID: "X")
            for step in history {
                let today = utc.date(byAdding: .day, value: step.day, to: start)!
                let grade = [Grade.again, .hard, .good, .easy][step.rating - 1]
                s = schedule(s, grade, today: today)
                #expect(abs(s.stability! - step.stability) < 1e-3, "day \(step.day)")
                #expect(abs(s.difficulty! - step.difficulty) < 1e-3, "day \(step.day)")
            }
        }
    }
}

@Suite("SM-2 migration")
struct SM2MigrationTests {
    let today = day(2026, 3, 10)

    @Test("Spec scenario: interval 20, ease 2.5, due in 5 days → S 20, D mid, last review 15 days ago")
    func reviewCard() {
        let due = utc.date(byAdding: .day, value: 5, to: today)!
        let s = ReviewState(cardID: "X", easeFactor: 2.5, interval: 20, repetitions: 5, dueDate: due, status: .review)
        let m = SM2Migration.memoryState(from: s, calendar: utc)!
        #expect(m.stability == 20)
        #expect(m.difficulty == 5)
        #expect(days(m.lastReviewDate, today) == 15)
        // Grading applies the grade on top of the migrated state; ease untouched.
        let r = schedule(s, .good, today: today)
        let R = FSRSScheduler.retrievability(elapsedDays: 15, stability: 20)
        #expect(abs(r.stability! - FSRSScheduler.nextRecallStability(difficulty: 5, stability: 20, retrievability: R, grade: .good)) < 1e-9)
        #expect(r.easeFactor == 2.5)
    }

    @Test("Ease → difficulty: 2.5 → 5, 1.3 → 9, clamped to 1…10; stability ≥ 1")
    func mapping() {
        func d(_ ease: Double) -> Double {
            SM2Migration.memoryState(from: ReviewState(cardID: "X", easeFactor: ease, interval: 0, status: .learning), calendar: utc)!.difficulty
        }
        #expect(d(2.5) == 5)
        #expect(abs(d(1.3) - 9) < 1e-9)
        #expect(d(0.5) == 10 && d(5.0) == 1)
        let m = SM2Migration.memoryState(from: ReviewState(cardID: "X", interval: 0, dueDate: today, status: .learning), calendar: utc)!
        #expect(m.stability == 1 && m.lastReviewDate == today)
    }

    @Test("Existing lastReviewDate is kept")
    func keepsLastReview() {
        let last = day(2026, 3, 1)
        let s = ReviewState(cardID: "X", interval: 7, dueDate: today, status: .review, lastReviewDate: last)
        #expect(SM2Migration.memoryState(from: s, calendar: utc)!.lastReviewDate == last)
    }

    @Test("New and suspended cards are not migrated")
    func untouched() {
        #expect(SM2Migration.memoryState(from: ReviewState(cardID: "X"), calendar: utc) == nil)
        #expect(SM2Migration.memoryState(from: ReviewState(cardID: "X", interval: 5, status: .suspended), calendar: utc) == nil)
    }
}

@Suite("Scheduler version consistency")
struct SchedulerConsistencyTests {
    let today = day(2026, 3, 10)

    @Test("Valid only with version 2 and fsrsDueDate == dueDate")
    func validity() {
        let s = reviewCard(stability: 10, elapsed: 5, today: today)
        #expect(FSRSScheduler.hasValidMemory(s))
        var older = s; older.schedulerVersion = nil
        #expect(!FSRSScheduler.hasValidMemory(older))
        var moved = s; moved.dueDate = utc.date(byAdding: .day, value: 3, to: s.dueDate)!
        #expect(!FSRSScheduler.hasValidMemory(moved))
    }

    @Test("An older build moved dueDate → re-migrated from SM-2 fields before grading")
    func remigrates() {
        // FSRS state from 30 days ago, then an SM-2 build graded the card 4 days ago:
        // interval 12, due in 8 days, ease 2.3. The stale FSRS memory is ignored.
        var s = reviewCard(stability: 60, difficulty: 2, elapsed: 30, today: today)
        s.interval = 12
        s.easeFactor = 2.3
        s.dueDate = utc.date(byAdding: .day, value: 8, to: today)!
        let r = schedule(s, .good, today: today)
        let D = SM2Migration.difficulty(fromEase: 2.3)
        let R = FSRSScheduler.retrievability(elapsedDays: 4, stability: 12)
        #expect(abs(r.stability! - FSRSScheduler.nextRecallStability(difficulty: D, stability: 12, retrievability: R, grade: .good)) < 1e-9)
        #expect(r.schedulerVersion == 2 && r.fsrsDueDate == r.dueDate)
    }

    @Test("Ungraded cards keep their due dates (migration is lazy and pure)")
    func lazy() {
        let s = ReviewState(cardID: "X", easeFactor: 2.5, interval: 20, repetitions: 5, dueDate: day(2026, 3, 15), status: .review)
        _ = SM2Migration.memoryState(from: s, calendar: utc)
        _ = IntervalPreview.intervals(for: s, today: today, retention: 0.9, calendar: utc)
        #expect(s.dueDate == day(2026, 3, 15))
    }
}
