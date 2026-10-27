import SwiftUI
import DesignSystem

/// Focus-mode top bar shared by the study and exercise sessions: a round close
/// button, the session progress bar, and the "4/18" position.
struct SessionTopBar: View {
    let segments: [SessionSegment]
    let position: String
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: LoritoSpacing.sm) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(LoritoColor.onInk)
                    .frame(width: LoritoLayout.minTouchTarget, height: LoritoLayout.minTouchTarget)
                    .background(LoritoColor.inkRaised, in: Circle())
            }
            .buttonStyle(.plain)
            .loritoHover()
            .accessibilityLabel("Закрыть")

            SessionProgressBar(segments: segments)

            Text(position)
                .font(LoritoFont.caption)
                .monospacedDigit()
                .foregroundStyle(LoritoColor.onInkSecondary)
                .accessibilityHidden(true)
        }
    }
}

/// Completion state of a session on ink: a brand mark, a title and a way home.
struct SessionCompleteView: View {
    let subtitle: String
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
            Spacer()
            Text("¡")
                .loritoStyle(.number)
                .foregroundStyle(LoritoColor.highlight)
                .accessibilityHidden(true)
            Text("Готово!")
                .loritoStyle(.title)
                .foregroundStyle(LoritoColor.onInk)
                .loritoTitleFit(lines: 1)
            Text(subtitle)
                .font(LoritoFont.body)
                .foregroundStyle(LoritoColor.onInkSecondary)
            Spacer()
            PrimaryButton("На главную", variant: .highlight, action: onClose)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, LoritoSpacing.screenGutter)
        .padding(.bottom, LoritoSpacing.md)
    }
}
