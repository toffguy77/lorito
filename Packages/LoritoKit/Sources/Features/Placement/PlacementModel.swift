import Foundation
import Observation
import Domain

/// Drives the placement test in onboarding: asks the questions chosen by the
/// pure `PlacementTest`, checks answers with `ExerciseChecker` without writing
/// anything, then shows the result (proposal, traps, «Пропустить то, что я
/// знаю»). Nothing is persisted until onboarding completes (`apply`).
@MainActor
@Observable
public final class PlacementModel {
    private let catalog: ContentCatalog
    private let seed: UInt64
    private let analytics: AnalyticsRecording

    public private(set) var history: [PlacementAnswer] = []
    public private(set) var current: Exercise?
    /// Set when the last question has been answered.
    public private(set) var result: PlacementResult?

    // Input for the current question.
    public var selectedOption: String?
    public var ordering: [String] = []
    public var matches: [String: String] = [:]

    /// Result screen: the level to apply (pre-selected proposal) and the opt-in skip.
    public var chosenLevel: CEFRLevel = .a1
    public var skipKnown = false

    /// UI testing only: per-level outcomes replacing the answer check
    /// (`-lorito-placement-script A2=1,B1=0`).
    private let scripted: [CEFRLevel: Bool]?

    public init(catalog: ContentCatalog, seed: UInt64 = UInt64.random(in: 1...UInt64.max),
                analytics: AnalyticsRecording? = nil, scripted: [CEFRLevel: Bool]? = nil) {
        self.catalog = catalog
        self.scripted = scripted
        self.seed = seed
        self.analytics = analytics ?? AnalyticsService.shared
        self.current = PlacementTest.next(exercises: catalog.exercises, seed: seed, history: [])
        self.analytics.record(.placementStarted)
    }

    public var isFinished: Bool { result != nil }
    public var questionNumber: Int { history.count + 1 }

    public var traps: [PlacementTrap] { PlacementTest.traps(history: history, catalog: catalog) }

    // MARK: Question input

    public var options: [String] {
        if case let .multipleChoice(options, _) = current?.kind { return options }
        return []
    }

    public var pictureOptions: [PictureOption] {
        if case let .pictureMatching(options) = current?.kind { return options }
        return []
    }

    public var remainingTokens: [String] {
        guard case let .wordOrder(tokens, _, _) = current?.kind else { return [] }
        var pool = tokens
        for placed in ordering { if let i = pool.firstIndex(of: placed) { pool.remove(at: i) } }
        return pool
    }

    public func placeToken(_ token: String) { ordering.append(token) }
    public func resetOrdering() { ordering = [] }

    public var canSubmit: Bool {
        if scripted != nil { return current != nil }
        return switch current?.kind {
        case .multipleChoice: selectedOption != nil
        case .wordOrder: remainingTokens.isEmpty && !ordering.isEmpty
        case .pictureMatching(let options): matches.count == options.count
        default: false
        }
    }

    /// Record the answer (no feedback, nothing persisted) and move on.
    public func submit() {
        guard let exercise = current, canSubmit else { return }
        if let scripted {
            answerCurrent(correct: scripted[exercise.level] ?? false)
            return
        }
        let answer: ExerciseAnswer
        switch exercise.kind {
        case .multipleChoice: answer = .option(selectedOption ?? "")
        case .wordOrder: answer = .ordering(ordering)
        default: answer = .matches(matches)
        }
        let correct = (try? ExerciseChecker.check(exercise, answer: answer).isCorrect) ?? false
        answerCurrent(correct: correct)
    }

    /// Records the current question's outcome (also the test seam).
    func answerCurrent(correct: Bool) {
        guard let exercise = current else { return }
        history.append(PlacementAnswer(exercise: exercise, correct: correct))
        selectedOption = nil
        ordering = []
        matches = [:]
        current = PlacementTest.next(exercises: catalog.exercises, seed: seed, history: history)
        if current == nil {
            let r = PlacementTest.result(history: history)
            result = r
            chosenLevel = r.proposedTarget
            analytics.record(.placementCompleted(level: r.proposedTarget, known: r.highestKnown, questions: r.questionCount))
        }
    }

    /// Parses `-lorito-placement-script A2=1,B1=0` from launch arguments.
    static func uiTestScript(from arguments: [String]) -> [CEFRLevel: Bool]? {
        guard let i = arguments.firstIndex(of: "-lorito-placement-script"), i + 1 < arguments.count else { return nil }
        var out: [CEFRLevel: Bool] = [:]
        for pair in arguments[i + 1].split(separator: ",") {
            let parts = pair.split(separator: "=")
            if parts.count == 2, let level = CEFRLevel(rawValue: String(parts[0])) { out[level] = parts[1] == "1" }
        }
        return out
    }

    // MARK: Apply on onboarding completion

    /// Cards failed in the test, in test order (introduced first in the first session).
    public var failedCardIDs: [String] {
        var seen: Set<String> = []
        return history.filter { !$0.correct }.map(\.cardID).filter { seen.insert($0).inserted }
    }

    /// Store `placementKnownLevel` and, when opted in, seed the known cards.
    /// Returns the seeded card ids. Writes review states only — no study events.
    @discardableResult
    public func apply(to store: UserDataStore, today: Date = Date(), calendar: Calendar = .learningDay) throws -> [String] {
        guard let result else { return [] }
        var settings = try store.loadSettings()
        settings.placementKnownLevel = result.highestKnown
        try store.saveSettings(settings)
        guard skipKnown else { return [] }
        let existing = Set(try store.allReviews().map(\.cardID))
        let seeded = PlacementTest.seedReviews(history: history, result: result, today: today, calendar: calendar)
            .filter { !existing.contains($0.cardID) }
        for review in seeded { try store.upsertReview(review) }
        analytics.record(.placementSkipKnownApplied(cards: seeded.count))
        return seeded.map(\.cardID)
    }
}
