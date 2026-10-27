import Testing
import Foundation
@testable import Domain

private let utc: Calendar = Calendar.learningDay(in: TimeZone(identifier: "UTC")!)
private func day(_ m: Int, _ d: Int, hour: Int = 10) -> Date {
    utc.date(from: DateComponents(year: 2026, month: m, day: d, hour: hour))!
}

private func cards(_ level: CEFRLevel, _ n: Int, theme: String? = nil) -> [Card] {
    (1...n).map {
        Card(id: "\(level.rawValue)-\(String(format: "%02d", $0))", level: level,
             themeID: theme ?? "\(level.rawValue.lowercased())-1", order: $0, title: "", body: "")
    }
}

private func introduced(_ ids: [String], status: ReviewStatus = .review) -> [ReviewState] {
    ids.map { ReviewState(cardID: $0, status: status) }
}

private func goal(_ level: CEFRLevel = .a2, target: Date, start: Date = day(1, 1), startIntroduced: Int = 0) -> LevelGoal {
    LevelGoal(targetLevel: level, targetDate: target, startDate: start, startIntroduced: startIntroduced)
}

@Suite("Goal pacing")
struct GoalPacingTests {
    let catalog = cards(.a1, 20) + cards(.a2, 10) + cards(.b1, 10)

    @Test("Spec: 30 cards and 10 learning days left, dailyNewCardCount 1 → 3")
    func paceRaises() {
        let p = GoalPacing.progress(goal: goal(target: day(3, 19)), cards: catalog, reviews: [],
                                    selectedThemeIDs: [], today: day(3, 10), calendar: utc)
        #expect(p.cardsLeft == 30 && p.learningDaysLeft == 10 && p.pace == 3)
        #expect(GoalPacing.newCardsPerDay(pace: p.pace, dailyNewCardCount: 1) == 3)
    }

    @Test("Spec: pace 2 never lowers dailyNewCardCount 4")
    func manualKept() {
        #expect(GoalPacing.newCardsPerDay(pace: 2, dailyNewCardCount: 4) == 4)
    }

    @Test("Rounds up; inclusive local days; at least one day")
    func roundingAndDays() {
        let p = GoalPacing.progress(goal: goal(target: day(3, 13)), cards: catalog, reviews: [],
                                    selectedThemeIDs: [], today: day(3, 10, hour: 23), calendar: utc)
        #expect(p.learningDaysLeft == 4 && p.pace == 8)            // 30 / 4 = 7.5 → 8
        let last = GoalPacing.progress(goal: goal(target: day(3, 10, hour: 1)), cards: catalog, reviews: [],
                                       selectedThemeIDs: [], today: day(3, 10, hour: 22), calendar: utc)
        #expect(last.learningDaysLeft == 1 && last.pace == 30)
    }

    @Test("Only in-scope .card items up to the target level; suspended excluded; introduced = has a state")
    func scope() {
        let extra = cards(.a2, 2, theme: "a2-9").map { Card(id: "A2-9\($0.id.suffix(1))", level: .a2, themeID: "a2-9",
                                                             order: 50, title: "", body: "") }
        let reviews = introduced(["A1-01", "A1-02"]) + introduced(["A1-03"], status: .suspended)
            + [ReviewState(cardID: "conj:hablar"), ReviewState(cardID: "word:casa")]
        let p = GoalPacing.progress(goal: goal(target: day(3, 19)), cards: catalog + extra, reviews: reviews,
                                    selectedThemeIDs: ["a1-1", "a2-1"], today: day(3, 10), calendar: utc)
        #expect(p.total == 29)                 // 20 + 10 − suspended A1-03; B1 and a2-9 out of scope
        #expect(p.introduced == 2 && p.cardsLeft == 27)
    }

    @Test("Budget cap: never above the daily new-introduction budget")
    func budgetCap() {
        #expect(GoalPacing.newCardsPerDay(pace: 25, dailyNewCardCount: 1) == DailyBudget.defaultTotal)
    }

    @Test("Deterministic for an injected today")
    func deterministic() {
        let a = GoalPacing.progress(goal: goal(target: day(4, 1)), cards: catalog, reviews: [], selectedThemeIDs: [],
                                    today: day(3, 10), calendar: utc)
        let b = GoalPacing.progress(goal: goal(target: day(4, 1)), cards: catalog, reviews: [], selectedThemeIDs: [],
                                    today: day(3, 10), calendar: utc)
        #expect(a == b)
    }
}

@Suite("Goal status")
struct GoalStatusTests {
    let catalog = cards(.a1, 20) + cards(.a2, 10)

    // Start 1 Jan with 0 introduced, target 31 Jan with 30 total: day 13 → expected 12.
    func status(introducedCount: Int, today: Date = day(1, 13)) -> GoalStatus {
        let ids = catalog.prefix(introducedCount).map(\.id)
        let p = GoalPacing.progress(goal: goal(target: day(1, 31)), cards: catalog, reviews: introduced(ids),
                                    selectedThemeIDs: [], today: today, calendar: utc)
        return GoalPacing.status(p, dailyNewCardCount: 1)
    }

    @Test("Spec: 12 expected, 14 introduced → on track")
    func onTrack() { #expect(status(introducedCount: 14) == .onTrack) }

    @Test("Spec: 12 expected, 9 introduced → behind by 3")
    func behind() { #expect(status(introducedCount: 9) == .behind(cards: 3)) }

    @Test("Budget caps the count below the pace → behind")
    func capped() {
        let big = cards(.a1, 30) + cards(.a2, 30)
        let p = GoalPacing.progress(goal: goal(target: day(1, 3), start: day(1, 1)), cards: big, reviews: [],
                                    selectedThemeIDs: [], today: day(1, 1), calendar: utc)
        #expect(p.pace > DailyBudget.defaultTotal)
        guard case .behind = GoalPacing.status(p, dailyNewCardCount: 1) else { Issue.record("not behind"); return }
    }

    @Test("Russian plurals: 1 карточку / 2 карточки / 5 карточек")
    func plurals() {
        #expect(GoalStatus.behind(cards: 1).text == "отстаёте на 1 карточку")
        #expect(GoalStatus.behind(cards: 2).text == "отстаёте на 2 карточки")
        #expect(GoalStatus.behind(cards: 5).text == "отстаёте на 5 карточек")
        #expect(GoalStatus.onTrack.text == "в графике")
    }
}

@Suite("Goal lifecycle")
struct GoalLifecycleTests {
    let catalog = cards(.a1, 3) + cards(.a2, 2)

    @Test("Achieved when every in-scope card is introduced; expired the learning day after the date")
    func level() {
        let all = introduced(catalog.map(\.id))
        let g = goal(target: day(3, 20))
        #expect(GoalPacing.evaluate(g, cards: catalog, reviews: all, selectedThemeIDs: [], today: day(3, 10), calendar: utc) == .achieved)
        #expect(GoalPacing.evaluate(g, cards: catalog, reviews: [], selectedThemeIDs: [], today: day(3, 20, hour: 23), calendar: utc) == .active)
        #expect(GoalPacing.evaluate(g, cards: catalog, reviews: [], selectedThemeIDs: [], today: day(3, 21, hour: 0), calendar: utc) == .expired)
    }

    @Test("Exam: achieved by the date passing or the done flag — never by cards")
    func exam() {
        let exam = ExamGoal(kind: .deleA2, date: day(5, 20))
        #expect(ExamCountdown.state(exam, today: day(5, 20), calendar: utc) == .active)
        #expect(ExamCountdown.state(exam, today: day(5, 21), calendar: utc) == .achieved)
        var done = exam
        done.done = true
        #expect(ExamCountdown.state(done, today: day(5, 1), calendar: utc) == .achieved)
        #expect(ExamCountdown.learningDaysLeft(exam, today: day(5, 18), calendar: utc) == 3)
    }

    @Test("DELE A2 preset writes a level goal A2 and an exam on the same date")
    func preset() {
        let (g, e) = GoalPresets.deleA2(date: day(5, 20), today: day(3, 1), introduced: 7, calendar: utc)
        #expect(g.targetLevel == .a2 && g.targetDate == e.date && e.kind == .deleA2)
        #expect(g.startIntroduced == 7 && g.state == .active)
    }

    @Test("Target date must be after today")
    func pastDate() {
        #expect(!LevelGoal.isValidTargetDate(day(3, 10, hour: 23), today: day(3, 10), calendar: utc))
        #expect(LevelGoal.isValidTargetDate(day(3, 11), today: day(3, 10), calendar: utc))
    }
}

@Suite("Goal-raised new-card limit in the plan")
struct GoalPlanLimitTests {
    let catalog = cards(.a1, 20) + cards(.a2, 10)

    func newCount(goal: LevelGoal?, perDay: Int) -> Int {
        let base = UserSettings(targetLevel: .a2, dailyNewCardCount: perDay)
        let settings = GoalPacing.planSettings(base, goal: goal, cards: catalog, reviews: [], today: day(3, 10), calendar: utc)
        return DailyPlanner.composePlan(DailyPlanRequest(cards: catalog, reviews: [], settings: settings, today: day(3, 10),
                                                         calendar: utc)).counts.newCount
    }

    @Test("Spec: active goal with pace 3 and dailyNewCardCount 1 → up to 3 new cards")
    func raised() { #expect(newCount(goal: goal(target: day(3, 19)), perDay: 1) == 3) }

    @Test("Spec: no goal keeps dailyNewCardCount 2")
    func noGoal() { #expect(newCount(goal: nil, perDay: 2) == 2) }

    @Test("Expired or achieved goals don't change the plan")
    func inactive() {
        var g = goal(target: day(3, 1))
        #expect(newCount(goal: g, perDay: 1) == 1)                // expired (date passed)
        g = goal(target: day(3, 19)); g.state = .achieved
        #expect(newCount(goal: g, perDay: 1) == 1)
    }
}
