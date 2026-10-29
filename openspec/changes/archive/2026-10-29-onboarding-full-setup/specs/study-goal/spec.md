## MODIFIED Requirements

### Requirement: Goal prompt after the first session
The goal SHALL be offered in the onboarding goal step. A user who has not completed the current onboarding and has no goal SHALL, after the first completed study session, be offered a dismissible goal prompt on Today through the post-session prompt slot; dismissing it SHALL leave no goal and SHALL NOT show the prompt again.

#### Scenario: Dismiss the prompt
- **WHEN** the user dismisses the goal prompt
- **THEN** no goal is stored and the prompt does not return

#### Scenario: Goal chosen in onboarding
- **WHEN** the user skipped the goal step in onboarding and finishes the first session
- **THEN** Today does not offer the goal prompt
