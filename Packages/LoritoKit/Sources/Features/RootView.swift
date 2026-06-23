// Features — SwiftUI screens. Depends inward on Domain, Content, Persistence, DesignSystem.
//
// During the foundation phase RootView surfaces the design-system gallery so the
// components can be verified on device/simulator. Real screens (Today, study,
// catalog, onboarding) replace this in later changes.

import SwiftUI
import DesignSystem

public struct RootView: View {
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
                Text("Foundation scaffold — экраны появятся в следующих изменениях.")
                    .font(LoritoFont.caption)
                    .foregroundStyle(LoritoColor.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LoritoSpacing.xl)

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
        }
    }
}

#Preview {
    RootView()
}
