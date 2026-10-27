import Foundation

public enum GoalState: String, Codable, Sendable, CaseIterable {
    case active, achieved, expired
}

/// Optional level goal: reach every card up to `targetLevel` by `targetDate`.
public struct LevelGoal: Codable, Sendable, Hashable {
    public var targetLevel: CEFRLevel
    public var targetDate: Date
    /// Captured at creation: the baseline for the status line.
    public var startDate: Date
    public var startIntroduced: Int
    public var state: GoalState

    public init(targetLevel: CEFRLevel, targetDate: Date, startDate: Date, startIntroduced: Int,
                state: GoalState = .active) {
        self.targetLevel = targetLevel
        self.targetDate = targetDate
        self.startDate = startDate
        self.startIntroduced = startIntroduced
        self.state = state
    }

    /// A target date must lie on a later learning day than today.
    public static func isValidTargetDate(_ date: Date, today: Date, calendar: Calendar = .learningDay) -> Bool {
        calendar.startOfDay(for: date) > calendar.startOfDay(for: today)
    }
}

public enum ExamKind: String, Codable, Sendable, CaseIterable {
    case deleA2, ccse

    public var title: String {
        switch self {
        case .deleA2: "DELE A2"
        case .ccse: "CCSE"
        }
    }
}

/// Optional exam date, independent of card progress.
public struct ExamGoal: Codable, Sendable, Hashable {
    public var kind: ExamKind
    public var date: Date
    public var done: Bool

    public init(kind: ExamKind, date: Date, done: Bool = false) {
        self.kind = kind
        self.date = date
        self.done = done
    }
}

/// Snapshot of a level goal's progress on a learning day.
public struct GoalProgress: Sendable, Hashable {
    /// In-scope, non-suspended cards up to the target level.
    public let total: Int
    public let introduced: Int
    public var cardsLeft: Int { max(0, total - introduced) }
    /// Local learning days from today through the target date, inclusive.
    public let learningDaysLeft: Int
    /// ceil(cardsLeft / max(daysLeft, 1)).
    public let pace: Int
    /// Introductions expected by today (linear from start to target).
    public let expectedIntroduced: Int
}

public enum GoalStatus: Sendable, Hashable {
    case onTrack
    case behind(cards: Int)

    public var text: String {
        switch self {
        case .onTrack: "в графике"
        case .behind(let n): "отстаёте на \(n) \(RussianPlural.form(n, one: "карточку", few: "карточки", many: "карточек"))"
        }
    }
}

/// Pure pacing for the level goal (study-goal): it can only raise the daily
/// new-card count, never lower the user's setting, and never exceeds the
/// daily new-introduction budget.
public enum GoalPacing {
    public static func progress(goal: LevelGoal, cards: [Card], reviews: [ReviewState], selectedThemeIDs: [String],
                                today: Date, calendar: Calendar = .learningDay) -> GoalProgress {
        let (total, introduced) = counts(level: goal.targetLevel, cards: cards, reviews: reviews,
                                         selectedThemeIDs: selectedThemeIDs)
        let today0 = calendar.startOfDay(for: today)
        let target0 = calendar.startOfDay(for: goal.targetDate)
        let daysLeft = max(0, (calendar.dateComponents([.day], from: today0, to: target0).day ?? 0) + 1)
        let left = max(0, total - introduced)
        let pace = left == 0 ? 0 : (left + max(daysLeft, 1) - 1) / max(daysLeft, 1)

        let start0 = calendar.startOfDay(for: goal.startDate)
        let span = max(1, calendar.dateComponents([.day], from: start0, to: target0).day ?? 1)
        let elapsed = min(span, max(0, calendar.dateComponents([.day], from: start0, to: today0).day ?? 0))
        let expected = goal.startIntroduced + (total - goal.startIntroduced) * elapsed / span
        return GoalProgress(total: total, introduced: introduced, learningDaysLeft: daysLeft, pace: pace,
                            expectedIntroduced: expected)
    }

    /// max(pace, dailyNewCardCount), capped by the daily new-introduction budget.
    public static func newCardsPerDay(pace: Int, dailyNewCardCount: Int) -> Int {
        min(max(pace, dailyNewCardCount), DailyBudget.defaultTotal)
    }

    public static func status(_ p: GoalProgress, dailyNewCardCount: Int) -> GoalStatus {
        let shortfall = p.expectedIntroduced - p.introduced
        let capped = newCardsPerDay(pace: p.pace, dailyNewCardCount: dailyNewCardCount) < p.pace
        if capped { return .behind(cards: max(shortfall, p.pace - DailyBudget.defaultTotal)) }
        return shortfall > 0 ? .behind(cards: shortfall) : .onTrack
    }

    /// Achieved once every in-scope card is introduced; expired the learning day after the date.
    public static func evaluate(_ goal: LevelGoal, cards: [Card], reviews: [ReviewState], selectedThemeIDs: [String],
                                today: Date, calendar: Calendar = .learningDay) -> GoalState {
        guard goal.state == .active else { return goal.state }
        let (total, introduced) = counts(level: goal.targetLevel, cards: cards, reviews: reviews,
                                         selectedThemeIDs: selectedThemeIDs)
        if introduced >= total { return .achieved }
        return calendar.startOfDay(for: today) > calendar.startOfDay(for: goal.targetDate) ? .expired : .active
    }

    /// Settings for plan recomputation: `dailyNewCardCount` raised by an
    /// active level goal (the composer itself is unchanged).
    public static func planSettings(_ settings: UserSettings, goal: LevelGoal?, cards: [Card], reviews: [ReviewState],
                                    today: Date, calendar: Calendar = .learningDay) -> UserSettings {
        guard let goal, evaluate(goal, cards: cards, reviews: reviews, selectedThemeIDs: settings.selectedThemeIDs,
                                 today: today, calendar: calendar) == .active else { return settings }
        let p = progress(goal: goal, cards: cards, reviews: reviews, selectedThemeIDs: settings.selectedThemeIDs,
                         today: today, calendar: calendar)
        var out = settings
        out.dailyNewCardCount = newCardsPerDay(pace: p.pace, dailyNewCardCount: settings.dailyNewCardCount)
        return out
    }

    /// (in-scope non-suspended cards up to `level`, how many of them have a review state).
    static func counts(level: CEFRLevel, cards: [Card], reviews: [ReviewState], selectedThemeIDs: [String]) -> (Int, Int) {
        let themes = Set(selectedThemeIDs)
        let byID = Dictionary(reviews.filter { $0.kind == .card }.map { ($0.cardID, $0) }, uniquingKeysWith: { a, _ in a })
        let scope = cards.filter { $0.level <= level && (themes.isEmpty || themes.contains($0.themeID))
            && byID[$0.id]?.status != .suspended }
        return (scope.count, scope.filter { byID[$0.id] != nil }.count)
    }
}

public enum ExamCountdown {
    /// Achieved when the learning day after the exam arrives or it is marked done.
    public static func state(_ exam: ExamGoal, today: Date, calendar: Calendar = .learningDay) -> GoalState {
        if exam.done { return .achieved }
        return calendar.startOfDay(for: today) > calendar.startOfDay(for: exam.date) ? .achieved : .active
    }

    public static func learningDaysLeft(_ exam: ExamGoal, today: Date, calendar: Calendar = .learningDay) -> Int {
        let d = calendar.dateComponents([.day], from: calendar.startOfDay(for: today),
                                        to: calendar.startOfDay(for: exam.date)).day ?? 0
        return max(0, d + 1)
    }
}

public enum GoalPresets {
    /// "DELE A2": a level goal A2 and a DELE A2 exam on the same date.
    public static func deleA2(date: Date, today: Date, introduced: Int,
                              calendar: Calendar = .learningDay) -> (LevelGoal, ExamGoal) {
        let start = calendar.startOfDay(for: today)
        return (LevelGoal(targetLevel: .a2, targetDate: date, startDate: start, startIntroduced: introduced),
                ExamGoal(kind: .deleA2, date: date))
    }
}
