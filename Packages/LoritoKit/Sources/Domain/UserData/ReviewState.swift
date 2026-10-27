import Foundation

/// Scheduling status of a card for the current user.
public enum ReviewStatus: String, Codable, Sendable, CaseIterable {
    case new
    case learning
    case review
    case suspended
}

/// Per-card spaced-repetition state. `FSRSScheduler` reads and updates it;
/// the SM-2 fields (`easeFactor` …) stay for migration and rollback.
public struct ReviewState: Codable, Sendable, Hashable, Identifiable {
    public var cardID: String
    public var easeFactor: Double
    public var interval: Int        // days
    public var repetitions: Int
    public var dueDate: Date
    public var lastGrade: String?
    public var status: ReviewStatus
    // FSRS memory state (fsrs-scheduler); absent for never-reviewed and
    // not-yet-migrated SM-2 cards.
    /// Days until retrievability falls to 90 %.
    public var stability: Double?
    /// 1 (easy) … 10 (hard).
    public var difficulty: Double?
    /// Learning day of the last memory-updating grade.
    public var lastReviewDate: Date?
    /// `FSRSScheduler.version` when FSRS wrote this state.
    public var schedulerVersion: Int?
    /// The due date FSRS computed; differs from `dueDate` after an older
    /// (SM-2) build rescheduled the card on another device.
    public var fsrsDueDate: Date?

    public var id: String { cardID }

    public init(
        cardID: String,
        easeFactor: Double = 2.5,
        interval: Int = 0,
        repetitions: Int = 0,
        dueDate: Date = .distantPast,
        lastGrade: String? = nil,
        status: ReviewStatus = .new,
        stability: Double? = nil,
        difficulty: Double? = nil,
        lastReviewDate: Date? = nil,
        schedulerVersion: Int? = nil,
        fsrsDueDate: Date? = nil
    ) {
        self.cardID = cardID
        self.easeFactor = easeFactor
        self.interval = interval
        self.repetitions = repetitions
        self.dueDate = dueDate
        self.lastGrade = lastGrade
        self.status = status
        self.stability = stability
        self.difficulty = difficulty
        self.lastReviewDate = lastReviewDate
        self.schedulerVersion = schedulerVersion
        self.fsrsDueDate = fsrsDueDate
    }
}
