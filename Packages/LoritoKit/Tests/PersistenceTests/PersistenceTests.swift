import Testing
import Foundation
import SwiftData
import Domain
@testable import Persistence

@Suite("Persistence round-trip")
struct PersistenceTests {
    /// Settings and review state survive a simulated relaunch (new container from the same file).
    @Test("Data persists across a simulated relaunch")
    func persistsAcrossRelaunch() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("lorito-test-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        // Session 1: write
        do {
            let container = try PersistenceController.makeContainer(config: .init(url: url))
            let store = SwiftDataUserDataStore(container: container)
            var settings = UserSettings.default
            settings.targetLevel = .b1
            settings.selectedThemeIDs = ["a1-1", "b1-2"]
            settings.dailyNewCardCount = 3
            settings.didCompleteOnboarding = true
            try store.saveSettings(settings)
            try store.upsertReview(ReviewState(cardID: "A1-15", interval: 6, repetitions: 2, status: .review))
        }

        // Session 2: fresh container from the same URL
        let container2 = try PersistenceController.makeContainer(config: .init(url: url))
        let store2 = SwiftDataUserDataStore(container: container2)
        let settings = try store2.loadSettings()
        #expect(settings.targetLevel == .b1)
        #expect(settings.selectedThemeIDs == ["a1-1", "b1-2"])
        #expect(settings.dailyNewCardCount == 3)
        #expect(settings.didCompleteOnboarding == true)

        let review = try store2.review(for: "A1-15")
        #expect(review?.interval == 6)
        #expect(review?.status == .review)
    }

    @Test("Upsert updates an existing review in place")
    func upsertUpdates() throws {
        let container = try PersistenceController.makeContainer(config: .init(inMemory: true))
        let store = SwiftDataUserDataStore(container: container)
        try store.upsertReview(ReviewState(cardID: "B2-01", interval: 1))
        try store.upsertReview(ReviewState(cardID: "B2-01", interval: 10, status: .review))
        let all = try store.allReviews()
        #expect(all.count == 1)
        #expect(all.first?.interval == 10)
    }

    @Test("Events append")
    func eventsAppend() throws {
        let container = try PersistenceController.makeContainer(config: .init(inMemory: true))
        let store = SwiftDataUserDataStore(container: container)
        try store.appendEvent(StudyEvent(cardID: "A1-01", date: .now, grade: "good"))
        try store.appendEvent(StudyEvent(cardID: "A1-02", date: .now, grade: "again"))
        #expect(try store.allEvents().count == 2)
    }

    @Test("Exercise attempts append and survive a relaunch")
    func attemptsPersist() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("lorito-attempts-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        do {
            let store = SwiftDataUserDataStore(container: try PersistenceController.makeContainer(config: .init(url: url)))
            try store.appendAttempt(ExerciseAttempt(exerciseID: "A1-EX-01", cardID: "A1-07", date: .now, correct: true, grade: "good"))
            try store.appendAttempt(ExerciseAttempt(exerciseID: "A1-EX-06", cardID: "A1-08", date: .now, correct: false, grade: "again"))
        }

        let store2 = SwiftDataUserDataStore(container: try PersistenceController.makeContainer(config: .init(url: url)))
        let attempts = try store2.allAttempts()
        #expect(attempts.count == 2)
        #expect(attempts.contains { $0.exerciseID == "A1-EX-01" && $0.correct })
        #expect(attempts.contains { $0.exerciseID == "A1-EX-06" && !$0.correct })
    }
}
