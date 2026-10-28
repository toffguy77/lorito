import Foundation
import Observation
import StoreKit
import Domain

/// A Pro product as the paywall shows it.
public struct ProProductInfo: Identifiable, Sendable, Hashable {
    public let id: String
    public let displayName: String
    public let displayPrice: String
    /// "в год, продлевается автоматически" / "навсегда".
    public let terms: String
    /// e.g. "1 неделя бесплатно", when the store has an introductory offer.
    public let introOffer: String?
}

public enum PurchaseOutcome: Sendable, Equatable { case purchased, cancelled, pending, failed }

/// The store behind `PurchaseService` (StoreKit in the app, a fake in tests).
public protocol ProStore: Sendable {
    func products() async throws -> [ProProductInfo]
    func currentPurchases() async -> [VerifiedPurchase]
    func purchase(_ productID: String) async throws -> PurchaseOutcome
    func sync() async throws
    /// Calls `onUpdate` for every transaction update (purchases, renewals, revocations).
    func listenForUpdates(_ onUpdate: @escaping @Sendable () async -> Void) -> Task<Void, Never>
}

/// Resolves Pro entitlements at launch and on every transaction update; the
/// last resolution is cached device-locally so Pro works on an offline launch
/// (a fresh store read always wins).
@MainActor
@Observable
public final class PurchaseService {
    public enum Availability: Equatable { case loading, available([ProProductInfo]), unavailable }

    static let cacheKey = "pro.entitlements"
    private let store: ProStore
    private let defaults: UserDefaults
    private let analytics: AnalyticsRecording
    private let now: () -> Date
    private var updates: Task<Void, Never>?

    public private(set) var entitlements: Set<ProFeature>
    public private(set) var availability: Availability = .loading

    public init(store: ProStore = StoreKitProStore(), defaults: UserDefaults = .standard,
                analytics: AnalyticsRecording? = nil, now: @escaping () -> Date = { Date() }) {
        self.store = store
        self.defaults = defaults
        self.analytics = analytics ?? AnalyticsService.shared
        self.now = now
        let cached = defaults.stringArray(forKey: Self.cacheKey) ?? []
        self.entitlements = Set(cached.compactMap(ProFeature.init(rawValue:)))
    }

    public func isEntitled(_ feature: ProFeature) -> Bool { entitlements.contains(feature) }

    /// Launch: resolve from the store and listen for updates.
    public func start() async {
        updates?.cancel()
        updates = store.listenForUpdates { [weak self] in await self?.refresh() }
        await refresh()
    }

    public func refresh() async {
        let resolved = EntitlementResolver.resolve(await store.currentPurchases(), now: now())
        entitlements = resolved
        let raw = resolved.map(\.rawValue).sorted()
        if defaults.stringArray(forKey: Self.cacheKey) != raw { defaults.set(raw, forKey: Self.cacheKey) }
    }

    public func loadProducts() async {
        do {
            let products = try await store.products()
            availability = products.isEmpty ? .unavailable : .available(products)
        } catch {
            availability = .unavailable
        }
    }

    public func purchase(_ productID: String) async -> PurchaseOutcome {
        analytics.record(.purchaseStarted(productID: productID))
        let outcome: PurchaseOutcome
        do {
            outcome = try await store.purchase(productID)
        } catch {
            ErrorReports.report(error, area: .purchase)
            outcome = .failed
        }
        switch outcome {
        case .purchased:
            analytics.record(.purchaseCompleted(productID: productID))
            await refresh()
        case .cancelled: analytics.record(.purchaseFailed(productID: productID, reason: .cancelled))
        case .pending: analytics.record(.purchaseFailed(productID: productID, reason: .pending))
        case .failed: analytics.record(.purchaseFailed(productID: productID, reason: .error))
        }
        return outcome
    }

    /// «Восстановить покупки»: App Store sync, then re-resolve.
    @discardableResult
    public func restore() async -> RestoreOutcome {
        do {
            try await store.sync()
        } catch {
            ErrorReports.report(error, area: .purchase)
            analytics.record(.restore(outcome: .failed))
            return .failed
        }
        await refresh()
        let outcome: RestoreOutcome = entitlements.isEmpty ? .nothingToRestore : .restored
        analytics.record(.restore(outcome: outcome))
        return outcome
    }
}

/// StoreKit 2 implementation.
public struct StoreKitProStore: ProStore {
    public init() {}

    public func products() async throws -> [ProProductInfo] {
        let products = try await Product.products(for: ProProducts.all)
        var out: [ProProductInfo] = []
        for p in products.sorted(by: { $0.id == ProProducts.yearly && $1.id != ProProducts.yearly }) {
            var intro: String?
            if let offer = p.subscription?.introductoryOffer {
                intro = offer.paymentMode == .freeTrial ? "\(Self.period(offer.period)) бесплатно" : offer.displayPrice
            }
            let terms = p.type == .autoRenewable ? "в год, продлевается автоматически; отменить можно в настройках App Store"
                                                 : "один раз, навсегда"
            out.append(ProProductInfo(id: p.id, displayName: p.displayName, displayPrice: p.displayPrice,
                                      terms: terms, introOffer: intro))
        }
        return out
    }

    public func currentPurchases() async -> [VerifiedPurchase] {
        var out: [VerifiedPurchase] = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let t) = result else { continue }
            var grace = false
            if let status = await t.subscriptionStatus { grace = status.state == .inGracePeriod }
            out.append(VerifiedPurchase(productID: t.productID, expirationDate: t.expirationDate,
                                        revocationDate: t.revocationDate,
                                        ownership: t.ownershipType == .familyShared ? .familyShared : .purchased,
                                        inGracePeriod: grace))
        }
        return out
    }

    public func purchase(_ productID: String) async throws -> PurchaseOutcome {
        guard let product = try await Product.products(for: [productID]).first else { return .failed }
        switch try await product.purchase() {
        case .success(let verification):
            guard case .verified(let t) = verification else { return .failed }
            await t.finish()
            return .purchased
        case .userCancelled: return .cancelled
        case .pending: return .pending
        @unknown default: return .failed
        }
    }

    public func sync() async throws { try await AppStore.sync() }

    public func listenForUpdates(_ onUpdate: @escaping @Sendable () async -> Void) -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let t) = result { await t.finish() }
                await onUpdate()
            }
        }
    }

    static func period(_ p: Product.SubscriptionPeriod) -> String {
        switch p.unit {
        case .day: return RussianPlural.days(p.value)
        case .week: return "\(p.value) \(RussianPlural.form(p.value, one: "неделя", few: "недели", many: "недель"))"
        case .month: return "\(p.value) \(RussianPlural.form(p.value, one: "месяц", few: "месяца", many: "месяцев"))"
        case .year: return "\(p.value) \(RussianPlural.form(p.value, one: "год", few: "года", many: "лет"))"
        @unknown default: return ""
        }
    }
}
