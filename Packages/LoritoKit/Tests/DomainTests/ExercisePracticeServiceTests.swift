import Testing
import Foundation
@testable import Domain

/// In-memory store double that records attempts (the protocol's default
/// implementation is a no-op, so the practice tests need a real one).
private final class FakeStore: UserDataStore {
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

private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    return cal.date(from: DateComponents(year: y, month: m, day: d))!
}

private func exercise(_ kind: ExerciseKind, card: String = "A1-07") -> Exercise {
    Exercise(id: "A1-EX-01", level: .a1, themeID: "a1-2", card: card,
             prompt: "P", explanation: "E", kind: kind)
}

@Suite("Exercise practice service")
struct ExercisePracticeServiceTests {
    let today = day(2026, 6, 23)

    @Test("Correct answer applies a passing grade to the card and records an attempt")
    func correctApplies() throws {
        let store = FakeStore()
        let svc = ExercisePracticeService(store: store)
        let out = try svc.submit(exercise(.multipleChoice(options: ["el", "la"], answer: "la")),
                                 answer: .option("la"), today: today)
        #expect(out.check.isCorrect)
        // card's review advanced with a passing grade
        #expect(try store.review(for: "A1-07")?.repetitions == 1)
        #expect(store.events.count == 1)
        #expect(store.attempts.count == 1)
        #expect(store.attempts.first?.correct == true)
        #expect(store.attempts.first?.cardID == "A1-07")
    }

    @Test("Incorrect answer applies Опять to the card and records a failed attempt")
    func incorrectApplies() throws {
        let store = FakeStore()
        try store.upsertReview(ReviewState(cardID: "A1-07", interval: 10, repetitions: 3, status: .review))
        let svc = ExercisePracticeService(store: store)
        let out = try svc.submit(exercise(.fillInTheBlank(answer: "casas", accept: [])),
                                 answer: .text("casa"), today: today)
        #expect(out.check.isCorrect == false)
        let review = try store.review(for: "A1-07")
        #expect(review?.lastGrade == Grade.again.rawValue)
        #expect(review?.repetitions == 0)  // lapse reset
        #expect(store.attempts.first?.correct == false)
    }

    @Test("Practice touches only the associated card's review — no separate schedule")
    func noSeparateSchedule() throws {
        let store = FakeStore()
        let svc = ExercisePracticeService(store: store)
        _ = try svc.submit(exercise(.multipleChoice(options: ["el", "la"], answer: "la"), card: "A1-07"),
                           answer: .option("la"), today: today)
        let all = try store.allReviews()
        #expect(all.count == 1)
        #expect(all.first?.cardID == "A1-07")
    }

    @Test("Self-graded free-response applies the user's grade")
    func selfGraded() throws {
        let store = FakeStore()
        let svc = ExercisePracticeService(store: store)
        let review = try svc.submitSelfGraded(exercise(.freeResponse(answer: "hola", accept: [])),
                                              grade: .easy, today: today)
        #expect(review.lastGrade == Grade.easy.rawValue)
        #expect(store.attempts.first?.correct == true)
        #expect(store.attempts.first?.grade == Grade.easy.rawValue)
    }
}

@Suite("Free practice grading (practice-hub)")
struct FreePracticeGradingTests {
    let today = day(2026, 6, 23)
    let due = day(2026, 7, 23)

    private func storeWithReview() throws -> FakeStore {
        let store = FakeStore()
        try store.upsertReview(ReviewState(cardID: "A1-07", interval: 30, repetitions: 3, dueDate: due,
                                           lastGrade: "good", status: .review))
        return store
    }

    @Test("Correct auto-checked answer: attempt only, no study event, schedule unchanged")
    func correctIsAttemptOnly() throws {
        let store = try storeWithReview()
        let svc = ExercisePracticeService(store: store, policy: .free)
        let out = try svc.submit(exercise(.multipleChoice(options: ["el", "la"], answer: "la")),
                                 answer: .option("la"), today: today)
        #expect(out.check.isCorrect)
        #expect(store.attempts.count == 1 && store.attempts[0].correct)
        #expect(store.events.isEmpty)
        #expect(try store.review(for: "A1-07")?.dueDate == due)
    }

    @Test("Passing self-grades are attempts only")
    func passingSelfGrade() throws {
        for grade in [Grade.hard, .good, .easy] {
            let store = try storeWithReview()
            let svc = ExercisePracticeService(store: store, policy: .free)
            _ = try svc.submitSelfGraded(exercise(.freeResponse(answer: "x", accept: [])), grade: grade, today: today)
            #expect(store.attempts.count == 1)
            #expect(store.events.isEmpty)
            #expect(try store.review(for: "A1-07")?.dueDate == due)
        }
    }

    @Test("A mistake applies Опять and records a study event; self-assessed Опять too")
    func mistakeLapses() throws {
        let store = try storeWithReview()
        let svc = ExercisePracticeService(store: store, policy: .free)
        _ = try svc.submit(exercise(.fillInTheBlank(answer: "casas", accept: [])), answer: .text("casa"), today: today)
        #expect(store.events.count == 1)
        #expect(try store.review(for: "A1-07")?.dueDate != due)

        let store2 = try storeWithReview()
        _ = try ExercisePracticeService(store: store2, policy: .free)
            .submitSelfGraded(exercise(.freeResponse(answer: "x", accept: [])), grade: .again, today: today)
        #expect(store2.events.count == 1)
        #expect(try store2.review(for: "A1-07")?.dueDate != due)
    }

    @Test("A second mistake on the same day records an event but leaves the state")
    func secondMistakeSameDay() throws {
        let store = try storeWithReview()
        let svc = ExercisePracticeService(store: store, policy: .free)
        let wrong = exercise(.fillInTheBlank(answer: "casas", accept: []))
        _ = try svc.submit(wrong, answer: .text("casa"), today: today)
        let afterFirst = try store.review(for: "A1-07")
        _ = try svc.submit(wrong, answer: .text("casa"), today: today)
        #expect(store.events.count == 2)
        #expect(try store.review(for: "A1-07") == afterFirst)
    }

    @Test("Recognised speech in free practice never touches the schedule")
    func speakFree() throws {
        let store = try storeWithReview()
        let svc = ExercisePracticeService(store: store, policy: .free)
        _ = try svc.submit(exercise(.speak(answer: "hola", accept: [])), answer: .transcripts(["hola"]), today: today)
        #expect(store.events.isEmpty)
        #expect(try store.review(for: "A1-07")?.dueDate == due)
    }

    @Test("recordAttemptOnly can record a correct attempt")
    func attemptOnlyCorrect() throws {
        let store = FakeStore()
        try ExercisePracticeService(store: store).recordAttemptOnly(exercise(.freeResponse(answer: "x", accept: [])),
                                                                    grade: .good, correct: true, today: today)
        #expect(store.attempts.first?.correct == true)
    }
}
