## ADDED Requirements

### Requirement: Adaptive placement question selection
The placement test SHALL select questions one at a time from the bundled auto-checkable multiple-choice, picture-matching and word-order exercises, starting at level A2, stepping up a level after two consecutive correct answers at the current level and down a level after a wrong answer. Selection SHALL be a pure `Domain` function of the exercise pool, an injected seed and the answer history.

#### Scenario: Two correct answers step up
- **WHEN** the user answers two A2 questions correctly in a row
- **THEN** the next question is a B1 exercise

#### Scenario: Wrong answer steps down
- **WHEN** the user answers a B1 question incorrectly
- **THEN** the next question is an A2 exercise

#### Scenario: Deterministic sequence
- **WHEN** the selection function is called twice with the same pool, seed and answer history
- **THEN** it returns the same next exercise both times

### Requirement: Placement stopping rule and proposed level
The test SHALL stop after at most 12 questions, or earlier once a level has been passed and the level above it failed. It SHALL propose the highest level with at least two correct answers and no more wrong than correct answers at that level, or A1 when no level qualifies.

#### Scenario: Budget ends the test
- **WHEN** the user has answered 12 questions
- **THEN** the test ends and shows the result

#### Scenario: Proposed level
- **WHEN** the user answered A2 questions 3 of 3 correctly and B1 questions 1 of 3 correctly
- **THEN** the proposed level is A2

#### Scenario: No level qualifies
- **WHEN** the user answered every question incorrectly
- **THEN** the proposed level is A1

### Requirement: Placement result shows personal traps
The result screen SHALL show the proposed level and up to three trap items, each being the first «Частые ошибки» item of a card whose exercise the user failed in the test, one item per card, most recent failure first. Cards without a mistakes section SHALL be skipped. When no trap qualifies, the trap list SHALL be omitted.

#### Scenario: Traps from failed exercises
- **WHEN** the user failed exercises of cards A1-07 and A1-09, both with mistakes sections
- **THEN** the result shows one trap from each of those cards

#### Scenario: No failures
- **WHEN** the user answered every question correctly
- **THEN** the result shows the level and no trap list

### Requirement: Placement test does not change study state
Answers in the placement test SHALL NOT modify any card's `CardReview`, SHALL NOT write study events or exercise attempts, and SHALL NOT affect the streak.

#### Scenario: SRS untouched
- **WHEN** the user completes the placement test
- **THEN** no `CardReview`, study event or exercise attempt has been written
