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
    @State private var loadError = false

    public init() {}

    public var body: some View {
        Group {
            if let model, let store, let catalog {
                if didCompleteOnboarding {
                    MainTabView(store: store, catalog: catalog, scopeModel: model)
                } else {
                    OnboardingView(model: model) { didCompleteOnboarding = true }
                }
            } else if loadError {
                errorView
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(LoritoColor.surface.ignoresSafeArea())
            }
        }
        .task { await load() }
    }

    @MainActor
    private func load() async {
        guard model == nil else { return }
        do {
            let catalog = try ContentLoader.loadCatalog()
            let container = try PersistenceController.makeContainer()
            let store = SwiftDataUserDataStore(container: container)
            // Respect a completion flag already recorded in persisted settings.
            if let settings = try? store.loadSettings(), settings.didCompleteOnboarding {
                didCompleteOnboarding = true
            }
            self.catalog = catalog
            self.store = store
            self.model = ScopeSelectionModel(store: store, catalog: catalog)
        } catch {
            loadError = true
        }
    }

    private var errorView: some View {
        Text("Не удалось загрузить контент")
            .font(LoritoFont.caption)
            .foregroundStyle(LoritoColor.danger)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LoritoColor.surface.ignoresSafeArea())
    }
}

#Preview {
    RootView()
}
