import Testing
import Foundation
@testable import Domain

private let cal = Calendar.learningDay(in: TimeZone(identifier: "UTC")!)
private let origin = cal.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 12))!
/// Day `n` after the origin, at noon.
private func d(_ n: Int) -> Date { cal.date(byAdding: .day, value: n, to: origin)! }
/// One graded event on each listed day.
private func log(_ days: [Int]) -> [StudyEvent] { days.map { StudyEvent(cardID: "A1-01", date: d($0), grade: "good") } }
private func report(_ days: [Int], today: Int) -> StreakReport {
    StatsCalculator.streak(events: log(days), today: d(today), calendar: cal)
}

@Suite("Streak freezes")
struct StreakFreezeTests {
    @Test("Spec: 7 consecutive days earn one freeze")
    func earned() { #expect(report(Array(0..<7), today: 7).freezes == 1) }

    @Test("Spec: 21 consecutive days → capped at 2")
    func cap() { #expect(report(Array(0..<21), today: 21).freezes == 2) }

    @Test("Spec: holding 1, missed yesterday → frozen, 0 held, streak kept")
    func consumed() {
        let r = report(Array(0..<7), today: 8)               // day 7 missed
        #expect(r.frozenYesterday && r.freezes == 0 && r.current == 7)
    }

    @Test("Spec: 10 days, one frozen miss, studied today → 11")
    func frozenKeeps() {
        #expect(report(Array(0..<10) + [11], today: 11).current == 11)
    }

    @Test("Consecutive misses consume one each; empty stock breaks the run")
    func consecutiveMisses() {
        let days = Array(0..<14)                               // 2 freezes
        #expect(report(days, today: 16).current == 14)           // 14, 15 frozen
        #expect(report(days, today: 17).current == 0)            // 16 breaks (revival pending, not studied)
    }

    @Test("Frozen days pause the earning counter; earning at the cap is lost")
    func earningCounter() {
        // 4 studied, frozen day needs a freeze: none yet → break. Use 7 + 1 frozen + 6 studied: 7th after = 13 consecutive studied.
        let r = report(Array(0..<7) + Array(8..<14), today: 14)  // day 7 frozen; counter: 7 → earn, then 6
        #expect(r.freezes == 0 && r.current == 13)
        let r2 = report(Array(0..<7) + Array(8..<15), today: 15) // 7 more studied after the frozen day → earn again
        #expect(r2.freezes == 1)
        #expect(report(Array(0..<28), today: 28).freezes == 2)    // 4 earnings, cap 2
    }

    @Test("Today is never frozen (savable)")
    func todaySavable() {
        let r = report(Array(0..<7), today: 7)
        #expect(!r.frozenYesterday && r.freezes == 1 && r.current == 7)
    }

    // The spec's "6 + frozen + 6" can't arise from a log: a freeze needs 7
    // studied days earlier in the same run, and a run only breaks once the
    // stock is empty. Same property with a reachable log: 7 + frozen + 5.
    @Test("Protected run counts as one: 7 studied + frozen + 5 studied → best 12")
    func bridgedBest() {
        let r = report(Array(0..<7) + Array(8..<13) + [30], today: 30)
        #expect(r.best == 12)
    }
}

@Suite("Streak revival")
struct StreakRevivalTests {
    // 40 studied days (0…39) earn 2 freezes: days 40, 41 frozen, day 42 = L (first lost day).
    let lost = Array(0..<40)
    let L = 42

    @Test("Spec: revive a 40-day streak with L+2, L+3, L+4 → 43")
    func revived() {
        let r = report(lost + [L + 2, L + 3, L + 4], today: L + 4)
        #expect(r.current == 43)
        #expect(r.revival == .completed(lost: 40))
    }

    @Test("Spec: three consecutive days ending L+9 → not revived")
    func windowMissed() {
        let r = report(lost + [L + 7, L + 8, L + 9], today: L + 9)
        #expect(r.current == 3 && r.revival == .none)
    }

    @Test("Spec: L+1, L+2 → current 2, in progress 2 of 3, deadline L+7, lost 40")
    func inProgress() {
        let r = report(lost + [L + 1, L + 2], today: L + 2)
        #expect(r.current == 2)
        #expect(r.revival == .inProgress(daysDone: 2, deadline: cal.startOfDay(for: d(L + 7)), lost: 40))
    }

    @Test("Run shorter than 2 is not revivable")
    func tooShort() {
        let r = report([0, 5, 6, 7], today: 7)
        #expect(r.current == 3 && r.revival == .none)
    }

    @Test("Second loss within 30 days of a revived loss is not revivable")
    func cooldown() {
        // Revive at L (=42), keep going to L+10, then lose again (no freezes left? earned anew) — make it a long gap.
        let revivedRun = lost + Array((L + 2)...(L + 10))          // run continues 40 + 9 = 49
        let r = report(revivedRun + [L + 20, L + 21, L + 22], today: L + 22)
        // Second loss: day L+11..: freezes from 9 new days? 7 → +1 freeze: L+11 frozen, L+12 lost (< 30 days after L).
        #expect(r.current == 3 && r.revival == .none)
    }

    @Test("Deterministic for the same log and today")
    func deterministic() {
        #expect(report(lost + [L + 1], today: L + 1) == report(lost + [L + 1], today: L + 1))
    }
}
