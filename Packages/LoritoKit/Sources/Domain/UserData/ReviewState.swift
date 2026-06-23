import Foundation

/// Scheduling status of a card for the current user.
public enum ReviewStatus: String, Codable, Sendable, CaseIterable {
    case new
    case learning
    case review
    case suspended
}

/// Per-card spaced-repetition state. The SM-2 algorithm (a later change) reads
/// and updates these fields; this change only defines and persists them.
public struct ReviewState: Codable, Sendable, Hashable, Identifiable {
    public var cardID: String
    public var easeFactor: Double
    public var interval: Int        // days
    public var repetitions: Int
    public var dueDate: Date
    public var lastGrade: String?
    public var status: ReviewStatus

    public var id: String { cardID }

    public init(
        cardID: String,
        easeFactor: Double = 2.5,
        interval: Int = 0,
        repetitions: Int = 0,
        dueDate: Date = .distantPast,
        lastGrade: String? = nil,
        status: ReviewStatus = .new
    ) {
        self.cardID = cardID
        self.easeFactor = easeFactor
        self.interval = interval
        self.repetitions = repetitions
        self.dueDate = dueDate
        self.lastGrade = lastGrade
        self.status = status
    }
}
