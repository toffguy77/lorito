import Foundation

/// Bridges exercise answering to the existing SRS: checks the answer, records an
/// attempt, and applies the resulting SM-2 grade to the associated card's review
/// through `GradingService` (which uses `srs-engine`). No new schedule is
/// introduced — practice feeds the same per-card `ReviewState`.
public struct ExercisePracticeService {
    private let store: UserDataStore
    private let grading: GradingService
    private let passingGrade: Grade

    public init(store: UserDataStore, passingGrade: Grade = .good) {
        self.store = store
        self.grading = GradingService(store: store)
        self.passingGrade = passingGrade
    }

    /// The result of submitting an answer: the check outcome and the updated review.
    public struct Outcome: Sendable {
        public let check: ExerciseCheck
        public let review: ReviewState
    }

    /// Submit an answer to an auto-checkable exercise. Records an attempt and
    /// applies the grade to the card's review.
    @discardableResult
    public func submit(_ exercise: Exercise, answer: ExerciseAnswer, today: Date) throws -> Outcome {
        let check = try ExerciseChecker.check(exercise, answer: answer, passingGrade: passingGrade)
        try store.appendAttempt(ExerciseAttempt(
            exerciseID: exercise.id, cardID: exercise.cardID, date: today,
            correct: check.isCorrect, grade: check.grade.rawValue
        ))
        let review = try grading.grade(cardID: exercise.cardID, grade: check.grade, today: today)
        return Outcome(check: check, review: review)
    }

    /// Submit a self-assessed (`free-response`) result: the user picked the grade.
    /// Records an attempt (correct when the grade is passing) and applies it.
    @discardableResult
    public func submitSelfGraded(_ exercise: Exercise, grade: Grade, today: Date) throws -> ReviewState {
        try store.appendAttempt(ExerciseAttempt(
            exerciseID: exercise.id, cardID: exercise.cardID, date: today,
            correct: grade != .again, grade: grade.rawValue
        ))
        return try grading.grade(cardID: exercise.cardID, grade: grade, today: today)
    }
}
