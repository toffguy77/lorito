import Foundation

/// Which listening / speaking exercises a practice session may contain
/// (listening-and-pronunciation): turned-off types never, skipped types not
/// within 15 minutes, listening types not without a Spanish voice.
public struct AudioExercisePolicy: Sendable, Equatable {
    public static let skipDuration: TimeInterval = 15 * 60

    public var listeningEnabled: Bool
    public var speakingEnabled: Bool
    public var hasSpanishVoice: Bool
    public var listeningSkippedUntil: Date?
    public var speakingSkippedUntil: Date?

    public init(listeningEnabled: Bool = true, speakingEnabled: Bool = true, hasSpanishVoice: Bool = true,
                listeningSkippedUntil: Date? = nil, speakingSkippedUntil: Date? = nil) {
        self.listeningEnabled = listeningEnabled
        self.speakingEnabled = speakingEnabled
        self.hasSpanishVoice = hasSpanishVoice
        self.listeningSkippedUntil = listeningSkippedUntil
        self.speakingSkippedUntil = speakingSkippedUntil
    }

    public static func isListening(_ kind: ExerciseKind) -> Bool {
        switch kind {
        case .listenChoose, .dictation: true
        default: false
        }
    }

    public static func isSpeaking(_ kind: ExerciseKind) -> Bool {
        if case .speak = kind { return true }
        return false
    }

    public func allows(_ exercise: Exercise, now: Date) -> Bool {
        if Self.isListening(exercise.kind) {
            return listeningEnabled && hasSpanishVoice && (listeningSkippedUntil.map { now >= $0 } ?? true)
        }
        if Self.isSpeaking(exercise.kind) {
            return speakingEnabled && (speakingSkippedUntil.map { now >= $0 } ?? true)
        }
        return true
    }

    public func filter(_ exercises: [Exercise], now: Date) -> [Exercise] {
        exercises.filter { allows($0, now: now) }
    }
}
