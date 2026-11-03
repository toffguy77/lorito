import Testing
import Foundation
import Domain
@testable import Features

private final class HubStore: UserDataStore {
    var settings = UserSettings.default
    var reviews: [String: ReviewState] = [:]
    var events: [StudyEvent] = []
    var attempts: [ExerciseAttempt] = []

    func loadSettings() throws -> UserSettings { settings }
    func saveSettings(_ s: UserSettings) throws { settings = s }
    func allReviews() throws -> [ReviewState] { Array(reviews.values) }
    func review(for cardID: String) throws -> ReviewState? { reviews[cardID] }
    func upsertReview(_ r: ReviewState) throws { reviews[r.cardID] = r }
    func appendEvent(_ e: StudyEvent) throws { events.append(e) }
    func allEvents() throws -> [StudyEvent] { events }
    func appendAttempt(_ a: ExerciseAttempt) throws { attempts.append(a) }
    func allAttempts() throws -> [ExerciseAttempt] { attempts }
}

private final class HubRecorder: AnalyticsRecording {
    var events: [AnalyticsEvent] = []
    func record(_ event: AnalyticsEvent) { events.append(event) }
}

private func mc(_ id: String, card: String) -> Exercise {
    Exercise(id: id, level: .a1, themeID: "a1-1", card: card, prompt: "P", explanation: "E",
             kind: .multipleChoice(options: ["el", "la"], answer: "la"))
}

private let catalog = ContentCatalog(
    themes: [Theme(id: "a1-1", level: .a1, title: "T", order: 1)],
    cards: [Card(id: "A1-01", level: .a1, themeID: "a1-1", order: 1, title: "A", body: ""),
            Card(id: "A1-02", level: .a1, themeID: "a1-1", order: 2, title: "B", body: "")],
    exercises: [mc("A1-01-EX-1", card: "A1-01"), mc("A1-01-EX-2", card: "A1-01"),
                mc("A1-02-EX-1", card: "A1-02")]
)

private let due = Date(timeIntervalSince1970: 2_000_000_000)

@Suite("Practice hub")
@MainActor
struct PracticeHubFeatureTests {
    private func make(_ store: HubStore, recorder: HubRecorder = HubRecorder(), salesEnabled: Bool = false) -> PracticeHubModel {
        PracticeHubModel(store: store, catalog: catalog, salesEnabled: salesEnabled, analytics: recorder,
                         preferences: AudioExercisePreferences(defaults: UserDefaults(suiteName: UUID().uuidString)!),
                         seed: { 42 })
    }

    private func studiedStore() -> HubStore {
        let store = HubStore()
        store.reviews["A1-01"] = ReviewState(cardID: "A1-01", interval: 30, repetitions: 3, dueDate: due,
                                             lastGrade: "good", status: .review)
        return store
    }

    @Test("Nothing studied → explained empty state, no session")
    func nothingStudied() {
        let hub = make(HubStore())
        guard case .empty(let message) = hub.start(.mixed, purchases: nil, hasSpanishVoice: true) else {
            Issue.record("expected empty"); return
        }
        #expect(message == PracticeHubModel.nothingStudied)
        #expect(hub.availability(.theme("a1-1")) == PracticeAvailability(available: 0, total: 3))
    }

    @Test("No misses → the weak-spot message")
    func noMisses() {
        let hub = make(studiedStore())
        guard case .empty(let message) = hub.start(.weakSpots, purchases: nil, hasSpanishVoice: true) else {
            Issue.record("expected empty"); return
        }
        #expect(message == PracticeHubModel.noMisses)
    }

    @Test("Session holds only studied cards' exercises, records practice_started, and a correct answer leaves the schedule")
    func session() {
        let store = studiedStore()
        let recorder = HubRecorder()
        let hub = make(store, recorder: recorder)
        #expect(hub.availability(.theme("a1-1")) == PracticeAvailability(available: 2, total: 3))
        guard case .session(let s) = hub.start(.theme("a1-1"), purchases: nil, hasSpanishVoice: true) else {
            Issue.record("expected session"); return
        }
        #expect(s.count == 2)
        #expect(s.grading == .free)
        #expect(recorder.events.contains(.practiceStarted(mode: .theme, count: 2)))
        s.selectedOption = "la"
        s.submit()
        s.advance()
        s.selectedOption = "el"
        s.submit()
        s.advance()
        #expect(s.isComplete)
        #expect(s.completionSubtitle == "Верно 1 из 2.")
        #expect(store.reviews["A1-02"] == nil)                      // never introduced
        #expect(store.events.count == 1)                            // only the miss
        #expect(store.reviews["A1-01"]?.dueDate != due)             // the miss lapsed it
    }

    @Test("Sales on without Pro → paywall; sales off → unlocked")
    func gate() {
        #expect(make(studiedStore(), salesEnabled: false).isUnlocked(nil))
        let locked = make(studiedStore(), salesEnabled: true)
        #expect(!locked.isUnlocked(nil))
        guard case .paywall = locked.start(.mixed, purchases: nil, hasSpanishVoice: true) else {
            Issue.record("expected paywall"); return
        }
    }

    @Test("Card-reader sessions keep the reader policy and the plain completion line")
    func readerUnchanged() {
        let s = ExerciseSessionModel(store: HubStore(), exercises: [mc("X", card: "A1-01")])
        #expect(s.grading == .reader)
        #expect(s.completionSubtitle == "Все упражнения пройдены.")
    }
}
