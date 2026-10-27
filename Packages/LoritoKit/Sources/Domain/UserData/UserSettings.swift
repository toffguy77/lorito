import Foundation

/// User-chosen study scope and preferences. Synced via the user's private store.
public struct UserSettings: Codable, Sendable, Hashable {
    /// Target CEFR level; selecting it includes all lower levels. `nil` until onboarding.
    public var targetLevel: CEFRLevel?
    /// Theme ids the user wants to study; empty means "all themes in scope".
    public var selectedThemeIDs: [String]
    /// How many brand-new cards to introduce per day.
    public var dailyNewCardCount: Int
    /// Whether daily reminders are enabled (reminders change defines the rest).
    public var remindersEnabled: Bool
    /// Reminder times as minutes from midnight (e.g. 540 == 09:00).
    public var reminderMinutes: [Int]
    /// Whether onboarding has been completed.
    public var didCompleteOnboarding: Bool
    /// Spanish variant of the speech voice (spanish-audio).
    public var spanishVariant: SpanishVariant
    /// Speech speed (spanish-audio).
    public var speechRate: SpeechRate
    /// Speak even when the Ring/Silent switch is on (spanish-audio).
    public var playAudioWhenSilent: Bool
    /// Target recall probability for FSRS intervals, 0.80–0.95 (fsrs-scheduler).
    public var desiredRetention: Double {
        didSet { desiredRetention = Self.clampRetention(desiredRetention) }
    }

    /// Highest level passed in the placement test (set on accept; nil for a
    /// manual level choice). Its cards are introduced after higher levels.
    public var placementKnownLevel: CEFRLevel?
    /// Optional level goal and exam date (study-goal), stored as scalars.
    public var goalTargetLevel: CEFRLevel?
    public var goalTargetDate: Date?
    public var goalStartDate: Date?
    public var goalStartIntroduced: Int?
    public var goalState: GoalState?
    public var examKind: ExamKind?
    public var examDate: Date?
    public var examDone: Bool?
    /// New conjugation items per day (conjugation-trainer): 0 = trainer off.
    public var dailyConjugationCount: Int = 0

    public static let conjugationDefaultWhenEnabled = 3
    public static let conjugationRange = 0...20

    public static let retentionRange: ClosedRange<Double> = 0.80...0.95

    public static func clampRetention(_ value: Double) -> Double {
        guard value.isFinite else { return 0.9 }
        return min(max(value, retentionRange.lowerBound), retentionRange.upperBound)
    }

    public init(
        targetLevel: CEFRLevel? = nil,
        selectedThemeIDs: [String] = [],
        dailyNewCardCount: Int = 1,
        remindersEnabled: Bool = false,
        reminderMinutes: [Int] = [],
        didCompleteOnboarding: Bool = false,
        spanishVariant: SpanishVariant = .spain,
        speechRate: SpeechRate = .normal,
        playAudioWhenSilent: Bool = false,
        desiredRetention: Double = 0.9,
        placementKnownLevel: CEFRLevel? = nil
    ) {
        self.targetLevel = targetLevel
        self.selectedThemeIDs = selectedThemeIDs
        self.dailyNewCardCount = dailyNewCardCount
        self.remindersEnabled = remindersEnabled
        self.reminderMinutes = reminderMinutes
        self.didCompleteOnboarding = didCompleteOnboarding
        self.spanishVariant = spanishVariant
        self.speechRate = speechRate
        self.playAudioWhenSilent = playAudioWhenSilent
        self.desiredRetention = Self.clampRetention(desiredRetention)
        self.placementKnownLevel = placementKnownLevel
    }

    public static let `default` = UserSettings()

    /// The level goal assembled from its scalar fields (nil = none).
    public var levelGoal: LevelGoal? {
        get {
            guard let level = goalTargetLevel, let date = goalTargetDate else { return nil }
            return LevelGoal(targetLevel: level, targetDate: date, startDate: goalStartDate ?? date,
                             startIntroduced: goalStartIntroduced ?? 0, state: goalState ?? .active)
        }
        set {
            goalTargetLevel = newValue?.targetLevel
            goalTargetDate = newValue?.targetDate
            goalStartDate = newValue?.startDate
            goalStartIntroduced = newValue?.startIntroduced
            goalState = newValue?.state
        }
    }

    /// The exam date assembled from its scalar fields (nil = none).
    public var exam: ExamGoal? {
        get {
            guard let kind = examKind, let date = examDate else { return nil }
            return ExamGoal(kind: kind, date: date, done: examDone ?? false)
        }
        set {
            examKind = newValue?.kind
            examDate = newValue?.date
            examDone = newValue?.done
        }
    }
}
