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

    public init(
        targetLevel: CEFRLevel? = nil,
        selectedThemeIDs: [String] = [],
        dailyNewCardCount: Int = 1,
        remindersEnabled: Bool = false,
        reminderMinutes: [Int] = [],
        didCompleteOnboarding: Bool = false,
        spanishVariant: SpanishVariant = .spain,
        speechRate: SpeechRate = .normal,
        playAudioWhenSilent: Bool = false
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
    }

    public static let `default` = UserSettings()
}
