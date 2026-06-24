import SwiftUI
import DesignSystem

/// A tappable pill used to select a level or toggle a theme. Mirrors the
/// design-system `LevelChip` look but is interactive and reflects a selected
/// state. Uses semantic tokens only.
struct SelectableChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(LoritoFont.body.weight(.semibold))
                .foregroundStyle(isSelected ? LoritoColor.onAccent : LoritoColor.textSecondary)
                .padding(.horizontal, LoritoSpacing.md)
                .padding(.vertical, LoritoSpacing.xs)
                .frame(maxWidth: .infinity)
                .background(
                    isSelected ? LoritoColor.accent : LoritoColor.surfaceSecondary,
                    in: RoundedRectangle(cornerRadius: LoritoRadius.sm, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LoritoRadius.sm, style: .continuous)
                        .strokeBorder(isSelected ? Color.clear : LoritoColor.separator)
                )
        }
        .buttonStyle(.plain)
    }
}
