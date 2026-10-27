## Context

Lorito is free, ad-free and account-free; no server. Facts used:

- Russia storefront: Russian bank cards have not worked for Apple purchases since
  2022; payment for digital purchases and subscriptions via mobile carrier accounts
  ended on 1 April 2026 ([Sostav](https://www.sostav.ru/blogs/295419/116138)). The
  products stay available there but simply cannot be bought.
- Price references: Duolingo Super $83.99–119.99/year
  ([Lingostar](https://lingostar.ai/blog/duolingo-max-review/)); AnkiMobile is a
  one-time purchase ([App Store](https://apps.apple.com/KR/app/id373493387)); DELE A2
  retake ≈ €130 ([Jobbatical](https://www.jobbatical.com/es/blog/guide-passing-spain-ccse-dele-a2-exams)).
- Owner decision 2026-10-27: Pro = exam path only; conjugation trainer, regional
  variants and Grammar Lens are free.

## Goals / Non-Goals

**Goals:** two simple products; correct offline entitlements incl. grace period;
nothing free becomes paid; clean lapse; graceful unavailable storefronts.

**Non-Goals:** ads; accounts; server receipt validation; App Store Server
Notifications (no backend to receive them); web checkout or external links; price
logic in code.

## Decisions

**Two products, one entitlement.** `com.toffguy.lorito.pro.yearly`
(auto-renewable, group «Lorito Pro») and `com.toffguy.lorito.pro.lifetime`
(non-consumable). Either grants `ProFeature.examPath`. Monthly deferred.

**Pure resolver.** `EntitlementResolver.resolve(_ purchases: [VerifiedPurchase], now:)`
in Domain takes plain values (product id, expiration date, revocation date, ownership
type, `inGracePeriod`). Lifetime unrevoked → entitled. Yearly unrevoked and (not
expired OR in billing grace period) → entitled. Billing retry without grace →
not entitled. Family-shared = purchased. StoreKit types stay in Features;
`PurchaseService` maps verified `Transaction`s plus `Product.SubscriptionInfo.Status`
(`.inGracePeriod`) into `VerifiedPurchase`.

**Offline-safe state.** Recompute at launch and on every `Transaction.updates` event
from `Transaction.currentEntitlements`; cache the resolved set locally (not synced)
for cold offline launches. A fresh StoreKit read always wins.

**Lapse.** When entitlement ends, exam content outside the preview set shows the
paywall again; past mock attempts and readiness history stay visible read-only; no
other screen changes because nothing else is gated. CCSE review items already
introduced keep their review state; new non-preview CCSE introductions stop.

**Unavailable storefront.** If `Product.products(for:)` returns nothing or throws,
the paywall shows «Lorito Pro пока недоступен в вашем регионе», no buy button.

**Honest paywall (Russian).** Exactly what Pro adds; `displayPrice`; renewal terms;
Terms and Privacy links; «Восстановить покупки»; close button. No countdowns or
invented discounts. Introductory offer (e.g. 1-week free trial on yearly) is an owner
decision in ASC; if configured, the paywall shows it from `subscription.introductoryOffer`.

**App Store Connect stage before StoreKit code ships.** See tasks §1; owner may use
the ASC API key already in `secrets/asc.env` (fastlane) to automate product setup and
localizations.

## Risks / Trade-offs

- [Owner has no non-Russian payout account] → blocking prerequisite; Apple does not
  pay out to Russian bank accounts, so nothing ships without it.
- [Most current users cannot pay] → Pro aims at diaspora; free core is the growth engine.
- [Review rejection] → standard StoreKit flow, restore, Terms/Privacy, no external links.

## Migration Plan

Ships together with `exam-path-dele-ccse`. Rollback: remove paywall entry points;
resolver code can stay dormant.
