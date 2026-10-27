## ADDED Requirements

### Requirement: Onboarding reminder-time step
Onboarding SHALL end with a skippable reminder-time step (default 20:00 local). Confirming a time SHALL run the existing `reminders` authorization flow and, on success, persist `reminderConfig` enabled with that time first. Skipping SHALL leave reminders disabled without requesting authorization. The step SHALL NOT block completing onboarding or redefine `reminderConfig`.

#### Scenario: Setting a time enables reminders
- **WHEN** the user picks a reminder time of 20:00 in the onboarding step and confirms, and authorization is granted
- **THEN** `reminderConfig.enabled` is true and `reminderConfig` contains 20:00 as its first reminder time, persisted before onboarding completes

#### Scenario: Skipping leaves reminders off
- **WHEN** the user skips the reminder-time step
- **THEN** `reminderConfig.enabled` is false, no authorization is requested, and onboarding still completes

#### Scenario: Default time is offered
- **WHEN** the reminder-time step is shown
- **THEN** a default reminder time of 20:00 is presented as the initial selection

#### Scenario: Denied authorization does not block onboarding
- **WHEN** the user confirms a reminder time but notification authorization is denied
- **THEN** onboarding still completes and the app follows the `reminders` denied-authorization guidance rather than scheduling
