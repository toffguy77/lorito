## Context

Lorito is free, ad-free and account-free (App Store description). There is no
server; the user's data lives in SwiftData with optional CloudKit sync. Facts used:

- Russia storefront: since 1 April 2026 digital purchases and subscriptions can no
  longer be paid via mobile carrier accounts, and Russian bank cards no longer work
  for direct Apple payments ([Sostav](https://www.sostav.ru/blogs/295419/116138)).
- Price references: Duolingo Super $83.99–119.99/year
  ([Lingostar](https://lingostar.ai/blog/duolingo-max-review/)); AnkiMobile sells as a
  one-time purchase ([App Store](https://apps.apple.com/KR/app/id373493387)); DELE A2
  retake ≈ €130 ([Jobbatical](https://www.jobbatical.com/es/blog/guide-passing-spain-ccse-dele-a2-exams)).

## Goals / Non-Goals

**Goals:** a simple, honest Pro with two products; correct offline entitlements;
nothing free today becomes paid; graceful behaviour where IAP cannot be paid.

**Non-Goals:** ads; accounts or server receipt validation; promo codes from our own
backend; web checkout or external purchase links; price localisation logic in code.

## Decisions

**Two products, one entitlement.** `pro.yearly` (auto-renewable, own subscription
group) and `pro.lifetime` (non-consumable). Either grants `Entitlement.pro`. A
monthly plan is deferred: one price signal is easier to learn from.

**Pure resolver.** `EntitlementResolver.resolve(_ transactions: [VerifiedPurchase], now:) -> Set<ProFeature>`
lives in Domain and takes plain values (product id, expiration, revocation date,
ownership type). It ignores revoked and expired transactions. StoreKit types never
enter Domain; `PurchaseService` maps `Transaction` → `VerifiedPurchase` after
`VerificationResult` is `.verified`.

**Offline-safe state.** `PurchaseService` recomputes from
`Transaction.currentEntitlements` at launch and on every `Transaction.updates` event,
and caches the last resolved set locally (not synced) so a cold offline launch keeps
Pro. The cache is only a hint; a fresh StoreKit read wins.

**Feature gating contract.** `ProFeature` cases: `examPath`, `conjugationTrainer`,
`regionalVariants`. Consumers call `ProGate(.examPath)`; when locked, it shows the
paywall sheet instead of the content. Free previews are the consumer's decision and
are expressed as counters in that capability, not here.

**Unavailable storefront.** If `Product.products(for:)` returns no products or
throws, the paywall shows «Lorito Pro пока недоступен в вашем регионе» with no buy
button; Pro features stay locked; the free product is unaffected. No region
detection by IP or locale; the StoreKit response is the source of truth.

**Paywall copy (Russian), no dark patterns.** Lists exactly what Pro adds, shows
StoreKit `displayPrice` per product, the renewal terms for the subscription, links
to terms and privacy, a visible «Восстановить покупки», and a close button. No
countdowns or fake discounts.

**Family Sharing** enabled for both products (owner sets it in App Store Connect);
resolver treats `familyShared` ownership the same as `purchased`.

## Risks / Trade-offs

- [Most current users are in Russia and cannot pay] → Pro is aimed at diaspora
  storefronts; the free core is the growth engine; no free feature is removed.
- [Review rejection for gating or copy] → standard StoreKit 2 flow, restore button,
  terms links, no external links; reviewer notes explain the free preview.
- [Revenue too small to matter] → measured via `product-analytics` funnel
  (paywall shown → product loaded → purchase) before investing in more Pro content.

## Migration Plan

Additive. Ship with products in "Ready to Submit" alongside the first Pro consumer
(`exam-path-dele-ccse` or `conjugation-trainer`). Rollback: remove the Settings entry
and paywall; existing purchasers keep the entitlement logic in place.
