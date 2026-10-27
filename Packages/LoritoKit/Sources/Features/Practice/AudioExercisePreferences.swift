import Foundation
import Domain

/// Device-local listening / speaking preferences (microphone and voice are per
/// device): Settings toggles plus the 15-minute session skips.
@MainActor
public final class AudioExercisePreferences {
    public static let shared = AudioExercisePreferences()

    static let listeningKey = "exercises.listening.enabled"
    static let speakingKey = "exercises.speaking.enabled"
    private let defaults: UserDefaults
    /// Session-scoped skips (not persisted).
    public var listeningSkippedUntil: Date?
    public var speakingSkippedUntil: Date?

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var listeningEnabled: Bool {
        get { defaults.object(forKey: Self.listeningKey) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Self.listeningKey) }
    }

    public var speakingEnabled: Bool {
        get { defaults.object(forKey: Self.speakingKey) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Self.speakingKey) }
    }

    public func policy(hasSpanishVoice: Bool) -> AudioExercisePolicy {
        AudioExercisePolicy(listeningEnabled: listeningEnabled, speakingEnabled: speakingEnabled,
                            hasSpanishVoice: hasSpanishVoice, listeningSkippedUntil: listeningSkippedUntil,
                            speakingSkippedUntil: speakingSkippedUntil)
    }
}
