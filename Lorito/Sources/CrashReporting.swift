import Foundation
import Sentry
import Domain

/// Sentry crash, hang and non-fatal error reporting (`crash-reporting`).
/// Started first in `LoritoApp.init`; gating lives in `CrashReportingConfig`.
enum CrashReporting {
    static func start(uiTesting: Bool) {
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
            options.enableAppHangTracking = true
            options.tracesSampleRate = 0
            options.enableAutoPerformanceTracing = false
            options.enableNetworkTracking = false
            options.enableFileIOTracing = false
            options.enableUserInteractionTracing = false
            options.enableNetworkBreadcrumbs = false
            options.enableCaptureFailedRequests = false
            options.sessionReplay.sessionSampleRate = 0
            options.sessionReplay.onErrorSampleRate = 0
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
