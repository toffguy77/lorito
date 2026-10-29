## Why

The Paid Apps Agreement cannot be signed for the owner's account right now. Owner
decision (2026-10-29): ship everything free; if the app gains traction, sell Pro
through a European publisher. The exam path is ready and should not sit behind a
paywall nobody can pay.

## What Changes

- A build constant `Monetization.salesEnabled` (now `false`) decides whether Pro is sold.
- While sales are off: every user gets the whole exam path (every DELE A2 and CCSE
  mock in full), the app shows no paywall, Pro settings, lock marks or «бесплатная
  часть» labels, and makes no StoreKit requests.
- StoreKit code, the entitlement logic, `Lorito.storekit` and the products in App
  Store Connect stay as they are; turning sales on restores today's behaviour.
- App Store descriptions (ru, es-ES, es-MX) drop the Lorito Pro sentence.

## Capabilities

### Modified Capabilities
- `monetization`: sales switch.
- `exam-path`: the free preview applies only while sales are on.

## Impact

- Domain `Monetization`; Features `ExamsModel`, exam views, `AdaptiveRootView`
  (purchase service not started, no Pro section in Settings).
- Tests: Features exam tests, UI tests (`LoritoProUITests`, `ExamPathUITests`).
- `fastlane/metadata/*/description.txt`.
- In App Store Connect the Pro products stay unsubmitted and are not attached to a version.
