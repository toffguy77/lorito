import SwiftUI
import Domain
import DesignSystem

/// Catalog browsing: level pills → the level's themes as a path with progress
/// per theme → cards, each card row showing its status, drilling into a reader
/// that reuses the shared Markdown rendering and can suspend / unsuspend the
/// card. At regular width: three columns (themes, cards, reader) whose
/// selection lives in `AppNavigation` so it survives rotation and resizes.
public struct CatalogView: View {
    @State private var model: CatalogModel
    private let catalog: ContentCatalog
    private let navigation: AppNavigation
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(PurchaseService.self) private var purchases: PurchaseService?
    @State private var exams: ExamsModel?

    public init(store: UserDataStore, catalog: ContentCatalog, navigation: AppNavigation) {
        _model = State(initialValue: CatalogModel(store: store, catalog: catalog))
        self.catalog = catalog
        self.navigation = navigation
    }

    private var level: CEFRLevel { navigation.catalogLevel ?? model.levels.first ?? .a1 }

    public var body: some View {
        Group {
            if sizeClass == .regular {
                regularLayout
            } else {
                compactLayout
            }
        }
        .onAppear { model.refresh() }
        .sheet(item: $exams) { exams in
            NavigationStack {
                ExamsView(model: exams)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Готово") { self.exams = nil } } }
            }
        }
    }

    /// «Экзамены DELE и CCSE» (exam-path-dele-ccse).
    @ViewBuilder
    private var examsRow: some View {
        if catalog.exams != nil {
            Button {
                exams = ExamsModel(store: model.store, catalog: catalog, purchases: purchases)
            } label: {
                HStack(spacing: LoritoSpacing.sm) {
                    Image(systemName: "graduationcap").foregroundStyle(LoritoColor.accent).accessibilityHidden(true)
                    Text("Экзамены DELE и CCSE").font(LoritoFont.bodyStrong).foregroundStyle(LoritoColor.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(LoritoColor.textSecondary).accessibilityHidden(true)
                }
                .padding(LoritoSpacing.md)
                .frame(minHeight: LoritoLayout.minTouchTarget)
                .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("catalog.exams")
        }
    }

    // MARK: Compact

    private var compactLayout: some View {
        NavigationStack {
            List {
                Group {
                    header
                    levelPills
                    examsRow
                    LensEntryButton(identifier: "catalog.lens")
                    ForEach(model.themes(in: level)) { theme in
                        themeRow(theme)
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: LoritoSpacing.xxs, leading: LoritoSpacing.screenGutter,
                                          bottom: LoritoSpacing.xxs, trailing: LoritoSpacing.screenGutter))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .frame(maxWidth: LoritoLayout.readingWidth)
            .frame(maxWidth: .infinity)
            .background(LoritoColor.surface.ignoresSafeArea())
            .navigationBarVisibility(.hidden)
            .navigationTitle("Каталог")
        }
    }

    // MARK: Regular — themes | cards | reader

    private var themeSelection: Binding<String?> {
        Binding(get: { navigation.catalogThemeID },
                set: { id in navigation.selectTheme(id.flatMap(catalog.theme(id:))) })
    }

    private var cardSelection: Binding<String?> {
        Binding(get: { navigation.catalogCardID },
                set: { id in
                    if let card = id.flatMap(catalog.card(id:)) { navigation.selectCard(card) } else { navigation.clearCard() }
                })
    }

    private var regularLayout: some View {
        NavigationSplitView {
            List(selection: themeSelection) {
                Group {
                    header
                    levelPills
                    examsRow
                    LensEntryButton(identifier: "catalog.lens")
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                ForEach(model.themes(in: level)) { theme in
                    let progress = model.progress(in: theme)
                    HStack {
                        Text(theme.title)
                            .font(LoritoFont.body)
                            .foregroundStyle(LoritoColor.textPrimary)
                        Spacer()
                        Text("\(progress.started)/\(progress.total)")
                            .font(LoritoFont.caption)
                            .monospacedDigit()
                            .foregroundStyle(LoritoColor.textSecondary)
                    }
                    .tag(theme.id)
                    .loritoHover()
                }
            }
            .scrollContentBackground(.hidden)
            .background(LoritoColor.surface)
            .navigationSplitViewColumnWidth(min: 280, ideal: 320)
        } content: {
            if let theme = navigation.catalogThemeID.flatMap(catalog.theme(id:)) {
                List(model.cards(in: theme), selection: cardSelection) { card in
                    cardRow(card)
                        .tag(card.id)
                        .loritoHover()
                }
                .scrollContentBackground(.hidden)
                .background(LoritoColor.surface)
                .navigationTitle(theme.title)
            } else {
                placeholder("Выберите тему")
            }
        } detail: {
            if let card = navigation.catalogCardID.flatMap(catalog.card(id:)) {
                CardReaderView(model: model, card: card)
                    .id(card.id)
            } else {
                placeholder("Выберите карточку")
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    private func placeholder(_ text: String) -> some View {
        VStack(spacing: LoritoSpacing.xs) {
            Text("¿")
                .loritoStyle(.display)
                .foregroundStyle(LoritoColor.textSecondary)
                .accessibilityHidden(true)
            Text(text)
                .font(LoritoFont.body)
                .foregroundStyle(LoritoColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LoritoColor.surface)
    }

    private func cardRow(_ card: Card) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: LoritoSpacing.xxs) {
                Text(card.id)
                    .font(LoritoFont.caption)
                    .foregroundStyle(LoritoColor.textSecondary)
                Text(card.title)
                    .font(LoritoFont.body)
                    .foregroundStyle(LoritoColor.textPrimary)
            }
            Spacer()
            StatusBadge(status: model.status(for: card.id))
        }
    }

    private var header: some View {
        let overall = model.overallProgress
        return HStack(alignment: .firstTextBaseline) {
            Text("Каталог")
                .loritoStyle(.title)
                .foregroundStyle(LoritoColor.textPrimary)
                .loritoTitleFit(lines: 1)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Text("\(overall.started) из \(overall.total)")
                .font(LoritoFont.caption)
                .foregroundStyle(LoritoColor.textSecondary)
        }
        .padding(.top, LoritoSpacing.lg)
    }

    private var levelPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(model.levels) { item in
                    let isSelected = item == level
                    Button { navigation.selectLevel(item) } label: {
                        Text(item.rawValue)
                            .font(LoritoTextStyle.heading.sized(13).font)
                            .foregroundStyle(isSelected ? LoritoColor.highlight : LoritoColor.textPrimary)
                            .padding(.horizontal, LoritoSpacing.md)
                            .frame(minWidth: LoritoLayout.minTouchTarget, minHeight: LoritoLayout.minTouchTarget)
                            .background(isSelected ? LoritoColor.ink : LoritoColor.surfaceRaised, in: Capsule())
                            .overlay(Capsule().strokeBorder(isSelected ? Color.clear : LoritoColor.separator))
                    }
                    .buttonStyle(.plain)
                    .loritoHover()
                    .accessibilityLabel("Уровень \(item.rawValue)")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
        .padding(.vertical, LoritoSpacing.xs)
    }

    private func themeRow(_ theme: Theme) -> some View {
        let progress = model.progress(in: theme)
        let isCurrent = model.currentTheme(in: level)?.id == theme.id
        let isDone = progress.total > 0 && progress.started == progress.total
        return ZStack {
            NavigationLink { themeCards(theme) } label: { EmptyView() }
                .opacity(0)
            HStack(alignment: .top, spacing: LoritoSpacing.sm) {
                pathMarker(isCurrent: isCurrent, isDone: isDone)
                VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(theme.title)
                            .font(isCurrent ? LoritoFont.bodyStrong : LoritoFont.body)
                            .foregroundStyle(isCurrent ? LoritoColor.onInk : LoritoColor.textPrimary)
                        Spacer(minLength: LoritoSpacing.xs)
                        Text("\(progress.started)/\(progress.total)")
                            .font(LoritoFont.caption)
                            .monospacedDigit()
                            .foregroundStyle(isCurrent ? LoritoColor.highlight
                                             : (isDone ? LoritoColor.accent : LoritoColor.textSecondary))
                    }
                    if isCurrent, progress.total > 0 {
                        ProgressView(value: Double(progress.started), total: Double(progress.total))
                            .tint(LoritoColor.highlight)
                            .background(LoritoColor.inkTrack, in: Capsule())
                            .accessibilityHidden(true)
                    }
                }
                .padding(.horizontal, LoritoSpacing.md)
                .padding(.vertical, LoritoSpacing.sm + 2)
                .background(isCurrent ? LoritoColor.ink : LoritoColor.surfaceRaised,
                            in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
            }
        }
    }

    /// The node on the vertical path: filled when done, Lima when current.
    private func pathMarker(isCurrent: Bool, isDone: Bool) -> some View {
        ZStack {
            if isDone {
                Circle().fill(LoritoColor.accent)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(LoritoColor.onAccent)
            } else if isCurrent {
                Circle().fill(LoritoColor.highlight)
            } else {
                Circle().strokeBorder(LoritoColor.separator, lineWidth: 3)
            }
        }
        .frame(width: 26, height: 26)
        .padding(.top, LoritoSpacing.sm)
        .accessibilityHidden(true)
    }

    private func themeCards(_ theme: Theme) -> some View {
        List(model.cards(in: theme)) { card in
            NavigationLink {
                CardReaderView(model: model, card: card)
            } label: {
                cardRow(card)
            }
            .listRowBackground(LoritoColor.surfaceRaised)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(LoritoColor.surface.ignoresSafeArea())
        .navigationTitle(theme.title)
        .navigationBarVisibility(.visible)
        .onAppear { model.refresh() }
    }
}

/// A small status pill for a catalog card row.
private struct StatusBadge: View {
    let status: CatalogCardStatus

    var body: some View {
        Text(status.title)
            .font(LoritoFont.caption)
            .foregroundStyle(foreground)
            .padding(.horizontal, LoritoSpacing.xs + 2)
            .padding(.vertical, LoritoSpacing.xxs)
            .background(background, in: Capsule())
    }

    private var foreground: Color {
        switch status {
        case .new: return LoritoColor.textSecondary
        case .learning: return LoritoColor.onAccentSoft
        case .review: return LoritoColor.onAccentSoft
        case .due: return LoritoColor.onHighlight
        case .suspended: return LoritoColor.dangerText
        }
    }

    private var background: Color {
        switch status {
        case .new: return LoritoColor.surfaceSunken
        case .learning, .review: return LoritoColor.accentSoft
        case .due: return LoritoColor.highlight
        case .suspended: return LoritoColor.dangerSoft
        }
    }
}

/// The card reader: chip, title, shared Markdown rendering, and a suspend toggle.
struct CardReaderView: View {
    let model: CatalogModel
    let card: Card
    @State private var practiceSession: ExerciseSessionModel?
    @State private var drill: ConjugationDrillModel?
    @Environment(\.speechService) private var speech
    @Environment(\.practiceSessionDidEnd) private var practiceSessionDidEnd

    private var exerciseCount: Int { model.exercises(forCard: card.id).count }

    var body: some View {
        ScrollView {
            StudyCardContainer {
                LevelChip(level: card.level.rawValue, theme: card.themeID)
                Text(card.title)
                    .loritoStyle(.title)
                    .foregroundStyle(LoritoColor.textPrimary)
                    .loritoTitleFit()
                CardContentView(card.body)

                if exerciseCount > 0 {
                    PrimaryButton("Практика · \(exerciseCount)", variant: .ink) {
                        practiceSession = model.makeExerciseSession(forCard: card.id,
                                                                    hasSpanishVoice: speech?.hasSpanishVoice ?? false)
                    }
                    .padding(.top, LoritoSpacing.sm)
                }

                if model.catalog.conjugation?.tenses.contains(where: { $0.card == card.id }) == true {
                    PrimaryButton("Тренировать спряжения", variant: .ink) {
                        drill = model.makeConjugationDrill(forCard: card.id)
                    }
                    .disabled(ConjugationToday.readerItems(tenseCard: card.id, store: model.store, catalog: model.catalog).isEmpty)
                    .accessibilityIdentifier("reader.conjugation")
                }

                PrimaryButton(model.isSuspended(card.id) ? "Вернуть в изучение" : "Отложить карточку",
                              variant: .outline) {
                    model.toggleSuspended(card.id)
                }
            }
            .padding(LoritoSpacing.md)
            .frame(maxWidth: LoritoLayout.readingWidth)
            .frame(maxWidth: .infinity)
        }
        .background(LoritoColor.surface.ignoresSafeArea())
        .speechSilenceHint()
        .navigationTitle(card.id)
        .focusModeCover(item: $practiceSession) { session in
            ExerciseSessionView(model: session) {
                practiceSession = nil
                model.refresh()
                practiceSessionDidEnd()
            }
        }
        .focusModeCover(item: $drill) { d in
            ConjugationDrillView(model: d, onOpenCard: { _ in drill = nil }) {
                drill = nil
                model.refresh()
                practiceSessionDidEnd()
            }
        }
    }
}
