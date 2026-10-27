## 0. Dependencies

- [ ] 0.1 `product-analytics` applied (event API); ships together with `exam-path-dele-ccse`

## 1. App Store Connect stage (owner; must be complete before StoreKit code ships)

- [ ] 1.1 BLOCKING: set up a non-Russian payout bank account / legal entity — Apple does not pay out to Russian bank accounts
- [ ] 1.2 Accept the Paid Apps agreement
- [ ] 1.3 Complete tax forms
- [ ] 1.4 Add banking information for the payout account from 1.1
- [ ] 1.5 Create subscription group «Lorito Pro»; product `com.toffguy.lorito.pro.yearly` (auto-renewable, 1 year); product `com.toffguy.lorito.pro.lifetime` (non-consumable)
- [ ] 1.6 Set price points per storefront (owner decides; hypotheses ≈ €34.99/year, ≈ €59 lifetime)
- [ ] 1.7 Enable Family Sharing on both products
- [ ] 1.8 Availability: all storefronts (in Russia there is no payment method — the product simply cannot be bought there)
- [ ] 1.9 IAP localizations: ru, es-ES, es-MX, en (display name + description)
- [ ] 1.10 Review screenshot of the paywall and review notes (free core, preview set, what Pro unlocks)
- [ ] 1.11 Decide on an introductory offer (e.g. 1-week free trial on yearly) and configure it if chosen
- [ ] 1.12 Create sandbox testers
- [ ] 1.13 App Store Server Notifications: not needed (no backend) — leave unset
- [ ] 1.14 Enable the In-App Purchase capability on the App ID
- [ ] 1.15 Optional automation: use the ASC API key in `secrets/asc.env` (fastlane) for products and localizations

## 2. Domain (TDD)

- [ ] 2.1 Failing tests for `EntitlementResolver.resolve(_:now:)`: lifetime; unexpired yearly; expired yearly in grace → Pro; expired without grace → none; billing retry without grace → none; revoked → none; family-shared → Pro; empty → none; deterministic
- [ ] 2.2 Implement `VerifiedPurchase` (incl. `inGracePeriod`), `ProFeature.examPath`, `EntitlementResolver`

## 3. Purchase service

- [ ] 3.1 Create `Lorito.storekit` synced from App Store Connect; wire into the scheme
- [ ] 3.2 `PurchaseService`: load products, purchase, `Transaction.updates` listener at launch, `currentEntitlements` + subscription status (grace) → resolver, `AppStore.sync()` restore, local cache, finish transactions
- [ ] 3.3 Tests with `SKTestSession`: buy lifetime → Pro; expire subscription → not Pro; grace period → Pro; restore → Pro

## 4. UI and gating

- [ ] 4.1 `PaywallView`: feature list (exam section), product cards with `displayPrice`, renewal terms, intro offer if any, Terms/Privacy, «Восстановить покупки», close
- [ ] 4.2 Unavailable state «Lorito Pro пока недоступен в вашем регионе»
- [ ] 4.3 `ProGate(.examPath)` used only by exam content outside the preview set; lapse: read-only mock history
- [ ] 4.4 Settings «Lorito Pro»: status, restore, manage subscription
- [ ] 4.5 Analytics events per `product-analytics` delta

## 5. Validation

- [ ] 5.1 `swift test` green
- [ ] 5.2 `xcodebuild`; UI tests with the StoreKit config: locked exam content → paywall; buy → content opens; products failing → unavailable message, free features unaffected; expire → read-only history
- [ ] 5.3 Sandbox on device: purchase, restore on a second device, family sharing, offline launch keeps Pro
- [ ] 5.4 `rg 'https?://' Packages/LoritoKit/Sources/Features` shows only the Terms and Privacy URLs (allow-list), no payment links
- [ ] 5.5 `openspec validate lorito-pro --strict`
