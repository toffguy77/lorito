## Why

Lorito has no revenue and no way to fund content work (exam prep, conjugations,
regional variants). The audit's model is "core free forever, exam prep paid": the
grammar course, exercises, audio, streaks and widgets stay free; deep, high-intent
features become Lorito Pro. Payment reality constrains the design: since 1 April
2026 App Store purchases in Russia can no longer be paid by mobile carrier billing
or Russian bank cards (Sostav), so Pro targets the diaspora storefronts and must
never degrade the free experience where purchasing is impossible.

## What Changes

- **Lorito Pro** via StoreKit 2: one auto-renewable yearly subscription and one
  lifetime non-consumable. Prices are configured in App Store Connect (hypothesis
  from the audit: ≈ €34.99/year, ≈ €59 lifetime), never hard-coded.
- **Entitlements:** Pro unlocks `exam-path` (beyond the free preview),
  `conjugation-trainer` and `regional-variants`. Everything else stays free.
- **Pure entitlement mapping in Domain:** a function from verified transactions to
  a set of features, testable without StoreKit.
- **Offline-safe:** entitlement derived from `Transaction.currentEntitlements` and
  cached; no network required to keep Pro after purchase.
- **Restore purchases**, Family Sharing on both products, Russian paywall copy, and
  a «Pro недоступен в вашем регионе» state when products cannot be loaded.
- **No external payment links or codes** that unlock content (App Review).

## Capabilities

### New Capabilities
- `monetization`: products, entitlements, paywall, restore, unavailable-storefront
  behaviour, gating contract for Pro features.

### Modified Capabilities
<!-- None: gated capabilities consume the entitlement contract defined here. -->

## Impact

- **Domain**: `Entitlement`, `ProFeature`, `EntitlementResolver` (pure).
- **Features**: `PurchaseService` (StoreKit 2: products, purchase, `Transaction.updates`
  listener, restore), `PaywallView`, `ProGate` view modifier, Settings «Lorito Pro».
- **App target**: StoreKit configuration file for local testing; In-App Purchase
  capability.
- **App Store Connect (owner)**: create subscription group and products, prices,
  Family Sharing, review screenshots, paid apps agreement and tax/banking.
- **Depends on**: `product-analytics` (paywall funnel), consumers `exam-path-dele-ccse`,
  `conjugation-trainer`, `regional-variants`. Base: `plumaje-design-system`.
