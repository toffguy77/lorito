import Foundation

/// A record of one practice-exercise attempt, kept for statistics and review.
/// `grade` is the SM-2 grade applied to the associated card as a result.
public struct ExerciseAttempt: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var exerciseID: String
    public var cardID: String
    public var date: Date
    public var correct: Bool
    public var grade: String?

    public init(
        id: UUID = UUID(),
        exerciseID: String,
        cardID: String,
        date: Date,
        correct: Bool,
        grade: String? = nil
    ) {
        self.id = id
        self.exerciseID = exerciseID
        self.cardID = cardID
        self.date = date
        self.correct = correct
        self.grade = grade
    }
}
