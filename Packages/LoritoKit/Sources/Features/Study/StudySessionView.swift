import SwiftUI
import Domain
import DesignSystem

/// The study session, in focus mode on ink and recall first. Each card opens
/// on its front side — chip, title and recall prompt — and "Показать ответ"
/// reveals the body and the grade buttons with their interval preview. The
/// last grade leads to the session summary.
struct StudySessionView: View {
    @State var model: StudySessionModel
    let onClose: () -> Void
    @AccessibilityFocusState private var revealFocused: Bool

    var body: some View {
        Group {
            if let card = model.currentCard {
                sessionContent(card)
            } else if let summary = model.summary {
                SessionSummaryView(summary: summary, revisitThemes: model.revisitThemeTitles, onClose: onClose)
            } else {
                SessionCompleteView(subtitle: "Все карточки на сегодня пройдены.", onClose: onClose)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LoritoColor.ink.ignoresSafeArea())
    }

    private func sessionContent(_ card: Card) -> some View {
        VStack(spacing: LoritoSpacing.md) {
            SessionTopBar(segments: model.segments, position: model.positionText.replacingOccurrences(of: " ", with: ""), onClose: onClose)
                .padding(.horizontal, LoritoSpacing.screenGutter)
                .padding(.top, LoritoSpacing.sm)

            Group {
                if model.isRevealed {
                    back(card)
                } else {
                    front(card)
                }
            }
            .frame(maxWidth: LoritoLayout.readingWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            actions
                .frame(maxWidth: LoritoLayout.readingWidth)
                .padding(.horizontal, LoritoSpacing.screenGutter)
                .padding(.bottom, LoritoSpacing.md)
        }
        .animation(.easeOut(duration: 0.2), value: model.isRevealed)
        .onChange(of: model.index) { _, _ in if !model.isComplete { revealFocused = true } }
        .onAppear { revealFocused = true }
    }

    // MARK: Front

    private func front(_ card: Card) -> some View {
        ScrollView {
            StudyCardContainer {
                LevelChip(level: card.level.rawValue, theme: card.themeID)
                Text(card.title)
                    .font(LoritoFont.body)
                    .foregroundStyle(LoritoColor.textSecondary)
                RecallPromptView(model.recallPrompt)
                    .loritoTitleFit(lines: 8)
                if let hint = model.recallHint {
                    AnswerText(hint, spanishSize: LoritoTextStyle.spanishInline.size, color: LoritoColor.textSecondary)
                }
                recallTip
                    .padding(.top, LoritoSpacing.sm)
            }
            .background(alignment: .top) { cardStack }
            .padding(.top, LoritoSpacing.md)
            .padding(.horizontal, LoritoSpacing.screenGutter)
        }
    }

    /// The two card edges peeking above the current card.
    private var cardStack: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: LoritoRadius.xl, style: .continuous)
                .fill(LoritoColor.inkTrack.opacity(0.6))
                .padding(.horizontal, LoritoSpacing.lg)
                .offset(y: -LoritoSpacing.md)
            RoundedRectangle(cornerRadius: LoritoRadius.xl, style: .continuous)
                .fill(LoritoColor.inkTrack)
                .padding(.horizontal, LoritoSpacing.sm)
                .offset(y: -LoritoSpacing.xs)
        }
        .accessibilityHidden(true)
    }

    private var recallTip: some View {
        HStack(alignment: .top, spacing: LoritoSpacing.sm) {
            Image(systemName: "lightbulb")
                .foregroundStyle(LoritoColor.accent)
                .accessibilityHidden(true)
            Text("Сначала ответьте про себя, потом открывайте — так запоминается надёжнее, чем от перечитывания.")
                .font(LoritoFont.caption)
                .foregroundStyle(LoritoColor.textSecondary)
        }
        .padding(LoritoSpacing.md - 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LoritoColor.surfaceSunken, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
    }

    // MARK: Back

    private func back(_ card: Card) -> some View {
        ScrollView {
            StudyCardContainer {
                LevelChip(level: card.level.rawValue, theme: card.themeID)
                Text(card.title)
                    .loritoStyle(.title)
                    .foregroundStyle(LoritoColor.textPrimary)
                    .loritoTitleFit()
                CardContentView(card.body)
            }
            .padding(.horizontal, LoritoSpacing.screenGutter)
        }
    }

    // MARK: Actions (same thumb zone on both sides)

    @ViewBuilder
    private var actions: some View {
        if model.isRevealed {
            VStack(spacing: LoritoSpacing.sm) {
                Text("Насколько легко вспомнилось?")
                    .font(LoritoFont.caption)
                    .foregroundStyle(LoritoColor.onInkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                GradeButtons(captions: model.captions, spokenCaptions: model.spokenCaptions) { grade in
                    model.grade(grade)
                }
            }
        } else {
            PrimaryButton("Показать ответ", variant: .highlight) { model.reveal() }
                .accessibilityFocused($revealFocused)
        }
    }
}
