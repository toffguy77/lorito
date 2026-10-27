import Foundation
import Observation
import Domain

/// Settings «Цель»: an optional level goal and an optional exam date, stored
/// as synced scalar settings. Saving loads settings fresh so other fields survive.
@MainActor
@Observable
public final class GoalSettingsModel: Identifiable {
    private let store: UserDataStore
    private let catalog: ContentCatalog
    private let now: () -> Date
    public private(set) var settings: UserSettings

    // Editing state.
    public var goalLevel: CEFRLevel
    public var goalDate: Date
    public var examKind: ExamKind = .deleA2
    public var examDate: Date

    public init(store: UserDataStore, catalog: ContentCatalog, today: @escaping () -> Date = { Date() }) {
        self.store = store
        self.catalog = catalog
        self.now = today
        let s = (try? store.loadSettings()) ?? .default
        settings = s
        let inThreeMonths = Calendar.learningDay.date(byAdding: .month, value: 3, to: today()) ?? today()
        goalLevel = s.levelGoal?.targetLevel ?? s.targetLevel ?? .a1
        goalDate = s.levelGoal?.targetDate ?? inThreeMonths
        examKind = s.exam?.kind ?? .deleA2
        examDate = s.exam?.date ?? inThreeMonths
    }

    /// Re-read settings (the goal may have been set elsewhere, e.g. from Today).
    public func reload() {
        let s = (try? store.loadSettings()) ?? .default
        settings = s
        if let g = s.levelGoal { goalLevel = g.targetLevel; goalDate = g.targetDate }
        if let e = s.exam { examKind = e.kind; examDate = e.date }
    }

    public var levelGoal: LevelGoal? { settings.levelGoal }
    public var exam: ExamGoal? { settings.exam }

    /// Levels a goal may target: the included scope.
    public var goalLevels: [CEFRLevel] { settings.targetLevel?.included ?? CEFRLevel.allCases }

    public var canSaveGoal: Bool { LevelGoal.isValidTargetDate(goalDate, today: now()) }
    public var canSaveExam: Bool { LevelGoal.isValidTargetDate(examDate, today: now()) }

    public func saveLevelGoal() {
        guard canSaveGoal else { return }
        update { s in
            s.levelGoal = LevelGoal(targetLevel: goalLevel, targetDate: goalDate,
                                    startDate: Calendar.learningDay.startOfDay(for: now()),
                                    startIntroduced: introduced(upTo: goalLevel, settings: s))
        }
    }

    public func saveExam() {
        guard canSaveExam else { return }
        update { $0.exam = ExamGoal(kind: examKind, date: examDate) }
    }

    /// "DELE A2": a level goal A2 and a DELE A2 exam on `examDate`.
    public func applyDeleA2Preset() {
        guard canSaveExam else { return }
        update { s in
            let (goal, exam) = GoalPresets.deleA2(date: examDate, today: now(), introduced: introduced(upTo: .a2, settings: s))
            s.levelGoal = goal
            s.exam = exam
        }
        goalLevel = .a2
        goalDate = examDate
        examKind = .deleA2
    }

    public func markExamDone() { update { $0.exam?.done = true } }
    public func removeLevelGoal() { update { $0.levelGoal = nil } }
    public func removeExam() { update { $0.exam = nil } }

    private func introduced(upTo level: CEFRLevel, settings: UserSettings) -> Int {
        let goal = LevelGoal(targetLevel: level, targetDate: now(), startDate: now(), startIntroduced: 0)
        return GoalPacing.progress(goal: goal, cards: catalog.cards, reviews: (try? store.allReviews()) ?? [],
                                   selectedThemeIDs: settings.selectedThemeIDs, today: now()).introduced
    }

    private func update(_ change: (inout UserSettings) -> Void) {
        var s = (try? store.loadSettings()) ?? .default
        change(&s)
        try? store.saveSettings(s)
        settings = s
    }
}
