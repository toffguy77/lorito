## ADDED Requirements

### Requirement: Sales switch
A build constant SHALL decide whether Lorito Pro is sold. While sales are off, every user SHALL be entitled to the exam path; the app SHALL show no Pro offer, paywall, Pro settings section or locked content, and SHALL make no StoreKit requests. Turning sales on SHALL restore the Pro behaviour without changing stored data.

#### Scenario: Sales off
- **WHEN** sales are off and a user without a purchase opens the second CCSE mock
- **THEN** the full mock starts and no paywall is shown

#### Scenario: No Pro settings
- **WHEN** sales are off and the user opens Settings
- **THEN** there is no Lorito Pro section
