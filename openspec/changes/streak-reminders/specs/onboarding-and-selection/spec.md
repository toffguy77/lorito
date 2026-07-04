## ADDED Requirements

### Requirement: Onboarding reminder-time step
Onboarding SHALL present a final, skippable reminder-time step after the level/theme selection and before completing onboarding. The step SHALL offer a default reminder time (20:00 local). Choosing a time and confirming SHALL drive the existing `reminders` notification authorization flow and, on success, SHALL persist `reminderConfig` with `enabled = true` and the chosen time as the first reminder time. Skipping the step SHALL leave reminders disabled (`reminderConfig.enabled = false`) and SHALL NOT request authorization. Completing onboarding SHALL NOT be blocked by this step (it remains optional), and this step SHALL NOT redefine the `reminderConfig` shape owned by `reminders`/`app-foundation`.

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
