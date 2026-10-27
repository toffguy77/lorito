import Testing
import Foundation
import Domain
@testable import Features
@testable import WidgetSupport

private final class MemoryStore: UserDataStore {
    var settings = UserSettings(targetLevel: .a1, selectedThemeIDs: ["a1-1"], dailyNewCardCount: 2)
    var reviews: [String: ReviewState] = [:]
    var events: [StudyEvent] = []
    var writes = 0

    func loadSettings() throws -> UserSettings { settings }
    func saveSettings(_ s: UserSettings) throws { settings = s; writes += 1 }
    func allReviews() throws -> [ReviewState] { Array(reviews.values) }
    func review(for cardID: String) throws -> ReviewState? { reviews[cardID] }
    func upsertReview(_ review: ReviewState) throws { reviews[review.cardID] = review; writes += 1 }
    func appendEvent(_ event: StudyEvent) throws { events.append(event); writes += 1 }
    func allEvents() throws -> [StudyEvent] { events }
}

private let catalog = ContentCatalog(
    themes: [Theme(id: "a1-1", level: .a1, title: "T", order: 1), Theme(id: "a2-1", level: .a2, title: "T2", order: 1)],
    cards: [
        Card(id: "A1-01", level: .a1, themeID: "a1-1", order: 1, title: "Род существительных",
             body: "## ⚠️ Частые ошибки\n- Не *la problema*, а *el problema*.\n"),
        Card(id: "A1-02", level: .a1, themeID: "a1-1", order: 2, title: "B", body: ""),
        Card(id: "A2-01", level: .a2, themeID: "a2-1", order: 1, title: "C", body: ""),
    ],
    exercises: [
        Exercise(id: "A1-EX-01", level: .a1, themeID: "a1-1", card: "A1-01", prompt: "?", explanation: "",
                 kind: .multipleChoice(options: ["el", "la"], answer: "el")),
        Exercise(id: "A2-EX-01", level: .a2, themeID: "a2-1", card: "A2-01", prompt: "?", explanation: "",
                 kind: .multipleChoice(options: ["a", "b"], answer: "a")),
    ]
)

@Suite("Widget snapshot publisher")
@MainActor
struct WidgetSnapshotPublisherTests {
    @Test("Builds counts, trap word and in-scope questions from the store")
    func builds() {
        let store = MemoryStore()
        let s = WidgetSnapshotPublisher.makeSnapshot(store: store, catalog: catalog, today: Date())
        #expect(s.newToday == 2 && s.dueToday == 0 && s.remainingToday == 2)
        #expect(!s.studiedToday)
        #expect(s.wordOfDay == .init(spanish: "la problema", note: "Род существительных", cardID: "A1-01"))
        #expect(s.questions.map(\.id) == ["A1-EX-01"])     // A2 is out of scope
    }

    @Test("After a session the snapshot says studied today")
    func afterSession() throws {
        let store = MemoryStore()
        _ = try GradingService(store: store).grade(cardID: "A1-01", grade: .good, today: Date())
        let s = WidgetSnapshotPublisher.makeSnapshot(store: store, catalog: catalog, today: Date())
        #expect(s.studiedToday)
        #expect(s.currentStreak == 1)
    }

    @Test("Publishing writes the file and never writes to the user-data store")
    func publishes() {
        let store = MemoryStore()
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let target = WidgetSnapshotStore(directory: dir)
        WidgetSnapshotPublisher.publish(store: store, catalog: catalog, to: target, reloadTimelines: false)
        #expect(target.read()?.newToday == 2)
        #expect(store.writes == 0)
    }
}
