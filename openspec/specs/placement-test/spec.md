# placement-test Specification

## Purpose
TBD - created by archiving change placement-test-and-first-session. Update Purpose after archive.
## Requirements
### Requirement: Block-based placement questions
The placement test SHALL ask questions in blocks of 3 per level, drawn from the bundled multiple-choice, picture-matching and word-order exercises of that level, starting with A2 and never stopping inside a block. Question selection SHALL be a pure `Domain` function of the exercise pool, an injected seed and the answer history.

#### Scenario: Full block asked
- **WHEN** the user answers the first A2 question incorrectly
- **THEN** the remaining two A2 questions are still asked

#### Scenario: Deterministic sequence
- **WHEN** the selection function is called twice with the same pool, seed and answer history
- **THEN** it returns the same next exercise both times

### Requirement: Level pass and stopping rule
A level SHALL pass when at least 2 of its 3 questions are answered correctly. After a passed level the test SHALL continue with the next level up; after a failed level, or after C2 passes, it SHALL stop. If A2 fails, the test SHALL ask one A1 block and then stop.

#### Scenario: Climb after a pass
- **WHEN** the user answers 3 of 3 A2 questions correctly
- **THEN** the next block is B1

#### Scenario: Stop after a failed level
- **WHEN** the user answers 1 of 3 B1 questions correctly after passing A2
- **THEN** the test ends

#### Scenario: A2 failed
- **WHEN** the user answers 1 of 3 A2 questions correctly
- **THEN** one A1 block is asked and the test ends

### Requirement: Proposed level and known levels
The test SHALL report the highest passed level as known, together with every level below it, and SHALL propose as target level the level after the highest passed one, or C2 when C2 passed, or A1 when no level passed.

#### Scenario: A2 passed, B1 failed
- **WHEN** A2 was answered 3 of 3 and B1 1 of 3
- **THEN** known levels are A1 and A2 and the proposed target level is B1

#### Scenario: Nothing passed
- **WHEN** A2 and A1 both failed
- **THEN** there are no known levels and the proposed target level is A1

### Requirement: Placement result shows personal traps
The result screen SHALL show the proposed level and up to three trap items, each the first «Частые ошибки» item of a card whose exercise the user failed, one per card, most recent failure first, skipping cards without a mistakes section; with no trap the list SHALL be omitted.

#### Scenario: Traps from failed exercises
- **WHEN** the user failed exercises of cards A1-07 and A1-09, both with mistakes sections
- **THEN** the result shows one trap from each of those cards

### Requirement: Optional skip of known cards
The result screen SHALL offer «Пропустить то, что я знаю». Only when the user turns it on, each card whose exercise was answered correctly in the test at a known level SHALL get a review state produced by the scheduler for grade Хорошо on a new card; seeding SHALL NOT write study events, affect the streak, or spend the new-introduction budget. Without the option, the test SHALL write no review state.

#### Scenario: Option on
- **WHEN** the user answered an A1-07 exercise correctly, A1 is known, and the option is on
- **THEN** A1-07 has a review state equal to the scheduler's result for Хорошо on a new card and no study event is written

#### Scenario: Option off
- **WHEN** the user completes the test without the option
- **THEN** no review state, study event or exercise attempt has been written

