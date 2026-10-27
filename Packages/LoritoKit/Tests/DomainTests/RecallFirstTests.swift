import Foundation
import Testing
@testable import Domain

private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
    var c = DateComponents(); c.year = y; c.month = m; c.day = d; c.hour = 12
    var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: "UTC")!
    return cal.date(from: c)!
}

private let today = day(2026, 10, 27)

@Suite("Russian day plurals")
struct RussianPluralTests {
    @Test("Day counts use the correct plural form")
    func days() {
        #expect(RussianPlural.days(1) == "1 день")
        #expect(RussianPlural.days(2) == "2 дня")
        #expect(RussianPlural.days(3) == "3 дня")
        #expect(RussianPlural.days(5) == "5 дней")
        #expect(RussianPlural.days(8) == "8 дней")
        #expect(RussianPlural.days(11) == "11 дней")
        #expect(RussianPlural.days(14) == "14 дней")
        #expect(RussianPlural.days(21) == "21 день")
        #expect(RussianPlural.days(22) == "22 дня")
        #expect(RussianPlural.days(111) == "111 дней")
    }
}

@Suite("Interval preview")
struct IntervalPreviewTests {
    static let states: [ReviewState?] = [
        nil,
        ReviewState(cardID: "A1-01"),
        ReviewState(cardID: "A1-01", interval: 0, repetitions: 0, status: .learning),
        ReviewState(cardID: "A1-01", easeFactor: 2.5, interval: 3, repetitions: 2, status: .review),
        ReviewState(cardID: "A1-01", easeFactor: 2.6, interval: 40, repetitions: 6, status: .review),
    ]

    @Test("Each caption equals the formatted scheduler interval", arguments: states)
    func matchesScheduler(state: ReviewState?) {
        let captions = IntervalPreview.captions(for: state, today: today)
        for grade in Grade.allCases {
            let next = FSRSScheduler.schedule(
                state: state ?? ReviewState(cardID: ""), grade: grade, today: today
            )
            #expect(captions[grade] == IntervalPreview.format(days: next.interval), "\(grade)")
        }
    }

    @Test("Again on a reviewed card reads сегодня")
    func againToday() {
        let reviewed = ReviewState(cardID: "A1-01", interval: 3, repetitions: 2, status: .review)
        #expect(IntervalPreview.captions(for: reviewed, today: today)[.again] == "сегодня")
    }

    @Test("Formatting: 0 → сегодня, plurals, ≥ 30 → months")
    func formatting() {
        #expect(IntervalPreview.format(days: 0) == "сегодня")
        #expect(IntervalPreview.format(days: 1) == "1 день")
        #expect(IntervalPreview.format(days: 3) == "3 дня")
        #expect(IntervalPreview.format(days: 8) == "8 дней")
        #expect(IntervalPreview.format(days: 21) == "21 день")
        #expect(IntervalPreview.format(days: 29) == "29 дней")
        #expect(IntervalPreview.format(days: 30) == "≈ 1 мес.")
        #expect(IntervalPreview.format(days: 75) == "≈ 3 мес.")
    }

    @Test("Spoken form says через N")
    func spoken() {
        #expect(IntervalPreview.spoken(days: 3) == "через 3 дня")
        #expect(IntervalPreview.spoken(days: 0) == "сегодня")
    }

    @Test("Preview is deterministic")
    func deterministic() {
        let s = ReviewState(cardID: "A1-01", interval: 5, repetitions: 3, status: .review)
        #expect(IntervalPreview.captions(for: s, today: today) == IntervalPreview.captions(for: s, today: today))
    }
}

@Suite("Session summary")
struct SessionSummaryTests {
    static func card(_ id: String, theme: String) -> Card {
        Card(id: id, level: .a1, themeID: theme, order: Int(id.suffix(2)) ?? 1, title: id, body: "")
    }

    @Test("Spec scenario: 10 cards, 8 first-try, theme to revisit")
    func specScenario() {
        var grades: [SessionGrade] = (1...8).map { SessionGrade(cardID: String(format: "A1-%02d", $0), grade: .good) }
        grades.append(SessionGrade(cardID: "A1-09", grade: .again))
        grades.append(SessionGrade(cardID: "A1-10", grade: .again))
        var cards: [String: Card] = [:]
        for g in grades { cards[g.cardID] = Self.card(g.cardID, theme: g.cardID >= "A1-09" ? "a1-2" : "a1-1") }
        let stats = StudyStats(currentStreak: 4, bestStreak: 9, studiedToday: 10, studiedThisWeek: 10, studiedAllTime: 10)

        let s = SessionSummary.make(grades: grades, cardsByID: cards, stats: stats)
        #expect(s.studied == 10)
        #expect(s.firstTryPercent == 80)
        #expect(s.currentStreak == 4)
        #expect(!s.isNewRecord)
        #expect(s.revisitThemeIDs == ["a1-2"])
    }

    @Test("Revisit themes: Опять and Трудно, top 3 by count, ties by first appearance")
    func revisitOrdering() {
        let pairs: [(String, String, Grade)] = [
            ("A1-01", "t1", .hard), ("A1-02", "t2", .again), ("A1-03", "t2", .hard),
            ("A1-04", "t3", .again), ("A1-05", "t4", .again), ("A1-06", "t4", .again),
            ("A1-07", "t4", .hard), ("A1-08", "t5", .good),
        ]
        let grades = pairs.map { SessionGrade(cardID: $0.0, grade: $0.2) }
        let cards = Dictionary(uniqueKeysWithValues: pairs.map { ($0.0, Self.card($0.0, theme: $0.1)) })
        let s = SessionSummary.make(grades: grades, cardsByID: cards, stats: .empty)
        #expect(s.revisitThemeIDs == ["t4", "t2", "t1"])
    }

    @Test("Distinct cards and first grade only")
    func distinctFirstGrade() {
        let grades = [SessionGrade(cardID: "A1-01", grade: .again), SessionGrade(cardID: "A1-01", grade: .good),
                      SessionGrade(cardID: "A1-02", grade: .easy)]
        let cards = ["A1-01": Self.card("A1-01", theme: "t1"), "A1-02": Self.card("A1-02", theme: "t1")]
        let s = SessionSummary.make(grades: grades, cardsByID: cards, stats: .empty)
        #expect(s.studied == 2)
        #expect(s.firstTryPercent == 50)
    }

    @Test("New record when streak equals best and is > 1")
    func newRecord() {
        func stats(_ c: Int, _ b: Int) -> StudyStats {
            StudyStats(currentStreak: c, bestStreak: b, studiedToday: 1, studiedThisWeek: 1, studiedAllTime: 1)
        }
        let g = [SessionGrade(cardID: "A1-01", grade: .good)]
        let cards = ["A1-01": Self.card("A1-01", theme: "t1")]
        #expect(SessionSummary.make(grades: g, cardsByID: cards, stats: stats(5, 5)).isNewRecord)
        #expect(!SessionSummary.make(grades: g, cardsByID: cards, stats: stats(1, 1)).isNewRecord)
        #expect(!SessionSummary.make(grades: g, cardsByID: cards, stats: stats(3, 7)).isNewRecord)
    }

    @Test("Empty session")
    func empty() {
        let s = SessionSummary.make(grades: [], cardsByID: [:], stats: .empty)
        #expect(s.studied == 0 && s.firstTryPercent == 0 && s.revisitThemeIDs.isEmpty)
    }
}

@Suite("Daily trap")
struct DailyTrapTests {
    static let candidates = (1...7).map { TrapCandidate(cardID: String(format: "A1-%02d", $0), text: "ошибка \($0)") }

    @Test("Same day, same trap — regardless of candidate order")
    func deterministic() {
        let a = DailyTrap.pick(candidates: Self.candidates, studiedIDs: [], day: today)
        let b = DailyTrap.pick(candidates: Self.candidates.reversed(), studiedIDs: [], day: day(2026, 10, 27))
        #expect(a != nil)
        #expect(a == b)
    }

    @Test("Stable hash is fixed (not per-process hashValue)")
    func stableHash() {
        #expect(DailyTrap.stableHash("2026-10-27") == DailyTrap.stableHash("2026-10-27"))
        #expect(DailyTrap.stableHash("") == 0xcbf29ce484222325)  // FNV-1a offset basis
    }

    @Test("Different days spread across candidates")
    func varies() {
        let picks = Set((1...20).compactMap { DailyTrap.pick(candidates: Self.candidates, studiedIDs: [], day: day(2026, 11, $0))?.cardID })
        #expect(picks.count > 1)
    }

    @Test("Prefers studied cards")
    func prefersStudied() {
        for d in 1...20 {
            let pick = DailyTrap.pick(candidates: Self.candidates, studiedIDs: ["A1-03", "A1-06"], day: day(2026, 11, d))
            #expect(["A1-03", "A1-06"].contains(pick?.cardID ?? ""))
        }
    }

    @Test("Nil when no candidates")
    func empty() {
        #expect(DailyTrap.pick(candidates: [], studiedIDs: ["A1-01"], day: today) == nil)
    }
}
