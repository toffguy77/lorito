import Foundation

/// The single Spanish-variant setting (owned by spanish-audio; regional-variants
/// extends this enum rather than adding another setting).
public enum SpanishVariant: String, Codable, Sendable, CaseIterable {
    case spain
    case latinAmerica

    /// Locale of the speech voice.
    public var localeIdentifier: String {
        switch self {
        case .spain: return "es-ES"
        case .latinAmerica: return "es-MX"
        }
    }

    public var title: String {
        switch self {
        case .spain: return "Испания"
        case .latinAmerica: return "Латинская Америка"
        }
    }
}

/// Speech speed.
public enum SpeechRate: String, Codable, Sendable, CaseIterable {
    case normal
    case slow

    /// Multiplier of the system default speech rate.
    public var multiplier: Double {
        switch self {
        case .normal: return 1
        case .slow: return 0.8
        }
    }

    public var title: String {
        switch self {
        case .normal: return "Обычно"
        case .slow: return "Медленно"
        }
    }
}

/// Which text is spoken. Italic isn't a reliable Spanish marker, so a span is
/// speakable only with at least one Latin letter (incl. á é í ó ú ü ñ). Pure.
public enum SpeakableText {
    public static func isSpeakable(_ text: String) -> Bool {
        text.unicodeScalars.contains { s in
            (0x41...0x5A).contains(s.value) || (0x61...0x7A).contains(s.value)
                || ((0xC0...0x24F).contains(s.value) && s.properties.isAlphabetic)
        }
    }

    /// Text to speak: Markdown markers (emphasis, bold, code, link syntax)
    /// removed; ¿ and ¡ kept; whitespace collapsed.
    public static func extract(_ markdown: String) -> String {
        var s = markdown
        // [label](url) → label
        s = s.replacingOccurrences(of: #"\[([^\]]*)\]\([^)]*\)"#, with: "$1", options: .regularExpression)
        s = s.replacingOccurrences(of: #"[*_`]"#, with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Speakable single-asterisk emphasis spans of a Markdown block, in order,
    /// without duplicates (the Spanish marker in card content).
    public static func spans(inMarkdown markdown: String) -> [String] {
        let pattern = #"(?<![*\w])\*(?![\s*])([^*\n]+?)(?<![\s*])\*(?![*\w])"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = markdown as NSString
        var seen = Set<String>(), out: [String] = []
        for m in regex.matches(in: markdown, range: NSRange(location: 0, length: ns.length)) {
            let text = extract(ns.substring(with: m.range(at: 1)))
            if isSpeakable(text), seen.insert(text).inserted { out.append(text) }
        }
        return out
    }
}

/// Where audio is played.
public enum PlaybackContext: Sendable {
    /// Taps on Spanish text and speaker buttons.
    case content
    /// Listening exercises: meaningless when silent.
    case listeningExercise
    /// Listening exercises, slow replay (listening-and-pronunciation).
    case listeningSlow

    /// Extra rate factor on top of the user's speech rate.
    public var rateFactor: Double { self == .listeningSlow ? 0.7 : 1 }
}

/// Audio-session category to use (mapped to AVAudioSession in Features).
public enum AudioSessionCategory: Sendable, Equatable {
    /// Silenced by the Ring/Silent switch; mixes with other audio.
    case ambient
    /// Plays in silent mode; ducks other audio.
    case playbackDuckingOthers
    /// Plays in silent mode.
    case playback
}

public enum AudioSessionPolicy {
    public static func category(for context: PlaybackContext, playWhenSilent: Bool) -> AudioSessionCategory {
        switch context {
        case .content: return playWhenSilent ? .playbackDuckingOthers : .ambient
        case .listeningExercise, .listeningSlow: return .playback
        }
    }
}
