import SwiftUI

/// The primary pill action (56 pt), placed at the bottom in the thumb zone.
public struct PrimaryButtonStyle: ButtonStyle {
    public enum Variant: Sendable {
        /// Lima on ink — the main CTA in focus mode and hero cards.
        case highlight
        /// Ink with a Lima label — the main CTA on light page surfaces.
        case ink
        /// Outlined secondary action on page surfaces.
        case outline
        /// Outlined secondary action on ink.
        case outlineOnInk
    }

    private let variant: Variant
    @Environment(\.isEnabled) private var isEnabled

    public init(_ variant: Variant = .ink) {
        self.variant = variant
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(LoritoFont.bodyStrong)
            .multilineTextAlignment(.center)
            .foregroundStyle(foreground)
            .padding(.horizontal, LoritoSpacing.lg)
            .frame(maxWidth: .infinity, minHeight: LoritoLayout.primaryButtonHeight)
            .background(background, in: Capsule())
            .overlay {
                if let border {
                    Capsule().strokeBorder(border, lineWidth: 2)
                }
            }
            .contentShape(Capsule())
            .loritoHover()
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch variant {
        case .highlight: return LoritoColor.onHighlight
        case .ink: return LoritoColor.highlight
        case .outline: return LoritoColor.textPrimary
        case .outlineOnInk: return LoritoColor.onInk
        }
    }

    private var background: Color {
        switch variant {
        case .highlight: return LoritoColor.highlight
        case .ink: return LoritoColor.ink
        case .outline, .outlineOnInk: return .clear
        }
    }

    private var border: Color? {
        switch variant {
        case .highlight, .ink: return nil
        case .outline: return LoritoColor.textPrimary
        case .outlineOnInk: return LoritoColor.inkTrack
        }
    }
}

/// Convenience pill button with a text label.
public struct PrimaryButton: View {
    private let title: String
    private let variant: PrimaryButtonStyle.Variant
    private let action: () -> Void

    public init(_ title: String, variant: PrimaryButtonStyle.Variant = .ink, action: @escaping () -> Void) {
        self.title = title
        self.variant = variant
        self.action = action
    }

    public var body: some View {
        Button(title, action: action)
            .buttonStyle(PrimaryButtonStyle(variant))
    }
}

#Preview {
    VStack(spacing: LoritoSpacing.sm) {
        PrimaryButton("Начать", variant: .ink) {}
        PrimaryButton("Назад", variant: .outline) {}
        PrimaryButton("Выключено", variant: .ink) {}.disabled(true)
        PrimaryButton("Показать ответ", variant: .highlight) {}
            .padding()
            .background(LoritoColor.ink)
    }
    .padding()
    .background(LoritoColor.surface)
}
