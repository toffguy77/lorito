## Why

Lorito has no revenue to fund content work. The audit's model is "core free forever,
exam prep paid": grammar, exercises, audio, conjugations, regional variants, Grammar
Lens, streaks and widgets stay free; the DELE/CCSE exam section is Lorito Pro.
Payment reality shapes the design: Russian bank cards have not worked for Apple
purchases since 2022, and carrier billing for App Store purchases in Russia ended on
1 April 2026 (Sostav). Pro therefore targets diaspora storefronts and must never
degrade the free experience where buying is impossible.

## What Changes

- **App Store Connect stage first:** agreements, tax, a non-Russian payout account
  (blocking), subscription group, products, prices, Family Sharing, localizations,
  review assets, sandbox testers, StoreKit configuration synced from ASC.
- **Lorito Pro via StoreKit 2:** one yearly auto-renewable subscription and one
  lifetime non-consumable; prices configured in App Store Connect only.
- **Pro = exam path** (`exam-path-dele-ccse`) beyond its free preview set. Nothing
  else is gated.
- **Pure entitlement resolution in Domain;** billing grace period counts as entitled;
  offline-safe via `Transaction.currentEntitlements` and a local cache.
- **Lapse behaviour:** exam content locks back to the preview set; mock history stays
  readable; everything else is unaffected.
- **Restore purchases**, honest Russian paywall, «Lorito Pro пока недоступен в вашем
  регионе» when products cannot be loaded, no external payment links.
- **Analytics events** for the paywall funnel via `product-analytics`.

## Capabilities

### New Capabilities
- `monetization`: products, entitlement rules, grace period, lapse, paywall, restore,
  unavailable storefront, Pro scope.

### Modified Capabilities
- `product-analytics`: adds the purchase-funnel events.

## Impact

- **Domain**: `VerifiedPurchase`, `ProFeature` (`examPath`), `EntitlementResolver`.
- **Features**: `PurchaseService` (StoreKit 2), `PaywallView`, `ProGate`, Settings
  «Lorito Pro».
- **App target**: In-App Purchase capability; `Lorito.storekit` synced from App Store
  Connect.
- **Owner / App Store Connect**: explicit stage in tasks; ASC API key in
  `secrets/asc.env` (fastlane) may automate parts.
- **Depends on**: `product-analytics`, `exam-path-dele-ccse` (only consumer),
  `plumaje-design-system` (archived).
