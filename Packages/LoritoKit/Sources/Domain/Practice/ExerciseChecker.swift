import Foundation

/// A user's submitted answer to an exercise. Phase 1 carries the two
/// auto-checkable inputs; later types extend this.
public enum ExerciseAnswer: Sendable, Equatable {
    /// A chosen option (multiple-choice).
    case option(String)
    /// Free text the user typed (fill-in-the-blank).
    case text(String)
}

/// The outcome of checking an auto-checkable answer.
public struct ExerciseCheck: Sendable, Equatable {
    public let isCorrect: Bool
    /// The SM-2 grade to apply to the exercise's associated card.
    public let grade: Grade
    /// A human-readable form of the correct answer, for feedback.
    public let correctAnswer: String

    public init(isCorrect: Bool, grade: Grade, correctAnswer: String) {
        self.isCorrect = isCorrect
        self.grade = grade
        self.correctAnswer = correctAnswer
    }
}

/// Pure checking of practice answers. No I/O. Maps correctness to an SM-2 grade
/// for the exercise's card: correct → `passingGrade` (Хорошо by default),
/// incorrect → `.again` (Опять).
public enum ExerciseChecker {
    public enum CheckError: Error, Equatable {
        /// The answer kind doesn't match the exercise type.
        case answerMismatch
        /// The exercise type is not auto-checkable in this build (Phase 2 / free-response).
        case notAutoCheckable
    }

    /// Normalized form for typed-answer comparison: case-folded, diacritic-
    /// insensitive (`á`→`a`, `ñ`→`n`), inner whitespace collapsed, trimmed.
    public static func normalize(_ s: String) -> String {
        let folded = s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
        return folded.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    private static func matches(_ input: String, expected: String, accept: [String]) -> Bool {
        let n = normalize(input)
        return n == normalize(expected) || accept.contains { n == normalize($0) }
    }

    /// Check an answer against an auto-checkable exercise. Throws for
    /// self-assessed (`free-response`) or not-yet-implemented types.
    public static func check(
        _ exercise: Exercise,
        answer: ExerciseAnswer,
        passingGrade: Grade = .good
    ) throws -> ExerciseCheck {
        switch exercise.kind {
        case let .multipleChoice(_, correct):
            guard case let .option(chosen) = answer else { throw CheckError.answerMismatch }
            let ok = chosen == correct
            return ExerciseCheck(isCorrect: ok, grade: ok ? passingGrade : .again, correctAnswer: correct)

        case let .fillInTheBlank(expected, accept):
            guard case let .text(typed) = answer else { throw CheckError.answerMismatch }
            let ok = matches(typed, expected: expected, accept: accept)
            return ExerciseCheck(isCorrect: ok, grade: ok ? passingGrade : .again, correctAnswer: expected)

        case .matching, .wordOrder, .pictureMatching:
            // Specified; implemented in a later phase.
            throw CheckError.notAutoCheckable

        case .freeResponse:
            // Self-assessed: correctness comes from the user's own grade.
            throw CheckError.notAutoCheckable
        }
    }
}
