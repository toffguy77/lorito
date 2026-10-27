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

private func ephemeralDefaults() -> UserDefaults {
    UserDefaults(suiteName: "lorito.tests.\(UUID().uuidString)")!
}

/// Answers every question of `level` with `correct`.
@MainActor
private func drive(_ model: PlacementModel, _ script: [CEFRLevel: Bool]) {
    var guardCount = 0
    while let current = model.current, guardCount < 40 {
        model.answerCurrent(correct: script[current.level] ?? false)
        guardCount += 1
    }
}

@Suite("Placement in onboarding")
@MainActor
struct PlacementFeatureTests {
    @Test("A2 passed, B1 failed → proposal B1 pre-selected, known A2")
    func proposal() throws {
        let model = PlacementModel(catalog: try ContentLoader.loadCatalog(), seed: 42, analytics: NoOpRecorder())
        drive(model, [.a2: true, .b1: false])
        #expect(model.isFinished && model.chosenLevel == .b1)
        #expect(model.result?.highestKnown == .a2 && model.result?.questionCount == 6)
        #expect(model.failedCardIDs.count >= 1)
    }

    @Test("Option off: apply stores the known level only — no review, event or attempt")
    func optionOff() throws {
        let store = try freshStore()
        let model = PlacementModel(catalog: try ContentLoader.loadCatalog(), seed: 42, analytics: NoOpRecorder())
        drive(model, [.a2: true, .b1: false])
        let seeded = try model.apply(to: store)
        #expect(seeded.isEmpty)
        #expect(try store.loadSettings().placementKnownLevel == .a2)
        #expect(try store.allReviews().isEmpty && store.allEvents().isEmpty && store.allAttempts().isEmpty)
    }

    @Test("Option on: correctly answered known-level cards get the scheduler's Хорошо state, no study event")
    func optionOn() throws {
        let store = try freshStore()
        let model = PlacementModel(catalog: try ContentLoader.loadCatalog(), seed: 42, analytics: NoOpRecorder())
        drive(model, [.a2: true, .b1: false])
        model.skipKnown = true
        let today = Date()
        let seeded = try model.apply(to: store, today: today)
        #expect(!seeded.isEmpty)
        let review = try #require(try store.review(for: seeded[0]))
        #expect(review == FSRSScheduler.schedule(state: ReviewState(cardID: seeded[0]), grade: .good, today: today))
        #expect(try store.allEvents().isEmpty)
        #expect(StatsCalculator.compute(events: try store.allEvents(), today: today).currentStreak == 0)
    }

    @Test("First session: 3 new cards with dailyNewCardCount 1, failed-test cards first; next day back to 1")
    func firstSession() throws {
        let catalog = try ContentLoader.loadCatalog()
        let store = try freshStore()
        try store.saveSettings(UserSettings(targetLevel: .b1, dailyNewCardCount: 1, didCompleteOnboarding: true))
        let boosts = FirstSessionBoostStore(defaults: ephemeralDefaults())
        let now = Date()
        boosts.save(FirstSessionBoost(day: now, priorityCardIDs: ["A2-05"]))
        let today = TodayModel(store: store, catalog: catalog, today: { now }, boosts: boosts)
        #expect(today.newRemaining == 3)
        #expect(today.sessionQueue().first == "A2-05")
        let tomorrow = Calendar.learningDay.date(byAdding: .day, value: 1, to: now)!
        #expect(TodayModel(store: store, catalog: catalog, today: { tomorrow }, boosts: boosts).newRemaining == 1)
        #expect(boosts.current(today: tomorrow) == nil)
    }

    @Test("Known A2 with target B1: Today introduces B1 first")
    func knownLevelOrder() throws {
        let catalog = try ContentLoader.loadCatalog()
        let store = try freshStore()
        try store.saveSettings(UserSettings(targetLevel: .b1, dailyNewCardCount: 3, didCompleteOnboarding: true,
                                            placementKnownLevel: .a2))
        let today = TodayModel(store: store, catalog: catalog, boosts: FirstSessionBoostStore(defaults: ephemeralDefaults()))
        #expect(today.sessionQueue().allSatisfy { $0.hasPrefix("B1-") })
    }
}

@Suite("Today prompt slot")
struct TodayPromptSlotTests {
    let prompts = [TodayPrompt(id: "goal", title: "Цель", message: "…", actionTitle: "Выбрать"),
                   TodayPrompt(id: "variant", title: "Вариант", message: "…", actionTitle: "Выбрать")]
    let graded = [StudyEvent(cardID: "A1-01", date: Date(), grade: "good")]

    @Test("Nothing before the first completed session; then one prompt, next after dismissal")
    func slot() {
        let slot = TodayPromptSlot(defaults: ephemeralDefaults())
        #expect(slot.prompt(candidates: prompts, events: []) == nil)
        #expect(slot.prompt(candidates: prompts, events: graded)?.id == "goal")
        slot.dismiss("goal")
        #expect(slot.prompt(candidates: prompts, events: graded)?.id == "variant")
    }
}

private final class NoOpRecorder: AnalyticsRecording {
    func record(_ event: AnalyticsEvent) {}
}
