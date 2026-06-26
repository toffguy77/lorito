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

    public var body: some View {
        TabView(selection: $selection) {
            TodayView(store: store, catalog: catalog, onSessionComplete: {
                Task { await reminders.reschedule() }
            })
            .tabItem { Label("Сегодня", systemImage: "sun.max") }
            .tag(0)

            CatalogView(store: store, catalog: catalog)
                .tabItem { Label("Каталог", systemImage: "books.vertical") }
                .tag(1)

            StatsView(store: store)
                .tabItem { Label("Прогресс", systemImage: "flame") }
                .tag(2)

            NavigationStack {
                SettingsView(model: scopeModel, reminders: reminders)
            }
            .tabItem { Label("Настройки", systemImage: "gearshape") }
            .tag(3)
        }
        .tint(LoritoColor.accent)
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
