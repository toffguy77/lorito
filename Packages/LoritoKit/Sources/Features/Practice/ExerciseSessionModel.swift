import Foundation
import Observation
import Domain

/// Walks a queue of exercises one at a time. For auto-checkable types, submitting
/// checks the answer, records an attempt, and applies the resulting grade to
/// the card (via `ExercisePracticeService`), then shows feedback. `free-response`
/// is self-assessed: submitting reveals the reference and the user grades it with
/// the four grade buttons. Practice always feeds the card's existing `ReviewState`.
@MainActor
@Observable
public final class ExerciseSessionModel: Identifiable {
    public let id = UUID()
    private let practice: ExercisePracticeService
    private var queue: [Exercise]
    private let analytics: AnalyticsRecording
    /// Speech recognition for `speak` (nil → self-assessed).
    let recognizer: SpeechRecognizing?
    private let preferences: AudioExercisePreferences
    private let now: () -> Date

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

    // speak (listening-and-pronunciation)
    /// Recognised transcript of the last attempt.
    public private(set) var transcript: String?
    /// Failed recognition attempts on the current `speak` exercise.
    public private(set) var speakAttempts = 0
    public private(set) var isRecording = false

    public static let maxSpeakAttempts = 2

    public init(store: UserDataStore, exercises: [Exercise], analytics: AnalyticsRecording? = nil,
                recognizer: SpeechRecognizing? = nil, hasSpanishVoice: Bool = true,
                preferences: AudioExercisePreferences = .shared, now: @escaping () -> Date = { Date() }) {
        self.practice = ExercisePracticeService(store: store)
        self.analytics = analytics ?? AnalyticsService.shared
        self.recognizer = recognizer
        self.preferences = preferences
        self.now = now
        // Turned-off, skipped and (without a voice) listening types are never shown.
        self.queue = preferences.policy(hasSpanishVoice: hasSpanishVoice).filter(exercises, now: now())
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
    public var isTextInput: Bool { isFillInTheBlank || isFreeResponse || isDictation }

    public var options: [String] {
        if case let .multipleChoice(options, _) = current?.kind { return options }
        if case let .listenChoose(_, options, _) = current?.kind { return options }
        return []
    }

    public var isListenChoose: Bool { if case .listenChoose = current?.kind { return true }; return false }
    public var isDictation: Bool { if case .dictation = current?.kind { return true }; return false }
    public var isSpeak: Bool { if case .speak = current?.kind { return true }; return false }
    /// Spoken text of a listening exercise (shown only after submission).
    public var audioText: String? { current?.kind.audioText }
    /// The phrase to say in a `speak` exercise.
    public var speakTarget: String {
        if case let .speak(answer, _) = current?.kind { return answer }
        return ""
    }

    /// `speak` runs automatically only with on-device recognition and permission.
    public var speakIsAuto: Bool { recognizer?.availability == .available }
    /// The explanation screen comes first when permissions haven't been asked.
    public var needsSpeechPermission: Bool { isSpeak && recognizer?.availability == .notDetermined }

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

    /// The reference answer revealed for a `free-response` (or self-assessed `speak`) exercise.
    public var referenceAnswer: String {
        if case let .freeResponse(answer, _) = current?.kind { return answer }
        if case let .speak(answer, _) = current?.kind { return answer }
        return ""
    }

    // MARK: Submission

    public var canSubmit: Bool {
        guard !isResolved, let current else { return false }
        switch current.kind {
        case .multipleChoice, .listenChoose: return selectedOption != nil
        case .fillInTheBlank, .freeResponse, .dictation: return !typedText.trimmingCharacters(in: .whitespaces).isEmpty
        case .speak: return !speakIsAuto      // self-assessed: reveal the reference
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
        if case .speak = current.kind {
            isRevealed = true                 // self-assessed speak: play the reference, then grade
            return
        }
        let answer: ExerciseAnswer
        switch current.kind {
        case .multipleChoice, .listenChoose:
            guard let chosen = selectedOption else { return }
            answer = .option(chosen)
        case .fillInTheBlank, .dictation:
            answer = .text(typedText)
        case .wordOrder:
            answer = .ordering(ordering)
        case .matching, .pictureMatching:
            answer = .matches(matches)
        case .freeResponse, .speak:
            return
        }
        lastCheck = try? practice.submit(current, answer: answer, today: now()).check
        if let lastCheck {
            analytics.record(.exerciseAnswered(type: ExerciseTypeName(current.kind), correct: lastCheck.isCorrect))
        }
    }

    /// Self-grade a revealed `free-response` or `speak` exercise, then advance.
    /// Speaking never lapses a card: a self-assessed Опять is an attempt only.
    public func selfGrade(_ grade: Grade) {
        guard isRevealed, let current else { return }
        switch current.kind {
        case .freeResponse:
            _ = try? practice.submitSelfGraded(current, grade: grade, today: now())
        case .speak:
            if grade == .again {
                try? practice.recordAttemptOnly(current, grade: .again, transcript: transcript, today: now())
            } else {
                _ = try? practice.submitSelfGraded(current, grade: grade, today: now())
            }
        default:
            return
        }
        analytics.record(.exerciseAnswered(type: ExerciseTypeName(current.kind), correct: grade != .again))
        advance()
    }

    /// Auto `speak`: record, compare transcripts; a match applies Хорошо. After
    /// two misses the attempt is recorded without touching the card and the
    /// reference is revealed for self-grading.
    public func recordSpeech() async {
        guard isSpeak, !isResolved, let current, let recognizer, recognizer.availability == .available else { return }
        isRecording = true
        let heard = (try? await recognizer.recognize(maxDuration: 8)) ?? []
        isRecording = false
        await submitTranscripts(heard, for: current)
    }

    func submitTranscripts(_ heard: [String], for exercise: Exercise) async {
        transcript = heard.first
        let check = try? ExerciseChecker.check(exercise, answer: .transcripts(heard))
        if check?.isCorrect == true {
            lastCheck = try? practice.submit(exercise, answer: .transcripts(heard), today: now()).check
            analytics.record(.exerciseAnswered(type: .speak, correct: true))
            return
        }
        speakAttempts += 1
        if speakAttempts >= Self.maxSpeakAttempts {
            try? practice.recordAttemptOnly(exercise, grade: .again, transcript: transcript, today: now())
            analytics.record(.exerciseAnswered(type: .speak, correct: false))
            isRevealed = true
        }
    }

    public func stopRecording() { recognizer?.stop() }

    /// After the explanation screen: ask for microphone + speech permission.
    public func requestSpeechPermission() async {
        _ = await recognizer?.requestPermissions()
    }

    // MARK: Skip (15 minutes, ungraded)

    /// «Не могу слушать сейчас»: no listening exercises for 15 minutes; none graded.
    public func skipListening() {
        preferences.listeningSkippedUntil = now().addingTimeInterval(AudioExercisePolicy.skipDuration)
        dropRemaining(where: { AudioExercisePolicy.isListening($0.kind) })
    }

    /// «Не могу говорить сейчас»
    public func skipSpeaking() {
        preferences.speakingSkippedUntil = now().addingTimeInterval(AudioExercisePolicy.skipDuration)
        dropRemaining(where: { AudioExercisePolicy.isSpeaking($0.kind) })
    }

    private func dropRemaining(where matches: (Exercise) -> Bool) {
        let head = Array(queue[..<min(index, queue.count)])
        let tail = queue[min(index, queue.count)...].filter { !matches($0) }
        queue = head + tail
        resetInput()
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
        resetInput()
    }

    private func resetInput() {
        lastCheck = nil
        isRevealed = false
        selectedOption = nil
        typedText = ""
        ordering = []
        matches = [:]
        transcript = nil
        speakAttempts = 0
    }
}
