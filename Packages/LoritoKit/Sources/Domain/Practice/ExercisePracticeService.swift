import Foundation

/// How practice results reach the card's schedule (practice-exercises).
public enum PracticeGrading: Sendable {
    /// Card-reader practice: every result is applied to the card.
    case reader
    /// Free practice (practice-hub): only a failing result reaches the card;
    /// a passing one is recorded as an attempt only.
    case free
}

/// Bridges exercise answering to the existing SRS: checks the answer, records an
/// attempt, and applies the resulting SM-2 grade to the associated card's review
/// through `GradingService` (which uses `srs-engine`). No new schedule is
/// introduced — practice feeds the same per-card `ReviewState`.
public struct ExercisePracticeService {
    private let store: UserDataStore
    private let grading: GradingService
    private let passingGrade: Grade
    private let policy: PracticeGrading

    public init(store: UserDataStore, passingGrade: Grade = .good, policy: PracticeGrading = .reader) {
        self.store = store
        self.grading = GradingService(store: store)
        self.passingGrade = passingGrade
        self.policy = policy
    }

    /// The card's review as it stands (free practice leaves it untouched on a pass).
    private func currentReview(_ cardID: String) throws -> ReviewState {
        try store.review(for: cardID) ?? ReviewState(cardID: cardID)
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
        if policy == .free, check.isCorrect {
            return Outcome(check: check, review: try currentReview(exercise.cardID))
        }
        let review = try grading.grade(cardID: exercise.cardID, grade: check.grade, today: today)
        return Outcome(check: check, review: review)
    }

    /// Record an attempt without touching the card's review (a `speak` miss or a
    /// self-assessed Опять: a recogniser error must not lapse the card).
    public func recordAttemptOnly(_ exercise: Exercise, grade: Grade, correct: Bool = false,
                                  transcript: String? = nil, today: Date) throws {
        try store.appendAttempt(ExerciseAttempt(
            exerciseID: exercise.id, cardID: exercise.cardID, date: today,
            correct: correct, grade: grade.rawValue, transcript: transcript
        ))
    }

    /// Submit a self-assessed (`free-response`) result: the user picked the grade.
    /// Records an attempt (correct when the grade is passing) and applies it.
    @discardableResult
    public func submitSelfGraded(_ exercise: Exercise, grade: Grade, today: Date) throws -> ReviewState {
        try store.appendAttempt(ExerciseAttempt(
            exerciseID: exercise.id, cardID: exercise.cardID, date: today,
            correct: grade != .again, grade: grade.rawValue
        ))
        if policy == .free, grade != .again { return try currentReview(exercise.cardID) }
        return try grading.grade(cardID: exercise.cardID, grade: grade, today: today)
    }
}
