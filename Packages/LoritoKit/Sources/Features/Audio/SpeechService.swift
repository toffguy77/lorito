import Foundation
import Observation
import AVFoundation
import Domain

/// Speaks Spanish text on device. One utterance at a time: starting another
/// stops the previous; speaking the same text again stops it.
@MainActor
public protocol SpeechService: AnyObject {
    /// A Spanish voice is installed (otherwise speak affordances are hidden).
    var hasSpanishVoice: Bool { get }
    /// The text being spoken, if any.
    var speakingText: String? { get }
    /// True once, the first time content speech is triggered on this device.
    var showsSilenceHint: Bool { get set }
    func speak(_ text: String, context: PlaybackContext)
    func stop()
}

/// `AVSpeechSynthesizer` with the variant's best installed voice (fallback: any
/// `es-*`), the chosen rate, and the audio-session category from
/// `AudioSessionPolicy`, set just before playback.
@MainActor
@Observable
public final class SystemSpeechService: NSObject, SpeechService {
    public private(set) var speakingText: String?
    public var showsSilenceHint = false

    @ObservationIgnored private let synthesizer = AVSpeechSynthesizer()
    @ObservationIgnored private let settings: () -> UserSettings
    @ObservationIgnored private let defaults: UserDefaults
    private static let hintKey = "audio.silenceHintShown"

    public init(settings: @escaping () -> UserSettings, defaults: UserDefaults = .standard) {
        self.settings = settings
        self.defaults = defaults
        super.init()
        synthesizer.delegate = self
    }

    public var hasSpanishVoice: Bool { Self.voice(for: .spain) != nil }

    /// Highest-quality installed voice in the variant's first available language
    /// (Rioplatense: es-AR → es-MX → es-ES), else any Spanish voice.
    nonisolated static func voice(for variant: SpanishVariant) -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let language = variant.preferredVoiceLanguage(installed: Set(voices.map(\.language)))
        let exact = voices.filter { $0.language == language }
        if let best = exact.max(by: { $0.quality.rawValue < $1.quality.rawValue }) { return best }
        return voices.filter { $0.language.hasPrefix("es") }.max { $0.quality.rawValue < $1.quality.rawValue }
    }

    public func speak(_ raw: String, context: PlaybackContext) {
        let text = SpeakableText.extract(raw)
        guard SpeakableText.isSpeakable(text) else { return }
        if speakingText == text {                 // tap a speaking span → stop
            stop()
            return
        }
        synthesizer.stopSpeaking(at: .immediate)
        let s = settings()
        guard let voice = Self.voice(for: s.spanishVariant) else { return }
        configureSession(AudioSessionPolicy.category(for: context, playWhenSilent: s.playAudioWhenSilent))
        if context == .content, !defaults.bool(forKey: Self.hintKey) {
            defaults.set(true, forKey: Self.hintKey)
            showsSilenceHint = true
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * Float(s.speechRate.multiplier * context.rateFactor)
        speakingText = text
        synthesizer.speak(utterance)
    }

    public func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        speakingText = nil
    }

    private func configureSession(_ category: AudioSessionCategory) {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        switch category {
        case .ambient: try? session.setCategory(.ambient, mode: .spokenAudio, options: [.mixWithOthers])
        case .playbackDuckingOthers: try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        case .playback: try? session.setCategory(.playback, mode: .spokenAudio)
        }
        try? session.setActive(true)
        #endif
    }
}

extension SystemSpeechService: AVSpeechSynthesizerDelegate {
    nonisolated public func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish u: AVSpeechUtterance) {
        let spoken = u.speechString
        Task { @MainActor in if self.speakingText == spoken { self.speakingText = nil } }
    }

    nonisolated public func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel u: AVSpeechUtterance) {
        let spoken = u.speechString
        Task { @MainActor in if self.speakingText == spoken { self.speakingText = nil } }
    }
}
