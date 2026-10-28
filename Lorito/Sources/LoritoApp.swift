import SwiftUI
import UIKit
import CloudKit
import Features
import DesignSystem
import Domain

@main
struct LoritoApp: App {
    /// Study buddy: accepting a CloudKit share arrives through the scene delegate.
    @UIApplicationDelegateAdaptor(LoritoAppDelegate.self) private var appDelegate

    init() {
        // First, so launch-time crashes are caught too.
        CrashReporting.start(.app, uiTesting: Self.uiTesting)
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
    /// Screenshot tests add `-lorito-demo-data`: the in-memory store is seeded
    /// with deterministic demo progress (UI testing only).
    private static let demoData = uiTesting && CommandLine.arguments.contains("-lorito-demo-data")

    var body: some Scene {
        WindowGroup {
            // `LORITO_CLOUDKIT` is defined only in builds that carry the iCloud
            // entitlement (cloudkit-sync branch). Off elsewhere → local store.
            #if LORITO_CLOUDKIT
            RootView(cloudKitEnabled: true, uiTesting: Self.uiTesting, demoData: Self.demoData)
            #else
            RootView(cloudKitEnabled: false, uiTesting: Self.uiTesting, demoData: Self.demoData)
            #endif
        }
    }
}

/// Supplies the scene delegate that receives accepted CloudKit shares.
final class LoritoAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting session: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: session.role)
        config.delegateClass = LoritoSceneDelegate.self
        return config
    }
}

/// Study buddy invite accepted (link opened by the partner).
final class LoritoSceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith metadata: CKShare.Metadata) {
        Task { @MainActor in
            do {
                try await CloudKitBuddyBackend.accept(metadata)
            } catch {
                ErrorReports.report(error, area: .buddy)
                return
            }
            AnalyticsService.shared.record(.buddyInviteAccepted)
            NotificationCenter.default.post(name: BuddyModel.shareAccepted, object: nil)
        }
    }
}
