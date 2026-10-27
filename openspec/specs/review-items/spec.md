# review-items Specification

## Purpose
TBD - created by archiving change learning-platform-foundation. Update Purpose after archive.
## Requirements
### Requirement: Item kinds from identifiers
The `Domain` layer SHALL classify every review and study-event identifier into a kind by a pure parser: a grammar card id (`A1-07`) is `card`, `conj:<verb>:<tense>` is `conjugation`, `word:<lemma>` is `word`, `ccse:<id>` is `ccse`, and anything else is `unknown`. Unknown items SHALL be kept in storage and ignored by planners.

#### Scenario: Prefixes map to kinds
- **WHEN** the ids `A1-07`, `conj:hablar:presente`, `word:casa` and `ccse:0123` are parsed
- **THEN** their kinds are card, conjugation, word and ccse respectively

#### Scenario: Unknown id is ignored by planning
- **WHEN** a review state has the id `foo:bar`
- **THEN** it is kept in storage and never enters a study queue

### Requirement: Card counts include only cards
Every user-facing count or status that speaks about cards — Today progress and all-done state, studied today/week/all-time, session summaries, catalog statuses, long-term memory — SHALL count only items of kind card unless the requirement that defines it names other kinds explicitly.

#### Scenario: Drills do not inflate card progress
- **WHEN** the user grades two cards and ten conjugation items today
- **THEN** Today shows two cards studied and the stats count two cards for today

### Requirement: Local learning day
The learning day SHALL be the local calendar day in the device's current time zone, with the boundary at local midnight. Every day-based rule — due dates, the daily plan, streaks, "today" counts, trap of the day — SHALL use this learning day. Historical events SHALL be bucketed by learning day when read, without data migration.

#### Scenario: Evening in Buenos Aires
- **WHEN** a user in UTC−3 studies at 22:00 local time
- **THEN** the session counts for that local date, not for the next UTC date

#### Scenario: Due today means local today
- **WHEN** a card's due date is the current local date
- **THEN** it is due today even if the UTC date is different

### Requirement: Introduction accounting
An item SHALL count as introduced on the learning day of its earliest graded study event. Every daily limit on new items SHALL be reduced by the number of items of that kind already introduced on the current learning day, so recomputing the plan during the day never offers more new items than the limit.

#### Scenario: Limit holds after grading
- **WHEN** the new-card limit is 1, the user grades the one new card and the plan is recomputed the same day
- **THEN** no further new card is offered that day

#### Scenario: Next day restores the allowance
- **WHEN** the learning day advances
- **THEN** the full new-card limit is available again

### Requirement: Combined daily budget
New items introduced per learning day across all kinds SHALL NOT exceed a combined budget (default 10). Conjugation and word quotas SHALL default to 0 for every user until the user enables them. When the budget binds, new items SHALL be allocated in the order cards, conjugations, words, CCSE.

#### Scenario: Budget caps the sum
- **WHEN** the budget is 10 and the enabled quotas are cards 5, conjugations 5 and words 5
- **THEN** at most 10 new items are introduced: 5 cards and 5 conjugations

#### Scenario: Existing user sees no new drills
- **WHEN** an existing user updates the app and has not enabled conjugations or words
- **THEN** their daily plan contains only grammar cards

### Requirement: First grade per day updates memory
Applying a grade SHALL update an item's review state only if the item has no earlier graded study event on the same learning day. Later grades of that item on the same day (exercises, in-session relearn) SHALL be recorded as study events and SHALL leave the review state unchanged.

#### Scenario: Several correct exercises on one day
- **WHEN** a card is graded Хорошо in the session and then answered correctly in three exercises the same day
- **THEN** its review state changes once and four study events are recorded

#### Scenario: Next day updates again
- **WHEN** the same card is graded on the following learning day
- **THEN** its review state is updated

