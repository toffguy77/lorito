## 0. Owner (App Store Connect / developer portal)

- [ ] 0.1 Accept the Paid Apps agreement; complete tax and banking
- [ ] 0.2 Create subscription group «Lorito Pro» with `pro.yearly`; create non-consumable `pro.lifetime`; set prices per storefront (hypothesis ≈ €34.99/year, ≈ €59 lifetime); enable Family Sharing on both
- [ ] 0.3 Add review screenshots and review notes (explain free core + previews)
- [ ] 0.4 Enable the In-App Purchase capability on the App ID

## 1. Domain (TDD)

- [ ] 1.1 Failing tests for `EntitlementResolver.resolve(_:now:)`: lifetime grants; unexpired yearly grants; expired yearly denies; revoked denies; family-shared grants; empty denies; deterministic
- [ ] 1.2 Implement `VerifiedPurchase`, `ProFeature` (`examPath`, `conjugationTrainer`, `regionalVariants`), `EntitlementResolver`

## 2. Purchase service (Features)

- [ ] 2.1 Add `Lorito.storekit` configuration with both products; wire it into the scheme for local testing
- [ ] 2.2 `PurchaseService` (`@Observable`): load products, purchase, `Transaction.updates` listener started at launch, `currentEntitlements` recompute, `AppStore.sync()` restore, local cache of the resolved set
- [ ] 2.3 Map `VerificationResult` → `VerifiedPurchase` only when verified; finish transactions
- [ ] 2.4 Unit tests with `SKTestSession` where available: purchase lifetime → Pro; expire subscription → not Pro; restore → Pro

## 3. UI

- [ ] 3.1 `PaywallView` (Plumaje tokens): feature list, product cards with `displayPrice` and renewal terms, terms/privacy links, «Восстановить покупки», close
- [ ] 3.2 Unavailable state «Lorito Pro пока недоступен в вашем регионе» when products fail to load
- [ ] 3.3 `ProGate` view modifier for consumers; Settings section «Lorito Pro» (status, restore, manage subscription)
- [ ] 3.4 Analytics via `product-analytics`: paywall shown, products loaded/failed, purchase started/succeeded/cancelled (no personal data)

## 4. Validation

- [ ] 4.1 `swift test` green
- [ ] 4.2 `xcodebuild` build; UI tests with the StoreKit config: open locked feature → paywall; buy lifetime → feature opens; products failing → unavailable message, free study unaffected
- [ ] 4.3 Sandbox test on device: purchase, restore on second device, family sharing, offline launch keeps Pro
- [ ] 4.4 `rg 'https?://' Packages/LoritoKit/Sources/Features` shows no payment links
- [ ] 4.5 `openspec validate lorito-pro --strict`
