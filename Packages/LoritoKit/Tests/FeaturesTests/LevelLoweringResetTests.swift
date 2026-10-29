import Foundation
import Testing
import Domain
import Persistence
import Content
@testable import Features

/// level-lowering-resets-progress: persisting a lower target level deletes the review
/// state of the grammar cards above it; everything else is kept.
@Suite("Scope: lowering the level resets progress above it")
@MainActor
struct LevelLoweringResetTests {
    private static let catalog = ContentCatalog(
        themes: [Theme(id: "a1-1", level: .a1, title: "a1", order: 1),
                 Theme(id: "a2-1", level: .a2, title: "a2", order: 1),
                 Theme(id: "b1-1", level: .b1, title: "b1", order: 1)],
        cards: [Card(id: "A1-01", level: .a1, themeID: "a1-1", order: 1, title: "A1-01", body: ""),
                Card(id: "A2-03", level: .a2, themeID: "a2-1", order: 1, title: "A2-03", body: ""),
                Card(id: "B1-02", level: .b1, themeID: "b1-1", order: 1, title: "B1-02", body: "")]
    )

    func make(level: CEFRLevel) throws -> (SwiftDataUserDataStore, ScopeSelectionModel) {
        let store = SwiftDataUserDataStore(container: try PersistenceController.makeContainer(config: .init(inMemory: true)), localMirror: nil)
        var settings = UserSettings(targetLevel: level, didCompleteOnboarding: true)
        settings.selectedThemeIDs = Self.catalog.themes.filter { $0.level <= level }.map(\.id)
        try store.saveSettings(settings)
        for id in ["A1-01", "A2-03", "B1-02", "word:casa", "conj:ser:presente"] {
            try store.upsertReview(ReviewState(cardID: id, interval: 3, status: .review))
        }
        try store.appendEvent(StudyEvent(cardID: "B1-02", date: Date(), grade: "good"))
        return (store, ScopeSelectionModel(store: store, catalog: Self.catalog))
    }

    @Test("Counts the cards with progress above a level")
    func counts() throws {
        let (_, model) = try make(level: .b1)
        #expect(model.cardsWithProgress(above: .a1).sorted() == ["A2-03", "B1-02"])
        #expect(model.cardsWithProgress(above: .a2) == ["B1-02"])
        #expect(model.cardsWithProgress(above: .b1).isEmpty)
    }

    @Test("Lowering B1 to A1 deletes only the A2 and B1 card reviews")
    func lowering() throws {
        let (store, model) = try make(level: .b1)
        model.selectLevel(.a1)
        #expect(model.persist())
        #expect(try store.allReviews().map(\.cardID).sorted() == ["A1-01", "conj:ser:presente", "word:casa"])
        #expect(try store.allEvents().count == 1)
        #expect(try store.loadSettings().targetLevel == .a1)
    }

    @Test("Raising or keeping the level deletes nothing")
    func raisingOrKeeping() throws {
        let (store, model) = try make(level: .a2)
        model.selectLevel(.b1)
        #expect(model.persist())
        model.toggleTheme("a1-1")
        #expect(model.persist())
        #expect(try store.allReviews().count == 5)
    }
}

/// setup-close-discards-unsaved-scope: closing the re-run drops unsaved choices.
@Suite("Scope: reload discards unsaved choices")
@MainActor
struct ScopeReloadTests {
    @Test("reload() restores the stored level and themes")
    func reload() throws {
        let store = SwiftDataUserDataStore(container: try PersistenceController.makeContainer(config: .init(inMemory: true)), localMirror: nil)
        var settings = UserSettings(targetLevel: .a1, didCompleteOnboarding: true)
        settings.selectedThemeIDs = ["a1-1"]
        try store.saveSettings(settings)
        let model = ScopeSelectionModel(store: store, catalog: try ContentLoader.loadCatalog())
        model.selectLevel(.b1)
        model.selectAllThemes()
        model.reload()
        #expect(model.targetLevel == .a1 && model.selectedThemeIDs == ["a1-1"])
    }
}
