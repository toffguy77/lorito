import Foundation

public enum PlacementConstants {
    /// Questions per level block.
    public static let itemsPerLevel = 3
    /// Correct answers needed for a level to pass.
    public static let passThreshold = 2
    /// The first level tested.
    public static let startLevel: CEFRLevel = .a2
    /// A level with fewer usable exercises is untestable; the test stops below it.
    public static let minUsableExercises = 2
    /// Traps shown on the result screen.
    public static let maxTraps = 3
}

/// One answered placement question.
public struct PlacementAnswer: Sendable, Hashable, Codable {
    public var exerciseID: String
    public var level: CEFRLevel
    public var themeID: String
    public var cardID: String
    public var correct: Bool

    public init(exerciseID: String, level: CEFRLevel, themeID: String, cardID: String, correct: Bool) {
        self.exerciseID = exerciseID
        self.level = level
        self.themeID = themeID
        self.cardID = cardID
        self.correct = correct
    }

    public init(exercise: Exercise, correct: Bool) {
        self.init(exerciseID: exercise.id, level: exercise.level, themeID: exercise.themeID,
                  cardID: exercise.cardID, correct: correct)
    }
}

public struct PlacementResult: Sendable, Hashable {
    /// Proposed `targetLevel`.
    public var proposedTarget: CEFRLevel
    /// Highest passed level (stored as `placementKnownLevel` on accept); nil when none passed.
    public var highestKnown: CEFRLevel?
    public var questionCount: Int

    public init(proposedTarget: CEFRLevel, highestKnown: CEFRLevel?, questionCount: Int) {
        self.proposedTarget = proposedTarget
        self.highestKnown = highestKnown
        self.questionCount = questionCount
    }

    /// A1 … highest passed level.
    public var knownLevels: [CEFRLevel] { highestKnown?.included ?? [] }
}

public struct PlacementTrap: Sendable, Hashable {
    public var cardID: String
    /// The card's first «Частые ошибки» item (Markdown).
    public var text: String
}

/// Pure placement test: blocks of three questions per level starting at A2,
/// climbing after each pass, stopping after a failed level or a C2 pass; an
/// A2 failure asks one A1 block. Selection is a function of the exercise pool,
/// an injected seed and the answer history only.
public enum PlacementTest {
    /// Fast, auto-checkable types only.
    public static func isEligible(_ exercise: Exercise) -> Bool {
        switch exercise.kind {
        case .multipleChoice, .pictureMatching, .wordOrder: true
        default: false
        }
    }

    /// The block asked for `level`: up to `itemsPerLevel` exercises, distinct
    /// themes first, in a seeded order independent of the pool's order.
    public static func block(level: CEFRLevel, exercises: [Exercise], seed: UInt64) -> [Exercise] {
        var candidates = exercises.filter { $0.level == level && isEligible($0) }.sorted { $0.id < $1.id }
        var rng = SplitMix64(seed: seed &+ UInt64(level.order) &* 0x9E37_79B9_7F4A_7C15)
        candidates.shuffle(using: &rng)
        var picked: [Exercise] = []
        var themes: Set<String> = []
        for e in candidates where picked.count < PlacementConstants.itemsPerLevel && !themes.contains(e.themeID) {
            picked.append(e)
            themes.insert(e.themeID)
        }
        for e in candidates where picked.count < PlacementConstants.itemsPerLevel && !picked.contains(e) {
            picked.append(e)
        }
        return picked
    }

    /// The next question, or nil when the test is over.
    public static func next(exercises: [Exercise], seed: UInt64, history: [PlacementAnswer]) -> Exercise? {
        var level = PlacementConstants.startLevel
        var index = 0
        while true {
            let questions = block(level: level, exercises: exercises, seed: seed)
            guard questions.count >= PlacementConstants.minUsableExercises else { return nil }
            let answered = history.dropFirst(index).prefix(questions.count)
            if answered.count < questions.count { return questions[answered.count] }
            index += questions.count
            let passed = answered.filter(\.correct).count >= PlacementConstants.passThreshold
            if level == .a1 { return nil }                       // only reached after an A2 failure
            if passed {
                guard let up = level.next else { return nil }    // C2 passed
                level = up
            } else if level == PlacementConstants.startLevel {
                level = .a1
            } else {
                return nil
            }
        }
    }

    public static func result(history: [PlacementAnswer]) -> PlacementResult {
        var correctByLevel: [CEFRLevel: Int] = [:]
        for a in history where a.correct { correctByLevel[a.level, default: 0] += 1 }
        let passed = correctByLevel.filter { $0.value >= PlacementConstants.passThreshold }.keys
        let highest = passed.max()
        let proposed = highest.map { $0.next ?? $0 } ?? .a1
        return PlacementResult(proposedTarget: proposed, highestKnown: highest, questionCount: history.count)
    }

    /// Up to three traps: the first «Частые ошибки» item of each failed card,
    /// most recent failure first, cards without a mistakes section skipped.
    public static func traps(history: [PlacementAnswer], catalog: ContentCatalog) -> [PlacementTrap] {
        var out: [PlacementTrap] = []
        var seen: Set<String> = []
        for a in history.reversed() where !a.correct && !seen.contains(a.cardID) {
            seen.insert(a.cardID)
            guard let body = catalog.card(id: a.cardID)?.body, let item = CardBodyParser.firstMistake(in: body) else { continue }
            out.append(PlacementTrap(cardID: a.cardID, text: item))
            if out.count == PlacementConstants.maxTraps { break }
        }
        return out
    }

    /// «Пропустить то, что я знаю»: review states for cards answered correctly
    /// at a known level — the scheduler's result for Хорошо on a new card.
    public static func seedReviews(history: [PlacementAnswer], result: PlacementResult, today: Date,
                                   calendar: Calendar = .learningDay) -> [ReviewState] {
        guard let known = result.highestKnown else { return [] }
        var seen: Set<String> = []
        var out: [ReviewState] = []
        for a in history where a.correct && a.level <= known && !seen.contains(a.cardID) {
            seen.insert(a.cardID)
            out.append(FSRSScheduler.schedule(state: ReviewState(cardID: a.cardID), grade: .good,
                                              today: today, calendar: calendar))
        }
        return out
    }
}

extension CEFRLevel {
    /// The level above, or nil for C2.
    public var next: CEFRLevel? {
        let all = Self.allCases
        return order + 1 < all.count ? all[order + 1] : nil
    }
}

/// Small deterministic PRNG for seeded question order.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
