## ADDED Requirements

### Requirement: Placement and first-session events
The event taxonomy SHALL include `placementStarted`, `placementCompleted` with the proposed level, the highest known level (or none) and the number of questions, `placementSkipKnownApplied` with the number of seeded cards, and `firstSessionStarted` with the number of new cards; all payloads SHALL be enumerated values, integers or booleans.

#### Scenario: Test completed
- **WHEN** the user completes the placement test with proposal B1 after 6 questions
- **THEN** a `placementCompleted` event with level B1, known level A2 and 6 questions is recorded

#### Scenario: First session
- **WHEN** the first session opens after onboarding with 3 new cards
- **THEN** a `firstSessionStarted` event with 3 new cards is recorded
