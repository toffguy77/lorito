import Foundation
import SwiftData
import Domain

/// SwiftData-backed `UserDataStore`. Maps between Domain value types and the
/// SwiftData @Model records. Use one instance per `ModelContext`.
public final class SwiftDataUserDataStore: UserDataStore {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public convenience init(container: ModelContainer) {
        self.init(context: ModelContext(container))
    }

    // MARK: Settings

    public func loadSettings() throws -> UserSettings {
        guard let r = try context.fetch(FetchDescriptor<SettingsRecord>()).first else {
            return .default
        }
        return UserSettings(
            targetLevel: r.targetLevelRaw.flatMap(CEFRLevel.init(rawValue:)),
            selectedThemeIDs: r.selectedThemeIDs,
            dailyNewCardCount: r.dailyNewCardCount,
            remindersEnabled: r.remindersEnabled,
            reminderMinutes: r.reminderMinutes,
            didCompleteOnboarding: r.didCompleteOnboarding
        )
    }

    public func saveSettings(_ settings: UserSettings) throws {
        let record = try context.fetch(FetchDescriptor<SettingsRecord>()).first ?? {
            let new = SettingsRecord()
            context.insert(new)
            return new
        }()
        record.targetLevelRaw = settings.targetLevel?.rawValue
        record.selectedThemeIDs = settings.selectedThemeIDs
        record.dailyNewCardCount = settings.dailyNewCardCount
        record.remindersEnabled = settings.remindersEnabled
        record.reminderMinutes = settings.reminderMinutes
        record.didCompleteOnboarding = settings.didCompleteOnboarding
        try context.save()
    }

    // MARK: Reviews

    public func allReviews() throws -> [ReviewState] {
        try context.fetch(FetchDescriptor<ReviewRecord>()).map(Self.toDomain)
    }

    public func review(for cardID: String) throws -> ReviewState? {
        try fetchRecord(cardID: cardID).map(Self.toDomain)
    }

    public func upsertReview(_ review: ReviewState) throws {
        let record = try fetchRecord(cardID: review.cardID) ?? {
            let new = ReviewRecord(cardID: review.cardID)
            context.insert(new)
            return new
        }()
        record.easeFactor = review.easeFactor
        record.interval = review.interval
        record.repetitions = review.repetitions
        record.dueDate = review.dueDate
        record.lastGrade = review.lastGrade
        record.statusRaw = review.status.rawValue
        try context.save()
    }

    // MARK: Events

    public func appendEvent(_ event: StudyEvent) throws {
        context.insert(EventRecord(eventID: event.id, cardID: event.cardID, date: event.date, grade: event.grade))
        try context.save()
    }

    public func allEvents() throws -> [StudyEvent] {
        try context.fetch(FetchDescriptor<EventRecord>()).map {
            StudyEvent(id: $0.eventID, cardID: $0.cardID, date: $0.date, grade: $0.grade)
        }
    }

    // MARK: Exercise attempts

    public func appendAttempt(_ attempt: ExerciseAttempt) throws {
        context.insert(AttemptRecord(
            attemptID: attempt.id,
            exerciseID: attempt.exerciseID,
            cardID: attempt.cardID,
            date: attempt.date,
            correct: attempt.correct,
            grade: attempt.grade
        ))
        try context.save()
    }

    public func allAttempts() throws -> [ExerciseAttempt] {
        try context.fetch(FetchDescriptor<AttemptRecord>()).map {
            ExerciseAttempt(
                id: $0.attemptID, exerciseID: $0.exerciseID, cardID: $0.cardID,
                date: $0.date, correct: $0.correct, grade: $0.grade
            )
        }
    }

    // MARK: Helpers

    private func fetchRecord(cardID: String) throws -> ReviewRecord? {
        let id = cardID
        var descriptor = FetchDescriptor<ReviewRecord>(predicate: #Predicate { $0.cardID == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private static func toDomain(_ r: ReviewRecord) -> ReviewState {
        ReviewState(
            cardID: r.cardID,
            easeFactor: r.easeFactor,
            interval: r.interval,
            repetitions: r.repetitions,
            dueDate: r.dueDate,
            lastGrade: r.lastGrade,
            status: ReviewStatus(rawValue: r.statusRaw) ?? .new
        )
    }
}
