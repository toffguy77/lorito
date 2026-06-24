import Testing
import Foundation
import Domain
@testable import Features

/// In-memory `UserDataStore` for exercising the scope model without SwiftData.
private final class MockStore: UserDataStore {
    var settings = UserSettings.default
    func loadSettings() throws -> UserSettings { settings }
    func saveSettings(_ s: UserSettings) throws { settings = s }
    func allReviews() throws -> [ReviewState] { [] }
    func review(for cardID: String) throws -> ReviewState? { nil }
    func upsertReview(_ review: ReviewState) throws {}
    func appendEvent(_ event: StudyEvent) throws {}
    func allEvents() throws -> [StudyEvent] { [] }
}

private func theme(_ id: String, _ level: CEFRLevel, order: Int) -> Theme {
    Theme(id: id, level: level, title: id, order: order)
}
private func card(_ id: String, _ level: CEFRLevel, theme: String, order: Int) -> Card {
    Card(id: id, level: level, themeID: theme, order: order, title: id, body: "")
}

private let catalog = ContentCatalog(
    themes: [theme("a1-1", .a1, order: 1), theme("a2-1", .a2, order: 1), theme("b1-1", .b1, order: 1)],
    cards: [
        card("A1-01", .a1, theme: "a1-1", order: 1),
        card("A2-01", .a2, theme: "a2-1", order: 1),
        card("B1-01", .b1, theme: "b1-1", order: 1),
    ]
)

@Suite("Scope selection model")
@MainActor
struct ScopeSelectionModelTests {
    @Test("Selecting a level derives included levels and available themes")
    func levelDerivesScope() {
        let model = ScopeSelectionModel(store: MockStore(), catalog: catalog)
        model.selectLevel(.a2)
        #expect(model.includedLevels == [.a1, .a2])
        #expect(model.availableThemes.map(\.id) == ["a1-1", "a2-1"])
    }

    @Test("Raising the level widens scope and selects newly in-scope themes")
    func raisingWidens() {
        let model = ScopeSelectionModel(store: MockStore(), catalog: catalog)
        model.selectLevel(.a1)
        model.selectAllThemes()
        #expect(model.selectedThemeIDs == ["a1-1"])
        model.selectLevel(.b1)  // widen
        #expect(model.availableThemes.map(\.id) == ["a1-1", "a2-1", "b1-1"])
        #expect(model.selectedThemeIDs == ["a1-1", "a2-1", "b1-1"])  // new ones auto-selected
    }

    @Test("Lowering the level drops out-of-scope themes")
    func loweringNarrows() {
        let model = ScopeSelectionModel(store: MockStore(), catalog: catalog)
        model.selectLevel(.b1)
        model.selectAllThemes()
        model.selectLevel(.a1)  // narrow
        #expect(model.selectedThemeIDs == ["a1-1"])  // a2-1, b1-1 dropped
    }

    @Test("Persist is blocked for an unstudyable (empty) selection")
    func guardBlocksEmpty() {
        let store = MockStore()
        let model = ScopeSelectionModel(store: store, catalog: catalog)
        model.selectLevel(.a1)
        model.toggleTheme("a1-1")  // deselect the only theme → empty
        #expect(!model.isStudyable)
        #expect(!model.persist())
        #expect(store.settings.targetLevel == nil)  // nothing persisted
        #expect(model.recomputeToken == 0)
    }

    @Test("Persisting a studyable selection saves and triggers a recompute")
    func persistTriggersRecompute() {
        let store = MockStore()
        let model = ScopeSelectionModel(store: store, catalog: catalog)
        model.selectLevel(.a2)
        model.selectAllThemes()
        #expect(model.persist(completingOnboarding: true))
        #expect(store.settings.targetLevel == .a2)
        #expect(Set(store.settings.selectedThemeIDs) == ["a1-1", "a2-1"])
        #expect(store.settings.didCompleteOnboarding)
        #expect(model.recomputeToken == 1)
    }

    @Test("Model initializes from previously persisted settings")
    func initializesFromStore() {
        let store = MockStore()
        store.settings.targetLevel = .b1
        store.settings.selectedThemeIDs = ["b1-1"]
        let model = ScopeSelectionModel(store: store, catalog: catalog)
        #expect(model.targetLevel == .b1)
        #expect(model.selectedThemeIDs == ["b1-1"])
    }
}
