import Foundation
import Testing
@testable import Domain

@Suite("Item kinds")
struct ItemKindTests {
    @Test("Prefixes map to kinds")
    func parse() {
        #expect(ItemKind.parse("A1-07") == .card)
        #expect(ItemKind.parse("C2-30") == .card)
        #expect(ItemKind.parse("conj:hablar:presente") == .conjugation)
        #expect(ItemKind.parse("word:casa") == .word)
        #expect(ItemKind.parse("ccse:0123") == .ccse)
    }

    @Test("Anything else is unknown")
    func unknown() {
        for id in ["foo:bar", "", "A1-7", "D1-01", "a1-07", "conj:", "word:", "ccse:", "A1-07x", "conj:hablar"] {
            #expect(ItemKind.parse(id) == .unknown, "\(id)")
        }
    }
}

@Suite("Card-only counts")
struct CardOnlyCountsTests {
    private static let today = Calendar.learningDay(in: TimeZone(identifier: "UTC")!).date(
        from: DateComponents(year: 2026, month: 10, day: 27, hour: 12))!

    private static func ev(_ id: String, _ offset: TimeInterval = 0) -> StudyEvent {
        StudyEvent(cardID: id, date: today.addingTimeInterval(offset), grade: "good")
    }

    @Test("Stats count only card events; drills keep the streak alive")
    func stats() {
        let cal = Calendar.learningDay(in: TimeZone(identifier: "UTC")!)
        let events = [Self.ev("A1-01"), Self.ev("A1-02")] + (1...10).map { Self.ev("conj:hablar:t\($0)") }
            + [StudyEvent(cardID: "conj:ser:presente", date: Self.today.addingTimeInterval(-86_400), grade: "good")]
        let stats = StatsCalculator.compute(events: events, today: Self.today, calendar: cal)
        #expect(stats.studiedToday == 2)
        #expect(stats.studiedAllTime == 2)
        #expect(stats.currentStreak == 2)
    }

    @Test("Session summary counts only cards")
    func summary() {
        let grades = [SessionGrade(cardID: "A1-01", grade: .good), SessionGrade(cardID: "conj:ser:presente", grade: .good)]
        let card = Card(id: "A1-01", level: .a1, themeID: "t", order: 1, title: "A", body: "")
        let s = SessionSummary.make(grades: grades, cardsByID: ["A1-01": card], stats: .empty)
        #expect(s.studied == 1)
    }

    @Test("Unknown and non-card review states never enter the daily plan")
    func planner() {
        let cal = Calendar.learningDay(in: TimeZone(identifier: "UTC")!)
        let reviews = [
            ReviewState(cardID: "foo:bar", dueDate: .distantPast, status: .review),
            ReviewState(cardID: "conj:ser:presente", dueDate: .distantPast, status: .review),
            ReviewState(cardID: "A1-01", dueDate: .distantPast, status: .review),
        ]
        let card = Card(id: "A1-01", level: .a1, themeID: "a1-1", order: 1, title: "A", body: "")
        let plan = DailyPlanner.composePlan(DailyPlanRequest(
            cards: [card], reviews: reviews,
            settings: UserSettings(targetLevel: .a1, selectedThemeIDs: [], dailyNewCardCount: 1),
            today: Self.today, calendar: cal))
        #expect(plan.queue.map(\.cardID) == ["A1-01"])
    }
}
