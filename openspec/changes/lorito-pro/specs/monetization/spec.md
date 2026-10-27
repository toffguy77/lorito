## ADDED Requirements

### Requirement: Free core is never gated
The grammar cards, exercises, daily plan, reminders, streaks, progress, widgets and audio SHALL remain available without purchase. Only features listed as Pro features SHALL be gated.

#### Scenario: Non-purchaser studies normally
- **WHEN** a user without any purchase completes onboarding and a study session
- **THEN** no paywall is shown and all free features work

### Requirement: Pro products
Lorito Pro SHALL be offered as one auto-renewable yearly subscription and one lifetime non-consumable, both loaded from the App Store with their localized display price; prices SHALL NOT be hard-coded in the app.

#### Scenario: Prices from the store
- **WHEN** the paywall loads products successfully
- **THEN** each product shows the `displayPrice` returned by the App Store

### Requirement: Pure entitlement resolution
Pro entitlement SHALL be resolved by a pure Domain function from verified purchases and an injected date: an unrevoked lifetime purchase or an unexpired, unrevoked yearly subscription, whether purchased or family-shared, SHALL grant all Pro features; anything else grants none.

#### Scenario: Expired subscription
- **WHEN** the only purchase is a yearly subscription that expired yesterday
- **THEN** no Pro feature is granted

#### Scenario: Family-shared lifetime
- **WHEN** a lifetime purchase is present with family-shared ownership
- **THEN** all Pro features are granted

#### Scenario: Revoked purchase
- **WHEN** a lifetime purchase has a revocation date
- **THEN** no Pro feature is granted

### Requirement: Offline-safe entitlements
The app SHALL recompute entitlements from the store's current entitlements at launch and on every transaction update, and SHALL keep the last resolved entitlement locally so that Pro features stay available when the device is offline.

#### Scenario: Offline launch after purchase
- **WHEN** a Pro user launches the app with no network
- **THEN** Pro features are available

### Requirement: Restore purchases
Settings and the paywall SHALL provide «Восстановить покупки», which syncs with the App Store and re-resolves entitlements.

#### Scenario: Restore on a new device
- **WHEN** a lifetime purchaser taps «Восстановить покупки» on a new device
- **THEN** Pro features become available

### Requirement: Pro feature gating
The Pro features SHALL be the exam path, the conjugation trainer and regional variants. Opening a locked Pro feature SHALL present the paywall instead of the content and SHALL NOT crash or show an empty screen.

#### Scenario: Locked feature opened
- **WHEN** a non-Pro user opens the conjugation trainer
- **THEN** the paywall is presented

### Requirement: Unavailable storefront
When Pro products cannot be loaded, the paywall SHALL say «Lorito Pro пока недоступен в вашем регионе», show no purchase button, keep Pro features locked, and leave every free feature unaffected.

#### Scenario: Products fail to load
- **WHEN** the App Store returns no Pro products
- **THEN** the paywall shows the unavailable message and no purchase button

### Requirement: Honest paywall
The paywall SHALL list what Pro adds, the price and renewal terms of each product, links to terms and privacy, a restore action and a close control, in Russian, and SHALL NOT contain external payment links, countdown timers or invented discounts.

#### Scenario: Paywall content
- **WHEN** the paywall is shown with products loaded
- **THEN** it shows the Pro feature list, both prices, renewal terms, terms and privacy links, «Восстановить покупки» and a close button
