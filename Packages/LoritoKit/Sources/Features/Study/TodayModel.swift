import Foundation
import Observation
import Domain
import DesignSystem

/// Drives the Today screen. Reads the day's queue and counts from `daily-plan`
/// (it does not compute the queue itself), subtracts cards already graded today
/// so a returning user resumes where they left off, and derives the day-progress
/// numbers and the empty/all-done states.
@MainActor
@Observable
public final class TodayModel {
    private let store: UserDataStore
    private let catalog: ContentCatalog
    private let now: () -> Date
    private let boosts: FirstSessionBoostStore

    /// Cards still to study today, in queue order.
    public private(set) var remaining: [PlanEntry] = []
    public private(set) var dueRemaining = 0
    public private(set) var newRemaining = 0
    /// Cards graded so far today (drives the progress indicator).
    public private(set) var studiedCount = 0
    /// "Ловушка дня": one mistakes item from an in-scope card, stable per day.
    public private(set) var trap: TrapCandidate?
    /// The last seven days ending today (week strip).
    public private(set) var week: [WeekDay] = []
    /// The one prompt of this visit (goal / variant …), if any.
    public private(set) var prompt: TodayPrompt?
    /// Open prompts in priority order; registered by `study-goal` and
    /// `regional-variants`.
    public var promptCandidates: [TodayPrompt] = [] {
        didSet { prompt = promptSlot.prompt(candidates: promptCandidates, events: (try? store.allEvents()) ?? []) }
    }
    private let promptSlot: TodayPromptSlot
    /// The goal has an exam date (study-goal) → Today offers the exam path.
    public private(set) var hasExamGoal = false
    /// CCSE questions planned today (exam-path-dele-ccse).
    public private(set) var ccseCount = 0
    /// Weekly recap of the completed Monday–Sunday week, shown once from Monday.
    public private(set) var recap: WeeklyRecap?
    /// A newly closed level to celebrate (shown once).
    public private(set) var milestone: CEFRLevel?
    /// Today's conjugation items (conjugation-trainer); empty when the trainer is off.
    public private(set) var conjugationItems: [String] = []
    /// In-scope personal traps (personal-traps).
    public private(set) var personalTraps: [PersonalTrap] = []
    /// Streak-protection banner (freeze used / revival in progress).
    public private(set) var streakBanner: StreakBanner?
    private let streakLedger: StreakBannerLedger
    /// Goal card lines (study-goal).
    public private(set) var goalLines: [TodayGoalLine] = []
    private let goalBuilder: TodayGoalBuilder
    /// End states shown during this model's lifetime keep showing until it goes away.
    private var shownEndStates: Set<String> = []
    /// Long-term memory across the included levels (regular-width dashboard).
    public private(set) var memory: (longTerm: Int, total: Int) = (0, 0)

    /// One day of the week strip.
    public struct WeekDay: Equatable, Sendable {
        public let day: Date
        /// Short Russian weekday name ("Пн").
        public let label: String
        public let studied: Bool
        public let isToday: Bool
    }

    /// `today` is a clock so tests can pin the date; defaults to now.
    public init(store: UserDataStore, catalog: ContentCatalog, today: @escaping () -> Date = { Date() },
                boosts: FirstSessionBoostStore = .shared, prompts: TodayPromptSlot = TodayPromptSlot(),
                goals: TodayGoalBuilder = TodayGoalBuilder(), streak: StreakBannerLedger = StreakBannerLedger()) {
        self.streakLedger = streak
        self.promptSlot = prompts
        self.goalBuilder = goals
        self.store = store
        self.catalog = catalog
        self.now = today
        self.boosts = boosts
        refresh()
    }

    /// Total cards for the day = studied + remaining (stable as good/easy grades
    /// drop cards out of the recomputed plan).
    public var totalCount: Int { studiedCount + remaining.count }

    public var hasWork: Bool { !remaining.isEmpty }
    /// Distinct from `isEmpty`: work existed today and is now finished.
    public var isAllDone: Bool { remaining.isEmpty && studiedCount > 0 }
    /// Nothing was due and nothing new is available today.
    public var isEmpty: Bool { remaining.isEmpty && studiedCount == 0 }

    /// Localized "N на повторение + M новых".
    public var summary: String {
        "\(dueRemaining) на повторение + \(newRemaining) новых"
    }

    public static let goalPrompt = TodayPrompt(
        id: "goal", title: "Есть дедлайн?",
        message: "Экзамен, переезд или просто дата — поставьте цель, и Lorito подстроит темп новых карточек.",
        actionTitle: "Поставить цель")

    /// Today appeared: a freeze banner and goal end states now count as seen (shown once).
    public func markShownOnAppear() {
        if streakBanner == .frozen { streakLedger.markFrozenShown(today: now()) }
        goalBuilder.markSeen(goalLines.filter(\.isEndState).map(\.id))
        guard recap != nil || milestone != nil, var s = try? store.loadSettings() else { return }
        if let recap { s.lastRecapWeek = recap.weekID }
        if let milestone { s.celebratedLevels.insert(milestone) }
        if s != (try? store.loadSettings()) { try? store.saveSettings(s) }
    }

    /// The completed week's recap until it has been shown; nil for users with no history.
    static func pendingRecap(events: [StudyEvent], reviews: [ReviewState], practice: [TrapPracticeEvent],
                             catalog: ContentCatalog, settings: UserSettings, today: Date, keep: WeeklyRecap?) -> WeeklyRecap? {
        guard !events.isEmpty else { return nil }
        let r = WeeklyRecap.make(events: events, reviews: reviews, practice: practice, catalog: catalog,
                                 settings: settings, today: today)
        if let keep, keep.weekID == r.weekID { return keep }       // keeps showing during this visit
        // Nothing before the recap week → too new to recap.
        guard events.contains(where: { $0.date < r.weekStart.addingTimeInterval(7 * 86_400) }) else { return nil }
        return settings.lastRecapWeek == r.weekID ? nil : r
    }

    /// "Не сейчас" on the prompt: never offered again; the slot stays empty this visit.
    public func dismissPrompt() {
        guard let prompt else { return }
        promptSlot.dismiss(prompt.id)
        self.prompt = nil
    }

    func makeCCSEDrill() -> CCSEDrillModel? { CCSEDrillModel.today(store: store, catalog: catalog, today: now()) }

    func makeConjugationDrill() -> ConjugationDrillModel? {
        guard let conj = catalog.conjugation, !conjugationItems.isEmpty else { return nil }
        return ConjugationDrillModel(store: store, catalog: conj, itemIDs: conjugationItems, today: now)
    }

    /// The ordered card ids to study now (snapshot for a session).
    public func sessionQueue() -> [String] { remaining.map(\.cardID) }

    /// Recompute from persistence — call on appearance and after a session.
    public func refresh() {
        let settings = (try? store.loadSettings()) ?? .default
        let reviews = (try? store.allReviews()) ?? []
        let events = (try? store.allEvents()) ?? []
        let today = now()

        // An active level goal can raise the day's new-card count (study-goal).
        let planSettings = GoalPacing.planSettings(settings, goal: settings.levelGoal, cards: catalog.cards,
                                                   reviews: reviews, today: today)
        let plan = DailyPlanner.composePlan(
            DailyPlanRequest(cards: catalog.cards, reviews: reviews, settings: planSettings, today: today, events: events,
                             firstSession: boosts.current(today: today))
        )
        let gradedToday = Set(
            events.filter { $0.grade != nil && $0.isCard && StudyDay.isSameDay($0.date, today) }.map(\.cardID)
        )
        remaining = plan.queue.filter { !gradedToday.contains($0.cardID) }
        dueRemaining = remaining.filter { $0.kind == .due }.count
        newRemaining = remaining.filter { $0.kind == .new }.count
        studiedCount = gradedToday.count
        week = Self.weekStrip(events: events, today: today)
        let levels = settings.targetLevel.map(SelectionScope.includedLevels(for:)) ?? []
        let rows = StatsCalculator.longTermMemory(reviews: reviews, catalog: catalog, levels: levels)
        memory = (rows.reduce(0) { $0 + $1.longTerm }, rows.reduce(0) { $0 + $1.total })
        hasExamGoal = settings.exam.map { !$0.done } ?? false
        ccseCount = CCSEDrillModel.today(store: store, catalog: catalog, today: today)?.items.count ?? 0
        recap = Self.pendingRecap(events: events, reviews: reviews, practice: (try? store.allTrapPractice()) ?? [],
                                  catalog: catalog, settings: settings, today: today, keep: recap)
        milestone = milestone ?? LevelMilestones.newlyClosed(cards: catalog.cards, reviews: reviews, settings: settings,
                                                             celebrated: settings.celebratedLevels).first
        conjugationItems = ConjugationToday.plan(store: store, catalog: catalog, today: today)?.all ?? []
        personalTraps = PersonalTraps.list(events: events, practice: (try? store.allTrapPractice()) ?? [],
                                           catalog: catalog, settings: settings, today: today)
        trap = Self.pickTrap(settings: settings, reviews: reviews, catalog: catalog, today: today,
                             personalTrapIDs: Set(personalTraps.map(\.cardID)))
        streakBanner = streakLedger.banner(events: events, today: today, keepFrozen: streakBanner == .frozen)
        goalLines = goalBuilder.lines(settings: settings, cards: catalog.cards, reviews: reviews, today: today,
                                      keepShowing: shownEndStates)
        shownEndStates.formUnion(goalLines.filter(\.isEndState).map(\.id))
        // «Есть дедлайн?» until the user sets a goal or dismisses it.
        promptCandidates = settings.levelGoal == nil && settings.exam == nil ? [Self.goalPrompt] : []
    }

    private static let weekdayLabels = ["Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"]  // Calendar weekday 1…7

    private static func weekStrip(events: [StudyEvent], today: Date) -> [WeekDay] {
        let series = StatsCalculator.dailyActivity(events: events, days: 7, today: today)
        return series.enumerated().map { i, entry in
            let weekday = Calendar.learningDay.component(.weekday, from: entry.day)
            return WeekDay(day: entry.day, label: weekdayLabels[weekday - 1],
                           studied: entry.count > 0, isToday: i == series.count - 1)
        }
    }

    /// Candidates are in-scope cards with a "Частые ошибки" section.
    static func pickTrap(
        settings: UserSettings, reviews: [ReviewState], catalog: ContentCatalog, today: Date,
        personalTrapIDs: Set<String> = []
    ) -> TrapCandidate? {
        guard let level = settings.targetLevel else { return nil }
        let candidates = SelectionScope
            .inScopeCards(targetLevel: level, selectedThemeIDs: Set(settings.selectedThemeIDs), in: catalog)
            .compactMap { card in
                CardBodyParser.firstMistake(in: card.body).map { TrapCandidate(cardID: card.id, text: $0) }
            }
        let studied = Set(reviews.filter { $0.status != .new }.map(\.cardID))
        return DailyTrap.pick(candidates: candidates, studiedIDs: studied, personalTrapIDs: personalTrapIDs, day: today)
    }
}
