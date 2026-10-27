## ADDED Requirements

### Requirement: Onboarding step order
Onboarding SHALL run its steps in this order: level selection (manual list or placement test), theme narrowing, then the reminder-time step when it exists, which SHALL remain last. Study goal and regional variant SHALL NOT be asked during onboarding; they SHALL be offered as dismissible prompts on Today after the first completed study session, one prompt per visit.

#### Scenario: Order on first run
- **WHEN** a new user goes through onboarding
- **THEN** level comes first, themes second, and the reminder step last, with no goal or variant step

#### Scenario: Prompts after first session
- **WHEN** the user finishes the first study session and returns to Today
- **THEN** Today offers one of the goal or regional-variant prompts, which can be dismissed

### Requirement: Placement test path in level selection
The level step SHALL offer, alongside the manual list, "Не знаю — проверить за 2 минуты", which runs the placement test. The result SHALL pre-select the proposed level; the user MAY pick another. Accepting SHALL apply the level exactly as a manual choice and SHALL store the highest known level as `placementKnownLevel` (an optional setting, unset for a manual choice).

#### Scenario: Accept the proposal
- **WHEN** the test proposes B1 with A1–A2 known and the user accepts
- **THEN** `targetLevel` is B1, A1–B1 are included, and `placementKnownLevel` is A2

#### Scenario: Manual path unchanged
- **WHEN** the user picks a level without taking the test
- **THEN** onboarding continues as before and `placementKnownLevel` stays unset

### Requirement: First study session starts after onboarding
When onboarding completes, the app SHALL give that learning day a one-off new-card allowance of the larger of 3 and `dailyNewCardCount`, within the daily new-introduction budget, introduce cards failed in the placement test first, and open the study session on the first card instead of showing Today; with an empty queue it SHALL show Today. This SHALL happen once and never on a later launch.

#### Scenario: Session opens with three new cards
- **WHEN** a user with `dailyNewCardCount` 1 completes onboarding
- **THEN** the study session opens and the day's queue holds 3 new cards

#### Scenario: Relaunch does not auto-start
- **WHEN** the app is relaunched after onboarding was completed
- **THEN** it opens on Today without starting a session
