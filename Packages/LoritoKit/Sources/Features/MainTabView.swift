import SwiftUI
import UserNotifications
import Domain
import DesignSystem

/// The app's main flow after onboarding: Today, Catalog, and Settings tabs.
/// Owns the reminder service and routes reschedule triggers (launch, foreground
/// / day rollover, session completion) and the reminder deep link to Today.
public struct MainTabView: View {
    private let store: UserDataStore
    private let catalog: ContentCatalog
    private let scopeModel: ScopeSelectionModel
    private let reminders: ReminderService

    @State private var router = RemindersRouter()
    @State private var notificationDelegate: ReminderNotificationDelegate?
    @State private var selection = 0
    @Environment(\.scenePhase) private var scenePhase

    public init(store: UserDataStore, catalog: ContentCatalog, scopeModel: ScopeSelectionModel) {
        self.store = store
        self.catalog = catalog
        self.scopeModel = scopeModel
        self.reminders = ReminderService(scheduler: SystemNotificationScheduler(), store: store, catalog: catalog)
    }

    private static let tabs: [FloatingTabItem<Int>] = [
        FloatingTabItem(id: 0, title: "Сегодня", systemImage: "sun.max"),
        FloatingTabItem(id: 1, title: "Каталог", systemImage: "point.topleft.down.to.point.bottomright.curvepath"),
        FloatingTabItem(id: 2, title: "Прогресс", systemImage: "flame"),
        FloatingTabItem(id: 3, title: "Настройки", systemImage: "slider.horizontal.3"),
    ]

    public var body: some View {
        // `TabView` keeps per-tab state and the reminder deep link; its system
        // chrome is hidden in favor of the floating bar.
        TabView(selection: $selection) {
            TodayView(store: store, catalog: catalog, onSessionComplete: {
                Task { await reminders.reschedule() }
            })
            .floatingTabBarInset()
            .tag(0)

            CatalogView(store: store, catalog: catalog)
                .floatingTabBarInset()
                .tag(1)

            StatsView(store: store)
                .floatingTabBarInset()
                .tag(2)

            NavigationStack {
                SettingsView(model: scopeModel, reminders: reminders)
            }
            .floatingTabBarInset()
            .tag(3)
        }
        .tint(LoritoColor.accent)
        .overlay(alignment: .bottom) {
            FloatingTabBar(items: Self.tabs, selection: $selection)
                .frame(maxWidth: LoritoLayout.readingWidth)
                .padding(.horizontal, LoritoSpacing.screenGutter)
                .padding(.bottom, LoritoSpacing.xs)
        }
        .task {
            // Route tapped reminders to Today, then reschedule on launch.
            let delegate = ReminderNotificationDelegate(router: router)
            notificationDelegate = delegate
            UNUserNotificationCenter.current().delegate = delegate
            await reminders.reschedule()
        }
        .onChange(of: scenePhase) { _, phase in
            // Foreground / day-rollover trigger.
            if phase == .active { Task { await reminders.reschedule() } }
        }
        .onChange(of: router.openToday) { _, open in
            if open { selection = 0; router.consume() }  // reminder deep link
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
