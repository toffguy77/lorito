## ADDED Requirements

### Requirement: Purchase funnel events
The app SHALL record the anonymous events `paywall_shown` (with the entry point), `purchase_started`, `purchase_completed` and `purchase_failed` (with product id and a coarse reason: cancelled, pending, error, unavailable) and `restore` (with outcome), and SHALL NOT include prices paid, Apple IDs or any personal data.

#### Scenario: Purchase completed
- **WHEN** a user buys the lifetime product
- **THEN** `purchase_started` and `purchase_completed` are recorded with the product id and no personal data

#### Scenario: Unavailable storefront
- **WHEN** the paywall cannot load products
- **THEN** `paywall_shown` is recorded and a `purchase_failed` event is not recorded unless a purchase was attempted
