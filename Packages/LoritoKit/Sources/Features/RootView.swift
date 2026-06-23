// Features — SwiftUI screens. Depends inward on Domain, Content, Persistence, DesignSystem.
//
// RootView is the placeholder root screen for the foundation. Real screens
// (Today, study, catalog, onboarding) arrive in later changes.

import SwiftUI

public struct RootView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Text("Lorito")
                .font(.largeTitle.weight(.bold))
            Text("Español")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Foundation scaffold — экраны появятся в следующих изменениях.")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
    }
}

#Preview {
    RootView()
}
