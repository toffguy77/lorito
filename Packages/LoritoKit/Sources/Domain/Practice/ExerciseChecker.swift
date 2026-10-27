import Foundation

/// A user's submitted answer to an exercise, one case per input modality.
public enum ExerciseAnswer: Sendable, Equatable {
    /// A chosen option (multiple-choice).
    case option(String)
    /// Free text the user typed (fill-in-the-blank / free-response).
    case text(String)
    /// Tokens arranged into an order (word-order), left-to-right.
    case ordering([String])
    /// A mapping of left→right (matching) or label→image (picture-matching).
    case matches([String: String])
    /// Speech recogniser output: the best transcript first, then alternatives (speak).
    case transcripts([String])
}

/// One differing word between the expected and the typed text.
public struct WordDiff: Sendable, Equatable {
    public let expected: String
    public let typed: String
    public init(expected: String, typed: String) {
        self.expected = expected
        self.typed = typed
    }
}

/// The outcome of checking an auto-checkable answer.
public struct ExerciseCheck: Sendable, Equatable {
    public let isCorrect: Bool
    /// The SM-2 grade to apply to the exercise's associated card.
    public let grade: Grade
    /// A human-readable form of the correct answer, for feedback.
    public let correctAnswer: String
    /// Accent-only difference (dictation): «почти», graded Трудно.
    public let isAlmost: Bool
    /// Word-level differences (dictation), when not exact.
    public let wordDiff: [WordDiff]?

    public init(isCorrect: Bool, grade: Grade, correctAnswer: String, isAlmost: Bool = false, wordDiff: [WordDiff]? = nil) {
        self.isCorrect = isCorrect
        self.grade = grade
        self.correctAnswer = correctAnswer
        self.isAlmost = isAlmost
        self.wordDiff = wordDiff
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

        case let .matching(pairs):
            guard case let .matches(chosen) = answer else { throw CheckError.answerMismatch }
            let authored = Dictionary(pairs.map { ($0.left, $0.right) }, uniquingKeysWith: { a, _ in a })
            let ok = chosen == authored
            return ExerciseCheck(isCorrect: ok, grade: ok ? passingGrade : .again,
                                 correctAnswer: displayPairs(pairs.map { ($0.left, $0.right) }))

        case let .wordOrder(_, expected, accept):
            guard case let .ordering(tokens) = answer else { throw CheckError.answerMismatch }
            let ok = matches(tokens.joined(separator: " "), expected: expected, accept: accept)
            return ExerciseCheck(isCorrect: ok, grade: ok ? passingGrade : .again, correctAnswer: expected)

        case let .pictureMatching(options):
            guard case let .matches(chosen) = answer else { throw CheckError.answerMismatch }
            let authored = Dictionary(options.map { ($0.label, $0.image) }, uniquingKeysWith: { a, _ in a })
            let ok = chosen == authored
            return ExerciseCheck(isCorrect: ok, grade: ok ? passingGrade : .again,
                                 correctAnswer: displayPairs(options.map { ($0.label, $0.image) }))

        case .freeResponse:
            // Self-assessed: correctness comes from the user's own grade, not this method.
            throw CheckError.notAutoCheckable

        case let .listenChoose(_, _, correct):
            guard case let .option(chosen) = answer else { throw CheckError.answerMismatch }
            let ok = chosen == correct
            return ExerciseCheck(isCorrect: ok, grade: ok ? passingGrade : .again, correctAnswer: correct)

        case let .dictation(audio, accept):
            guard case let .text(typed) = answer else { throw CheckError.answerMismatch }
            let t = dictationNormal(typed)
            let targets = [audio] + accept
            if targets.contains(where: { dictationNormal($0) == t }) {
                return ExerciseCheck(isCorrect: true, grade: passingGrade, correctAnswer: audio)
            }
            let diff = wordDiff(expected: dictationNormal(audio), typed: t)
            if targets.contains(where: { fold(dictationNormal($0)) == fold(t) }) {
                return ExerciseCheck(isCorrect: false, grade: .hard, correctAnswer: audio, isAlmost: true, wordDiff: diff)
            }
            return ExerciseCheck(isCorrect: false, grade: .again, correctAnswer: audio, wordDiff: diff)

        case let .speak(expected, accept):
            guard case let .transcripts(heard) = answer else { throw CheckError.answerMismatch }
            let targets = Set(([expected] + accept).map { fold(dictationNormal($0)) })
            let ok = heard.prefix(5).contains { targets.contains(fold(dictationNormal($0))) }
            return ExerciseCheck(isCorrect: ok, grade: ok ? passingGrade : .again, correctAnswer: expected)
        }
    }

    /// Dictation normal form: lower-cased, punctuation (incl. ¿ ¡) removed,
    /// whitespace collapsed and trimmed. Accents are kept (they are spelling).
    public static func dictationNormal(_ s: String) -> String {
        let noPunct = s.lowercased().unicodeScalars.map { CharacterSet.punctuationCharacters.contains($0) || CharacterSet.symbols.contains($0) ? " " : String($0) }.joined()
        return noPunct.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    static func fold(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive], locale: Locale(identifier: "es"))
    }

    /// Position-wise word differences (extra words on either side included).
    static func wordDiff(expected: String, typed: String) -> [WordDiff] {
        let e = expected.split(separator: " ").map(String.init), t = typed.split(separator: " ").map(String.init)
        return (0..<max(e.count, t.count)).compactMap { i in
            let a = i < e.count ? e[i] : "", b = i < t.count ? t[i] : ""
            return a == b ? nil : WordDiff(expected: a, typed: b)
        }
    }

    private static func displayPairs(_ pairs: [(String, String)]) -> String {
        pairs.map { "\($0.0) → \($0.1)" }.joined(separator: "; ")
    }
}
