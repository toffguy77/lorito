import Foundation
import Testing
import Domain
import Content
import Persistence
@testable import Features

@Suite("Onboarding: full setup")
@MainActor
struct OnboardingSetupTests {
    func make(_ settings: UserSettings = UserSettings()) throws -> (SwiftDataUserDataStore, ScopeSelectionModel, UserDefaults) {
        let store = SwiftDataUserDataStore(container: try PersistenceController.makeContainer(config: .init(inMemory: true)), localMirror: nil)
        try store.saveSettings(settings)
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        return (store, ScopeSelectionModel(store: store, catalog: try ContentLoader.loadCatalog()), defaults)
    }

    @Test("Setup model: defaults, pace clamps, enabling words and conjugations sets their defaults; saves keep other settings")
    func setupModel() throws {
        var settings = UserSettings(targetLevel: .a2, dailyNewCardCount: 2)
        settings.selectedThemeIDs = ["a1-1"]
        let (store, _, _) = try make(settings)
        let m = OnboardingSetupModel(store: store)
        #expect(m.cardsPerDay == 2 && !m.wordsEnabled && !m.conjugationsEnabled && m.variant == .spain)
        m.cardsPerDay = 40
        #expect(m.cardsPerDay == 10)
        m.cardsPerDay = 0
        #expect(m.cardsPerDay == 1)
        m.wordsEnabled = true
        m.conjugationsEnabled = true
        #expect(m.wordsPerDay == UserSettings.wordsDefaultWhenEnabled && m.conjugationsPerDay == UserSettings.conjugationDefaultWhenEnabled)
        m.cardsPerDay = 4
        m.savePace()
        m.variant = .rioplatense
        m.saveVariant()
        m.rate = .slow
        m.playWhenSilent = true
        m.saveSound()
        let s = try store.loadSettings()
        #expect(s.dailyNewCardCount == 4 && s.dailyNewWordCount == 5 && s.dailyConjugationCount == 3)
        #expect(s.spanishVariant == .rioplatense && s.speechRate == .slow && s.playAudioWhenSilent)
        #expect(s.targetLevel == .a2 && s.selectedThemeIDs == ["a1-1"])
    }

    @Test("First run: completion records the version, grants the first-session boost and answers the Today prompts")
    func firstRun() throws {
        let (store, scope, defaults) = try make()
        scope.selectLevel(.a1)
        scope.selectAllThemes()
        let versions = OnboardingVersionStore(defaults: defaults)
        let prompts = TodayPromptSlot(defaults: defaults)
        let boosts = FirstSessionBoostStore(defaults: defaults)
        #expect(versions.needsOnboarding(completedInSettings: false))
        #expect(OnboardingFinish.complete(.firstRun, scope: scope, placement: nil, versions: versions, prompts: prompts,
                                          boosts: boosts, today: Date()))
        #expect(!versions.needsOnboarding(completedInSettings: true))
        #expect(boosts.current() != nil)
        let s = try store.loadSettings()
        #expect(s.didCompleteOnboarding && s.variantPromptAnswered)
        let open = [TodayModel.goalPrompt, TodayModel.variantPrompt, TodayModel.wordsPrompt]
        #expect(prompts.prompt(candidates: open, events: [StudyEvent(cardID: "A1-01", date: Date(), grade: "good")]) == nil)
    }

    @Test("Revisit: no boost, reviews untouched, level change applied; an older version on the device needs the onboarding")
    func revisit() throws {
        let (store, scope, defaults) = try make(UserSettings(targetLevel: .a2, didCompleteOnboarding: true))
        scope.selectAllThemes()
        _ = scope.persist(completingOnboarding: true)
        try store.upsertReview(ReviewState(cardID: "A1-01", interval: 3, status: .review))
        let versions = OnboardingVersionStore(defaults: defaults)
        // Completed in 1.5 (no version recorded on this device) → shown once again.
        #expect(versions.needsOnboarding(completedInSettings: true))
        let boosts = FirstSessionBoostStore(defaults: defaults)
        scope.selectLevel(.b1)
        #expect(OnboardingFinish.complete(.revisit, scope: scope, placement: nil, versions: versions,
                                          prompts: TodayPromptSlot(defaults: defaults), boosts: boosts, today: Date()))
        #expect(boosts.current() == nil)
        #expect(try store.loadSettings().targetLevel == .b1)
        #expect(try store.allReviews().map(\.cardID) == ["A1-01"] && store.review(for: "A1-01")?.interval == 3)
        #expect(!versions.needsOnboarding(completedInSettings: true))
    }
}
