import Testing
import Foundation
@testable import Domain

private let cal = Calendar.learningDay(in: TimeZone(identifier: "UTC")!)
private let origin = cal.date(from: DateComponents(year: 2026, month: 3, day: 1, hour: 9))!
private func d(_ n: Int, hour: Int = 0) -> Date { cal.date(byAdding: .hour, value: n * 24 + hour, to: origin)! }
private func ev(_ card: String, _ grade: Grade, _ day: Int, hour: Int = 0) -> StudyEvent {
    StudyEvent(cardID: card, date: d(day, hour: hour), grade: grade.rawValue)
}

private func card(_ id: String, level: CEFRLevel = .a1, order: Int, mistakes: Bool = true) -> Card {
    let body = "> **Суть**\n> Текст.\n\n" + (mistakes ? "## ⚠️ Частые ошибки (для русскоязычных)\n- Ошибка \(id)\n- вторая\n" : "")
    return Card(id: id, level: level, themeID: "\(level.rawValue.lowercased())-1", order: order, title: id, body: body)
}

private let catalog = ContentCatalog(themes: [], cards: [
    card("A1-01", order: 1), card("A1-02", order: 2), card("A1-03", order: 3, mistakes: false),
    card("A1-04", order: 4), card("B1-01", level: .b1, order: 1),
])
private let scopeA1 = UserSettings(targetLevel: .a1)
private let scopeB1 = UserSettings(targetLevel: .b1)

private func traps(_ events: [StudyEvent], practice: [TrapPracticeEvent] = [], settings: UserSettings = scopeA1,
                   today: Int = 10) -> [PersonalTrap] {
    PersonalTraps.list(events: events, practice: practice, catalog: catalog, settings: settings, today: d(today), calendar: cal)
}

@Suite("Personal traps")
struct PersonalTrapsTests {
    @Test("First-of-day Опять on a card with mistakes creates a trap; later same-day grades ignored")
    func created() {
        let t = traps([ev("A1-01", .again, 1), ev("A1-01", .good, 1, hour: 2)])
        #expect(t.map(\.cardID) == ["A1-01"])
        #expect(t.first?.failures == 1 && t.first?.firstMistake == "Ошибка A1-01")
        // A pass first that day, then Опять (in-session relearn / exercise) → no trap.
        #expect(traps([ev("A1-02", .good, 1), ev("A1-02", .again, 1, hour: 3)]).isEmpty)
    }

    @Test("An exercise failure (one graded study event) counts once")
    func exerciseOnce() {
        #expect(traps([ev("A1-01", .again, 1)]).first?.failures == 1)
    }

    @Test("Трудно is neutral; no mistakes section → no trap; non-card items ignored")
    func ignored() {
        #expect(traps([ev("A1-01", .hard, 1)]).isEmpty)
        #expect(traps([ev("A1-03", .again, 1)]).isEmpty)
        #expect(traps([ev("conj:hablar", .again, 1), ev("word:casa", .again, 1)]).isEmpty)
    }

    @Test("Scope filter hides out-of-scope traps and restores them when scope widens")
    func scope() {
        let events = [ev("B1-01", .again, 1), ev("A1-01", .again, 2)]
        #expect(traps(events).map(\.cardID) == ["A1-01"])
        #expect(Set(traps(events, settings: scopeB1).map(\.cardID)) == ["A1-01", "B1-01"])
    }

    @Test("Ranking: last failure day desc, failures desc, card order")
    func ranking() {
        let events = [ev("A1-04", .again, 1), ev("A1-04", .again, 3), ev("A1-02", .again, 3),
                      ev("A1-01", .again, 5), ev("A1-01", .again, 2) ]
        #expect(traps(events).map(\.cardID) == ["A1-01", "A1-04", "A1-02"])
        let tie = [ev("A1-04", .again, 3), ev("A1-02", .again, 3)]
        #expect(traps(tie).map(\.cardID) == ["A1-02", "A1-04"])
    }

    @Test("Resolved after two first-of-day passes or «Ясно»; reopened by a later failure")
    func resolution() {
        let failed = [ev("A1-01", .again, 1)]
        #expect(traps(failed + [ev("A1-01", .good, 2)]).count == 1)
        #expect(traps(failed + [ev("A1-01", .good, 2), ev("A1-01", .easy, 3)]).isEmpty)
        // Two passes on the same day count once.
        #expect(traps(failed + [ev("A1-01", .good, 2), ev("A1-01", .good, 2, hour: 2)]).count == 1)
        let clear = [TrapPracticeEvent(cardID: "A1-01", date: d(2), outcome: .clear),
                     TrapPracticeEvent(cardID: "A1-01", date: d(3), outcome: .clear)]
        #expect(traps(failed, practice: clear).isEmpty)
        let still = [TrapPracticeEvent(cardID: "A1-01", date: d(2), outcome: .stillConfused)]
        #expect(traps(failed, practice: still).count == 1)
        #expect(traps(failed + [ev("A1-01", .good, 2), ev("A1-01", .good, 3), ev("A1-01", .again, 4)]).count == 1)
    }

    @Test("Deterministic for the same inputs")
    func deterministic() {
        let e = [ev("A1-01", .again, 1), ev("A1-02", .again, 1)]
        #expect(traps(e) == traps(e))
    }
}

@Suite("Trap of the day with personal traps")
struct TrapOfDayPersonalTests {
    let candidates = ["A1-01", "A1-02", "A1-04", "B1-01"].map { TrapCandidate(cardID: $0, text: "x") }

    @Test("Prefers in-scope personal traps, stable within a day; unchanged without them")
    func picker() {
        let base = DailyTrap.pick(candidates: candidates, studiedIDs: [], personalTrapIDs: [], day: d(1), calendar: cal)
        #expect(base == DailyTrap.pick(candidates: candidates, studiedIDs: [], day: d(1), calendar: cal))
        let p = DailyTrap.pick(candidates: candidates, studiedIDs: [], personalTrapIDs: ["A1-04"], day: d(1), calendar: cal)
        #expect(p?.cardID == "A1-04")
        let a = DailyTrap.pick(candidates: candidates, studiedIDs: [], personalTrapIDs: ["A1-01", "A1-02", "A1-04"],
                               day: d(1), calendar: cal)
        let b = DailyTrap.pick(candidates: candidates, studiedIDs: ["A1-02"], personalTrapIDs: ["A1-04", "A1-02", "A1-01"],
                               day: d(1, hour: 10), calendar: cal)
        #expect(a == b)
        #expect(["A1-01", "A1-02", "A1-04"].contains(a?.cardID ?? ""))
    }
}
