import SwiftUI
import Domain

extension CalloutKind {
    var titleColor: Color {
        switch self {
        case .essence: return LoritoColor.highlight
        case .keyPoints: return LoritoColor.onAccentSoft
        case .mistakes: return LoritoColor.dangerText
        case .useful: return LoritoColor.textSecondary
        }
    }

    var background: Color {
        isOnInk ? LoritoColor.ink : LoritoColor.surfaceSunken
    }

    var textColor: Color {
        isOnInk ? LoritoColor.onInk : LoritoColor.textPrimary
    }
}

/// A titled callout block used for Суть / Ключевые моменты / Ошибки / Полезно
/// sections of a card. Суть renders on ink; the others on `surfaceSunken`.
public struct CalloutBlock<Content: View>: View {
    private let kind: CalloutKind
    private let content: Content

    public init(_ kind: CalloutKind, @ViewBuilder content: () -> Content) {
        self.kind = kind
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
            Text(kind.title)
                .loritoStyle(.label)
                .foregroundStyle(kind.titleColor)
            content
                .font(LoritoFont.body)
                .foregroundStyle(kind.textColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, LoritoSpacing.md)
        .padding(.vertical, LoritoSpacing.sm + 2)
        .background(kind.background, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
    }
}

/// Convenience for a plain-text callout.
public extension CalloutBlock where Content == Text {
    init(_ kind: CalloutKind, _ text: String) {
        self.init(kind) { Text(text) }
    }
}

#Preview {
    VStack(spacing: LoritoSpacing.sm) {
        CalloutBlock(.essence, "Ser выражает идентичность, происхождение и неизменные свойства.")
        CalloutBlock(.mistakes, "Не путать ser и estar для временных состояний.")
    }
    .padding()
    .background(LoritoColor.surface)
}
