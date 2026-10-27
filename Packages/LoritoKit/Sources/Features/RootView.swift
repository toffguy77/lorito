// Features — SwiftUI screens. Depends inward on Domain, Content, Persistence, DesignSystem.
//
// RootView loads the bundled content and the user-data store at startup, then
// gates first-run onboarding behind a local completion flag: the onboarding
// flow is shown exactly once; later launches open the main flow directly.

import SwiftUI
import Domain
import Content
import Persistence
import DesignSystem

public struct RootView: View {
    @AppStorage("lorito.didCompleteOnboarding") private var didCompleteOnboarding = false

    @State private var model: ScopeSelectionModel?
    @State private var store: (any UserDataStore)?
    @State private var catalog: ContentCatalog?
    @State private var reminders: ReminderService?
    @State private var speech: SystemSpeechService?
    @State private var loadError = false
    private let cloudKitEnabled: Bool
    private let uiTesting: Bool
    private let demoData: Bool

    /// `uiTesting`: in-memory store and first-run onboarding on every launch, so
    /// UI tests are independent of each other (launch argument `-lorito-ui-testing`).
    /// `demoData` (UI testing only): seed that store with `DemoSeed` for screenshots.
    public init(cloudKitEnabled: Bool = false, uiTesting: Bool = false, demoData: Bool = false) {
        self.cloudKitEnabled = cloudKitEnabled
        self.uiTesting = uiTesting
        self.demoData = uiTesting && demoData
    }

    public var body: some View {
        Group {
            if let model, let store, let catalog {
                if didCompleteOnboarding {
                    AdaptiveRootView(store: store, catalog: catalog, scopeModel: model)
                } else {
                    OnboardingView(model: model, reminders: reminders) { didCompleteOnboarding = true }
                }
            } else if loadError {
                errorView
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(LoritoColor.surface.ignoresSafeArea())
            }
        }
        .speechSilenceHint()
        .spanishSpeech(speech)
        .environment(\.loritoUITesting, uiTesting)
        .task { await load() }
    }

    @MainActor
    private func load() async {
        guard model == nil else { return }
        // Device-local analytics consent is resolved before any event.
        AnalyticsService.shared.resolveConsentOnFirstLaunch()
        do {
            let catalog = try ContentLoader.loadCatalog()
            // Syncs through the user's private CloudKit DB when enabled (and an
            // iCloud account is available); falls back to a local store otherwise.
            if uiTesting { didCompleteOnboarding = false }
            let container = PersistenceController.makeUserContainer(cloudKitEnabled: cloudKitEnabled, inMemory: uiTesting)
            let store = SwiftDataUserDataStore(container: container)
            if demoData { try DemoSeed.make(catalog: catalog, today: Date()).apply(to: store) }
            // Respect a completion flag already recorded in persisted settings.
            if let settings = try? store.loadSettings(), settings.didCompleteOnboarding {
                didCompleteOnboarding = true
            }
            self.catalog = catalog
            self.store = store
            self.speech = SystemSpeechService(settings: { (try? store.loadSettings()) ?? .default })
            self.model = ScopeSelectionModel(store: store, catalog: catalog)
            self.reminders = ReminderService(
                scheduler: SystemNotificationScheduler(), store: store, catalog: catalog
            )
        } catch {
            loadError = true
        }
    }

    private var errorView: some View {
        Text("Не удалось загрузить контент")
            .font(LoritoFont.caption)
            .foregroundStyle(LoritoColor.dangerText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LoritoColor.surface.ignoresSafeArea())
    }
}

#Preview {
    RootView()
}
