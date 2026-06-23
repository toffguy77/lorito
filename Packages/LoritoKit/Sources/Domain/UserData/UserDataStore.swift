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
}
