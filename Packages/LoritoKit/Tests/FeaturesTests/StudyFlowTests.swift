import Testing
import Foundation
import Domain
@testable import Features

/// In-memory store capturing reviews and events for study-flow tests.
private final class FlowStore: UserDataStore {
    var settings = UserSettings.default
    var reviews: [String: ReviewState] = [:]
    var events: [StudyEvent] = []

    func loadSettings() throws -> UserSettings { settings }
    func saveSettings(_ s: UserSettings) throws { settings = s }
    func allReviews() throws -> [ReviewState] { Array(reviews.values) }
    func review(for cardID: String) throws -> ReviewState? { reviews[cardID] }
    func upsertReview(_ review: ReviewState) throws { reviews[review.cardID] = review }
    func appendEvent(_ event: StudyEvent) throws { events.append(event) }
    func allEvents() throws -> [StudyEvent] { events }
}

private func card(_ id: String, _ level: CEFRLevel, theme: String, order: Int) -> Card {
    Card(id: id, level: level, themeID: theme, order: order, title: id, body: "> **Суть**\n> \(id)")
}

private let catalog = ContentCatalog(
    themes: [Theme(id: "a1-1", level: .a1, title: "Тема", order: 1)],
    cards: [
        card("A1-01", .a1, theme: "a1-1", order: 1),
        card("A1-02", .a1, theme: "a1-1", order: 2),
        card("A1-03", .a1, theme: "a1-1", order: 3),
    ]
)

private func studyableSettings() -> UserSettings {
    UserSettings(targetLevel: .a1, selectedThemeIDs: ["a1-1"], dailyNewCardCount: 3)
}

@Suite("Today model")
@MainActor
struct TodayModelTests {
    @Test("Empty state when nothing is selected/available")
    func emptyState() {
        let store = FlowStore()  // no target level → nothing in scope
        let model = TodayModel(store: store, catalog: catalog)
        #expect(model.isEmpty)
        #expect(!model.hasWork)
        #expect(!model.isAllDone)
    }

    @Test("Active state surfaces new-card work and counts")
    func activeState() {
        let store = FlowStore()
        store.settings = studyableSettings()
        let model = TodayModel(store: store, catalog: catalog)
        #expect(model.hasWork)
        #expect(model.newRemaining == 3)
        #expect(model.summary == "0 на повторение + 3 новых")
        #expect(model.sessionQueue() == ["A1-01", "A1-02", "A1-03"])
    }

    @Test("Cards graded today are excluded and counted as studied; all-done when finished")
    func allDoneAfterGrading() {
        let store = FlowStore()
        store.settings = studyableSettings()
        // Grade all three today.
        let grading = GradingService(store: store)
        for id in ["A1-01", "A1-02", "A1-03"] {
            _ = try? grading.grade(cardID: id, grade: .good, today: Date())
        }
        let model = TodayModel(store: store, catalog: catalog)
        #expect(!model.hasWork)
        #expect(model.isAllDone)
        #expect(model.studiedCount == 3)
    }
}

@Suite("Study session model")
@MainActor
struct StudySessionModelTests {
    @Test("Grading advances, persists reviews and study-log entries, then completes")
    func gradingFlow() {
        let store = FlowStore()
        let session = StudySessionModel(store: store, catalog: catalog, queue: ["A1-01", "A1-02"])
        #expect(session.currentCard?.id == "A1-01")

        session.grade(.again)
        #expect(session.currentCard?.id == "A1-02")
        #expect(store.reviews["A1-01"] != nil)            // srs-engine applied
        #expect(store.events.last?.cardID == "A1-01")     // study-log written
        #expect(store.events.last?.grade == "again")      // specific grade recorded

        session.grade(.easy)
        #expect(session.isComplete)
        #expect(session.currentCard == nil)
        #expect(store.events.count == 2)
    }
}

@Suite("Catalog model")
@MainActor
struct CatalogModelTests {
    @Test("Status reflects review state; suspend/unsuspend persists and round-trips")
    func statusAndSuspend() {
        let store = FlowStore()
        let model = CatalogModel(store: store, catalog: catalog)
        #expect(model.status(for: "A1-01") == .new)  // no review yet

        model.toggleSuspended("A1-01")
        #expect(model.isSuspended("A1-01"))
        #expect(model.status(for: "A1-01") == .suspended)
        #expect(store.reviews["A1-01"]?.status == .suspended)  // persisted

        // Reload from store and confirm the suspended status survives.
        let reloaded = CatalogModel(store: store, catalog: catalog)
        #expect(reloaded.status(for: "A1-01") == .suspended)

        model.toggleSuspended("A1-01")  // unsuspend
        #expect(!model.isSuspended("A1-01"))
        #expect(model.status(for: "A1-01") == .new)  // never studied → back to new
    }

    @Test("Browsing preserves bundle order")
    func browsing() {
        let model = CatalogModel(store: FlowStore(), catalog: catalog)
        #expect(model.levels == [.a1])
        let theme = model.themes(in: .a1).first!
        #expect(model.cards(in: theme).map(\.id) == ["A1-01", "A1-02", "A1-03"])
    }
}
