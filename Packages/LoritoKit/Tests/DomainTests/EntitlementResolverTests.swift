import Testing
import Foundation
@testable import Domain

private let now = Date(timeIntervalSince1970: 1_800_000_000)
private func yearly(expires: TimeInterval, grace: Bool = false, revoked: Bool = false,
                    ownership: VerifiedPurchase.Ownership = .purchased) -> VerifiedPurchase {
    VerifiedPurchase(productID: ProProducts.yearly, expirationDate: now.addingTimeInterval(expires),
                     revocationDate: revoked ? now.addingTimeInterval(-60) : nil, ownership: ownership, inGracePeriod: grace)
}

@Suite("Entitlement resolver")
struct EntitlementResolverTests {
    @Test("Lifetime unrevoked → Pro; revoked → none")
    func lifetime() {
        let p = VerifiedPurchase(productID: ProProducts.lifetime, expirationDate: nil, revocationDate: nil,
                                 ownership: .purchased, inGracePeriod: false)
        #expect(EntitlementResolver.resolve([p], now: now) == [.examPath])
        var revoked = p
        revoked.revocationDate = now.addingTimeInterval(-1)
        #expect(EntitlementResolver.resolve([revoked], now: now).isEmpty)
    }

    @Test("Yearly: unexpired → Pro; expired in grace → Pro; expired without grace (incl. billing retry) → none")
    func yearlyStates() {
        #expect(EntitlementResolver.resolve([yearly(expires: 3600)], now: now) == [.examPath])
        #expect(EntitlementResolver.resolve([yearly(expires: -3600, grace: true)], now: now) == [.examPath])
        #expect(EntitlementResolver.resolve([yearly(expires: -3600)], now: now).isEmpty)
        #expect(EntitlementResolver.resolve([yearly(expires: 3600, revoked: true)], now: now).isEmpty)
    }

    @Test("Family-shared counts as purchased; empty → none; unknown products ignored; deterministic")
    func misc() {
        #expect(EntitlementResolver.resolve([yearly(expires: 3600, ownership: .familyShared)], now: now) == [.examPath])
        #expect(EntitlementResolver.resolve([], now: now).isEmpty)
        let other = VerifiedPurchase(productID: "com.example.other", expirationDate: nil, revocationDate: nil,
                                     ownership: .purchased, inGracePeriod: false)
        #expect(EntitlementResolver.resolve([other], now: now).isEmpty)
        let mix = [yearly(expires: -10), yearly(expires: 3600)]
        #expect(EntitlementResolver.resolve(mix, now: now) == EntitlementResolver.resolve(mix.reversed(), now: now))
    }
}
