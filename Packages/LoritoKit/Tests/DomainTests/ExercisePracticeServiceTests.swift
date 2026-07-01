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
