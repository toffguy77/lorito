import Foundation
import Testing
import Domain
import Content
import Persistence
@testable import Features

@MainActor
private func freshStore() throws -> SwiftDataUserDataStore {
    SwiftDataUserDataStore(container: try PersistenceController.makeContainer(config: .init(inMemory: true)))
}
private func ephemeral() -> UserDefaults { UserDefaults(suiteName: "lorito.tests.\(UUID().uuidString)")! }

@Suite("Study goal in Settings and on Today")
@MainActor
struct GoalFeatureTests {
    let now = Date()
    var cal: Calendar { .learningDay }

    @Test("Set a level goal two months ahead; a past date can't be saved")
    func setGoal() throws {
        let store = try freshStore()
        try store.saveSettings(UserSettings(targetLevel: .b1, didCompleteOnboarding: true))
        let model = GoalSettingsModel(store: store, catalog: try ContentLoader.loadCatalog(), today: { now })
        model.goalLevel = .b1
        model.goalDate = cal.date(byAdding: .month, value: 2, to: now)!
        model.saveLevelGoal()
        let goal = try #require(try store.loadSettings().levelGoal)
        #expect(goal.targetLevel == .b1 && goal.state == .active)
        model.goalDate = now
        #expect(!model.canSaveGoal)
    }

    @Test("DELE A2 preset stores a level goal A2 and an exam on the same date; mark done; remove")
    func preset() throws {
        let store = try freshStore()
        try store.saveSettings(UserSettings(targetLevel: .a2, didCompleteOnboarding: true))
        let model = GoalSettingsModel(store: store, catalog: try ContentLoader.loadCatalog(), today: { now })
        model.examDate = cal.date(byAdding: .day, value: 60, to: now)!
        model.applyDeleA2Preset()
        let s = try store.loadSettings()
        #expect(s.levelGoal?.targetLevel == .a2 && s.exam?.kind == .deleA2 && s.levelGoal?.targetDate == s.exam?.date)
        model.markExamDone()
        #expect(try store.loadSettings().exam?.done == true)
        model.removeLevelGoal()
        model.removeExam()
        #expect(try store.loadSettings().levelGoal == nil && store.loadSettings().exam == nil)
    }

    @Test("Today: goal lines with days and status; achieved end state shown once")
    func todayLines() throws {
        let catalog = try ContentLoader.loadCatalog()
        var settings = UserSettings(targetLevel: .a1, didCompleteOnboarding: true)
        settings.levelGoal = LevelGoal(targetLevel: .a1, targetDate: cal.date(byAdding: .day, value: 9, to: now)!,
                                       startDate: now, startIntroduced: 0)
        settings.exam = ExamGoal(kind: .ccse, date: cal.date(byAdding: .day, value: 4, to: now)!)
        let builder = TodayGoalBuilder(defaults: ephemeral())
        let lines = builder.lines(settings: settings, cards: catalog.cards, reviews: [], today: now, keepShowing: [])
        #expect(lines.map(\.id) == ["level", "exam"])
        #expect(lines[0].detail.hasPrefix("осталось 10 дней"))
        #expect(lines[1].detail == "осталось 5 дней")

        let all = catalog.cards(in: .a1).map { ReviewState(cardID: $0.id, status: .review) }
        let first = builder.lines(settings: settings, cards: catalog.cards, reviews: all, today: now, keepShowing: [])
        #expect(first.first?.isEndState == true)
        let later = builder.lines(settings: settings, cards: catalog.cards, reviews: all, today: now, keepShowing: [])
        #expect(!later.contains { $0.isEndState })
    }

    @Test("Days copy uses plurals: 1 день, 2 дня, 5 дней")
    func days() {
        #expect(TodayGoalBuilder.daysText(1) == "остался 1 день")
        #expect(TodayGoalBuilder.daysText(2) == "осталось 2 дня")
        #expect(TodayGoalBuilder.daysText(5) == "осталось 5 дней")
    }

    @Test("«Есть дедлайн?» is offered after the first session without a goal; dismissing never brings it back")
    func prompt() throws {
        let store = try freshStore()
        try store.saveSettings(UserSettings(targetLevel: .a1, didCompleteOnboarding: true))
        try store.appendEvent(StudyEvent(cardID: "A1-01", date: now, grade: "good"))
        let slot = TodayPromptSlot(defaults: ephemeral())
        let today = TodayModel(store: store, catalog: try ContentLoader.loadCatalog(),
                               boosts: FirstSessionBoostStore(defaults: ephemeral()), prompts: slot,
                               goals: TodayGoalBuilder(defaults: ephemeral()))
        #expect(today.prompt?.id == "goal")
        today.dismissPrompt()
        today.refresh()
        #expect(today.prompt == nil)
        #expect(try store.loadSettings().levelGoal == nil)
    }
}
