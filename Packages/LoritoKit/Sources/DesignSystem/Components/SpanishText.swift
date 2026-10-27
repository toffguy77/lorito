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
    private let interaction: Interaction
    @Environment(\.spanishSpanActions) private var spanActions

    /// How the span takes part in the Spanish-text gesture contract.
    public enum Interaction: Sendable {
        /// Tap = primary action; long press = menu.
        case standalone
        /// Inside a button: no gesture of its own (it would swallow the button's
        /// tap) — the button's action calls the primary action; long press = menu.
        case inButton
        /// Not interactive (widgets, rendered images).
        case none
    }

    public init(_ text: String, size: Size = .display, color: Color = LoritoColor.accent,
                interaction: Interaction = .standalone) {
        self.text = text
        self.size = size
        self.color = color
        self.interaction = interaction
    }

    /// Back-compat shorthand: `interactive: false` → `.none`.
    public init(_ text: String, size: Size = .display, color: Color = LoritoColor.accent, interactive: Bool) {
        self.init(text, size: size, color: color, interaction: interactive ? .standalone : .none)
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
        switch interaction {
        case .standalone:
            // Same gesture contract as card-body spans: tap = primary, long press = menu.
            label
                .onTapGesture { spanActions.performPrimary(text) }
                .spanishSpanMenu(spans: [text], actions: spanActions)
        case .inButton:
            label.spanishSpanMenu(spans: [text], actions: spanActions)
        case .none:
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

    private let interaction: SpanishText.Interaction

    public init(_ text: String, spanishSize: CGFloat = LoritoTextStyle.spanishInline.size + 4, color: Color,
                interaction: SpanishText.Interaction = .inButton) {
        self.text = text
        self.spanishSize = spanishSize
        self.color = color
        self.interaction = interaction
    }

    /// True when the text contains no Cyrillic letters (the Spanish face has none).
    public static func isSpanish(_ text: String) -> Bool {
        !text.unicodeScalars.contains { (0x0400...0x04FF).contains($0.value) }
    }

    public var body: some View {
        if Self.isSpanish(text) {
            SpanishText(text, size: .custom(spanishSize), color: color, interaction: interaction)
        } else {
            Text(text).font(LoritoFont.body).foregroundStyle(color)
        }
    }
}
