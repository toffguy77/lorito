import Foundation
import Testing
import SwiftData
import Domain
@testable import Persistence

private final class Reports: ErrorReporting, @unchecked Sendable {
    private let lock = NSLock()
    private var items: [ErrorReport] = []
    var all: [ErrorReport] { lock.withLock { items } }
    func report(_ report: ErrorReport) { lock.withLock { items.append(report) } }
}

@Suite("Persistence fallback reporting")
struct PersistenceFallbackTests {
    private func local(_ config: PersistenceConfig) throws -> ModelContainer {
        if config.cloudKitEnabled { throw NSError(domain: "CKErrorDomain", code: 9, userInfo: ["record": "secret"]) }
        return try PersistenceController.makeContainer(config: .init(inMemory: true))
    }

    @Test("A failing synced container falls back to local and reports persistenceFallback")
    func fallbackReported() {
        let reports = Reports()
        ErrorReports.$override.withValue(reports) {
            _ = PersistenceController.userContainer(cloudKitEnabled: true, make: local)
        }
        #expect(reports.all == [ErrorReport(area: .persistenceFallback, domain: "CKErrorDomain", code: 9)])
    }

    @Test("Sync off by build: no report")
    func localByDesign() {
        let reports = Reports()
        ErrorReports.$override.withValue(reports) {
            _ = PersistenceController.userContainer(cloudKitEnabled: false, make: local)
        }
        #expect(reports.all.isEmpty)
    }
}
