import SwiftUI

/// A keyboard key label, e.g. "1", "Пробел", "esc".
public struct KeyCap: View {
    public enum Tone: Sendable { case surface, ink }

    private let key: String
    private let tone: Tone

    public init(_ key: String, tone: Tone = .ink) {
        self.key = key
        self.tone = tone
    }

    public var body: some View {
        Text(key)
            .font(LoritoFont.caption)
            .monospacedDigit()
            .foregroundStyle(tone == .ink ? LoritoColor.onInk : LoritoColor.textPrimary)
            .padding(.horizontal, 7)
            .frame(minWidth: 24, minHeight: 22)
            .background(tone == .ink ? LoritoColor.inkTrack : LoritoColor.surfaceSunken,
                        in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// "Клавиатура" panel listing shortcuts (action → key).
public struct KeyboardHintsPanel: View {
    public struct Hint: Identifiable, Sendable {
        public let id: String
        public let title: String
        public let key: String

        public init(_ title: String, key: String) {
            self.id = title
            self.title = title
            self.key = key
        }
    }

    private let hints: [Hint]

    public init(hints: [Hint]) {
        self.hints = hints
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
            Text("Клавиатура")
                .loritoStyle(.label)
                .foregroundStyle(LoritoColor.onInkSecondary)
            ForEach(hints) { hint in
                HStack {
                    Text(hint.title)
                        .font(LoritoFont.caption)
                        .foregroundStyle(LoritoColor.onInk)
                    Spacer()
                    KeyCap(hint.key)
                }
            }
        }
        .padding(LoritoSpacing.md)
        .background(LoritoColor.inkRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Сочетания клавиш: " + hints.map { "\($0.title) — \($0.key)" }.joined(separator: ", "))
    }
}

public extension View {
    /// System pointer hover effect on iPadOS; no-op elsewhere.
    @ViewBuilder
    func loritoHover() -> some View {
        #if os(iOS)
        hoverEffect(.highlight)
        #else
        self
        #endif
    }
}
