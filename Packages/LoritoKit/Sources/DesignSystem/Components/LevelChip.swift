import SwiftUI

/// A small pill showing a level and (optionally) a theme, e.g. "A1 · Verbos".
public struct LevelChip: View {
    public enum Tone: Sendable {
        /// Lima pill — the default on cards and page surfaces.
        case highlight
        /// Neutral pill for secondary metadata.
        case neutral
    }

    private let text: String
    private let tone: Tone

    public init(_ text: String, tone: Tone = .highlight) {
        self.text = text
        self.tone = tone
    }

    public init(level: String, theme: String? = nil, tone: Tone = .highlight) {
        if let theme, !theme.isEmpty {
            self.text = "\(level) · \(theme)"
        } else {
            self.text = level
        }
        self.tone = tone
    }

    public var body: some View {
        Text(text)
            .loritoStyle(.label)
            .foregroundStyle(tone == .highlight ? LoritoColor.onHighlight : LoritoColor.textSecondary)
            .padding(.horizontal, LoritoSpacing.sm)
            .padding(.vertical, LoritoSpacing.xxs + 2)
            .background(tone == .highlight ? LoritoColor.highlight : LoritoColor.surfaceSunken, in: Capsule())
    }
}

#Preview {
    HStack {
        LevelChip(level: "A1", theme: "Verbos")
        LevelChip("Повтор", tone: .neutral)
    }
    .padding()
    .background(LoritoColor.surface)
}
