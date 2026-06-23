import SwiftUI

/// The four callout kinds used in card bodies.
public enum CalloutKind: String, CaseIterable, Sendable {
    case essence      // Суть
    case keyPoints    // Ключевые моменты
    case mistakes     // Ошибки
    case useful       // Полезно

    public var title: String {
        switch self {
        case .essence: return "Суть"
        case .keyPoints: return "Ключевые моменты"
        case .mistakes: return "Частые ошибки"
        case .useful: return "Полезно"
        }
    }

    var accent: Color {
        switch self {
        case .essence: return LoritoColor.accent
        case .keyPoints: return LoritoColor.info
        case .mistakes: return LoritoColor.danger
        case .useful: return LoritoColor.warning
        }
    }

    var background: Color {
        switch self {
        case .essence: return LoritoColor.accentSoft
        case .keyPoints: return LoritoColor.infoSoft
        case .mistakes: return LoritoColor.dangerSoft
        case .useful: return LoritoColor.warningSoft
        }
    }
}

/// A titled callout block with a leading accent rule, used for Суть / Ключевые
/// моменты / Ошибки / Полезно sections of a card.
public struct CalloutBlock<Content: View>: View {
    private let kind: CalloutKind
    private let content: Content

    public init(_ kind: CalloutKind, @ViewBuilder content: () -> Content) {
        self.kind = kind
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
            Text(kind.title.uppercased())
                .font(LoritoFont.label)
                .tracking(0.6)
                .foregroundStyle(kind.accent)
            content
                .font(LoritoFont.body)
                .foregroundStyle(LoritoColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LoritoSpacing.sm)
        .background(kind.background, in: RoundedRectangle(cornerRadius: LoritoRadius.md))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(kind.accent)
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: LoritoRadius.md))
        }
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
