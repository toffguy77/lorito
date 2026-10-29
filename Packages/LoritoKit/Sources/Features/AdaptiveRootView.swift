import SwiftUI
import UserNotifications
import Domain
import DesignSystem
import WidgetSupport

/// The app's main flow after onboarding. Switches layout by horizontal size
/// class — compact: the iPhone tree with the floating bottom bar; regular: the
/// iPad tree (sidebar-adaptable tabs) — while `AppNavigation`, owned here
/// above the switch, keeps the destination, catalog selection and an open
/// study session across rotation, Split View and Stage Manager resizes.
/// Also owns the reminder service: reschedule triggers (launch, foreground /
/// day rollover, session end) and the reminder deep link to Today.
public struct AdaptiveRootView: View {
    private let store: UserDataStore
    /// The bundle as loaded; screens get it resolved for the learner's variant.
    private let baseCatalog: ContentCatalog
    /// regional-variants: exercises with the variant's overrides, `only` applied.
    @State private var variantCatalog: ContentCatalog?
    private var catalog: ContentCatalog { variantCatalog ?? baseCatalog }
    private let scopeModel: ScopeSelectionModel
    private let reminders: ReminderService

    @State private var navigation = AppNavigation()
    @State private var router = RemindersRouter()
    @State private var notificationDelegate: ReminderNotificationDelegate?
    @State private var path: [LevelPathProgress] = []
    @State private var liveActivity = SessionActivityController()
    @State private var audioSettings: AudioSettingsModel
    @State private var retentionSettings: RetentionSettingsModel
    @State private var goalSettings: GoalSettingsModel
    @State private var conjugationSettings: ConjugationSettingsModel
    /// Lorito Pro entitlements (resolved at launch and on every transaction update).
    @State private var purchases = PurchaseService()
    /// Words (vocabulary-decks): «В мои слова» and the personal deck.
    @State private var vocabulary: VocabularyModel
    /// Grammar Lens rules (nil without lens.json) and the open lens.
    private let lensCatalog = LensModel.bundledCatalog()
    @State private var lens: LensModel?
    /// Study buddy (CloudKit share; unavailable without iCloud sync).
    @State private var buddy: BuddyModel
    @Environment(\.speechService) private var speech
    @SceneStorage("lorito.catalogSelection") private var storedCatalogSelection = ""
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.scenePhase) private var scenePhase

    /// Open the study session right away (first launch after onboarding only).
    @State private var autoStartFirstSession: Bool

    public init(store: UserDataStore, catalog: ContentCatalog, scopeModel: ScopeSelectionModel,
                autoStartFirstSession: Bool = false, syncEnabled: Bool = false) {
        _autoStartFirstSession = State(initialValue: autoStartFirstSession)
        self.store = store
        self.baseCatalog = catalog
        _variantCatalog = State(initialValue: catalog.resolved(for: ((try? store.loadSettings()) ?? .default).spanishVariant))
        self.scopeModel = scopeModel
        self.reminders = ReminderService(scheduler: SystemNotificationScheduler(), store: store, catalog: catalog)
        _audioSettings = State(initialValue: AudioSettingsModel(store: store))
        _retentionSettings = State(initialValue: RetentionSettingsModel(store: store))
        _goalSettings = State(initialValue: GoalSettingsModel(store: store, catalog: catalog))
        _conjugationSettings = State(initialValue: ConjugationSettingsModel(store: store))
        _vocabulary = State(initialValue: VocabularyModel(store: store, catalog: catalog))
        _buddy = State(initialValue: BuddyModel(backend: syncEnabled ? CloudKitBuddyBackend() : nil, store: store,
                                                syncEnabled: syncEnabled))
    }

    private static let tabs: [FloatingTabItem<AppNavigation.Destination>] =
        AppNavigation.Destination.allCases.map { FloatingTabItem(id: $0, title: $0.title, systemImage: $0.systemImage) }

    public var body: some View {
        Group {
            if sizeClass == .regular {
                regularLayout
            } else {
                compactLayout
            }
        }
        .tint(LoritoColor.accent)
        .focusModeCover(item: sessionBinding, onDismiss: {
            refreshPath()
            publishWidgets()
            afterStudy()
            Task { await reminders.reschedule() }
        }) { session in
            StudySessionView(model: session, onClose: { navigation.endSession() },
                             onOpenTraps: { navigation.showTraps = true; navigation.endSession() })
        }
        .task {
            // Route tapped reminders to Today, then reschedule on launch.
            let delegate = ReminderNotificationDelegate(router: router)
            notificationDelegate = delegate
            UNUserNotificationCenter.current().delegate = delegate
            navigation.restoreCatalogSelection(storedCatalogSelection, in: catalog)
            startFirstSessionIfNeeded()
            if Monetization.salesEnabled { Task { await purchases.start() } }
            refreshPath()
            publishWidgets()
            AnalyticsService.shared.checkStreakOnLaunch(currentStreak())
            await AnalyticsService.shared.flush()
            await reminders.reschedule()
        }
        .onChange(of: scenePhase) { _, phase in
            // Foreground / day-rollover trigger.
            if phase == .active {
                Task {
                    await ForegroundRefresh.run(
                        publishWidgets: publishWidgets,
                        flushAnalytics: { await AnalyticsService.shared.flush() },
                        rescheduleReminders: { await reminders.reschedule() })
                    await buddy.refresh()
                }
            }
        }
        // Live Activity follows the open study session.
        .onChange(of: navigation.session.map(ObjectIdentifier.init)) { _, id in
            if id != nil, let session = navigation.session {
                liveActivity.start(total: session.totalCount)
            } else {
                liveActivity.end()
            }
        }
        .onChange(of: navigation.session?.index) { _, index in
            guard let session = navigation.session, let index else { return }
            liveActivity.update(position: index, total: session.totalCount)
            if session.isComplete { liveActivity.end() }
        }
        // Widgets deep-link to Today.
        .onOpenURL { url in
            if LoritoDeepLink.isToday(url) { navigation.openToday() }
            if let text = LoritoDeepLink.lensText(url) { openLens(.share, text) }
        }
        .environment(\.practiceSessionDidEnd, {
            publishWidgets()
            afterStudy()
        })
        .onChange(of: router.openToday) { _, open in
            if open {   // reminder deep link
                AnalyticsService.shared.record(.reminderOpened)
                navigation.openToday()
                router.consume()
            }
        }
        .onChange(of: navigation.catalogSelectionStorage) { _, stored in
            storedCatalogSelection = stored
        }
        .onChange(of: navigation.destination) { _, _ in refreshPath() }
        .onChange(of: audioSettings.variant) { _, variant in variantCatalog = baseCatalog.resolved(for: variant) }
        .modifier(LensPresenter(store: store, catalog: catalog, lens: $lens,
                                open: lensCatalog == nil ? nil : { openLens($0, $1) },
                                onDismiss: { navigation.notePlanChanged(); refreshPath() }))
        .onChange(of: navigation.sessionEndCount) { _, _ in Task { await buddy.refresh() } }
        .onReceive(NotificationCenter.default.publisher(for: BuddyModel.shareAccepted)) { _ in
            Task { await buddy.refresh() }
        }
        // Last, so presented sessions inherit them too.
        .environment(buddy)
        .environment(\.spanishVariant, audioSettings.variant)
        .environment(\.spanishVariantDidChange, { audioSettings.reload() })
        .environment(purchases)
        .modifier(SaveWordAction(enabled: catalog.vocabulary != nil, vocabulary: vocabulary))
    }

    private func openLens(_ source: LensSource, _ text: String) {
        guard let lensCatalog else { return }
        let model = LensModel(store: store, catalog: catalog, lens: lensCatalog, source: source, text: text)
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { model.analyze() }
        lens = model
    }

    /// The first session after onboarding opens on its first card instead of
    /// Today; with an empty queue Today stays. Consumed once (not on relaunch).
    private func startFirstSessionIfNeeded() {
        guard autoStartFirstSession else { return }
        autoStartFirstSession = false
        let today = TodayModel(store: store, catalog: catalog)
        guard today.hasWork else { return }
        AnalyticsService.shared.record(.firstSessionStarted(newCards: today.newRemaining))
        AnalyticsService.shared.record(.sessionStarted(due: today.dueRemaining, new: today.newRemaining))
        navigation.startSession(StudySessionModel(store: store, catalog: catalog, queue: today.sessionQueue()))
    }

    private var sessionBinding: Binding<StudySessionModel?> {
        Binding(get: { navigation.session }, set: { if $0 == nil { navigation.endSession() } })
    }

    private var destinationBinding: Binding<AppNavigation.Destination> {
        Binding(get: { navigation.destination }, set: { navigation.destination = $0 })
    }

    @ViewBuilder
    private func screen(_ destination: AppNavigation.Destination) -> some View {
        switch destination {
        case .today:
            TodayView(store: store, catalog: catalog, navigation: navigation)
        case .catalog:
            CatalogView(store: store, catalog: catalog, navigation: navigation)
        case .progress:
            StatsView(store: store, catalog: catalog)
        case .settings:
            NavigationStack {
                SettingsView(model: scopeModel, reminders: reminders, audio: audioSettings,
                             retention: retentionSettings, goals: goalSettings, conjugation: conjugationSettings,
                             pro: Monetization.salesEnabled ? purchases : nil, vocabulary: catalog.vocabulary != nil ? vocabulary : nil,
                             hasSpanishVoice: speech != nil)
            }
        }
    }

    // MARK: Compact (iPhone, Slide Over, narrow Split View)

    private var compactLayout: some View {
        // `TabView` keeps per-tab state; its system chrome is hidden in favor
        // of the floating bar.
        TabView(selection: destinationBinding) {
            ForEach(AppNavigation.Destination.allCases, id: \.self) { destination in
                screen(destination)
                    .floatingTabBarInset()
                    .tag(destination)
            }
        }
        .overlay(alignment: .bottom) {
            FloatingTabBar(items: Self.tabs, selection: destinationBinding)
                .frame(maxWidth: LoritoLayout.readingWidth)
                .padding(.horizontal, LoritoSpacing.screenGutter)
                .padding(.bottom, LoritoSpacing.xs)
        }
    }

    // MARK: Regular (iPad full screen, wide Split View)

    @ViewBuilder
    private var regularLayout: some View {
        if #available(iOS 18, macOS 15, *) {
            // The system shows a top tab bar the user can expand into a sidebar
            // and picks the portrait/landscape default.
            TabView(selection: destinationBinding) {
                ForEach(AppNavigation.Destination.allCases, id: \.self) { destination in
                    Tab(destination.title, systemImage: destination.systemImage, value: destination) {
                        screen(destination)
                    }
                }
            }
            .tabViewStyle(.sidebarAdaptable)
            .tabViewSidebarBottomBar {
                LevelPathSummary(levels: path).padding(LoritoSpacing.md)
            }
        } else {
            legacyRegularLayout
        }
    }

    /// iPadOS 17: a sidebar in landscape, a top tab bar in portrait.
    private var legacyRegularLayout: some View {
        GeometryReader { proxy in
            if proxy.size.width > proxy.size.height {
                HStack(spacing: 0) {
                    Sidebar(items: Self.tabs, selection: destinationBinding, path: path)
                        .frame(width: LoritoLayout.sidebarWidth)
                    Divider()
                    screen(navigation.destination)
                }
            } else {
                screen(navigation.destination)
                    .safeAreaInset(edge: .top, spacing: 0) {
                        TopTabBar(items: Self.tabs, selection: destinationBinding)
                            .padding(.vertical, LoritoSpacing.xs)
                    }
            }
        }
    }

    /// After a study or exercise session: streak-extended event, then flush.
    private func afterStudy() {
        AnalyticsService.shared.noteStreak(currentStreak())
        Task { await AnalyticsService.shared.flush() }
    }

    private func currentStreak() -> Int {
        StatsCalculator.compute(events: (try? store.allEvents()) ?? [], today: Date()).currentStreak
    }

    private func publishWidgets() {
        WidgetSnapshotPublisher.publish(store: store, catalog: catalog)
    }

    private func refreshPath() {
        path = PathProgress.levels(store: store, catalog: catalog)
    }
}

/// "Мой путь": share of started cards per included level.
enum PathProgress {
    @MainActor
    static func levels(store: UserDataStore, catalog: ContentCatalog) -> [LevelPathProgress] {
        let settings = (try? store.loadSettings()) ?? .default
        guard let target = settings.targetLevel else { return [] }
        let started = Set(((try? store.allReviews()) ?? []).filter { $0.status != .new }.map(\.cardID))
        return SelectionScope.includedLevels(for: target).map { level in
            let cards = catalog.cards(in: level)
            let done = cards.filter { started.contains($0.id) }.count
            return LevelPathProgress(level: level.rawValue, fraction: cards.isEmpty ? 0 : Double(done) / Double(cards.count))
        }
    }
}

private extension View {
    /// Hide the system tab bar and reserve room for the floating one so content
    /// scrolls clear of it.
    func floatingTabBarInset() -> some View {
        systemTabBarHidden()
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: LoritoLayout.tabBarHeight + LoritoSpacing.xs)
            }
    }
}

extension EnvironmentValues {
    /// Called when an exercise (practice) session closes — a widget refresh trigger.
    @Entry var practiceSessionDidEnd: @MainActor () -> Void = {}
}

/// «В мои слова» in the Spanish-span menu (vocabulary-decks): a bundled word is
/// saved at once; an unknown one opens the translation sheet where it was pressed.
private struct SaveWordAction: ViewModifier {
    let enabled: Bool
    let vocabulary: VocabularyModel

    func body(content: Content) -> some View {
        if enabled {
            content.spanishSpanAction(SpanishSpanAction(
                id: "save-word", title: "В мои слова", systemImage: "text.badge.plus",
                sheet: { text, dismiss in
                    guard case .unknown(let t) = vocabulary.save(text) else { return nil }
                    return AnyView(UnknownWordSheet(text: t, onSave: { ru in
                        vocabulary.saveUnknown(t, ru: ru)
                        dismiss()
                    }, onCancel: dismiss))
                },
                perform: { _ in }))
        } else {
            content
        }
    }
}

/// Grammar Lens sheet and the `openLens` action for everything below.
private struct LensPresenter: ViewModifier {
    let store: UserDataStore
    let catalog: ContentCatalog
    @Binding var lens: LensModel?
    let open: (@MainActor (LensSource, String) -> Void)?
    /// A requested card changes today's plan.
    let onDismiss: @MainActor () -> Void

    func body(content: Content) -> some View {
        content
            .sheet(item: $lens, onDismiss: onDismiss) { model in
                NavigationStack {
                    LensView(model: model, catalogModel: CatalogModel(store: store, catalog: catalog))
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Готово") { lens = nil } } }
                }
            }
            .environment(\.openLens, open)
    }
}
