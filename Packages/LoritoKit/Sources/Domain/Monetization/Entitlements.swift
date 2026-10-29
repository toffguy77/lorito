import Foundation

/// The only paid feature: the exam path (DELE / CCSE). Everything else is free.
public enum ProFeature: String, Codable, Sendable, CaseIterable {
    case examPath
}

/// Whether Lorito Pro is sold in this build. While off, everyone gets the exam
/// path and the app shows no paywall or Pro settings (owner decision 2026-10-29).
public enum Monetization {
    public static let salesEnabled = false
}

public enum ProProducts {
    public static let yearly = "com.toffguy.lorito.pro.yearly"
    public static let lifetime = "com.toffguy.lorito.pro.lifetime"
    public static let all = [yearly, lifetime]
}

/// A verified transaction as plain values (StoreKit types stay in Features).
public struct VerifiedPurchase: Codable, Sendable, Hashable {
    public enum Ownership: String, Codable, Sendable { case purchased, familyShared }

    public var productID: String
    public var expirationDate: Date?
    public var revocationDate: Date?
    public var ownership: Ownership
    /// The subscription is in its billing grace period (still entitled).
    public var inGracePeriod: Bool

    public init(productID: String, expirationDate: Date?, revocationDate: Date?, ownership: Ownership, inGracePeriod: Bool) {
        self.productID = productID
        self.expirationDate = expirationDate
        self.revocationDate = revocationDate
        self.ownership = ownership
        self.inGracePeriod = inGracePeriod
    }
}

/// Pure entitlement resolution: lifetime unrevoked, or yearly unrevoked and
/// unexpired or in its grace period → `examPath`. Billing retry without grace
/// and revocations → nothing. Family sharing counts as a purchase.
public enum EntitlementResolver {
    public static func resolve(_ purchases: [VerifiedPurchase], now: Date) -> Set<ProFeature> {
        let entitled = purchases.contains { p in
            guard p.revocationDate == nil else { return false }
            switch p.productID {
            case ProProducts.lifetime: return true
            case ProProducts.yearly:
                guard let expires = p.expirationDate else { return false }
                return expires > now || p.inGracePeriod
            default: return false
            }
        }
        return entitled ? [.examPath] : []
    }
}
