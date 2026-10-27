## ADDED Requirements

### Requirement: Goal-paced new-card limit
When a study goal is active, the new-card limit supplied to the composer for a day SHALL be the goal pace computed for that day; otherwise it SHALL be `UserSettings.dailyNewCardCount`. The composer's selection and ordering rules SHALL be unchanged.

#### Scenario: Goal pace drives new cards
- **WHEN** a goal is active with a pace of 3 and `dailyNewCardCount` is 1
- **THEN** the day's queue introduces up to 3 new cards

#### Scenario: No goal keeps the setting
- **WHEN** no goal is active and `dailyNewCardCount` is 2
- **THEN** the day's queue introduces up to 2 new cards
