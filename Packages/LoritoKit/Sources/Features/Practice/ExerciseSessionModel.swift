import Foundation
import Observation
import Domain

/// Walks a queue of exercises one at a time. For auto-checkable types, submitting
/// checks the answer, records an attempt, and applies the resulting SM-2 grade to
/// the card (via `ExercisePracticeService`), then shows feedback. `free-response`
/// is self-assessed: submitting reveals the reference and the user grades it with
/// the four SM-2 buttons. Practice always feeds the card's existing `ReviewState`.
@MainActor
@Observable
public final class ExerciseSessionModel: Identifiable {
    public let id = UUID()
    private let practice: ExercisePracticeService
    private let queue: [Exercise]

    public private(set) var index = 0
    /// Set once an auto-checkable exercise has been submitted.
    public private(set) var lastCheck: ExerciseCheck?
    /// True once a `free-response` exercise has been submitted (reference revealed).
    public private(set) var isRevealed = false

    // User input for the current exercise (per modality).
    public var selectedOption: String?           // multiple-choice
    public var typedText: String = ""            // fill-in-the-blank / free-response
    public var ordering: [String] = []           // word-order (chosen order)
    public var matches: [String: String] = [:]   // matching (left→right) / picture (label→image)

    public init(store: UserDataStore, exercises: [Exercise]) {
        self.practice = ExercisePracticeService(store: store)
        self.queue = exercises
    }

    public var current: Exercise? {
        guard index < queue.count else { return nil }
        return queue[index]
    }

    public var isComplete: Bool { index >= queue.count }
    public var count: Int { queue.count }
    /// True when the current exercise is the last in the queue.
    public var isLast: Bool { index + 1 >= queue.count }
    /// The current exercise has been resolved (auto-checked or self-graded reveal).
    public var isResolved: Bool { lastCheck != nil || isRevealed }
    public var positionText: String { "\(min(index + 1, queue.count)) / \(queue.count)" }

    // MARK: Per-type accessors

    public var isMultipleChoice: Bool { if case .multipleChoice = current?.kind { return true }; return false }
    public var isFillInTheBlank: Bool { if case .fillInTheBlank = current?.kind { return true }; return false }
    public var isWordOrder: Bool { if case .wordOrder = current?.kind { return true }; return false }
    public var isMatching: Bool { if case .matching = current?.kind { return true }; return false }
    public var isPictureMatching: Bool { if case .pictureMatching = current?.kind { return true }; return false }
    public var isFreeResponse: Bool { if case .freeResponse = current?.kind { return true }; return false }
    /// True for types that take a typed answer and a text input.
    public var isTextInput: Bool { isFillInTheBlank || isFreeResponse }

    public var options: [String] {
        if case let .multipleChoice(options, _) = current?.kind { return options }
        return []
    }

    /// Tokens not yet placed, for word-order.
    public var remainingTokens: [String] {
        guard case let .wordOrder(tokens, _, _) = current?.kind else { return [] }
        var pool = tokens
        for placed in ordering { if let i = pool.firstIndex(of: placed) { pool.remove(at: i) } }
        return pool
    }

    /// Left column items for matching.
    public var matchingLefts: [String] {
        if case let .matching(pairs) = current?.kind { return pairs.map(\.left) }
        return []
    }
    /// Right column choices for matching (the pool of answers).
    public var matchingRights: [String] {
        if case let .matching(pairs) = current?.kind { return pairs.map(\.right) }
        return []
    }

    /// Picture-matching options (label + image asset name).
    public var pictureOptions: [PictureOption] {
        if case let .pictureMatching(options) = current?.kind { return options }
        return []
    }

    /// The reference answer revealed for a `free-response` exercise.
    public var referenceAnswer: String {
        if case let .freeResponse(answer, _) = current?.kind { return answer }
        return ""
    }

    // MARK: Submission

    public var canSubmit: Bool {
        guard !isResolved, let current else { return false }
        switch current.kind {
        case .multipleChoice: return selectedOption != nil
        case .fillInTheBlank, .freeResponse: return !typedText.trimmingCharacters(in: .whitespaces).isEmpty
        case let .wordOrder(tokens, _, _): return ordering.count == tokens.count
        case let .matching(pairs): return pairs.allSatisfy { matches[$0.left] != nil }
        case let .pictureMatching(options): return options.allSatisfy { matches[$0.label] != nil }
        }
    }

    /// Submit the current answer. Auto-checkable types are checked and graded now;
    /// `free-response` only reveals the reference (the user grades it next).
    public func submit() {
        guard !isResolved, let current else { return }
        if case .freeResponse = current.kind {
            isRevealed = true
            return
        }
        let answer: ExerciseAnswer
        switch current.kind {
        case .multipleChoice:
            guard let chosen = selectedOption else { return }
            answer = .option(chosen)
        case .fillInTheBlank:
            answer = .text(typedText)
        case .wordOrder:
            answer = .ordering(ordering)
        case .matching, .pictureMatching:
            answer = .matches(matches)
        case .freeResponse:
            return
        }
        lastCheck = try? practice.submit(current, answer: answer, today: Date()).check
    }

    /// Self-grade a revealed `free-response` exercise, then advance.
    public func selfGrade(_ grade: Grade) {
        guard isRevealed, let current, case .freeResponse = current.kind else { return }
        _ = try? practice.submitSelfGraded(current, grade: grade, today: Date())
        advance()
    }

    /// Append a token to the word-order answer.
    public func placeToken(_ token: String) {
        guard !isResolved else { return }
        ordering.append(token)
    }

    /// Clear the word-order answer.
    public func resetOrdering() { ordering.removeAll() }

    /// Advance to the next exercise (or completion) and reset input.
    public func advance() {
        index += 1
        lastCheck = nil
        isRevealed = false
        selectedOption = nil
        typedText = ""
        ordering = []
        matches = [:]
    }
}
