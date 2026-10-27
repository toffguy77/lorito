import SwiftUI

/// Spanish-language text in the Spanish voice: Instrument Serif Italic in the
/// `accent` color, tagged `es-ES` so VoiceOver pronounces it in Spanish.
/// Never use for Russian — the family has no Cyrillic glyphs.
public struct SpanishText: View {
    public enum Size: Sendable {
        /// Large Spanish words/answers (`spanish`).
        case display
        /// Spanish inside running text (`spanishInline`).
        case inline
        /// A custom base size of the same face (still Dynamic Type–relative).
        case custom(CGFloat)
    }

    private let text: String
    private let size: Size
    private let color: Color
    private let interactive: Bool
    @Environment(\.spanishSpanActions) private var spanActions

    /// `interactive: false` inside buttons, where the button's action wins.
    public init(_ text: String, size: Size = .display, color: Color = LoritoColor.accent, interactive: Bool = true) {
        self.text = text
        self.size = size
        self.color = color
        self.interactive = interactive
    }

    /// The text tagged with its language (drives VoiceOver pronunciation).
    static func attributed(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        attributed.languageIdentifier = SpanishText.languageIdentifier
        return attributed
    }

    static let languageIdentifier = "es-ES"

    private var style: LoritoTextStyle {
        switch size {
        case .display: return .spanish
        case .inline: return .spanishInline
        case .custom(let points): return LoritoTextStyle.spanish.sized(points)
        }
    }

    public var body: some View {
        let label = Text(Self.attributed(text))
            .font(style.font)
            .foregroundStyle(color)
            .environment(\.locale, Locale(identifier: "es_ES"))
        if interactive {
            // Same gesture contract as card-body spans: tap = primary, long press = menu.
            label
                .onTapGesture { spanActions.performPrimary(text) }
                .spanishSpanMenu(spans: [text], actions: spanActions)
        } else {
            label
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        SpanishText("el problema")
        SpanishText("la mano", size: .inline)
    }
    .padding()
    .background(LoritoColor.surface)
}

/// Exercise content (options, tokens, answers) that is usually Spanish but can
/// be Russian: Spanish voice when the text has no Cyrillic, Onest otherwise.
public struct AnswerText: View {
    private let text: String
    private let spanishSize: CGFloat
    private let color: Color

    public init(_ text: String, spanishSize: CGFloat = LoritoTextStyle.spanishInline.size + 4, color: Color) {
        self.text = text
        self.spanishSize = spanishSize
        self.color = color
    }

    /// True when the text contains no Cyrillic letters (the Spanish face has none).
    public static func isSpanish(_ text: String) -> Bool {
        !text.unicodeScalars.contains { (0x0400...0x04FF).contains($0.value) }
    }

    public var body: some View {
        if Self.isSpanish(text) {
            SpanishText(text, size: .custom(spanishSize), color: color, interactive: false)
        } else {
            Text(text).font(LoritoFont.body).foregroundStyle(color)
        }
    }
}
