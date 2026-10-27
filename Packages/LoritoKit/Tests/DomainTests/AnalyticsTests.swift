import Foundation
import Testing
@testable import Domain

@Suite("Analytics events")
struct AnalyticsEventTests {
    /// Parameter values must be enum raw values, ints or bools — never ids or text.
    private static let allowedValue = try! NSRegularExpression(pattern: #"^([a-z][a-zA-Z0-9]*|-?\d+|true|false)$"#)

    static let samples: [AnalyticsEvent] = [
        .onboardingStep(.level), .onboardingCompleted,
        .sessionStarted(due: 8, new: 4), .sessionCompleted(items: 12, firstTryPercent: 83),
        .itemGraded(kind: .card, grade: .good, revealed: true),
        .exerciseAnswered(type: .multipleChoice, correct: false),
        .reminderOpened, .streakExtended(length: 13), .streakLost(previous: 6),
    ]

    @Test("Every event encodes to a name and enum/int/bool parameters", arguments: samples)
    func encoding(event: AnalyticsEvent) {
        let record = AnalyticsRecord(event: event, date: Date(timeIntervalSince1970: 0))
        #expect(!record.name.isEmpty)
        for (key, value) in record.parameters {
            let ok = Self.allowedValue.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)) != nil
            #expect(ok, "\(record.name).\(key)=\(value)")
        }
    }

    @Test("Grade event carries kind, grade and revealed — no item id")
    func gradeEvent() {
        let r = AnalyticsRecord(event: .itemGraded(kind: .conjugation, grade: .again, revealed: true), date: Date())
        #expect(r.name == "itemGraded")
        #expect(r.parameters == ["kind": "conjugation", "grade": "again", "revealed": "true"])
    }

    @Test("Experiment and variant come from closed enums")
    func experiment() {
        let r = AnalyticsRecord(event: .sessionCompleted(items: 5, firstTryPercent: 60), date: Date(),
                                experiment: .firstSessionImmediately, variant: .b)
        #expect(r.parameters["experiment"] == "firstSessionImmediately")
        #expect(r.parameters["variant"] == "b")
    }

    @Test("Records round-trip through Codable (queue persistence)")
    func codable() throws {
        let r = AnalyticsRecord(event: .streakLost(previous: 6), date: Date(timeIntervalSince1970: 100))
        #expect(try JSONDecoder().decode(AnalyticsRecord.self, from: JSONEncoder().encode(r)) == r)
    }
}

@Suite("Event queue")
struct EventQueueTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    func rec(_ age: TimeInterval) -> AnalyticsRecord {
        AnalyticsRecord(event: .reminderOpened, date: now.addingTimeInterval(-age))
    }

    @Test("Append keeps order; cap drops the oldest")
    func cap() {
        var q = EventQueue(cap: 3)
        for i in 0..<5 { q.append(AnalyticsRecord(event: .streakExtended(length: i), date: now)) }
        #expect(q.records.map(\.parameters["length"]) == ["2", "3", "4"])
        #expect(EventQueue.defaultCap == 2000)
    }

    @Test("Batches of N from the front; removing a sent batch")
    func batches() {
        var q = EventQueue()
        for _ in 0..<5 { q.append(rec(0)) }
        #expect(q.nextBatch(size: 2).count == 2)
        q.removeFirst(2)
        #expect(q.records.count == 3)
    }

    @Test("Events older than 30 days are discarded unsent")
    func ageOut() {
        var q = EventQueue()
        q.append(rec(31 * 86_400)); q.append(rec(29 * 86_400)); q.append(rec(0))
        q.discardExpired(now: now)
        #expect(q.records.count == 2)
    }
}

@Suite("Streak loss detector")
struct StreakLossDetectorTests {
    @Test("Positive → 0 emits once with the previous length")
    func loss() {
        let first = StreakLossDetector.check(lastReported: 6, current: 0)
        #expect(first.event == .streakLost(previous: 6))
        #expect(first.report == 0)
        let again = StreakLossDetector.check(lastReported: first.report, current: 0)
        #expect(again.event == nil)
    }

    @Test("A streak the calculator keeps (e.g. a freeze) emits nothing")
    func kept() {
        #expect(StreakLossDetector.check(lastReported: 6, current: 6).event == nil)
        #expect(StreakLossDetector.check(lastReported: 6, current: 7).report == 7)
        #expect(StreakLossDetector.check(lastReported: nil, current: 0).event == nil)
    }
}
