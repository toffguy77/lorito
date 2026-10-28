import SwiftUI
import WidgetKit
import DesignSystem

/// Lorito's widgets and the study-session Live Activity. Everything reads the
/// App Group snapshot the app publishes — never the user-data store.
@main
struct LoritoWidgetsBundle: WidgetBundle {
    init() {
        CrashReporting.start(.widgets)
        // Brand fonts ship in the DesignSystem bundle; styles fall back to the
        // system font if registration fails.
        FontRegistry.registerAll()
    }

    var body: some Widget {
        StreakWidget()
        WordOfDayWidget()
        PracticeWidget()
        LockScreenWidget()
        SessionLiveActivity()
    }
}
