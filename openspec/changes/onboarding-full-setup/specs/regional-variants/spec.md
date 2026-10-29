## MODIFIED Requirements

### Requirement: Variant prompt after the first session
The variant SHALL be asked in the onboarding variant step and SHALL always be changeable in Settings. A learner who has not completed the current onboarding SHALL, after the first completed study session, see a one-time prompt on Today to choose the variant; dismissing it SHALL keep the current value.

#### Scenario: Prompt once
- **WHEN** a learner who has not completed the current onboarding completes their first session and returns to Today
- **THEN** the variant prompt is shown, and it is not shown again after a choice or dismissal

#### Scenario: Asked in onboarding
- **WHEN** a new learner goes through onboarding
- **THEN** the variant step is shown with Spain preselected, and Today later shows no variant prompt
