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

@Suite("First grade per learning day updates memory")
struct FirstGradePerDayTests {
    let cal = Calendar.learningDay(in: TimeZone(identifier: "UTC")!)
    let morning = day(2026, 6, 23).addingTimeInterval(9 * 3600)

    @Test("Later grades the same day are logged but leave the review state unchanged")
    func sameDay() throws {
        let store = FakeStore()
        let grading = GradingService(store: store, calendar: cal)
        let first = try grading.grade(cardID: "A1-01", grade: .good, today: morning)
        let second = try grading.grade(cardID: "A1-01", grade: .again, today: morning.addingTimeInterval(3600))
        #expect(second == first)
        #expect(store.reviews["A1-01"] == first)
        #expect(store.events.map(\.grade) == ["good", "again"])
    }

    @Test("Spec: Хорошо in the session + three correct exercises → state changes once, four events")
    func sessionThenExercises() throws {
        let store = FakeStore()
        let grading = GradingService(store: store, calendar: cal)
        let afterSession = try grading.grade(cardID: "A1-07", grade: .good, today: morning)
        for i in 1...3 {
            _ = try grading.grade(cardID: "A1-07", grade: .good, today: morning.addingTimeInterval(Double(i) * 600))
        }
        #expect(store.reviews["A1-07"] == afterSession)
        #expect(store.events.filter { $0.cardID == "A1-07" }.count == 4)
    }

    @Test("The next learning day updates again")
    func nextDay() throws {
        let store = FakeStore()
        let grading = GradingService(store: store, calendar: cal)
        let first = try grading.grade(cardID: "A1-01", grade: .good, today: morning)
        let next = try grading.grade(cardID: "A1-01", grade: .good, today: morning.addingTimeInterval(86_400))
        #expect(next != first)
        #expect(next.repetitions == first.repetitions + 1)
    }
}
