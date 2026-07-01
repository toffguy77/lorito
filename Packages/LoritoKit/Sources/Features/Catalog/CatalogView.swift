import SwiftUI
import Domain
import DesignSystem

/// Catalog browsing: levels → themes → cards, each card row showing its status,
/// drilling into a reader that reuses the shared Markdown rendering and can
/// suspend / unsuspend the card.
public struct CatalogView: View {
    @State private var model: CatalogModel

    public init(store: UserDataStore, catalog: ContentCatalog) {
        _model = State(initialValue: CatalogModel(store: store, catalog: catalog))
    }

    public var body: some View {
        NavigationStack {
            List(model.levels) { level in
                Section(level.rawValue) {
                    ForEach(model.themes(in: level)) { theme in
                        NavigationLink(theme.title) {
                            themeCards(theme)
                        }
                    }
                }
            }
            .navigationTitle("Каталог")
            .onAppear { model.refresh() }
        }
    }

    private func themeCards(_ theme: Theme) -> some View {
        List(model.cards(in: theme)) { card in
            NavigationLink {
                CardReaderView(model: model, card: card)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: LoritoSpacing.xxs) {
                        Text(card.id)
                            .font(LoritoFont.caption)
                            .foregroundStyle(LoritoColor.textTertiary)
                        Text(card.title)
                            .font(LoritoFont.body)
                            .foregroundStyle(LoritoColor.textPrimary)
                    }
                    Spacer()
                    StatusBadge(status: model.status(for: card.id))
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(theme.title)
        .onAppear { model.refresh() }
    }
}

/// A small status pill for a catalog card row.
private struct StatusBadge: View {
    let status: CatalogCardStatus

    var body: some View {
        Text(status.title)
            .font(LoritoFont.label)
            .foregroundStyle(color)
            .padding(.horizontal, LoritoSpacing.xs)
            .padding(.vertical, LoritoSpacing.xxs)
            .background(color.opacity(0.12), in: Capsule())
    }

    private var color: Color {
        switch status {
        case .new: return LoritoColor.textTertiary
        case .learning: return LoritoColor.info
        case .review: return LoritoColor.accent
        case .due: return LoritoColor.success
        case .suspended: return LoritoColor.warning
        }
    }
}

/// The card reader: chip, title, shared Markdown rendering, and a suspend toggle.
private struct CardReaderView: View {
    let model: CatalogModel
    let card: Card
    @State private var practiceSession: ExerciseSessionModel?

    private var exerciseCount: Int { model.exercises(forCard: card.id).count }

    var body: some View {
        ScrollView {
            StudyCardContainer {
                LevelChip(level: card.level.rawValue, theme: card.themeID)
                Text(card.title)
                    .font(LoritoFont.title)
                    .foregroundStyle(LoritoColor.textPrimary)
                CardContentView(card.body)

                if exerciseCount > 0 {
                    Button {
                        practiceSession = model.makeExerciseSession(forCard: card.id)
                    } label: {
                        Text("Практика · \(exerciseCount)")
                            .font(LoritoFont.body.weight(.semibold))
                            .foregroundStyle(LoritoColor.onAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, LoritoSpacing.sm)
                            .background(LoritoColor.accent, in: RoundedRectangle(cornerRadius: LoritoRadius.md))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, LoritoSpacing.sm)
                }

                Button {
                    model.toggleSuspended(card.id)
                } label: {
                    Text(model.isSuspended(card.id) ? "Вернуть в изучение" : "Отложить карточку")
                        .font(LoritoFont.body.weight(.semibold))
                        .foregroundStyle(model.isSuspended(card.id) ? LoritoColor.onAccent : LoritoColor.warning)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, LoritoSpacing.sm)
                        .background(
                            (model.isSuspended(card.id) ? LoritoColor.accent : LoritoColor.warningSoft),
                            in: RoundedRectangle(cornerRadius: LoritoRadius.md)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, LoritoSpacing.sm)
            }
            .padding(LoritoSpacing.md)
            .frame(maxWidth: LoritoLayout.readingWidth)
            .frame(maxWidth: .infinity)
        }
        .background(LoritoColor.surfaceSecondary.ignoresSafeArea())
        .navigationTitle(card.id)
        .sheet(item: $practiceSession) { session in
            ExerciseSessionView(model: session) {
                practiceSession = nil
                model.refresh()
            }
        }
    }
}
