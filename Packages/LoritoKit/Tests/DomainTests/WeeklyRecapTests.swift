import Testing
import Foundation
@testable import Domain

private let cal = Calendar.learningDay(in: TimeZone(identifier: "UTC")!)
/// 2026-10-26 is a Monday.
private func date(_ m: Int, _ d: Int, _ h: Int = 10) -> Date {
    cal.date(from: DateComponents(year: 2026, month: m, day: d, hour: h))!
}
private func ev(_ id: String, _ d: Date, _ g: Grade = .good) -> StudyEvent { StudyEvent(cardID: id, date: d, grade: g.rawValue) }
private func card(_ id: String, _ level: CEFRLevel = .a1, mistakes: Bool = true) -> Card {
    Card(id: id, level: level, themeID: "\(level.rawValue.lowercased())-1", order: Int(id.suffix(2)) ?? 1, title: id,
         body: mistakes ? "## ⚠️ Частые ошибки\n- Ошибка \(id)\n" : "Текст")
}

@Suite("Monday weeks")
struct MondayWeekTests {
    @Test("Studied this week runs Monday–Sunday: Sunday belongs to the ending week, Monday starts at 0")
    func week() {
        let events = [ev("A1-01", date(10, 25)), ev("A1-02", date(10, 25))]         // Sunday
        #expect(StatsCalculator.compute(events: events, today: date(10, 25), calendar: cal).studiedThisWeek == 2)
        #expect(StatsCalculator.compute(events: events, today: date(10, 26), calendar: cal).studiedThisWeek == 0)
        #expect(StatsCalculator.compute(events: events + [ev("A1-03", date(10, 26))], today: date(10, 27),
                                        calendar: cal).studiedThisWeek == 1)
    }
}

@Suite("Weekly recap")
struct WeeklyRecapTests {
    let catalog = ContentCatalog(themes: [], cards: [card("A1-01"), card("A1-02"), card("A1-03", mistakes: false), card("A1-04")])
    let settings = UserSettings(targetLevel: .a1)

    func recap(_ events: [StudyEvent], reviews: [ReviewState] = [], today: Date = date(10, 26)) -> WeeklyRecap {
        WeeklyRecap.make(events: events, reviews: reviews, practice: [], catalog: catalog, settings: settings,
                         today: today, calendar: cal)
    }

    @Test("Covers the latest completed Mon–Sun week: days studied, new rules (.card only), long-term")
    func facts() {
        let events = [
            ev("A1-01", date(10, 12)),                        // introduced the week before
            ev("A1-01", date(10, 19)), ev("A1-02", date(10, 19)), ev("conj:ser:presente", date(10, 21)),
            ev("A1-03", date(10, 25)),                         // Sunday — still this week
            ev("A1-04", date(10, 26)),                         // Monday — next week
        ]
        let longTerm = [ReviewState(cardID: "A1-01", interval: 30, repetitions: 4, status: .review)]
        let r = recap(events, reviews: longTerm)
        #expect(r.weekStart == cal.startOfDay(for: date(10, 19)))
        #expect(r.weekID == "2026-W43")
        #expect(r.daysStudied == 3)
        #expect(r.newRules == 2)                              // A1-02, A1-03
        #expect(r.longTerm == 1)
        #expect(!r.isEmpty)
    }

    @Test("Top trap: most first-of-day Опять in the week among traps; fallback without a mistakes section")
    func topTrap() {
        let events = [ev("A1-02", date(10, 20), .again), ev("A1-04", date(10, 21), .again), ev("A1-04", date(10, 22), .again)]
        #expect(recap(events).topTrapCardID == "A1-04")
        #expect(recap([ev("A1-03", date(10, 20), .again)]).topTrapCardID == "A1-03")
        #expect(recap([ev("A1-02", date(10, 20))]).topTrapCardID == nil)
    }

    @Test("Empty week; deterministic")
    func empty() {
        let r = recap([ev("A1-01", date(10, 5))])
        #expect(r.isEmpty && r.daysStudied == 0 && r.newRules == 0)
        #expect(recap([ev("A1-01", date(10, 20))]) == recap([ev("A1-01", date(10, 20))]))
    }
}

@Suite("Level milestones")
struct LevelMilestoneTests {
    let cards = [card("A1-01"), card("A1-02"), card("A2-01", .a2)]

    func long(_ id: String) -> ReviewState { ReviewState(cardID: id, interval: 25, repetitions: 4, status: .review) }

    @Test("Closed when every non-suspended card item is long-term; included levels only; not celebrated")
    func closed() {
        let s = UserSettings(targetLevel: .a2)
        #expect(LevelMilestones.newlyClosed(cards: cards, reviews: [long("A1-01")], settings: s, celebrated: []).isEmpty)
        let suspended = ReviewState(cardID: "A1-02", status: .suspended)
        #expect(LevelMilestones.newlyClosed(cards: cards, reviews: [long("A1-01"), suspended], settings: s, celebrated: []) == [.a1])
        #expect(LevelMilestones.newlyClosed(cards: cards, reviews: [long("A1-01"), long("A1-02")], settings: s,
                                            celebrated: [.a1]).isEmpty)
        #expect(LevelMilestones.newlyClosed(cards: cards, reviews: [long("A2-01")], settings: UserSettings(targetLevel: .a1),
                                            celebrated: []).isEmpty)
    }

    @Test("Celebrated levels: sorted codes; union is commutative and idempotent")
    func union() {
        #expect(CelebratedLevels.encode([.a2, .a1]) == "A1,A2")
        #expect(CelebratedLevels.decode("A2,A1,zz") == [.a1, .a2])
        #expect(CelebratedLevels.decode(nil).isEmpty)
        let a = CelebratedLevels.merge("A1", "B1,A2")
        #expect(a == CelebratedLevels.merge("B1,A2", "A1") && a == "A1,A2,B1")
        #expect(CelebratedLevels.merge(a, a) == a)
    }
}
