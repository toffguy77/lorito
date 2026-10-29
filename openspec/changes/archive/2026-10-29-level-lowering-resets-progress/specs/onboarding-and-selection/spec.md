## MODIFIED Requirements

### Requirement: Settings can change scope after onboarding
After onboarding, a settings screen SHALL let the user change the target level and the theme selection. Changing the target level SHALL re-scope the included content and the set of selectable themes; raising the level SHALL widen scope and lowering it SHALL narrow scope. Lowering the level SHALL reset progress above the new level (see «Lowering the level resets progress above it»). Any persisted change to target level or theme selection SHALL trigger a `daily-plan` recompute (referenced capability).

#### Scenario: Raising the level widens scope
- **WHEN** the current target level is `A2` and the user changes it to `B1` in settings
- **THEN** the included levels become `A1`, `A2`, `B1`
- **THEN** the themes selectable in settings now include `B1` themes
- **THEN** a `daily-plan` recompute is triggered

#### Scenario: Lowering the level narrows scope
- **WHEN** the current target level is `B1` and the user changes it to `A1` in settings
- **THEN** the included levels become only `A1`
- **THEN** themes that belonged solely to `A2` or `B1` are no longer in scope
- **THEN** a `daily-plan` recompute is triggered

#### Scenario: Changing theme selection triggers recompute
- **WHEN** the user changes the selected themes in settings to a different studyable set
- **THEN** `UserSettings.selectedThemes` is updated and a `daily-plan` recompute is triggered

### Requirement: Re-run onboarding from Settings
Settings SHALL offer «Пройти настройку заново», which runs all onboarding steps prefilled with the current settings. It SHALL NOT change study progress, except the reset that lowering the level causes, SHALL NOT start a study session or grant the first-session allowance, and SHALL be closable at any step, keeping the choices saved in earlier steps. Skipping its reminder step SHALL keep the current reminder settings.

#### Scenario: Re-run keeps progress
- **WHEN** a user with reviews re-runs the setup and changes the target level from A2 to B1
- **THEN** the level is B1, all review states are unchanged and Today opens without a session

#### Scenario: Reminder skip in a re-run
- **WHEN** a user with a 20:00 reminder skips the reminder step of a re-run
- **THEN** the 20:00 reminder stays enabled

## ADDED Requirements

### Requirement: Lowering the level resets progress above it
Persisting a target level lower than the stored one SHALL delete the review state of every grammar card whose level is above the new target, so those cards leave the daily plan and are introduced as new again only if the level is raised. The study log and the review state of words, conjugations, CCSE items and cards at or below the new level SHALL be kept. When at least one card would lose progress, Settings and the onboarding level step SHALL first ask for confirmation stating the number of cards; cancelling SHALL keep the stored level and all progress.

#### Scenario: Lowering B1 to A1 resets B1 and A2 cards
- **WHEN** a user with review states for `A1-01`, `A2-03` and `B1-02` confirms lowering the level from B1 to A1
- **THEN** only the review state of `A1-01` remains, and the next plan contains no A2 or B1 card

#### Scenario: Cancelling keeps everything
- **WHEN** the user cancels the confirmation
- **THEN** the level and all review states are unchanged

#### Scenario: No confirmation without progress above
- **WHEN** the user lowers the level and no card above the new level has a review state
- **THEN** the level changes without a confirmation
