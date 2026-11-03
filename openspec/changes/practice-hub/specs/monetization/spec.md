# Spec Delta

## MODIFIED Requirements

### Requirement: Pro scope is the exam path only
Lorito Pro SHALL gate only the exam section beyond its free preview set and free exercise practice outside the card reader (`practice-hub`). Grammar cards, exercises opened from a card's reader, the daily plan, reminders, streaks, progress, widgets, audio, the conjugation trainer, regional variants and Grammar Lens SHALL remain available without purchase.

#### Scenario: Non-purchaser uses free features
- **WHEN** a user without a purchase studies, practises a card's exercises from its reader, uses the conjugation trainer and switches the regional variant
- **THEN** no paywall is shown

#### Scenario: Locked exam content
- **WHEN** a non-Pro user opens exam content outside the preview set
- **THEN** the paywall is presented

#### Scenario: Locked free practice
- **WHEN** sales are on and a non-Pro user chooses a free-practice mode
- **THEN** the paywall is presented

### Requirement: Sales switch
A build constant SHALL decide whether Lorito Pro is sold. While sales are off, every user SHALL be entitled to the exam path and to free practice; the app SHALL show no Pro offer, paywall, Pro settings section or locked content, and SHALL make no StoreKit requests. Turning sales on SHALL restore the Pro behaviour without changing stored data.

#### Scenario: Sales off
- **WHEN** sales are off and a user without a purchase opens the second CCSE mock
- **THEN** the full mock starts and no paywall is shown

#### Scenario: Free practice with sales off
- **WHEN** sales are off and a user without a purchase starts «Слабые места»
- **THEN** the session starts and no lock or paywall is shown

#### Scenario: No Pro settings
- **WHEN** sales are off and the user opens Settings
- **THEN** there is no Lorito Pro section
