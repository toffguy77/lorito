import SwiftUI
import Domain
import DesignSystem

/// The Today screen: summary of the day's queue, a start action, distinct
/// empty / all-done states, the week strip and the trap of the day. Starting a
/// session hands it to `AppNavigation`, which presents it above every layout.
/// At regular width it is a two-column dashboard.
public struct TodayView: View {
    @State private var model: TodayModel
    @State private var trapCard: Card?
    @State private var goalModel: GoalSettingsModel?
    private let catalog: ContentCatalog
    private let store: UserDataStore
    private let navigation: AppNavigation
    @Environment(\.horizontalSizeClass) private var sizeClass

    public init(store: UserDataStore, catalog: ContentCatalog, navigation: AppNavigation) {
        self.store = store
        self.catalog = catalog
        self.navigation = navigation
        _model = State(initialValue: TodayModel(store: store, catalog: catalog))
    }

    public var body: some View {
        ScrollView {
            Group {
                if sizeClass == .regular {
                    regularLayout
                } else {
                    compactLayout
                }
            }
            .padding(.horizontal, LoritoSpacing.screenGutter)
            .padding(.top, LoritoSpacing.lg)
            .padding(.bottom, LoritoSpacing.xl)
        }
        .background(LoritoColor.surface.ignoresSafeArea())
        .onAppear { model.refresh() }
        // Return starts the session while "Начать" is shown and enabled.
        .hardwareKeyCommands(model.hasWork && navigation.session == nil
                             ? [HardwareKeyCommand(.return, title: "Начать", action: startSession)] : [])
        .onChange(of: navigation.sessionEndCount) { _, _ in model.refresh() }
        .sheet(item: $goalModel, onDismiss: { model.refresh() }) { goals in
            NavigationStack {
                GoalSettingsView(model: goals)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Готово") { goalModel = nil }
                        }
                    }
            }
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

    private func startSession() {
        guard model.hasWork else { return }
        AnalyticsService.shared.record(.sessionStarted(due: model.dueRemaining, new: model.newRemaining))
        navigation.startSession(StudySessionModel(store: store, catalog: catalog, queue: model.sessionQueue()))
    }

    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.md) {
            header
            planOrState
            WeekStrip(days: model.week)
            goalCard
            promptCard
            trap
        }
        .frame(maxWidth: LoritoLayout.readingWidth)
        .frame(maxWidth: .infinity)
    }

    /// Two columns: plan hero and start on the leading side; week strip, trap
    /// of the day and long-term memory on the trailing side.
    private var regularLayout: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.lg) {
            header
            HStack(alignment: .top, spacing: LoritoSpacing.lg) {
                planOrState
                    .frame(maxWidth: .infinity, alignment: .top)
                VStack(spacing: LoritoSpacing.md) {
                    WeekStrip(days: model.week)
                        .padding(.horizontal, LoritoSpacing.md)
                        .padding(.vertical, LoritoSpacing.sm)
                        .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.lg, style: .continuous))
                    goalCard
                    promptCard
                    trap
                    memorySummary
                }
                .frame(maxWidth: 420)
            }
        }
        .frame(maxWidth: 1100)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var planOrState: some View {
        if model.hasWork {
            activeState
        } else if model.isAllDone {
            message(mark: "¡", markColor: LoritoColor.accent,
                    title: "Всё на сегодня!", subtitle: "Вы прошли все карточки дня.")
        } else {
            message(mark: "¿", markColor: LoritoColor.textSecondary,
                    title: "Пока нечего изучать", subtitle: "Загляните позже — карточки появятся, когда придёт срок.")
        }
    }

    /// Today's prompt slot (at most one prompt per visit).
    @ViewBuilder
    private var promptCard: some View {
        if let prompt = model.prompt {
            VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
                Text(prompt.title)
                    .font(LoritoFont.bodyStrong)
                    .foregroundStyle(LoritoColor.textPrimary)
                Text(prompt.message)
                    .font(LoritoFont.body)
                    .foregroundStyle(LoritoColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Button(prompt.actionTitle) { onPromptAction(prompt) }
                        .buttonStyle(PrimaryButtonStyle(.ink))
                        .fixedSize()
                    Button("Не сейчас") { model.dismissPrompt() }
                        .font(LoritoFont.bodyStrong)
                        .foregroundStyle(LoritoColor.textSecondary)
                        .frame(minHeight: LoritoLayout.minTouchTarget)
                }
            }
            .padding(LoritoSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("today.prompt")
        }
    }

    /// Prompt actions are handled by the change that registers the prompt.
    private func onPromptAction(_ prompt: TodayPrompt) {
        model.dismissPrompt()
        if prompt.id == TodayModel.goalPrompt.id {
            goalModel = GoalSettingsModel(store: store, catalog: catalog)
        }
    }

    /// Level goal / exam countdown (study-goal).
    @ViewBuilder
    private var goalCard: some View {
        if !model.goalLines.isEmpty {
            VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
                ForEach(model.goalLines) { line in
                    HStack(alignment: .top, spacing: LoritoSpacing.sm) {
                        Image(systemName: line.isEndState ? "checkmark.seal" : "flag")
                            .foregroundStyle(LoritoColor.accent)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(line.title)
                                .font(LoritoFont.bodyStrong)
                                .foregroundStyle(LoritoColor.textPrimary)
                            Text(line.detail)
                                .font(LoritoFont.caption)
                                .foregroundStyle(LoritoColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("today.goal.\(line.id.prefix(while: { $0 != ":" }))")
                }
            }
            .padding(LoritoSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
        }
    }

    @ViewBuilder
    private var trap: some View {
        if let trap = model.trap, let card = catalog.card(id: trap.cardID) {
            trapCard(trap, card: card)
        }
    }

    private var memorySummary: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
            Text("В долгой памяти")
                .loritoStyle(.label)
                .foregroundStyle(LoritoColor.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: LoritoSpacing.xs) {
                Text("\(model.memory.longTerm)")
                    .loritoStyle(LoritoTextStyle.title.sized(30))
                    .foregroundStyle(LoritoColor.textPrimary)
                Text("из \(model.memory.total) \(RussianPlural.form(model.memory.total, one: "карточки", few: "карточек", many: "карточек"))")
                    .font(LoritoFont.body)
                    .foregroundStyle(LoritoColor.textSecondary)
            }
            Text("Интервал повторения от \(StatsConstants.longTermIntervalDays) дня")
                .font(LoritoFont.caption)
                .foregroundStyle(LoritoColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LoritoSpacing.md + 2)
        .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.lg, style: .continuous))
        .accessibilityElement(children: .combine)
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
        .loritoHover()
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
            Button("Начать", action: startSession)
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
