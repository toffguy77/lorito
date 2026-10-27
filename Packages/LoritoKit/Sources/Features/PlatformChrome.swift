import SwiftUI

/// iOS-only system chrome toggles, no-ops on the macOS test host.
extension View {
    @ViewBuilder
    func systemTabBarHidden() -> some View {
        #if os(iOS)
        toolbar(.hidden, for: .tabBar)
        #else
        self
        #endif
    }

    @ViewBuilder
    func navigationBarVisibility(_ visibility: Visibility) -> some View {
        #if os(iOS)
        toolbar(visibility, for: .navigationBar)
        #else
        self
        #endif
    }

    /// Present a focus-mode session full screen on iOS (a sheet elsewhere).
    @ViewBuilder
    func focusModeCover<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        #if os(iOS)
        fullScreenCover(item: item, onDismiss: onDismiss, content: content)
        #else
        sheet(item: item, onDismiss: onDismiss, content: content)
        #endif
    }
}
