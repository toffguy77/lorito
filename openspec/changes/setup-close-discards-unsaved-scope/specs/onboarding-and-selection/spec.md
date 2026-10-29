## MODIFIED Requirements

### Requirement: Re-run onboarding from Settings
Settings SHALL offer «Пройти настройку заново», which runs all onboarding steps prefilled with the current settings. It SHALL NOT change study progress, except the reset that lowering the level causes, SHALL NOT start a study session or grant the first-session allowance, and SHALL be closable at any step, keeping the choices saved in earlier steps and discarding unsaved ones, so Settings then shows the stored level and themes. Skipping its reminder step SHALL keep the current reminder settings.

#### Scenario: Re-run keeps progress
- **WHEN** a user with reviews re-runs the setup and changes the target level from A2 to B1
- **THEN** the level is B1, all review states are unchanged and Today opens without a session

#### Scenario: Reminder skip in a re-run
- **WHEN** a user with a 20:00 reminder skips the reminder step of a re-run
- **THEN** the 20:00 reminder stays enabled

#### Scenario: Closing before the scope is saved
- **WHEN** a user on A1 picks B1 at the level step of a re-run and closes it there
- **THEN** the stored level stays A1 and Settings shows A1 selected
