import Foundation
import Testing
@testable import Domain

final class RecordingReporter: ErrorReporting, @unchecked Sendable {
    private let lock = NSLock()
    private var _reports: [ErrorReport] = []
    var reports: [ErrorReport] { lock.withLock { _reports } }
    func report(_ report: ErrorReport) { lock.withLock { _reports.append(report) } }
}

@Suite("Error reporting")
struct ErrorReportingTests {
    @Test("Only area, domain and code leave: the message and user info are dropped")
    func sanitized() {
        let error = NSError(domain: "NSCocoaErrorDomain", code: 260,
                            userInfo: [NSLocalizedDescriptionKey: "/var/mobile/…/Espero que vengas.json",
                                       NSFilePathErrorKey: "/private/secret"])
        let r = ErrorReport(error, area: .contentLoad)
        #expect(r == ErrorReport(area: .contentLoad, domain: "NSCocoaErrorDomain", code: 260))
        #expect(!String(describing: r).contains("vengas") && !String(describing: r).contains("secret"))
    }

    @Test("Swift errors report their type-derived domain and code, not a description")
    func swiftError() {
        enum Broken: Error { case a, b }
        let r = ErrorReport(Broken.b, area: .buddy)
        #expect(r.area == .buddy && r.code == 1 && r.domain.contains("Broken"))
    }

    @Test("No reporter configured: reporting is a no-op; configured: it receives the sanitized report")
    func shared() {
        ErrorReports.report(NSError(domain: "x", code: 1), area: .purchase)  // no reporter: no crash
        let rec = RecordingReporter()
        ErrorReports.$override.withValue(rec) {
            ErrorReports.report(NSError(domain: "SKErrorDomain", code: 2, userInfo: ["k": "v"]), area: .purchase)
        }
        #expect(rec.reports == [ErrorReport(area: .purchase, domain: "SKErrorDomain", code: 2)])
    }

    @Test("Areas are a closed set")
    func areas() {
        #expect(Set(ErrorArea.allCases.map(\.rawValue)) == ["contentLoad", "persistenceFallback", "purchase", "buddy"])
    }
}

@Suite("Crash reporting gating")
struct CrashReportingConfigTests {
    let raw = "abc123@o42.ingest.de.sentry.io/7"

    @Test("Release with a DSN: on, production, scheme added")
    func release() {
        #expect(CrashReportingConfig.resolve(rawDSN: raw, uiTesting: false, debug: false, arguments: [])
                == CrashReportingConfig(dsn: "https://abc123@o42.ingest.de.sentry.io/7", environment: "production"))
    }

    @Test("Off without a DSN, with an unexpanded build variable, and in UI tests")
    func off() {
        for dsn in [nil, "", "  ", "$(SENTRY_DSN)"] {
            #expect(CrashReportingConfig.resolve(rawDSN: dsn, uiTesting: false, debug: false, arguments: []) == nil)
        }
        #expect(CrashReportingConfig.resolve(rawDSN: raw, uiTesting: true, debug: false, arguments: []) == nil)
    }

    @Test("Debug only with -crash-reporting, as the debug environment")
    func debug() {
        #expect(CrashReportingConfig.resolve(rawDSN: raw, uiTesting: false, debug: true, arguments: []) == nil)
        #expect(CrashReportingConfig.resolve(rawDSN: raw, uiTesting: false, debug: true,
                                             arguments: ["-crash-reporting"])?.environment == "debug")
    }
}
