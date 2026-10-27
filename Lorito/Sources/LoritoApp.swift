import SwiftUI
import Features
import DesignSystem

@main
struct LoritoApp: App {
    init() {
        // Bundled brand fonts live in the DesignSystem package bundle, which
        // `UIAppFonts` can't see — register them before the first view renders.
        FontRegistry.registerAll()
    }

    /// UI tests launch with `-lorito-ui-testing`: in-memory store, onboarding first.
    private static let uiTesting = CommandLine.arguments.contains("-lorito-ui-testing")

    var body: some Scene {
        WindowGroup {
            // `LORITO_CLOUDKIT` is defined only in builds that carry the iCloud
            // entitlement (cloudkit-sync branch). Off elsewhere → local store.
            #if LORITO_CLOUDKIT
            RootView(cloudKitEnabled: true, uiTesting: Self.uiTesting)
            #else
            RootView(cloudKitEnabled: false, uiTesting: Self.uiTesting)
            #endif
        }
    }
}
