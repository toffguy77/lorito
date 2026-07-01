import Foundation
import Observation
import Domain

/// Walks a queue of auto-checkable exercises one at a time. Submitting checks the
/// answer, records an attempt, and applies the resulting SM-2 grade to the
/// exercise's card (via `ExercisePracticeService`), then shows feedback until the
/// user continues. Phase 1 supports `multiple-choice` and `fill-in-the-blank`.
@MainActor
@Observable
public final class ExerciseSessionModel: Identifiable {
    public let id = UUID()
    private let practice: ExercisePracticeService
    private let queue: [Exercise]

    public private(set) var index = 0
    /// Set once the current exercise has been submitted.
    public private(set) var lastCheck: ExerciseCheck?

    // User input for the current exercise.
    public var selectedOption: String?
    public var typedText: String = ""

    public init(store: UserDataStore, exercises: [Exercise]) {
        self.practice = ExercisePracticeService(store: store)
        // Phase 1 UI handles the two auto-checkable text types.
        self.queue = exercises.filter { ex in
            switch ex.kind {
            case .multipleChoice, .fillInTheBlank: return true
            default: return false
            }
        }
    }

    public var current: Exercise? {
        guard index < queue.count else { return nil }
        return queue[index]
    }

    public var isComplete: Bool { index >= queue.count }
    public var isChecked: Bool { lastCheck != nil }
    public var positionText: String { "\(min(index + 1, queue.count)) / \(queue.count)" }

    /// Options to show for a multiple-choice exercise.
    public var options: [String] {
        if case let .multipleChoice(options, _) = current?.kind { return options }
        return []
    }

    public var isMultipleChoice: Bool {
        if case .multipleChoice = current?.kind { return true }
        return false
    }

    /// Whether the user has provided an answer for the current exercise.
    public var canSubmit: Bool {
        guard !isChecked, let current else { return false }
        switch current.kind {
        case .multipleChoice: return selectedOption != nil
        case .fillInTheBlank: return !typedText.trimmingCharacters(in: .whitespaces).isEmpty
        default: return false
        }
    }

    /// Check the current answer, persist the attempt + grade, and reveal feedback.
    public func submit() {
        guard !isChecked, let current else { return }
        let answer: ExerciseAnswer
        switch current.kind {
        case .multipleChoice:
            guard let chosen = selectedOption else { return }
            answer = .option(chosen)
        case .fillInTheBlank:
            answer = .text(typedText)
        default:
            return
        }
        lastCheck = try? practice.submit(current, answer: answer, today: Date()).check
    }

    /// Advance to the next exercise (or the completion state) and reset input.
    public func advance() {
        index += 1
        lastCheck = nil
        selectedOption = nil
        typedText = ""
    }
}
