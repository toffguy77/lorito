## ADDED Requirements

### Requirement: Optional study goal with a target date
The user SHALL be able to set at most one study goal consisting of a target level within their scope and a target date later than today, either from the presets "Закрыть уровень" and "DELE A2" (target level A2, user-entered date) or as a custom level and date. The goal SHALL be optional, persisted in `UserSettings` as an optional field defaulting to none, and editable or removable in Settings.

#### Scenario: Set a DELE A2 goal
- **WHEN** the user picks the "DELE A2" preset and enters a date three months ahead
- **THEN** a goal with target level A2 and that date is saved

#### Scenario: Past date rejected
- **WHEN** the user enters a target date that is today or earlier
- **THEN** the goal cannot be saved

#### Scenario: No goal by default
- **WHEN** a user has never set a goal
- **THEN** no goal exists and the daily plan behaves as before

### Requirement: Goal pace
While a goal is active, a pure `Domain` function SHALL compute the daily new-card pace as the number of not-yet-introduced, non-suspended cards up to the target level within the selected themes, divided by the days from today through the target date inclusive, rounded up and clamped to at least 1 and at most 10.

#### Scenario: Even pace
- **WHEN** 30 cards remain and 10 days remain including today
- **THEN** the pace is 3

#### Scenario: Pace is capped
- **WHEN** 200 cards remain and 5 days remain
- **THEN** the pace is 10

#### Scenario: Deterministic
- **WHEN** the pace is computed twice with the same inputs and injected today
- **THEN** both results are equal

### Requirement: Goal status
A pure function SHALL report a goal as on track when the number of introduced cards up to the target level is at least the expected count, linearly interpolated from the count when the goal was created to the total at the target date; otherwise as behind by the difference. A goal whose pace is clamped at the maximum SHALL be reported as behind.

#### Scenario: On track
- **WHEN** the expected count for today is 12 and 14 cards are introduced
- **THEN** the status is on track

#### Scenario: Behind
- **WHEN** the expected count for today is 12 and 9 cards are introduced
- **THEN** the status is behind by 3 cards

### Requirement: Goal lifecycle
A goal SHALL become achieved once every non-suspended card up to its target level within the selected themes has been introduced, and expired once its target date has passed without that. Achieved and expired goals SHALL no longer influence the daily plan.

#### Scenario: Goal achieved
- **WHEN** the last remaining card up to the target level is introduced before the date
- **THEN** the goal becomes achieved and pacing stops

#### Scenario: Goal expired
- **WHEN** the day after the target date arrives and cards remain
- **THEN** the goal becomes expired and pacing stops

### Requirement: Goal countdown on Today
While a goal is active, the Today screen SHALL show the days left, the cards left to introduce, and the status as "в графике" or "отстаёте на N карточек". When a goal becomes achieved or expired, Today SHALL show its end state once and then hide the goal card.

#### Scenario: Countdown shown
- **WHEN** a goal is active with 20 days and 40 cards left and the user is on track
- **THEN** Today shows 20 days, 40 cards and "в графике"

#### Scenario: End state shown once
- **WHEN** a goal has just been achieved
- **THEN** Today shows the achieved state on the next visit and not on later visits

### Requirement: Goal step in onboarding
After the level and theme steps, onboarding SHALL offer an optional goal step with the presets and a skip action; skipping SHALL leave no goal. The step SHALL precede the reminder-time step when that step exists.

#### Scenario: Skip the goal
- **WHEN** the user skips the goal step
- **THEN** onboarding continues and no goal is saved
