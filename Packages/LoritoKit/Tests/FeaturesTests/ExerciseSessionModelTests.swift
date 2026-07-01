import Testing
import Foundation
import Domain
@testable import Features

/// In-memory store that also records exercise attempts.
private final class PracticeStore: UserDataStore {
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

private let mc = Exercise(
    id: "A1-EX-01", level: .a1, themeID: "a1-2", card: "A1-07",
    prompt: "P", explanation: "E", kind: .multipleChoice(options: ["el", "la"], answer: "la")
)
private let fill = Exercise(
    id: "A1-EX-06", level: .a1, themeID: "a1-2", card: "A1-08",
    prompt: "P", explanation: "E", kind: .fillInTheBlank(answer: "casas", accept: [])
)

@Suite("Exercise session model")
@MainActor
struct ExerciseSessionModelTests {
    @Test("Submit checks, reveals feedback, persists grade + attempt; continue advances to completion")
    func fullFlow() {
        let store = PracticeStore()
        let session = ExerciseSessionModel(store: store, exercises: [mc, fill])

        // First exercise: multiple-choice answered correctly.
        #expect(session.current?.id == "A1-EX-01")
        #expect(!session.canSubmit)                 // nothing chosen yet
        session.selectedOption = "la"
        #expect(session.canSubmit)
        session.submit()
        #expect(session.isChecked)
        #expect(session.lastCheck?.isCorrect == true)
        #expect(store.reviews["A1-07"] != nil)       // grade applied to the card
        #expect(store.attempts.count == 1)
        #expect(store.attempts.first?.correct == true)

        session.advance()
        #expect(session.current?.id == "A1-EX-06")
        #expect(session.lastCheck == nil)            // feedback reset

        // Second exercise: fill-in-the-blank answered wrong.
        session.typedText = "casa"
        session.submit()
        #expect(session.lastCheck?.isCorrect == false)
        #expect(session.lastCheck?.correctAnswer == "casas")
        #expect(store.reviews["A1-08"]?.lastGrade == Grade.again.rawValue)

        session.advance()
        #expect(session.isComplete)
        #expect(session.current == nil)
        #expect(store.attempts.count == 2)
    }

    @Test("Only auto-checkable Phase-1 types enter the queue")
    func filtersUnsupportedTypes() {
        let free = Exercise(id: "X", level: .a1, themeID: "a1-2", card: "A1-07",
                            prompt: "P", explanation: "E",
                            kind: .freeResponse(answer: "hola", accept: []))
        let session = ExerciseSessionModel(store: PracticeStore(), exercises: [free, mc])
        #expect(session.current?.id == "A1-EX-01")   // free-response skipped
        #expect(session.positionText == "1 / 1")
    }
}
