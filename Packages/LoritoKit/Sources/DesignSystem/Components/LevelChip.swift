import SwiftUI

/// A small pill showing a level and (optionally) a theme, e.g. "A1 · Verbos".
public struct LevelChip: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public init(level: String, theme: String? = nil) {
        if let theme, !theme.isEmpty {
            self.text = "\(level) · \(theme)"
        } else {
            self.text = level
        }
    }

    public var body: some View {
        Text(text.uppercased())
            .font(LoritoFont.label)
            .tracking(0.5)
            .foregroundStyle(LoritoColor.onAccentSoft)
            .padding(.horizontal, LoritoSpacing.sm)
            .padding(.vertical, LoritoSpacing.xxs + 1)
            .background(LoritoColor.accentSoft, in: Capsule())
    }
}

#Preview {
    HStack {
        LevelChip(level: "A1", theme: "Verbos")
        LevelChip(level: "B2")
    }
    .padding()
    .background(LoritoColor.surface)
}
