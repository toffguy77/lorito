## MODIFIED Requirements

### Requirement: New-card count limit
The composer SHALL introduce at most `UserSettings.dailyNewCardCount` new cards in a single learning day, counting cards already introduced earlier on the same learning day (per `review-items` introduction accounting) against that limit, so recomputing the plan during the day never raises the total.

#### Scenario: New-card count is honored
- **WHEN** `dailyNewCardCount` is 1 and many cards are eligible as new
- **THEN** exactly one new card is added to the queue

#### Scenario: Fewer eligible than the limit
- **WHEN** `dailyNewCardCount` is 5 but only 2 cards are eligible as new
- **THEN** exactly those 2 new cards are added to the queue

#### Scenario: Recomputing after grading the new card
- **WHEN** `dailyNewCardCount` is 1, the day's new card has been graded and the plan is composed again on the same learning day
- **THEN** zero new cards are added to the queue
