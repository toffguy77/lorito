import Foundation
import Sentry
import Domain

/// Sentry crash, hang and non-fatal error reporting (`crash-reporting`), shared
/// by the app and its extensions. Started first in `LoritoApp.init`, the widget
/// bundle and the Lens Action; gating lives in `CrashReportingConfig`.
enum CrashReporting {
    /// The process reporting; tagged as `component` on every event.
    enum Component: String {
        case app, widgets, lensAction
    }

    /// Extensions report under the app's release so one release shows every process.
    static let appBundleID = "com.toffguy.lorito"

    static func start(_ component: Component, uiTesting: Bool = false) {
        #if DEBUG
        let debug = true
        #else
        let debug = false
        #endif
        guard let config = CrashReportingConfig.resolve(
            rawDSN: Bundle.main.object(forInfoDictionaryKey: "SentryDSN") as? String,
            uiTesting: uiTesting, debug: debug, arguments: CommandLine.arguments) else { return }
        SentrySDK.start { options in
            options.dsn = config.dsn
            options.environment = config.environment
            // Crashes, hangs and release health only — nothing that could carry
            // user content or identity.
            options.sendDefaultPii = false
            options.attachScreenshot = false
            options.attachViewHierarchy = false
            if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
               let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
                options.releaseName = "\(appBundleID)@\(version)+\(build)"
            }
            // Widget timelines and short extension launches would distort hangs
            // and crash-free sessions; extensions report crashes and errors only.
            options.enableAppHangTracking = component == .app
            options.enableAutoSessionTracking = component == .app
            options.tracesSampleRate = 0
            options.enableAutoPerformanceTracing = false
            options.enableNetworkTracking = false
            options.enableFileIOTracing = false
            options.enableUserInteractionTracing = false
            options.enableNetworkBreadcrumbs = false
            options.enableCaptureFailedRequests = false
            options.sessionReplay.sessionSampleRate = 0
            options.sessionReplay.onErrorSampleRate = 0
            options.initialScope = { scope in
                scope.setTag(value: component.rawValue, key: "component")
                return scope
            }
            options.beforeSend = { event in
                event.serverName = nil  // the device name
                if let user = event.user {
                    // Keep only the SDK's random installation id (crash-free users).
                    let anonymous = User()
                    anonymous.userId = user.userId
                    event.user = anonymous
                }
                return event
            }
        }
        ErrorReports.configure(SentryErrorReporter())
    }
}

/// Non-fatal errors: a fresh `NSError` with only the domain and code, tagged with
/// the area — the original message and user info never leave the device.
struct SentryErrorReporter: ErrorReporting {
    func report(_ report: ErrorReport) {
        let error = NSError(domain: report.domain, code: report.code)
        SentrySDK.capture(error: error) { scope in
            scope.setTag(value: report.area.rawValue, key: "area")
        }
    }
}
