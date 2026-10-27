## ADDED Requirements

### Requirement: Vocabulary counts beside the card plan
The day's plan SHALL report, alongside the card counts, the number of due and new word items produced by the vocabulary planner, with new words limited by `dailyNewWordCount` independently of `dailyNewCardCount`. Word items SHALL NOT be added to the card queue.

#### Scenario: Separate quotas
- **WHEN** `dailyNewCardCount` is 4 and `dailyNewWordCount` is 10
- **THEN** up to 4 new cards and up to 10 new words are planned, and neither limit affects the other

#### Scenario: Count report includes words
- **WHEN** the Today screen reads the plan's counts
- **THEN** it can show due and new word counts without iterating any queue
