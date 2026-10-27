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

/// Synced-data convention: every settings field survives save → load through
/// the SwiftData store, and records without a newer field load with defaults.
/// New synced settings fields add a line to `settingsRoundTrip`.
@Suite("Synced settings round trip")
struct SyncedSettingsRoundTripTests {
    /// Save `settings` through a fresh store and load them back.
    static func roundTrip(_ settings: UserSettings) throws -> UserSettings {
        let container = try PersistenceController.makeContainer(config: .init(inMemory: true))
        let store = SwiftDataUserDataStore(container: container)
        try store.saveSettings(settings)
        return try SwiftDataUserDataStore(container: container).loadSettings()
    }

    @Test("Every settings field round-trips")
    func settingsRoundTrip() throws {
        var s = UserSettings.default
        s.targetLevel = .b2
        s.selectedThemeIDs = ["b2-1", "a1-3"]
        s.dailyNewCardCount = 4
        s.didCompleteOnboarding = true
        s.reminderConfig = ReminderConfig(enabled: true, times: [ReminderTime(hour: 8, minute: 30)])
        s.spanishVariant = .latinAmerica                                // spanish-audio
        s.speechRate = .slow
        s.playAudioWhenSilent = true
        s.desiredRetention = 0.85                                       // fsrs-scheduler
        s.placementKnownLevel = .a2                                     // placement-test
        s.levelGoal = LevelGoal(targetLevel: .b1, targetDate: Date(timeIntervalSinceReferenceDate: 820_000_000),
                                startDate: Date(timeIntervalSinceReferenceDate: 810_000_000), startIntroduced: 12,
                                state: .active)                         // study-goal
        s.exam = ExamGoal(kind: .ccse, date: Date(timeIntervalSinceReferenceDate: 821_000_000), done: true)
        #expect(try Self.roundTrip(s) == s)
    }

    @Test("Every review field round-trips, FSRS memory included")
    func reviewRoundTrip() throws {
        let container = try PersistenceController.makeContainer(config: .init(inMemory: true))
        let due = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let r = ReviewState(cardID: "A1-07", easeFactor: 2.3, interval: 12, repetitions: 4, dueDate: due,
                            lastGrade: "good", status: .review, stability: 12.4, difficulty: 6.2,
                            lastReviewDate: due.addingTimeInterval(-12 * 86_400), schedulerVersion: 2, fsrsDueDate: due)
        try SwiftDataUserDataStore(container: container).upsertReview(r)
        #expect(try SwiftDataUserDataStore(container: container).review(for: "A1-07") == r)
    }

    @Test("A review saved without FSRS fields loads with no memory state")
    func oldReviewRecord() throws {
        let container = try PersistenceController.makeContainer(config: .init(inMemory: true))
        let context = ModelContext(container)
        context.insert(ReviewRecord(cardID: "A1-01", interval: 5, repetitions: 2, statusRaw: "review"))
        try context.save()
        let loaded = try #require(try SwiftDataUserDataStore(container: container).review(for: "A1-01"))
        #expect(loaded.stability == nil && loaded.difficulty == nil && loaded.schedulerVersion == nil)
        #expect(loaded.interval == 5 && loaded.status == .review)
    }

    @Test("A record saved without newer fields loads with their defaults")
    func oldRecordDefaults() throws {
        let container = try PersistenceController.makeContainer(config: .init(inMemory: true))
        let context = ModelContext(container)
        context.insert(SettingsRecord(targetLevelRaw: "A1"))   // only what an old version wrote
        try context.save()
        let loaded = try SwiftDataUserDataStore(container: container).loadSettings()
        #expect(loaded.targetLevel == .a1)
        #expect(loaded.dailyNewCardCount == UserSettings.default.dailyNewCardCount)
        #expect(loaded.didCompleteOnboarding == false)
        #expect(loaded.spanishVariant == .spain && loaded.speechRate == .normal && !loaded.playAudioWhenSilent)
        #expect(loaded.desiredRetention == 0.9)
        #expect(loaded.placementKnownLevel == nil)
        #expect(loaded.levelGoal == nil && loaded.exam == nil)
    }
}
