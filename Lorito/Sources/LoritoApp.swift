import SwiftUI
import Features

@main
struct LoritoApp: App {
    var body: some Scene {
        WindowGroup {
            // `LORITO_CLOUDKIT` is defined only in builds that carry the iCloud
            // entitlement (cloudkit-sync branch). Off elsewhere → local store.
            #if LORITO_CLOUDKIT
            RootView(cloudKitEnabled: true)
            #else
            RootView(cloudKitEnabled: false)
            #endif
        }
    }
}
