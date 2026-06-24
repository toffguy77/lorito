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
    @State private var catalog: ContentCatalog?
    @State private var loadError = false

    public init() {}

    public var body: some View {
        Group {
            if let model, let catalog {
                if didCompleteOnboarding {
                    mainFlow(model: model, catalog: catalog)
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
            self.model = ScopeSelectionModel(store: store, catalog: catalog)
        } catch {
            loadError = true
        }
    }

    // MARK: - Main flow

    private func mainFlow(model: ScopeSelectionModel, catalog: ContentCatalog) -> some View {
        NavigationStack {
            VStack(spacing: LoritoSpacing.sm) {
                Text("Lorito")
                    .font(LoritoFont.title)
                    .foregroundStyle(LoritoColor.textPrimary)
                Text("Español")
                    .font(LoritoFont.heading)
                    .foregroundStyle(LoritoColor.textSecondary)

                Text("\(catalog.cards.count) карточек · \(catalog.themes.count) тем · \(catalog.levels.count) уровней")
                    .font(LoritoFont.caption)
                    .foregroundStyle(LoritoColor.textTertiary)

                NavigationLink("Настройки") {
                    SettingsView(model: model)
                }
                .font(LoritoFont.body.weight(.semibold))
                .foregroundStyle(LoritoColor.onAccent)
                .padding(.horizontal, LoritoSpacing.lg)
                .padding(.vertical, LoritoSpacing.sm)
                .background(LoritoColor.accent, in: Capsule())
                .padding(.top, LoritoSpacing.md)

                NavigationLink("Дизайн-система") {
                    ComponentGalleryView()
                }
                .font(LoritoFont.body)
                .foregroundStyle(LoritoColor.onAccentSoft)
                .padding(.top, LoritoSpacing.xs)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LoritoColor.surface.ignoresSafeArea())
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
