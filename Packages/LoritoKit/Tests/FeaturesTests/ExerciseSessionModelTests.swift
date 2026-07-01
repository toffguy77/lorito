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
        #expect(session.isResolved)
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

    @Test("Word-order: placing tokens then submitting checks and grades")
    func wordOrderFlow() {
        let store = PracticeStore()
        let wo = Exercise(id: "WO", level: .a1, themeID: "a1-2", card: "A1-07", prompt: "P", explanation: "E",
                          kind: .wordOrder(tokens: ["yo", "como", "pan"], answer: "Yo como pan", accept: []))
        let session = ExerciseSessionModel(store: store, exercises: [wo])
        #expect(!session.canSubmit)
        for t in ["yo", "como", "pan"] { session.placeToken(t) }
        #expect(session.canSubmit)
        session.submit()
        #expect(session.lastCheck?.isCorrect == true)
        #expect(store.reviews["A1-07"] != nil)
        #expect(store.attempts.count == 1)
    }

    @Test("Matching: choosing a right for each left, submit checks all pairs")
    func matchingFlow() {
        let store = PracticeStore()
        let m = Exercise(id: "M", level: .a1, themeID: "a1-2", card: "A1-07", prompt: "P", explanation: "E",
                         kind: .matching(pairs: [MatchPair(left: "uno", right: "1"), MatchPair(left: "dos", right: "2")]))
        let session = ExerciseSessionModel(store: store, exercises: [m])
        session.matches["uno"] = "1"
        #expect(!session.canSubmit)              // not all lefts chosen yet
        session.matches["dos"] = "2"
        #expect(session.canSubmit)
        session.submit()
        #expect(session.lastCheck?.isCorrect == true)
        #expect(store.attempts.first?.correct == true)
    }

    @Test("Free-response: submit reveals reference, self-grade applies and advances")
    func freeResponseFlow() {
        let store = PracticeStore()
        let fr = Exercise(id: "FR", level: .a1, themeID: "a1-2", card: "A1-07", prompt: "P", explanation: "E",
                          kind: .freeResponse(answer: "hola", accept: []))
        let session = ExerciseSessionModel(store: store, exercises: [fr])
        session.typedText = "ola"
        #expect(session.canSubmit)
        session.submit()
        #expect(session.isRevealed)              // reference shown, not auto-checked
        #expect(session.lastCheck == nil)
        #expect(session.referenceAnswer == "hola")
        session.selfGrade(.good)                 // user grades themselves
        #expect(session.isComplete)              // advanced past the only exercise
        #expect(store.reviews["A1-07"]?.lastGrade == Grade.good.rawValue)
        #expect(store.attempts.first?.correct == true)
    }

    @Test("All six types enter the queue")
    func allTypesQueued() {
        let types: [ExerciseKind] = [
            .multipleChoice(options: ["a", "b"], answer: "a"),
            .fillInTheBlank(answer: "x", accept: []),
            .matching(pairs: [MatchPair(left: "l", right: "r"), MatchPair(left: "l2", right: "r2")]),
            .wordOrder(tokens: ["a"], answer: "a", accept: []),
            .pictureMatching(options: [PictureOption(image: "a.png", label: "a"), PictureOption(image: "b.png", label: "b")]),
            .freeResponse(answer: "y", accept: []),
        ]
        let exercises = types.enumerated().map {
            Exercise(id: "E\($0.offset)", level: .a1, themeID: "a1-2", card: "A1-07",
                     prompt: "P", explanation: "E", kind: $0.element)
        }
        let session = ExerciseSessionModel(store: PracticeStore(), exercises: exercises)
        #expect(session.count == 6)
    }
}
