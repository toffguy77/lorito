## MODIFIED Requirements

### Requirement: Pure deterministic scheduler
The scheduler SHALL be a pure function in the `Domain` layer that, given the current review state, a grade, an injected "today" and a desired retention, returns the next review state. It SHALL NOT perform I/O, SHALL NOT import SwiftUI, SwiftData, or CloudKit, SHALL NOT read any ambient clock (e.g. `Date.now`), and SHALL NOT apply random fuzz. For identical inputs it SHALL always produce identical outputs.

#### Scenario: Same inputs produce same output
- **WHEN** the scheduler is called twice with the same review state, grade, "today" and desired retention
- **THEN** both calls return identical next review state (stability, difficulty, lastReviewDate, interval, repetitions, dueDate, status)

#### Scenario: No hidden clock
- **WHEN** the scheduler computes a next `dueDate`
- **THEN** the result depends only on the injected "today" and the inputs, never on the wall-clock time of execution

### Requirement: Four grades accepted
The scheduler SHALL accept exactly four grades — `again` (Опять), `hard` (Трудно), `good` (Хорошо), `easy` (Легко) — mapped to FSRS ratings 1–4, and SHALL record the applied grade as the review's `lastGrade`. Each grade SHALL deterministically transform `stability`, `difficulty`, `interval`, `repetitions`, `dueDate`, and `status`.

#### Scenario: Grade is recorded
- **WHEN** any grade is applied to a review
- **THEN** the returned review's `lastGrade` equals the applied grade

#### Scenario: Each grade is handled distinctly
- **WHEN** the same starting review state is graded `again`, `hard`, `good`, and `easy` separately
- **THEN** each grade produces its own distinct next review state per the rules in this spec

### Requirement: First review of a new card
When a card with status `new` is reviewed for the first time, the scheduler SHALL move it out of `new` and initialise its stability and difficulty from the FSRS default parameters for the given grade. A passing grade (`hard`, `good`, or `easy`) SHALL set `repetitions` to 1 and a short first interval, with `easy` longer than `good` and `good` longer than or equal to `hard`. `again` on a `new` card SHALL follow the relearn rule.

#### Scenario: New card graded good
- **WHEN** a `new` card is graded `good` with "today" given
- **THEN** `repetitions` becomes 1, stability and difficulty are set, `dueDate` is a short interval from "today", and the card is no longer `new`

#### Scenario: New card graded easy gets a longer first interval
- **WHEN** a `new` card is graded `easy`
- **THEN** its first interval (and resulting `dueDate`) is longer than it would have been for `good`

#### Scenario: New card graded again enters relearning
- **WHEN** a `new` card is graded `again`
- **THEN** the card follows the `again` relearn rule (status `learning`, `repetitions` 0, due "today")

### Requirement: Suspended cards excluded from scheduling
Cards with status `suspended` SHALL be excluded from scheduling. The scheduler SHALL treat applying a grade to a `suspended` card as a no-op: it SHALL NOT change `stability`, `difficulty`, `interval`, `repetitions`, `dueDate`, or `status`. Selecting due cards SHALL never include `suspended` cards regardless of their `dueDate`.

#### Scenario: Grading a suspended card is a no-op
- **WHEN** a `suspended` card is passed to the scheduler with any grade
- **THEN** its stability, difficulty, interval, repetitions, dueDate, and status are unchanged

#### Scenario: Suspended cards are not due
- **WHEN** due cards are selected for a given "today"
- **THEN** no `suspended` card is included even if its `dueDate` is on or before "today"

## REMOVED Requirements

### Requirement: Again resets and relearns
**Reason**: Its ease-factor rule no longer applies; replaced by "Again lapses and relearns" with FSRS stability and difficulty.
**Migration**: Same observable reset (repetitions 0, status learning, due today); see the new requirement.

### Requirement: Review interval growth
**Reason**: Intervals no longer multiply by an ease factor; replaced by "Retention-based review interval".
**Migration**: See the new requirement; captions show the new intervals.

### Requirement: EaseFactor floor
**Reason**: FSRS has no ease factor; difficulty bounded to 1–10 replaces it.
**Migration**: Existing `easeFactor` values are read once by the SM-2 migration to derive difficulty and are otherwise left untouched.

### Requirement: Hard lowers ease and yields a smaller interval
**Reason**: Ease no longer exists; the relation between `hard` and `good` intervals is covered by "Interval ordering across grades".
**Migration**: None; behavior is expressed by the new ordering requirement.

### Requirement: Easy grants a bonus
**Reason**: FSRS derives the `easy` interval from its own stability update; the ordering guarantee replaces the explicit bonus rule.
**Migration**: None; covered by "Interval ordering across grades".

## ADDED Requirements

### Requirement: Again lapses and relearns
A grade of `again` SHALL reset `repetitions` to 0, set `status` to `learning`, and set the interval to 0 so the card is due "today"; re-showing it within the session follows `learning-platform-foundation`. Stability SHALL be reduced by the FSRS post-lapse rule and difficulty SHALL increase, never above 10.

#### Scenario: Again resets repetitions and moves to learning
- **WHEN** a card in `review` with `repetitions` of 4 is graded `again`
- **THEN** `repetitions` becomes 0, `status` becomes `learning`, and `dueDate` is "today"

#### Scenario: Again lowers stability and raises difficulty
- **WHEN** a `review` card is graded `again` as its first grade of the learning day
- **THEN** its stability is lower and its difficulty higher than before, with difficulty at most 10

### Requirement: Hard on a learning card
A `learning` card graded `hard` SHALL stay in `learning`, never return to `new`, keep its `repetitions`, update its memory state by the FSRS rule, and get an interval of at least 1 day. A `learning` card graded `good` or `easy` SHALL graduate to `review` as required by "Graduating from learning to review".

#### Scenario: Hard keeps learning
- **WHEN** a `learning` card is graded `hard`
- **THEN** its status is `learning`, its `repetitions` is unchanged, and its `dueDate` is at least 1 day after "today"

### Requirement: Retention-based review interval
For a card in `review` graded with a passing grade, the scheduler SHALL update stability by the FSRS rule and set the next `interval` to the whole number of days at which predicted retrievability falls to the desired retention, clamped between 1 day and the maximum interval. `dueDate` SHALL be "today" plus that interval and `repetitions` SHALL be incremented.

#### Scenario: Default retention gives interval equal to stability
- **WHEN** a `review` card is graded `good`, its new stability is 12.0 days, and desired retention is 0.9
- **THEN** the next `interval` is 12 days

#### Scenario: Higher retention shortens intervals
- **WHEN** the same `review` card is graded `good` with desired retention 0.95 versus 0.9
- **THEN** the 0.95 interval is shorter than or equal to the 0.9 interval

#### Scenario: Repetitions increment on good
- **WHEN** a `review` card is graded `good`
- **THEN** `repetitions` is incremented by 1

### Requirement: FSRS memory state
Each reviewed card SHALL carry an FSRS memory state — stability in days, difficulty on a 1–10 scale, and the date of the last memory-updating review — stored as optional fields of the review state, using FSRS-6 with its default parameters pinned in `Domain`. Cards never reviewed SHALL have no memory state.

#### Scenario: Never reviewed card
- **WHEN** a card has status `new`
- **THEN** its stability, difficulty and last review date are absent

#### Scenario: Pinned defaults
- **WHEN** the scheduler parameters are inspected in tests
- **THEN** they equal the 21 FSRS-6 default parameters

### Requirement: Elapsed time from last review
The scheduler SHALL compute elapsed time as whole learning days between the stored last review date and "today", and SHALL set the last review date to "today" whenever a grade updates the memory state. Grades that `learning-platform-foundation` logs without updating memory SHALL NOT change it.

#### Scenario: Elapsed days
- **WHEN** a card last reviewed 10 learning days ago is graded today
- **THEN** the scheduler uses 10 days of elapsed time and stores today as the last review date

### Requirement: Interval ordering across grades
For any review state and "today", the intervals of the four grades SHALL satisfy again ≤ hard ≤ good ≤ easy, and easy SHALL be strictly longer than good whenever good is below the maximum interval. At the maximum interval, good and easy MAY be equal.

#### Scenario: Ordered below the cap
- **WHEN** the interval preview is computed for a `review` card whose good interval is below the maximum
- **THEN** Опять ≤ Трудно ≤ Хорошо and Легко is longer than Хорошо

#### Scenario: At the cap
- **WHEN** both good and easy would exceed the maximum interval
- **THEN** both are the maximum interval

### Requirement: Captions at the maximum interval
When two grades produce the same interval because of the maximum-interval cap, their grade-button captions SHALL be allowed to show the same text; captions SHALL otherwise reflect the distinct intervals.

#### Scenario: Equal captions at the cap
- **WHEN** good and easy both yield 365 days
- **THEN** both captions show the same interval text

### Requirement: Desired retention setting
The user SHALL be able to set a desired retention between 80% and 95% in Settings («Целевая запоминаемость»), defaulting to 90%, persisted as a synced user setting. The value SHALL be passed to the scheduler and SHALL affect only intervals computed after the change.

#### Scenario: Change does not rewrite due dates
- **WHEN** the user changes desired retention from 90% to 95%
- **THEN** existing due dates are unchanged and the next grade uses 95%

### Requirement: Lossless migration from SM-2 state
A review state with status `review` or `learning` and no valid FSRS memory state SHALL be converted, the first time it is scheduled, by a pure function: stability from its interval, difficulty from its ease factor (both clamped), last review date = due date minus interval when absent. Migration SHALL keep the ease factor and SHALL NOT change due dates of cards that are not being graded.

#### Scenario: Migrated review card
- **WHEN** a `review` card with interval 20 days, ease 2.5, due in 5 days and no memory state is graded today
- **THEN** the scheduler first derives stability 20 days, a mid-range difficulty and a last review date 15 days ago, then applies the grade

#### Scenario: Ungraded cards keep due dates
- **WHEN** the app updates to the FSRS build
- **THEN** no card's `dueDate` changes until that card is graded

### Requirement: Scheduler version consistency
Each FSRS-updated review state SHALL record a scheduler version and the due date the FSRS scheduler computed. If a state's version is not FSRS or its stored due date differs from its `dueDate` (e.g. written by an older app on another device), the memory state SHALL be treated as invalid and re-migrated from the current fields.

#### Scenario: Older app edited the card
- **WHEN** a card with an FSRS memory state is graded by an older SM-2 build on another device, changing its `dueDate`, and then synced
- **THEN** the FSRS build re-migrates that card's memory state before the next grade

### Requirement: Maximum interval
No interval SHALL exceed a maximum constant of 365 days defined in `Domain`.

#### Scenario: Very stable card
- **WHEN** a card's computed interval would be 900 days
- **THEN** the scheduled interval is 365 days
