# monetization Specification

## Purpose
TBD - created by archiving change lorito-pro. Update Purpose after archive.
## Requirements
### Requirement: Pro scope is the exam path only
Lorito Pro SHALL gate only the exam section beyond its free preview set. Grammar cards, exercises, the daily plan, reminders, streaks, progress, widgets, audio, the conjugation trainer, regional variants and Grammar Lens SHALL remain available without purchase.

#### Scenario: Non-purchaser uses free features
- **WHEN** a user without a purchase studies, uses the conjugation trainer and switches the regional variant
- **THEN** no paywall is shown

#### Scenario: Locked exam content
- **WHEN** a non-Pro user opens exam content outside the preview set
- **THEN** the paywall is presented

### Requirement: Pro products
Lorito Pro SHALL be offered as one auto-renewable yearly subscription and one lifetime non-consumable, both loaded from the App Store with their localized display price; prices SHALL NOT be hard-coded.

#### Scenario: Prices from the store
- **WHEN** the paywall loads products successfully
- **THEN** each product shows the `displayPrice` returned by the App Store

### Requirement: Pure entitlement resolution
Entitlement SHALL be resolved by a pure Domain function from verified purchases and an injected date: an unrevoked lifetime purchase, or an unrevoked yearly subscription that is unexpired or in its billing grace period, purchased or family-shared, grants Pro; anything else grants nothing.

#### Scenario: Grace period
- **WHEN** the yearly subscription expired yesterday and is in its billing grace period
- **THEN** Pro is granted

#### Scenario: Expired without grace
- **WHEN** the yearly subscription expired yesterday and is not in grace
- **THEN** Pro is not granted

#### Scenario: Revoked lifetime
- **WHEN** the lifetime purchase has a revocation date
- **THEN** Pro is not granted

### Requirement: Offline-safe entitlements
The app SHALL recompute entitlements at launch and on every transaction update from the store's current entitlements, and SHALL cache the last resolved entitlement locally so Pro stays available offline.

#### Scenario: Offline launch after purchase
- **WHEN** a Pro user launches the app with no network
- **THEN** exam content is available

### Requirement: Lapse behaviour
When Pro ends, non-preview exam content SHALL show the paywall again, past mock attempts and readiness SHALL remain viewable read-only, and no other feature or data SHALL change.

#### Scenario: Subscription lapses
- **WHEN** a user's yearly subscription expires without grace
- **THEN** their previous mock results are still visible and starting a non-preview mock shows the paywall

### Requirement: Restore purchases
Settings and the paywall SHALL provide «Восстановить покупки», which syncs with the App Store and re-resolves entitlements.

#### Scenario: Restore on a new device
- **WHEN** a lifetime purchaser taps «Восстановить покупки» on a new device
- **THEN** Pro becomes available

### Requirement: Unavailable storefront
When Pro products cannot be loaded, the paywall SHALL say «Lorito Pro пока недоступен в вашем регионе», show no purchase button, and leave every free feature unaffected.

#### Scenario: Products fail to load
- **WHEN** the App Store returns no Pro products
- **THEN** the unavailable message is shown without a purchase button

### Requirement: Honest paywall
The paywall SHALL show, in Russian, what Pro adds, each product's price and renewal terms, any introductory offer configured in the store, Terms and Privacy links, a restore action and a close control, and SHALL NOT contain external payment links, countdown timers or invented discounts.

#### Scenario: Paywall content
- **WHEN** the paywall is shown with products loaded
- **THEN** it shows the Pro feature list, both prices, renewal terms, Terms and Privacy links, «Восстановить покупки» and a close button

### Requirement: Sales switch
A build constant SHALL decide whether Lorito Pro is sold. While sales are off, every user SHALL be entitled to the exam path; the app SHALL show no Pro offer, paywall, Pro settings section or locked content, and SHALL make no StoreKit requests. Turning sales on SHALL restore the Pro behaviour without changing stored data.

#### Scenario: Sales off
- **WHEN** sales are off and a user without a purchase opens the second CCSE mock
- **THEN** the full mock starts and no paywall is shown

#### Scenario: No Pro settings
- **WHEN** sales are off and the user opens Settings
- **THEN** there is no Lorito Pro section

