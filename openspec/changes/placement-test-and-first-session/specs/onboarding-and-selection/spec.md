## ADDED Requirements

### Requirement: Placement test path in level selection
The onboarding level step SHALL offer, alongside the manual level list, an action "Не знаю — проверить за 2 минуты" that runs the placement test. On its result screen the proposed level SHALL be pre-selected, the user SHALL be able to accept it or pick another level, and the accepted level SHALL be applied exactly as a manual choice (including auto-inclusion of lower levels).

#### Scenario: Accept the proposed level
- **WHEN** the placement test proposes B1 and the user accepts it
- **THEN** `UserSettings.targetLevel` is B1 and levels A1–B1 are included

#### Scenario: Override the proposal
- **WHEN** the placement test proposes B1 and the user picks A2 instead
- **THEN** `UserSettings.targetLevel` is A2

#### Scenario: Manual path unchanged
- **WHEN** the user picks a level without taking the test
- **THEN** onboarding continues exactly as before

### Requirement: First study session starts after onboarding
When onboarding completes and today's queue is non-empty, the app SHALL open the study session on the first card of the queue instead of showing Today; closing or finishing that session SHALL lead to Today. When the queue is empty it SHALL show Today. This hand-off SHALL happen only once, right after onboarding, and never on a later launch.

#### Scenario: Session opens after onboarding
- **WHEN** the user completes onboarding and the queue has cards
- **THEN** the study session opens on the first card

#### Scenario: Relaunch does not auto-start
- **WHEN** the app is relaunched after onboarding was completed
- **THEN** it opens on Today without starting a session
