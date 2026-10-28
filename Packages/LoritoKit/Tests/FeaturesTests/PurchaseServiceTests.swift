import Foundation
import Testing
import Domain
@testable import Features

private final class FakeStore: ProStore, @unchecked Sendable {
    var purchases: [VerifiedPurchase] = []
    var productList: [ProProductInfo] = []
    var productsFail = false
    var syncFails = false
    var nextOutcome: PurchaseOutcome = .purchased
    var purchaseThrows = false
    let lifetime = ProProducts.lifetime

    func products() async throws -> [ProProductInfo] {
        if productsFail { throw URLError(.notConnectedToInternet) }
        return productList
    }
    func currentPurchases() async -> [VerifiedPurchase] { purchases }
    func purchase(_ productID: String) async throws -> PurchaseOutcome {
        if purchaseThrows { throw NSError(domain: "SKErrorDomain", code: 0, userInfo: ["product": productID]) }
        if nextOutcome == .purchased {
            purchases.append(VerifiedPurchase(productID: productID, expirationDate: productID == ProProducts.yearly
                                              ? Date().addingTimeInterval(365 * 86_400) : nil,
                                              revocationDate: nil, ownership: .purchased, inGracePeriod: false))
        }
        return nextOutcome
    }
    func sync() async throws { if syncFails { throw URLError(.notConnectedToInternet) } }
    func listenForUpdates(_ onUpdate: @escaping @Sendable () async -> Void) -> Task<Void, Never> { Task {} }
}

private final class Recorder: AnalyticsRecording {
    var events: [AnalyticsEvent] = []
    func record(_ event: AnalyticsEvent) { events.append(event) }
}

@Suite("Purchase service")
@MainActor
struct PurchaseServiceTests {
    fileprivate func make(_ store: FakeStore, defaults: UserDefaults = UserDefaults(suiteName: UUID().uuidString)!,
              recorder: Recorder = Recorder()) -> PurchaseService {
        PurchaseService(store: store, defaults: defaults, analytics: recorder)
    }

    @Test("Buy lifetime → Pro, funnel events without prices or personal data")
    func buyLifetime() async {
        let store = FakeStore()
        let recorder = Recorder()
        let s = make(store, recorder: recorder)
        await s.start()
        #expect(!s.isEntitled(.examPath))
        #expect(await s.purchase(ProProducts.lifetime) == .purchased)
        #expect(s.isEntitled(.examPath))
        #expect(recorder.events == [.purchaseStarted(productID: ProProducts.lifetime),
                                    .purchaseCompleted(productID: ProProducts.lifetime)])
    }

    @Test("Expired subscription → not Pro; grace period → Pro")
    func subscription() async {
        let store = FakeStore()
        store.purchases = [VerifiedPurchase(productID: ProProducts.yearly, expirationDate: Date().addingTimeInterval(-60),
                                            revocationDate: nil, ownership: .purchased, inGracePeriod: false)]
        let s = make(store)
        await s.refresh()
        #expect(!s.isEntitled(.examPath))
        store.purchases[0].inGracePeriod = true
        await s.refresh()
        #expect(s.isEntitled(.examPath))
    }

    @Test("Restore re-resolves; nothing to restore; failure reported")
    func restore() async {
        let store = FakeStore()
        let s = make(store)
        #expect(await s.restore() == .nothingToRestore)
        store.purchases = [VerifiedPurchase(productID: ProProducts.lifetime, expirationDate: nil, revocationDate: nil,
                                            ownership: .familyShared, inGracePeriod: false)]
        #expect(await s.restore() == .restored && s.isEntitled(.examPath))
        store.syncFails = true
        #expect(await s.restore() == .failed)
    }

    @Test("Cached entitlement survives an offline cold launch; a fresh store read wins")
    func offline() async {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = FakeStore()
        store.purchases = [VerifiedPurchase(productID: ProProducts.lifetime, expirationDate: nil, revocationDate: nil,
                                            ownership: .purchased, inGracePeriod: false)]
        await make(store, defaults: defaults).refresh()
        let coldLaunch = make(FakeStore(), defaults: defaults)
        #expect(coldLaunch.isEntitled(.examPath))           // before any store read
        await coldLaunch.refresh()                           // the store says nothing now
        #expect(!coldLaunch.isEntitled(.examPath))
    }

    @Test("Products failing to load → unavailable; no purchase_failed unless a purchase was attempted")
    func unavailable() async {
        let store = FakeStore()
        store.productsFail = true
        let recorder = Recorder()
        let s = make(store, recorder: recorder)
        await s.loadProducts()
        #expect(s.availability == .unavailable)
        store.productsFail = false
        await s.loadProducts()
        #expect(s.availability == .unavailable)              // empty list
        #expect(!recorder.events.contains { if case .purchaseFailed = $0 { return true }; return false })
        store.nextOutcome = .cancelled
        _ = await s.purchase(ProProducts.yearly)
        #expect(recorder.events.last == .purchaseFailed(productID: ProProducts.yearly, reason: .cancelled))
    }

    @Test("Purchase and restore errors are reported (domain and code only); cancel and pending are not")
    func errorsReported() async {
        final class Reports: ErrorReporting, @unchecked Sendable {
            let lock = NSLock()
            var items: [ErrorReport] = []
            func report(_ report: ErrorReport) { lock.withLock { items.append(report) } }
        }
        let reports = Reports()
        let store = FakeStore()
        let s = make(store)
        await ErrorReports.$override.withValue(reports) {
            store.nextOutcome = .cancelled
            _ = await s.purchase(ProProducts.lifetime)
            store.nextOutcome = .pending
            _ = await s.purchase(ProProducts.lifetime)
            #expect(reports.items.isEmpty)
            store.purchaseThrows = true
            _ = await s.purchase(ProProducts.lifetime)
            store.syncFails = true
            _ = await s.restore()
        }
        #expect(reports.items == [ErrorReport(area: .purchase, domain: "SKErrorDomain", code: 0),
                                  ErrorReport(area: .purchase, domain: NSURLErrorDomain, code: URLError.notConnectedToInternet.rawValue)])
    }
}
