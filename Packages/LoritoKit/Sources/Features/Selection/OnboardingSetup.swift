import Foundation
import Observation
import Domain

/// How onboarding runs: on first launch (or once after an update) or again from
/// Settings. A revisit never starts a session and never touches progress.
public enum OnboardingMode: Sendable, Equatable {
    case firstRun, revisit
}

/// Device-local record of the onboarding version completed here. Version 2 adds
/// the goal, variant, pace and sound steps; a device that completed only version 1
/// goes through the current onboarding once.
public struct OnboardingVersionStore: @unchecked Sendable {
    public static let currentVersion = 2
    public static let key = "lorito.onboardingVersion"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var completedVersion: Int { defaults.integer(forKey: Self.key) }

    /// `completedInSettings`: onboarding finished at some version (synced flag).
    public func needsOnboarding(completedInSettings: Bool) -> Bool {
        !completedInSettings || completedVersion < Self.currentVersion
    }

    public func markCompleted() { defaults.set(Self.currentVersion, forKey: Self.key) }

    /// UI testing: every launch starts from scratch.
    public func reset() { defaults.removeObject(forKey: Self.key) }
}

/// Working state of the goal-free setup steps: variant, pace and sound. Values
/// start from the stored settings; each step saves its own fields (load fresh,
/// change, save) so the rest of the settings survive.
@MainActor
@Observable
public final class OnboardingSetupModel {
    public static let cardsRange = 1...10
    private let store: UserDataStore

    public var variant: SpanishVariant
    private var cards: Int
    public var cardsPerDay: Int {
        get { cards }
        set { cards = Self.clamp(newValue, Self.cardsRange) }
    }
    private var words: Bool
    public var wordsEnabled: Bool {
        get { words }
        set {
            words = newValue
            if newValue && wordsPerDay == 0 { wordsPerDay = UserSettings.wordsDefaultWhenEnabled }
        }
    }
    public var wordsPerDay: Int
    private var conjugations: Bool
    public var conjugationsEnabled: Bool {
        get { conjugations }
        set {
            conjugations = newValue
            if newValue && conjugationsPerDay == 0 { conjugationsPerDay = UserSettings.conjugationDefaultWhenEnabled }
        }
    }
    public var conjugationsPerDay: Int
    public var rate: SpeechRate
    public var playWhenSilent: Bool

    public init(store: UserDataStore) {
        self.store = store
        let s = (try? store.loadSettings()) ?? .default
        variant = s.spanishVariant
        cards = Self.clamp(s.dailyNewCardCount, Self.cardsRange)
        words = s.dailyNewWordCount > 0
        wordsPerDay = s.dailyNewWordCount
        conjugations = s.dailyConjugationCount > 0
        conjugationsPerDay = s.dailyConjugationCount
        rate = s.speechRate
        playWhenSilent = s.playAudioWhenSilent
    }

    public func saveVariant() {
        update {
            $0.spanishVariant = variant
            $0.variantPromptAnswered = true
        }
    }

    public func savePace() {
        update {
            $0.dailyNewCardCount = cardsPerDay
            $0.dailyNewWordCount = wordsEnabled ? Self.clamp(wordsPerDay, 1...20) : 0
            $0.dailyConjugationCount = conjugationsEnabled ? Self.clamp(conjugationsPerDay, 1...UserSettings.conjugationRange.upperBound) : 0
        }
    }

    public func saveSound() {
        update {
            $0.speechRate = rate
            $0.playAudioWhenSilent = playWhenSilent
        }
    }

    private func update(_ change: (inout UserSettings) -> Void) {
        var s = (try? store.loadSettings()) ?? .default
        change(&s)
        try? store.saveSettings(s)
    }

    private static func clamp(_ value: Int, _ range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}

/// Completing onboarding: persist the scope, record the version on this device and
/// answer the post-session prompts. A first run also stores the placement result
/// and the one-off first-session boost; a revisit changes no progress.
@MainActor
public enum OnboardingFinish {
    @discardableResult
    public static func complete(_ mode: OnboardingMode, scope: ScopeSelectionModel, placement: PlacementModel?,
                                versions: OnboardingVersionStore = OnboardingVersionStore(),
                                prompts: TodayPromptSlot = TodayPromptSlot(),
                                boosts: FirstSessionBoostStore = .shared, today: Date = Date()) -> Bool {
        guard scope.persist(completingOnboarding: true) else { return false }
        if mode == .firstRun {
            // Placement result (known level, opt-in seeding), then the boost with the failed-test cards first.
            let seeded = placement.flatMap { try? $0.apply(to: scope.store, today: today) } ?? []
            let failed = (placement?.failedCardIDs ?? []).filter { !seeded.contains($0) }
            boosts.save(FirstSessionBoost(day: today, priorityCardIDs: failed))
        }
        if var s = try? scope.store.loadSettings(), !s.variantPromptAnswered {
            s.variantPromptAnswered = true
            try? scope.store.saveSettings(s)
        }
        for prompt in [TodayModel.goalPrompt, TodayModel.wordsPrompt, TodayModel.variantPrompt] { prompts.dismiss(prompt.id) }
        versions.markCompleted()
        return true
    }
}
