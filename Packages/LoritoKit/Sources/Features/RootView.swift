// Features — SwiftUI screens. Depends inward on Domain, Content, Persistence, DesignSystem.
//
// During the foundation phase RootView loads the bundled content at startup and
// surfaces the design-system gallery. Real screens (Today, study, catalog,
// onboarding) replace this in later changes.

import SwiftUI
import Domain
import Content
import DesignSystem

public struct RootView: View {
    @State private var catalog: ContentCatalog?
    @State private var loadError: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: LoritoSpacing.sm) {
                Text("Lorito")
                    .font(LoritoFont.title)
                    .foregroundStyle(LoritoColor.textPrimary)
                Text("Español")
                    .font(LoritoFont.heading)
                    .foregroundStyle(LoritoColor.textSecondary)

                if let catalog {
                    Text("\(catalog.cards.count) карточек · \(catalog.themes.count) тем · \(catalog.levels.count) уровней")
                        .font(LoritoFont.caption)
                        .foregroundStyle(LoritoColor.textTertiary)
                } else if loadError {
                    Text("Не удалось загрузить контент")
                        .font(LoritoFont.caption)
                        .foregroundStyle(LoritoColor.danger)
                } else {
                    ProgressView()
                }

                NavigationLink("Дизайн-система") {
                    ComponentGalleryView()
                }
                .font(LoritoFont.body.weight(.semibold))
                .foregroundStyle(LoritoColor.onAccent)
                .padding(.horizontal, LoritoSpacing.lg)
                .padding(.vertical, LoritoSpacing.sm)
                .background(LoritoColor.accent, in: Capsule())
                .padding(.top, LoritoSpacing.md)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LoritoColor.surface.ignoresSafeArea())
            .task {
                do {
                    catalog = try ContentLoader.loadCatalog()
                } catch {
                    loadError = true
                }
            }
        }
    }
}

#Preview {
    RootView()
}
