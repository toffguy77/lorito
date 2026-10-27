import SwiftUI
import Domain
import DesignSystem

/// "¡Olé!" — the end of a study session: cards studied, share remembered on
/// the first grade, the streak (with a record badge) and themes to revisit.
/// Drawn on Lima with light-appearance surfaces in both themes, like focus mode.
struct SessionSummaryView: View {
    let summary: SessionSummary
    let revisitThemes: [String]
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            content
            PrimaryButton("Готово", variant: .ink, action: onClose)
                .frame(maxWidth: LoritoLayout.readingWidth)
                .padding(.horizontal, LoritoSpacing.screenGutter)
                .padding(.vertical, LoritoSpacing.md)
        }
        .background(alignment: .topTrailing) {
            Text("¡")
                .loritoStyle(LoritoTextStyle.display.sized(360))
                .dynamicTypeSize(.large)
                .foregroundStyle(LoritoColor.onHighlight.opacity(0.06))
                .offset(x: 40, y: 20)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
        }
        .background(LoritoColor.highlight.ignoresSafeArea())
        .environment(\.colorScheme, .light)
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LoritoSpacing.md) {
                VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
                    Text("День закрыт")
                        .font(LoritoFont.bodyStrong)
                    Text("¡Olé!")
                        .loritoStyle(LoritoTextStyle.display.sized(76))
                        .loritoTitleFit(lines: 1)
                        .accessibilityAddTraits(.isHeader)
                }
                .foregroundStyle(LoritoColor.onHighlight)

                streakTile

                HStack(spacing: LoritoSpacing.xs) {
                    tile("\(summary.studied)", RussianPlural.form(summary.studied, one: "карточка", few: "карточки", many: "карточек"))
                    tile("\(summary.firstTryPercent)%", "с первого раза")
                }

                if !revisitThemes.isEmpty {
                    VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
                        Text("Вернёмся к темам")
                            .loritoStyle(.label)
                            .foregroundStyle(LoritoColor.dangerText)
                        ForEach(revisitThemes, id: \.self) { theme in
                            Text(theme)
                                .font(LoritoFont.bodyStrong)
                                .foregroundStyle(LoritoColor.textPrimary)
                        }
                    }
                    .padding(LoritoSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md + 6, style: .continuous))
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.horizontal, LoritoSpacing.screenGutter)
            .padding(.top, LoritoSpacing.xl)
            .frame(maxWidth: LoritoLayout.readingWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private var streakTile: some View {
        HStack(spacing: LoritoSpacing.md) {
            Text("\(summary.currentStreak)")
                .loritoStyle(LoritoTextStyle.number.sized(72))
                .foregroundStyle(LoritoColor.highlight)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            VStack(alignment: .leading, spacing: LoritoSpacing.xxs) {
                Text(RussianPlural.form(summary.currentStreak, one: "день", few: "дня", many: "дней") + " подряд")
                    .font(LoritoFont.bodyStrong)
                    .foregroundStyle(LoritoColor.onInk)
                Text(summary.isNewRecord ? "Новый рекорд!" : "Лучшая серия: \(summary.bestStreak)")
                    .font(LoritoFont.caption)
                    .foregroundStyle(summary.isNewRecord ? LoritoColor.highlight : LoritoColor.onInkSecondary)
            }
        }
        .padding(LoritoSpacing.lg - 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LoritoColor.ink, in: RoundedRectangle(cornerRadius: LoritoRadius.xl - 4, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func tile(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .loritoStyle(LoritoTextStyle.heading.sized(26))
                .foregroundStyle(LoritoColor.textPrimary)
            Text(label)
                .font(LoritoFont.caption)
                .foregroundStyle(LoritoColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LoritoSpacing.md - 2)
        .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md + 2, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
