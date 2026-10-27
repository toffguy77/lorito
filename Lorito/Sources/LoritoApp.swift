import SwiftUI
import Features
import DesignSystem
import Domain

@main
struct LoritoApp: App {
    init() {
        // Bundled brand fonts live in the DesignSystem package bundle, which
        // `UIAppFonts` can't see — register them before the first view renders.
        FontRegistry.registerAll()
        Self.configureAnalytics()
    }

    /// Product analytics: TelemetryDeck in Release when an app ID is configured;
    /// no-op in Debug unless launched with `-analytics`; UI tests keep events in
    /// an ephemeral, never-flushed queue.
    private static func configureAnalytics() {
        if uiTesting {
            AnalyticsService.configure(AnalyticsService(
                sink: NoOpAnalyticsSink(),
                defaults: UserDefaults(suiteName: "lorito.uitesting.\(UUID().uuidString)"),
                queueURL: nil, flushEnabled: false))
            return
        }
        let appID = (Bundle.main.object(forInfoDictionaryKey: "TelemetryDeckAppID") as? String) ?? ""
        var sink: AnalyticsSink = NoOpAnalyticsSink()
        #if DEBUG
        let enabled = CommandLine.arguments.contains("-analytics")
        #else
        let enabled = true
        #endif
        if enabled, !appID.isEmpty { sink = TelemetryDeckSink(appID: appID) }
        AnalyticsService.configure(AnalyticsService(
            sink: sink, defaults: .standard, queueURL: AnalyticsService.defaultQueueURL))
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
