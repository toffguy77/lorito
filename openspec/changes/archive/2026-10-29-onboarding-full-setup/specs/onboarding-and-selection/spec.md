## MODIFIED Requirements

### Requirement: First-run onboarding is shown once
On the very first launch the app SHALL present the onboarding flow before the main flow. Once onboarding completes, the app SHALL record on the device that the current onboarding version was completed and SHALL NOT present onboarding again on subsequent launches; those launches SHALL open directly to the main flow. A device that completed only an earlier onboarding version SHALL present the current onboarding once, prefilled with the stored settings, without the first-session start.

#### Scenario: First launch shows onboarding
- **WHEN** the app launches and onboarding has never been completed
- **THEN** the onboarding flow is presented before the main flow

#### Scenario: Later launches skip onboarding
- **WHEN** the app launches and the current onboarding version was completed on this device
- **THEN** the main flow is shown directly and onboarding is not presented

#### Scenario: Update from an earlier version
- **WHEN** a user who completed onboarding in version 1.5 launches the updated app
- **THEN** the full onboarding is shown once with their level, themes and other settings preselected, and no study session starts automatically when it ends

### Requirement: Onboarding step order
Onboarding SHALL run its steps in this order: level selection (manual list or placement test), theme narrowing, goal and exam, Spanish variant, pace, sound, then the reminder-time step, which SHALL remain last. Completing onboarding SHALL answer the post-session goal, variant and words prompts, so Today does not offer them afterwards.

#### Scenario: Order on first run
- **WHEN** a new user goes through onboarding
- **THEN** the steps are level, themes, goal, variant, pace, sound and reminders, in that order

#### Scenario: No prompts after onboarding
- **WHEN** a user who completed onboarding finishes a study session and returns to Today
- **THEN** Today offers no goal, variant or words prompt

## ADDED Requirements

### Requirement: Onboarding setup steps
The goal step SHALL offer no goal (the default), a level goal with a date, an exam (DELE A2 or CCSE) with a date, and the «DELE A2» preset, with the same rules as Settings «Цель». The variant step SHALL offer Spain, Latin America and Rioplatense, preselecting the current value. The pace step SHALL set new cards per day (1–10), words on or off with words per day (enabling sets 5) and conjugations on or off with conjugations per day (enabling sets 3). The sound step SHALL set the speech rate and playback in silent mode. Each of these steps SHALL be skippable, keeping the current values, and SHALL save its choices when the user moves on.

#### Scenario: Defaults kept
- **WHEN** a new user skips the goal, variant, pace and sound steps
- **THEN** there is no goal, the variant is Spain, 1 new card per day, words and conjugations are off and the sound settings are unchanged

#### Scenario: Exam set in onboarding
- **WHEN** the user picks a CCSE exam on a future date in the goal step and continues
- **THEN** the exam is stored with that date and Today shows its countdown

### Requirement: Re-run onboarding from Settings
Settings SHALL offer «Пройти настройку заново», which runs all onboarding steps prefilled with the current settings. It SHALL NOT change study progress, SHALL NOT start a study session or grant the first-session allowance, and SHALL be closable at any step, keeping the choices saved in earlier steps. Skipping its reminder step SHALL keep the current reminder settings.

#### Scenario: Re-run keeps progress
- **WHEN** a user with reviews re-runs the setup and changes the target level from A2 to B1
- **THEN** the level is B1, all review states are unchanged and Today opens without a session

#### Scenario: Reminder skip in a re-run
- **WHEN** a user with a 20:00 reminder skips the reminder step of a re-run
- **THEN** the 20:00 reminder stays enabled

### Requirement: New cards per day setting
New grammar cards per day SHALL be editable from 1 to 10 in the onboarding pace step and in Settings «Повторение», persisted as `dailyNewCardCount` and still within the daily new-introduction budget.

#### Scenario: Pace changed in Settings
- **WHEN** the user sets 4 new cards per day in Settings
- **THEN** `dailyNewCardCount` is 4 and the next plan offers up to 4 new cards
