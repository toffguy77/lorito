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
    var onOpenTraps: () -> Void = {}
    @AccessibilityFocusState private var revealFocused: Bool
    @State private var openedRelated: Card?
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool { sizeClass == .regular }

    var body: some View {
        Group {
            if let card = model.currentCard {
                sessionContent(card)
            } else if let summary = model.summary {
                SessionSummaryView(summary: summary, revisitThemes: model.revisitThemeTitles,
                                   newTraps: model.newTrapsCount, onOpenTraps: onOpenTraps, onClose: onClose)
            } else {
                SessionCompleteView(subtitle: "Все карточки на сегодня пройдены.", onClose: onClose)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LoritoColor.ink.ignoresSafeArea())
        .speechSilenceHint()
        // Esc closes the session (the close button is always shown).
        .hardwareKeyCommands(openedRelated == nil ? [HardwareKeyCommand(.escape, title: "Выйти", action: onClose)] : [])
        .sheet(item: $openedRelated) { card in
            // Opens over the session; closing it returns to the same card.
            NavigationStack {
                CardReaderView(model: model.makeCatalogModel(), card: card)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Готово") { openedRelated = nil }
                        }
                    }
            }
        }
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
            .frame(maxWidth: model.isRevealed && isRegular ? .infinity : LoritoLayout.readingWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            actions
                .frame(maxWidth: model.isRevealed && isRegular ? 900 : LoritoLayout.readingWidth)
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
                HStack {
                    LevelChip(level: card.level.rawValue, theme: card.themeID)
                    Spacer()
                    SurfaceSpeakButton(spans: SpeakableText.spans(inMarkdown: model.recallPrompt))
                }
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

    @ViewBuilder
    private func back(_ card: Card) -> some View {
        if isRegular {
            regularBack(card)
        } else {
            ScrollView {
                StudyCardContainer {
                    cardHeader(card)
                    CardContentView(card.body)
                    if !model.visibleRelatedCards.isEmpty {
                        relatedList(tone: .surface)
                            .padding(.top, LoritoSpacing.sm)
                    }
                }
                .padding(.horizontal, LoritoSpacing.screenGutter)
            }
        }
    }

    @ViewBuilder
    private func cardHeader(_ card: Card) -> some View {
        HStack {
            LevelChip(level: card.level.rawValue, theme: card.themeID)
            Spacer()
            // The revealed card's main Spanish content: its first examples.
            SurfaceSpeakButton(spans: Array(SpeakableText.spans(inMarkdown: card.body).prefix(8)))
        }
        Text(card.title)
            .loritoStyle(.title)
            .foregroundStyle(LoritoColor.textPrimary)
            .loritoTitleFit()
    }

    /// Regular width: the body balanced over two columns next to a side panel
    /// with related cards and keyboard hints.
    private func regularBack(_ card: Card) -> some View {
        HStack(alignment: .top, spacing: LoritoSpacing.lg) {
            GeometryReader { proxy in
                ScrollView {
                    StudyCardContainer {
                        cardHeader(card)
                        CardContentView(card.body, twoColumnsAbove: max(proxy.size.height - 220, 200))
                    }
                }
            }
            VStack(spacing: LoritoSpacing.md) {
                if !model.visibleRelatedCards.isEmpty {
                    relatedList(tone: .ink)
                        .padding(LoritoSpacing.md)
                        .background(LoritoColor.inkRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
                }
                KeyboardHintsPanel(hints: Self.keyboardHints)
                Spacer(minLength: 0)
            }
            .frame(width: LoritoLayout.sidePanelWidth)
        }
        .padding(.horizontal, LoritoSpacing.screenGutter)
    }

    static let keyboardHints: [KeyboardHintsPanel.Hint] = [
        .init("Показать ответ", key: "Пробел"),
        .init("Оценка", key: "1 – 4"),
        .init("Выйти", key: "esc"),
    ]

    private func relatedList(tone: CardBodyTone) -> some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
            Text("Связанные")
                .loritoStyle(.label)
                .foregroundStyle(tone == .ink ? LoritoColor.onInkSecondary : LoritoColor.textSecondary)
            ForEach(model.visibleRelatedCards) { related in
                Button { openedRelated = related } label: {
                    HStack {
                        Text(related.title)
                            .font(LoritoFont.bodyStrong)
                            .foregroundStyle(tone == .ink ? LoritoColor.onInk : LoritoColor.textPrimary)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: LoritoSpacing.xs)
                        Text(related.id)
                            .font(LoritoFont.caption)
                            .foregroundStyle(tone == .ink ? LoritoColor.onInkSecondary : LoritoColor.textSecondary)
                    }
                    .frame(minHeight: LoritoLayout.minTouchTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .loritoHover()
                .accessibilityLabel("\(related.title), \(related.id)")
                .accessibilityHint("Открывает связанную карточку")
            }
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
                GradeButtons(captions: model.captions, spokenCaptions: model.spokenCaptions,
                             showsKeyCaps: isRegular) { grade in
                    model.grade(grade)
                }
            }
        } else {
            PrimaryButton("Показать ответ", variant: .highlight) { model.reveal() }
                .keyboardShortcut(.space, modifiers: [])
                .accessibilityFocused($revealFocused)
        }
    }
}
