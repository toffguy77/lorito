## ADDED Requirements

### Requirement: Goal-raised new-card limit
When a level goal is active, the new-card limit supplied to the composer for a learning day SHALL be the larger of the goal pace and `UserSettings.dailyNewCardCount`, capped by the daily new-introduction budget; otherwise it SHALL be `dailyNewCardCount` as before. The composer's selection and ordering rules SHALL be unchanged.

#### Scenario: Goal raises new cards
- **WHEN** a level goal is active with a pace of 3 and `dailyNewCardCount` is 1
- **THEN** the day's queue introduces up to 3 new cards

#### Scenario: No goal keeps the setting
- **WHEN** no level goal is active and `dailyNewCardCount` is 2
- **THEN** the day's queue introduces up to 2 new cards
