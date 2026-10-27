import SwiftUI
import Domain
import DesignSystem

/// The study session, in focus mode on ink: close button, segmented progress,
/// the current card in the study-card container (chip, title, Markdown body),
/// and the four SM-2 grade buttons. Grading advances; the last grade leads to a
/// completion state.
struct StudySessionView: View {
    @State var model: StudySessionModel
    let onClose: () -> Void

    var body: some View {
        Group {
            if let card = model.currentCard {
                sessionContent(card)
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
                .frame(maxWidth: LoritoLayout.readingWidth)
                .frame(maxWidth: .infinity)
            }

            GradeButtons { grade in model.grade(grade) }
                .frame(maxWidth: LoritoLayout.readingWidth)
                .padding(.horizontal, LoritoSpacing.screenGutter)
                .padding(.bottom, LoritoSpacing.md)
        }
    }
}
