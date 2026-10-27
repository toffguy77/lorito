import SwiftUI
import Domain
import DesignSystem

/// Sample Spanish phrase and Russian blurb shown for each level in onboarding.
extension CEFRLevel {
    var samplePhrase: String {
        switch self {
        case .a1: return "Me llamo Ana."
        case .a2: return "Ayer fui al mercado."
        case .b1: return "Espero que vengas."
        case .b2: return "Si lo hubiera sabido…"
        case .c1: return "No es que no quiera…"
        case .c2: return "A buen entendedor…"
        }
    }

    var blurb: String {
        switch self {
        case .a1: return "Знакомство, базовые фразы"
        case .a2: return "Прошедшие времена, быт"
        case .b1: return "Subjuntivo, мнения"
        case .b2: return "Гипотезы, сложный синтаксис"
        case .c1: return "Нюансы наклонений, регистр"
        case .c2: return "Фразеология, стиль, риторика"
        }
    }
}

/// An onboarding level row: the level code, a Spanish sample phrase and a
/// blurb. The target level is an ink row; lower levels show as included.
struct LevelRow: View {
    enum State { case target, included, off }

    let level: CEFRLevel
    let state: State
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LoritoSpacing.sm) {
                Text(level.rawValue)
                    .loritoStyle(LoritoTextStyle.heading.sized(state == .target ? 24 : 20))
                    .foregroundStyle(codeColor)
                    .frame(width: 52, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    SpanishText(level.samplePhrase, size: .custom(state == .target ? 24 : 21), color: phraseColor, interactive: false)
                    Text(state == .target ? "\(level.blurb) · цель" : level.blurb)
                        .font(LoritoFont.caption)
                        .foregroundStyle(state == .target ? LoritoColor.onInkSecondary : LoritoColor.textSecondary)
                }
                Spacer(minLength: 0)
                marker
            }
            .padding(.horizontal, LoritoSpacing.md - 2)
            .padding(.vertical, state == .target ? LoritoSpacing.md : LoritoSpacing.sm - 1)
            .frame(maxWidth: .infinity, minHeight: LoritoLayout.minTouchTarget)
            .background(background, in: RoundedRectangle(cornerRadius: state == .target ? LoritoRadius.md + 4 : LoritoRadius.md, style: .continuous))
            .overlay {
                if state == .off {
                    RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous)
                        .strokeBorder(LoritoColor.separator)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(level.rawValue)
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(state == .target ? .isSelected : [])
    }

    private var accessibilityValue: String {
        switch state {
        case .target: return "цель, \(level.blurb)"
        case .included: return "включён, \(level.blurb)"
        case .off: return level.blurb
        }
    }

    private var codeColor: Color {
        switch state {
        case .target: return LoritoColor.highlight
        case .included: return LoritoColor.accent
        case .off: return LoritoColor.textPrimary
        }
    }

    private var phraseColor: Color {
        state == .target ? LoritoColor.onInk : LoritoColor.textPrimary
    }

    private var background: Color {
        switch state {
        case .target: return LoritoColor.ink
        case .included: return LoritoColor.accentSoft
        case .off: return LoritoColor.surfaceRaised
        }
    }

    @ViewBuilder
    private var marker: some View {
        switch state {
        case .target:
            Circle().fill(LoritoColor.highlight).frame(width: 22, height: 22)
        case .included:
            Image(systemName: "checkmark")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(LoritoColor.accent)
                .frame(width: 22, height: 22)
        case .off:
            Circle().strokeBorder(LoritoColor.separator, lineWidth: 2).frame(width: 20, height: 20)
        }
    }
}
