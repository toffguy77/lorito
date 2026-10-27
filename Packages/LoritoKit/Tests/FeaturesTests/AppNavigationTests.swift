import Testing
import Foundation
import Domain
@testable import Features

private final class NullStore: UserDataStore {
    func loadSettings() throws -> UserSettings { .default }
    func saveSettings(_ s: UserSettings) throws {}
    func allReviews() throws -> [ReviewState] { [] }
    func review(for cardID: String) throws -> ReviewState? { nil }
    func upsertReview(_ review: ReviewState) throws {}
    func appendEvent(_ event: StudyEvent) throws {}
    func allEvents() throws -> [StudyEvent] { [] }
}

private let catalog = ContentCatalog(
    themes: [Theme(id: "a1-1", level: .a1, title: "T1", order: 1), Theme(id: "a2-1", level: .a2, title: "T2", order: 1)],
    cards: [
        Card(id: "A1-01", level: .a1, themeID: "a1-1", order: 1, title: "A", body: ""),
        Card(id: "A2-01", level: .a2, themeID: "a2-1", order: 1, title: "B", body: ""),
    ]
)

@Suite("App navigation")
@MainActor
struct AppNavigationTests {
    @Test("Reminder deep link selects Today from any destination")
    func deepLink() {
        let nav = AppNavigation()
        nav.destination = .progress
        nav.openToday()
        #expect(nav.destination == .today)
    }

    @Test("Selecting a card selects its level and theme; another theme clears the card")
    func catalogSelection() {
        let nav = AppNavigation()
        nav.selectCard(catalog.card(id: "A2-01")!)
        #expect(nav.catalogLevel == .a2 && nav.catalogThemeID == "a2-1" && nav.catalogCardID == "A2-01")
        nav.selectTheme(catalog.theme(id: "a2-1"))
        #expect(nav.catalogCardID == "A2-01")      // same theme keeps the card
        nav.selectTheme(catalog.theme(id: "a1-1"))
        #expect(nav.catalogCardID == nil)
        nav.selectLevel(.a2)
        #expect(nav.catalogThemeID == nil)
    }

    @Test("Catalog selection round-trips through scene storage; unknown ids are dropped")
    func sceneStorage() {
        let nav = AppNavigation()
        nav.selectCard(catalog.card(id: "A1-01")!)
        let stored = nav.catalogSelectionStorage

        let restored = AppNavigation()
        restored.restoreCatalogSelection(stored, in: catalog)
        #expect(restored.catalogLevel == .a1 && restored.catalogThemeID == "a1-1" && restored.catalogCardID == "A1-01")

        let bogus = AppNavigation()
        bogus.restoreCatalogSelection("A1|zz-9|A1-99", in: catalog)
        #expect(bogus.catalogLevel == .a1 && bogus.catalogThemeID == nil && bogus.catalogCardID == nil)
    }

    @Test("An open session is held by navigation and survives destination changes")
    func sessionSurvives() {
        let nav = AppNavigation()
        let session = StudySessionModel(store: NullStore(), catalog: catalog, queue: ["A1-01"])
        nav.startSession(session)
        session.reveal()
        nav.destination = .catalog          // e.g. a layout switch re-renders the tree
        #expect(nav.session === session && nav.session?.isRevealed == true)
        nav.endSession()
        #expect(nav.session == nil && nav.sessionEndCount == 1)
    }
}
