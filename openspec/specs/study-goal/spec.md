# study-goal Specification

## Purpose
TBD - created by archiving change study-goal. Update Purpose after archive.
## Requirements
### Requirement: Optional level goal
The user SHALL be able to set at most one level goal: a target level within scope and a target date after today. It SHALL be stored as optional scalar fields of `UserSettings` (target level, target date, start date, introduced count at start, state) and be editable or removable in Settings. Without it the daily plan SHALL behave as before.

#### Scenario: Set a level goal
- **WHEN** the user sets target level B1 with a date two months ahead
- **THEN** an active level goal with that level and date is stored

#### Scenario: Past date rejected
- **WHEN** the user enters a target date that is today or earlier
- **THEN** the goal cannot be saved

### Requirement: Optional exam date
The user SHALL be able to set an exam kind (DELE A2 or CCSE) and an exam date independently of the level goal, stored as optional scalars. The "DELE A2" preset SHALL set both a level goal with target A2 and a DELE A2 exam with the same date. An exam SHALL be achieved when the learning day after its date arrives or when the user marks it done, regardless of card progress.

#### Scenario: Preset sets both parts
- **WHEN** the user picks "DELE A2" with a date in May
- **THEN** a level goal A2 and a DELE A2 exam, both dated that day, are stored

#### Scenario: Exam not achieved by cards
- **WHEN** every A2 card is introduced before the exam date
- **THEN** the level goal is achieved and the exam is still active

#### Scenario: Marked done
- **WHEN** the user marks the exam as done
- **THEN** the exam is achieved

### Requirement: Goal pace never lowers the user's setting
While a level goal is active, a pure `Domain` function SHALL compute the pace as the not-yet-introduced, non-suspended `.card` items up to the target level within the selected themes, divided by the local learning days from today through the target date inclusive, rounded up. The daily new-card count SHALL be the larger of the pace and `dailyNewCardCount`, capped by the daily new-introduction budget.

#### Scenario: Pace raises the count
- **WHEN** 30 cards and 10 learning days remain and `dailyNewCardCount` is 1
- **THEN** the daily new-card count is 3

#### Scenario: Manual setting kept
- **WHEN** the pace is 2 and `dailyNewCardCount` is 4
- **THEN** the daily new-card count is 4

### Requirement: Goal status
A pure function SHALL report a level goal as on track when introduced cards up to the target level are at least the count expected today, interpolated linearly from the start date and count to the target date and total; otherwise as behind by the difference. When the budget caps the count below the pace, it SHALL report behind.

#### Scenario: On track
- **WHEN** 12 cards are expected and 14 are introduced
- **THEN** the status is on track

#### Scenario: Behind
- **WHEN** 12 cards are expected and 9 are introduced
- **THEN** the status is behind by 3 cards

### Requirement: Level goal lifecycle
A level goal SHALL become achieved once every non-suspended `.card` item up to its target level within the selected themes is introduced, and expired when the learning day after its date arrives without that. Achieved and expired goals SHALL NOT influence the daily plan.

#### Scenario: Expired
- **WHEN** the learning day after the target date arrives and cards remain
- **THEN** the goal is expired and pacing stops

### Requirement: Goal countdown on Today
While a level goal or exam is active, Today SHALL show learning days left and, for a level goal, cards left and the status «в графике» or «отстаёте на N карточек», with Russian plural forms for N and for days. An achieved or expired goal or exam SHALL show its end state once, then be hidden.

#### Scenario: Plural forms
- **WHEN** the user is behind by 1, 2 and 5 cards
- **THEN** Today reads «отстаёте на 1 карточку», «отстаёте на 2 карточки» and «отстаёте на 5 карточек»

#### Scenario: End state shown once
- **WHEN** a level goal has just been achieved
- **THEN** Today shows the achieved state on the next visit and not on later visits

### Requirement: Goal prompt after the first session
The goal SHALL be offered in the onboarding goal step. A user who has not completed the current onboarding and has no goal SHALL, after the first completed study session, be offered a dismissible goal prompt on Today through the post-session prompt slot; dismissing it SHALL leave no goal and SHALL NOT show the prompt again.

#### Scenario: Dismiss the prompt
- **WHEN** the user dismisses the goal prompt
- **THEN** no goal is stored and the prompt does not return

#### Scenario: Goal chosen in onboarding
- **WHEN** the user skipped the goal step in onboarding and finishes the first session
- **THEN** Today does not offer the goal prompt

