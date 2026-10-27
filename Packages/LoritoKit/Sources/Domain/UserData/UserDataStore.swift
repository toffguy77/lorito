import Foundation

/// Abstraction over user-data persistence so Domain and Features stay decoupled
/// from SwiftData/CloudKit. The concrete implementation lives in the Persistence
/// layer.
public protocol UserDataStore: AnyObject {
    func loadSettings() throws -> UserSettings
    func saveSettings(_ settings: UserSettings) throws

    func allReviews() throws -> [ReviewState]
    func review(for cardID: String) throws -> ReviewState?
    func upsertReview(_ review: ReviewState) throws

    func appendEvent(_ event: StudyEvent) throws
    func allEvents() throws -> [StudyEvent]

    // Practice-exercise attempts. Default implementations keep existing
    // conformers source-compatible; the SwiftData store overrides them.
    func appendAttempt(_ attempt: ExerciseAttempt) throws
    func allAttempts() throws -> [ExerciseAttempt]

    // Traps-session outcomes (personal-traps), outside SRS.
    func appendTrapPractice(_ event: TrapPracticeEvent) throws
    func allTrapPractice() throws -> [TrapPracticeEvent]

    // Mock exams (exam-path-dele-ccse).
    func upsertMockAttempt(_ attempt: MockAttempt) throws
    func allMockAttempts() throws -> [MockAttempt]
    func deleteMockAttempt(_ id: UUID) throws

    // Personal words (vocabulary-decks).
    func savePersonalWord(_ word: PersonalWord) throws
    func allPersonalWords() throws -> [PersonalWord]
    func deletePersonalWord(_ id: UUID) throws
    /// Removes an item's review state (study events stay for statistics).
    func deleteReview(for itemID: String) throws
}

public extension UserDataStore {
    func appendAttempt(_ attempt: ExerciseAttempt) throws {}
    func allAttempts() throws -> [ExerciseAttempt] { [] }
    func appendTrapPractice(_ event: TrapPracticeEvent) throws {}
    func allTrapPractice() throws -> [TrapPracticeEvent] { [] }
    func upsertMockAttempt(_ attempt: MockAttempt) throws {}
    func allMockAttempts() throws -> [MockAttempt] { [] }
    func deleteMockAttempt(_ id: UUID) throws {}
    func savePersonalWord(_ word: PersonalWord) throws {}
    func allPersonalWords() throws -> [PersonalWord] { [] }
    func deletePersonalWord(_ id: UUID) throws {}
    func deleteReview(for itemID: String) throws {}
}
