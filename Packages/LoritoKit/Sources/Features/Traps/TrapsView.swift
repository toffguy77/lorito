import SwiftUI
import Domain
import DesignSystem

/// «Мои ловушки»: ranked in-scope traps with their first mistakes item and
/// failure count; opens the card reader; starts a traps session.
public struct TrapsView: View {
    @State var model: TrapsModel
    @State private var session: TrapsSessionModel?
    @State private var openedCard: Card?

    public init(model: TrapsModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LoritoSpacing.md) {
                if model.traps.isEmpty {
                    Text("Ловушек нет. Они появляются, когда вы отвечаете «Опять» на карточку с частыми ошибками.")
                        .font(LoritoFont.body)
                        .foregroundStyle(LoritoColor.textSecondary)
                } else {
                    PrimaryButton("Потренировать ловушки", variant: .ink) { session = model.makeSession() }
                        .accessibilityIdentifier("traps.start")
                    ForEach(model.visible) { trap in
                        Button { openedCard = model.card(trap) } label: { row(trap) }
                            .buttonStyle(.plain)
                    }
                    if model.hasMore {
                        Button("Показать все") { model.showAll = true }
                            .font(LoritoFont.bodyStrong)
                            .foregroundStyle(LoritoColor.accent)
                            .frame(minHeight: LoritoLayout.minTouchTarget)
                    }
                }
            }
            .padding(.horizontal, LoritoSpacing.screenGutter)
            .padding(.vertical, LoritoSpacing.lg)
            .frame(maxWidth: LoritoLayout.readingWidth)
            .frame(maxWidth: .infinity)
        }
        .background(LoritoColor.surface.ignoresSafeArea())
        .navigationTitle("Мои ловушки")
        .onAppear { model.refresh() }
        .focusModeCover(item: $session, onDismiss: { model.refresh() }) { s in
            TrapsSessionView(model: s) { session = nil }
        }
        .sheet(item: $openedCard) { card in
            NavigationStack {
                CardReaderView(model: CatalogModel(store: model.store, catalog: model.catalog), card: card)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) { Button("Готово") { openedCard = nil } }
                    }
            }
        }
    }

    private func row(_ trap: PersonalTrap) -> some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
            HStack {
                Text(model.card(trap)?.title ?? trap.cardID)
                    .font(LoritoFont.bodyStrong)
                    .foregroundStyle(LoritoColor.textPrimary)
                Spacer()
                Text("× \(trap.failures)")
                    .font(LoritoFont.caption)
                    .foregroundStyle(LoritoColor.dangerText)
                    .accessibilityLabel("ошибок: \(trap.failures)")
            }
            CardBodyView(trap.firstMistake)
        }
        .padding(LoritoSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
        .contentShape(Rectangle())
    }
}

/// The traps session in focus mode.
struct TrapsSessionView: View {
    @Bindable var model: TrapsSessionModel
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: LoritoSpacing.md) {
            if let trap = model.current {
                SessionTopBar(segments: SessionProgressBar.segments(current: model.index, total: model.traps.count),
                              position: model.positionText, onClose: onClose)
                    .padding(.horizontal, LoritoSpacing.screenGutter)
                    .padding(.top, LoritoSpacing.sm)
                ScrollView {
                    VStack(alignment: .leading, spacing: LoritoSpacing.md) {
                        Text(model.currentCard?.title ?? trap.cardID)
                            .loritoStyle(.label)
                            .foregroundStyle(LoritoColor.highlight)
                        CardContentView(model.isRevealed ? model.mistakesSection : trap.firstMistake, tone: .ink)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, LoritoSpacing.screenGutter)
                }
                Group {
                    if model.isRevealed {
                        HStack(spacing: LoritoSpacing.sm) {
                            Button("Ещё путаю") { model.answer(.stillConfused) }
                                .buttonStyle(PrimaryButtonStyle(.outline))
                            Button("Ясно") { model.answer(.clear) }
                                .buttonStyle(PrimaryButtonStyle(.highlight))
                        }
                    } else {
                        PrimaryButton("Показать раздел", variant: .highlight) { model.reveal() }
                    }
                }
                .frame(maxWidth: LoritoLayout.readingWidth)
                .padding(.horizontal, LoritoSpacing.screenGutter)
                .padding(.bottom, LoritoSpacing.md)
            } else {
                SessionCompleteView(subtitle: "Ловушки на сегодня разобраны.", onClose: onClose)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LoritoColor.ink.ignoresSafeArea())
    }
}
