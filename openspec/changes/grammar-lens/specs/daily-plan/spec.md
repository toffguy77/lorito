## ADDED Requirements

### Requirement: User-requested new items
The daily plan SHALL accept a set of user-requested items without review state, each with its request time, and SHALL introduce them first among the day's new items, oldest request first, within the combined daily new-introduction budget; it SHALL NOT change the schedule of items that already have review state.

#### Scenario: Requested card first
- **WHEN** card A1-07 was requested and the budget allows 4 new items
- **THEN** A1-07 is the first new item of the day and at most 3 other new items follow

#### Scenario: Budget exhausted
- **WHEN** 6 cards were requested and the budget allows 4 new items
- **THEN** the 4 oldest requests are introduced today and the rest on later days
