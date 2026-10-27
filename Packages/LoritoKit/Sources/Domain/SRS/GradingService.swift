import Foundation

/// Applies a grade to an item and persists the result through the foundation's
/// `UserDataStore`. The pure scheduler stays free of persistence; this service
/// is the bridge. Only the first grade of an item on a learning day updates its
/// review state; later grades that day (exercises, in-session relearn) are
/// recorded as study events and leave the state unchanged.
public struct GradingService {
    private let store: UserDataStore
    private let calendar: Calendar

    public init(store: UserDataStore, calendar: Calendar = .learningDay) {
        self.store = store
        self.calendar = calendar
    }

    /// Log the grade; on the item's first grade of the learning day, also load
    /// (or initialize) its review, apply the scheduler and persist it. Returns
    /// the review state after the grade.
    @discardableResult
    public func grade(cardID: String, grade: Grade, today: Date) throws -> ReviewState {
        let current = try store.review(for: cardID) ?? ReviewState(cardID: cardID)
        let gradedEarlierToday = try store.allEvents().contains {
            $0.cardID == cardID && $0.grade != nil && calendar.isDate($0.date, inSameDayAs: today)
        }
        var result = current
        if !gradedEarlierToday {
            let retention = (try? store.loadSettings().desiredRetention) ?? 0.9
            result = FSRSScheduler.schedule(state: current, grade: grade, today: today,
                                            retention: retention, calendar: calendar)
            try store.upsertReview(result)
        }
        try store.appendEvent(StudyEvent(cardID: cardID, date: today, grade: grade.rawValue))
        return result
    }
}
