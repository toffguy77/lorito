import SwiftUI
import Domain
import DesignSystem

/// The app's main flow after onboarding: Today, Catalog, and Settings tabs.
/// The study session is presented modally from Today.
public struct MainTabView: View {
    private let store: UserDataStore
    private let catalog: ContentCatalog
    private let scopeModel: ScopeSelectionModel

    public init(store: UserDataStore, catalog: ContentCatalog, scopeModel: ScopeSelectionModel) {
        self.store = store
        self.catalog = catalog
        self.scopeModel = scopeModel
    }

    public var body: some View {
        TabView {
            TodayView(store: store, catalog: catalog)
                .tabItem { Label("Сегодня", systemImage: "sun.max") }

            CatalogView(store: store, catalog: catalog)
                .tabItem { Label("Каталог", systemImage: "books.vertical") }

            NavigationStack {
                SettingsView(model: scopeModel)
            }
            .tabItem { Label("Настройки", systemImage: "gearshape") }
        }
        .tint(LoritoColor.accent)
    }
}
