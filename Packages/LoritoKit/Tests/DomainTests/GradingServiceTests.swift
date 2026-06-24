import Testing
import Foundation
@testable import Domain

/// In-memory UserDataStore double — proves apply-and-persist without SwiftData.
private final class FakeStore: UserDataStore {
    var settings = UserSettings.default
    var reviews: [String: ReviewState] = [:]
    var events: [StudyEvent] = []

    func loadSettings() throws -> UserSettings { settings }
    func saveSettings(_ s: UserSettings) throws { settings = s }
    func allReviews() throws -> [ReviewState] { Array(reviews.values) }
    func review(for cardID: String) throws -> ReviewState? { reviews[cardID] }
    func upsertReview(_ r: ReviewState) throws { reviews[r.cardID] = r }
    func appendEvent(_ e: StudyEvent) throws { events.append(e) }
    func allEvents() throws -> [StudyEvent] { events }
}

private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    return cal.date(from: DateComponents(year: y, month: m, day: d))!
}

@Suite("Grading service")
struct GradingServiceTests {
    let today = day(2026, 6, 23)

    @Test("Grading an unseen card initializes and persists it")
    func initializesUnseen() throws {
        let store = FakeStore()
        let svc = GradingService(store: store)
        let result = try svc.grade(cardID: "A1-15", grade: .good, today: today)
        #expect(result.repetitions == 1)
        #expect(try store.review(for: "A1-15") != nil)
        #expect(store.events.count == 1)
    }

    @Test("Grading an existing card updates the persisted review")
    func updatesExisting() throws {
        let store = FakeStore()
        try store.upsertReview(ReviewState(cardID: "A1-15", easeFactor: 2.5, interval: 10, repetitions: 3, status: .review))
        let svc = GradingService(store: store)
        let result = try svc.grade(cardID: "A1-15", grade: .good, today: today)
        #expect(result.interval == 25)
        #expect(try store.review(for: "A1-15")?.interval == 25)
    }
}
