import SwiftUI
import DesignSystem

/// A tappable row used to select a level or toggle a theme. Reflects a selected
/// state with the accent-soft fill and a check mark. Uses semantic tokens only.
struct SelectableChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LoritoSpacing.xs) {
                Text(title)
                    .font(LoritoFont.bodyStrong)
                    .foregroundStyle(isSelected ? LoritoColor.onAccentSoft : LoritoColor.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? LoritoColor.accent : LoritoColor.separator)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, LoritoSpacing.md)
            .frame(maxWidth: .infinity, minHeight: LoritoLayout.minTouchTarget + 4)
            .background(
                isSelected ? LoritoColor.accentSoft : LoritoColor.surfaceRaised,
                in: RoundedRectangle(cornerRadius: LoritoRadius.sm, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LoritoRadius.sm, style: .continuous)
                    .strokeBorder(isSelected ? Color.clear : LoritoColor.separator)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
