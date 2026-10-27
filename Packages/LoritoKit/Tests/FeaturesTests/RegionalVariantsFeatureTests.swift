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

@Suite("Regional variants on Today and in drills")
@MainActor
struct RegionalVariantsFeatureTests {
    let now = Date()

    func today(_ store: UserDataStore) throws -> TodayModel {
        TodayModel(store: store, catalog: try ContentLoader.loadCatalog(),
                   boosts: FirstSessionBoostStore(defaults: ephemeral()), prompts: TodayPromptSlot(defaults: ephemeral()),
                   goals: TodayGoalBuilder(defaults: ephemeral()))
    }

    /// Onboarded, goal prompt already answered (a goal exists).
    func store(studied: Bool) throws -> SwiftDataUserDataStore {
        let store = try freshStore()
        var s = UserSettings(targetLevel: .a1, didCompleteOnboarding: true)
        s.levelGoal = LevelGoal(targetLevel: .a1, targetDate: now.addingTimeInterval(86_400 * 60), startDate: now,
                                startIntroduced: 0)
        try store.saveSettings(s)
        if studied { try store.appendEvent(StudyEvent(cardID: "A1-01", date: now, grade: "good")) }
        return store
    }

    @Test("«Где вы учите испанский?» appears after the first session with three choices; not before")
    func offered() throws {
        #expect(try today(try store(studied: false)).prompt == nil)
        let model = try today(try store(studied: true))
        #expect(model.prompt?.id == TodayModel.variantPrompt.id)
        #expect(model.prompt?.title == "Где вы учите испанский?")
        #expect(model.prompt?.choices.map(\.title) == ["Испания", "Латинская Америка", "Риоплатский"])
    }

    @Test("Choosing saves the variant and the synced «answered» flag; never offered again")
    func choose() throws {
        let store = try store(studied: true)
        let model = try today(store)
        model.choosePrompt(TodayPromptChoice(id: SpanishVariant.rioplatense.rawValue, title: "Риоплатский"))
        let s = try store.loadSettings()
        #expect(s.spanishVariant == .rioplatense && s.variantPromptAnswered)
        // A fresh device (no local dismissals) doesn't ask again either.
        let other = try today(store)
        #expect(other.prompt?.id != TodayModel.variantPrompt.id)
    }

    @Test("Dismissing keeps Испания and is remembered in sync")
    func dismiss() throws {
        let store = try store(studied: true)
        let model = try today(store)
        model.dismissPrompt()
        let s = try store.loadSettings()
        #expect(s.spanishVariant == .spain && s.variantPromptAnswered)
        #expect(try today(store).prompt?.id != TodayModel.variantPrompt.id)
    }

    @Test("Drill persons follow the variant: no vosotros in America; Rioplatense asks vos (hablás)")
    func drill() throws {
        let catalog = try #require(try ContentLoader.loadCatalog().conjugation)
        let store = try freshStore()
        for variant in [SpanishVariant.latinAmerica, .rioplatense] {
            let model = ConjugationDrillModel(store: store, catalog: catalog, itemIDs: ["conj:hablar:presente"],
                                              variant: variant)
            #expect(model.personSet == [0, 1, 2, 3, 5])
            #expect(!model.persons.contains(4))
        }
        let rio = ConjugationDrillModel(store: store, catalog: catalog, itemIDs: ["conj:hablar:presente"], variant: .rioplatense)
        let item = try #require(rio.current)
        #expect(item.form(person: 1, variant: .rioplatense) == "hablás")
        #expect(PersonRotation.label(1, variant: rio.variant) == "vos")
    }

    @Test("Today's drill and the catalog follow the stored variant")
    func stored() throws {
        let store = try store(studied: true)
        var s = try store.loadSettings()
        s.spanishVariant = .rioplatense
        s.dailyConjugationCount = 2
        try store.saveSettings(s)
        let model = try today(store)
        if let drill = model.makeConjugationDrill() { #expect(drill.variant == .rioplatense) }
    }
}
