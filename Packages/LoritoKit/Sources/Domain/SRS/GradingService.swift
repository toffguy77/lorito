import Foundation

/// Applies a grade to a card and persists the result through the foundation's
/// `UserDataStore`. The pure scheduler stays free of persistence; this service
/// is the bridge. It references the foundation review state, never redefines it.
public struct GradingService {
    private let store: UserDataStore

    public init(store: UserDataStore) {
        self.store = store
    }

    /// Load (or initialize) the card's review, apply the scheduler for the
    /// injected "today", persist the updated review, and log the event.
    @discardableResult
    public func grade(cardID: String, grade: Grade, today: Date) throws -> ReviewState {
        let current = try store.review(for: cardID) ?? ReviewState(cardID: cardID)
        let next = SpacedRepetitionScheduler.schedule(state: current, grade: grade, today: today)
        try store.upsertReview(next)
        try store.appendEvent(StudyEvent(cardID: cardID, date: today, grade: grade.rawValue))
        return next
    }
}
