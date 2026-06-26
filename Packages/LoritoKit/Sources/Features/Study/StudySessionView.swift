import SwiftUI
import Domain
import DesignSystem

/// The study session: renders the current card in the study-card container with
/// its chip, title, and Markdown body, and the four SM-2 grade buttons. Grading
/// advances; the last grade leads to a completion state.
struct StudySessionView: View {
    @State var model: StudySessionModel
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if let card = model.currentCard {
                    sessionContent(card)
                } else {
                    completionState
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LoritoColor.surfaceSecondary.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Закрыть", action: onClose)
                        .foregroundStyle(LoritoColor.textSecondary)
                }
            }
        }
    }

    private func sessionContent(_ card: Card) -> some View {
        VStack(spacing: LoritoSpacing.md) {
            Text(model.positionText)
                .font(LoritoFont.caption)
                .foregroundStyle(LoritoColor.textTertiary)
                .padding(.top, LoritoSpacing.xs)
            ScrollView {
                StudyCardContainer {
                    LevelChip(level: card.level.rawValue, theme: card.themeID)
                    Text(card.title)
                        .font(LoritoFont.title)
                        .foregroundStyle(LoritoColor.textPrimary)
                    CardContentView(card.body)
                }
                .padding(LoritoSpacing.md)
                .frame(maxWidth: LoritoLayout.readingWidth)
                .frame(maxWidth: .infinity)
            }
            GradeButtons { grade in model.grade(grade) }
                .frame(maxWidth: LoritoLayout.readingWidth)
                .padding(.horizontal, LoritoSpacing.md)
                .padding(.bottom, LoritoSpacing.md)
        }
    }

    private var completionState: some View {
        VStack(spacing: LoritoSpacing.sm) {
            Text("🎉").font(.system(size: 52))
            Text("Готово!")
                .font(LoritoFont.title)
                .foregroundStyle(LoritoColor.textPrimary)
            Text("Все карточки на сегодня пройдены.")
                .font(LoritoFont.body)
                .foregroundStyle(LoritoColor.textSecondary)
            Button("На главную", action: onClose)
                .font(LoritoFont.body.weight(.semibold))
                .foregroundStyle(LoritoColor.onAccent)
                .padding(.horizontal, LoritoSpacing.lg)
                .padding(.vertical, LoritoSpacing.sm)
                .background(LoritoColor.accent, in: Capsule())
                .padding(.top, LoritoSpacing.sm)
        }
        .padding(LoritoSpacing.xl)
    }
}
