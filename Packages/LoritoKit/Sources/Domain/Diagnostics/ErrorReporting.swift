import Foundation

/// Where a non-fatal error happened. Closed set: adding an area is a
/// `crash-reporting` spec change.
public enum ErrorArea: String, Sendable, CaseIterable {
    case contentLoad, persistenceFallback, purchase, buddy
}

/// What leaves the device for a non-fatal error: the area, the error domain and
/// the code — never the message or user info (paths, record names, text).
public struct ErrorReport: Sendable, Hashable {
    public let area: ErrorArea
    public let domain: String
    public let code: Int

    public init(area: ErrorArea, domain: String, code: Int) {
        self.area = area
        self.domain = domain
        self.code = code
    }

    public init(_ error: Error, area: ErrorArea) {
        let ns = error as NSError
        self.init(area: area, domain: ns.domain, code: ns.code)
    }
}

/// Implemented in the app target by the crash-reporting SDK.
public protocol ErrorReporting: Sendable {
    func report(_ report: ErrorReport)
}

/// The shared reporter: a no-op until the app configures one.
public enum ErrorReports {
    private final class Holder: @unchecked Sendable {
        let lock = NSLock()
        var reporter: ErrorReporting?
    }
    private static let holder = Holder()
    /// Tests scope a reporter to their task instead of the process-wide one.
    @TaskLocal public static var override: ErrorReporting?

    public static func configure(_ reporter: ErrorReporting?) {
        holder.lock.withLock { holder.reporter = reporter }
    }

    public static func report(_ error: Error, area: ErrorArea) {
        let reporter = override ?? holder.lock.withLock { holder.reporter }
        reporter?.report(ErrorReport(error, area: area))
    }
}

/// Whether and where crash reporting starts. Always on in Release with a DSN
/// (owner decision: not tied to the analytics consent); never in UI tests; in
/// Debug only with `-crash-reporting`.
public struct CrashReportingConfig: Equatable, Sendable {
    public let dsn: String
    public let environment: String

    /// `rawDSN` is the Info.plist value: no scheme, because `//` starts a comment
    /// in xcconfig files.
    public static func resolve(rawDSN: String?, uiTesting: Bool, debug: Bool,
                               arguments: [String]) -> CrashReportingConfig? {
        let raw = (rawDSN ?? "").trimmingCharacters(in: .whitespaces)
        guard !raw.isEmpty, !raw.hasPrefix("$("), !uiTesting else { return nil }
        if debug, !arguments.contains("-crash-reporting") { return nil }
        let dsn = raw.contains("://") ? raw : "https://" + raw
        return CrashReportingConfig(dsn: dsn, environment: debug ? "debug" : "production")
    }
}
