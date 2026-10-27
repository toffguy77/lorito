import SwiftUI
import Domain
import DesignSystem

/// The Today screen: summary of the day's queue, a start action, and distinct
/// empty / all-done states. Presents the study session modally.
public struct TodayView: View {
    @State private var model: TodayModel
    @State private var session: StudySessionModel?
    @State private var trapCard: Card?
    private let catalog: ContentCatalog
    private let store: UserDataStore
    private let onSessionComplete: () -> Void

    public init(
        store: UserDataStore,
        catalog: ContentCatalog,
        onSessionComplete: @escaping () -> Void = {}
    ) {
        self.store = store
        self.catalog = catalog
        self.onSessionComplete = onSessionComplete
        _model = State(initialValue: TodayModel(store: store, catalog: catalog))
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LoritoSpacing.md) {
                header

                if model.hasWork {
                    activeState
                } else if model.isAllDone {
                    message(mark: "¡", markColor: LoritoColor.accent,
                            title: "Всё на сегодня!", subtitle: "Вы прошли все карточки дня.")
                } else {
                    message(mark: "¿", markColor: LoritoColor.textSecondary,
                            title: "Пока нечего изучать", subtitle: "Загляните позже — карточки появятся, когда придёт срок.")
                }

                WeekStrip(days: model.week)

                if let trap = model.trap, let card = catalog.card(id: trap.cardID) {
                    trapCard(trap, card: card)
                }
            }
            .padding(.horizontal, LoritoSpacing.screenGutter)
            .padding(.top, LoritoSpacing.lg)
            .padding(.bottom, LoritoSpacing.xl)
            .frame(maxWidth: LoritoLayout.readingWidth)
            .frame(maxWidth: .infinity)
        }
        .background(LoritoColor.surface.ignoresSafeArea())
        .onAppear { model.refresh() }
        .focusModeCover(item: $session, onDismiss: {
            model.refresh()
            onSessionComplete()
        }) { session in
            StudySessionView(model: session) { self.session = nil }
        }
        .sheet(item: $trapCard, onDismiss: { model.refresh() }) { card in
            NavigationStack {
                CardReaderView(model: CatalogModel(store: store, catalog: catalog), card: card)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Готово") { trapCard = nil }
                        }
                    }
            }
        }
    }

    /// "Ловушка дня": one common mistake from a card in scope; opens the card.
    private func trapCard(_ trap: TrapCandidate, card: Card) -> some View {
        Button { trapCard = card } label: {
            VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
                HStack {
                    Text("Ловушка дня")
                        .loritoStyle(.label)
                        .foregroundStyle(LoritoColor.dangerText)
                    Spacer()
                    Text("из \(trap.cardID)")
                        .font(LoritoFont.caption)
                        .foregroundStyle(LoritoColor.textSecondary)
                }
                CardBodyView(trap.text)
                    .lineLimit(4)
                    .allowsHitTesting(false)
                HStack(spacing: LoritoSpacing.xxs) {
                    Text("Открыть карточку")
                    Image(systemName: "chevron.right").accessibilityHidden(true)
                }
                .font(LoritoFont.bodyStrong)
                .foregroundStyle(LoritoColor.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, LoritoSpacing.screenGutter)
            .padding(.vertical, LoritoSpacing.md + 2)
            .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.lg, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: LoritoRadius.lg, style: .continuous).strokeBorder(LoritoColor.separator))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Открывает карточку \(card.title)")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "ru_RU"))).capitalizedFirst)
                .font(LoritoFont.caption)
                .foregroundStyle(LoritoColor.textSecondary)
            Text("¡Hola!")
                .loritoStyle(.display)
                .foregroundStyle(LoritoColor.textPrimary)
                .loritoTitleFit(lines: 1)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var activeState: some View {
        PlanHeroCard(
            total: model.remaining.count,
            caption: model.summary,
            parts: [
                .init(count: model.dueRemaining, label: "повторить", tone: .highlight),
                .init(count: model.newRemaining, label: "новых", tone: .accent),
            ],
            showsCounts: false
        ) {
            DayProgressBar(completed: model.studiedCount, total: max(model.totalCount, 1), tone: .ink)
            Button("Начать") {
                session = StudySessionModel(store: store, catalog: catalog, queue: model.sessionQueue())
            }
            .buttonStyle(PrimaryButtonStyle(.highlight))
            .disabled(!model.hasWork)
        }
    }

    private func message(mark: String, markColor: Color, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
            Text(mark)
                .loritoStyle(.display)
                .foregroundStyle(markColor)
                .accessibilityHidden(true)
            Text(title)
                .loritoStyle(.heading)
                .foregroundStyle(LoritoColor.textPrimary)
            Text(subtitle)
                .font(LoritoFont.body)
                .foregroundStyle(LoritoColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LoritoSpacing.lg)
        .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.lg, style: .continuous))
    }
}

private extension String {
    /// "понедельник, 26 октября" → "Понедельник, 26 октября".
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}

// Allow presenting the session via `.sheet(item:)`.
extension StudySessionModel: @MainActor Identifiable {
    public var id: ObjectIdentifier { ObjectIdentifier(self) }
}

/// The last seven days: filled accent circles for studied days, a dashed ring
/// for today until it is studied.
private struct WeekStrip: View {
    let days: [TodayModel.WeekDay]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(days, id: \.day) { day in
                VStack(spacing: 6) {
                    marker(day)
                    Text(day.label)
                        .font(day.isToday ? LoritoFont.bodyStrong : LoritoFont.caption)
                        .foregroundStyle(day.isToday ? LoritoColor.textPrimary : LoritoColor.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(day.isToday ? "Сегодня, \(day.label)" : day.label)
                .accessibilityValue(day.studied ? "занимались" : "не занимались")
                .accessibilityIdentifier(day.isToday ? "weekStrip.today" : "weekStrip.day")
            }
        }
        .padding(.vertical, LoritoSpacing.xs)
    }

    @ViewBuilder
    private func marker(_ day: TodayModel.WeekDay) -> some View {
        if day.studied {
            Circle().fill(LoritoColor.accent)
                .frame(width: 34, height: 34)
                .overlay {
                    if day.isToday {
                        Circle().strokeBorder(LoritoColor.textPrimary, lineWidth: 2).padding(-4)
                    }
                }
        } else if day.isToday {
            Circle().strokeBorder(LoritoColor.textPrimary, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                .frame(width: 34, height: 34)
        } else {
            Circle().fill(LoritoColor.surfaceSunken).frame(width: 34, height: 34)
        }
    }
}
