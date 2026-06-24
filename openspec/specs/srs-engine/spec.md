# srs-engine Specification

## Purpose
TBD - created by archiving change srs-engine. Update Purpose after archive.
## Requirements
### Requirement: Pure deterministic scheduler
The scheduler SHALL be a pure function in the `Domain` layer that, given the current review state, a grade, and an injected "today", returns the next review state. It SHALL NOT perform I/O, SHALL NOT import SwiftUI, SwiftData, or CloudKit, and SHALL NOT read any global or ambient clock (e.g. `Date.now`). For identical inputs it SHALL always produce identical outputs.

#### Scenario: Same inputs produce same output
- **WHEN** the scheduler is called twice with the same review state, the same grade, and the same "today"
- **THEN** both calls return identical next review state (easeFactor, interval, repetitions, dueDate, status)

#### Scenario: No hidden clock
- **WHEN** the scheduler computes a next `dueDate`
- **THEN** the result depends only on the injected "today" and the inputs, never on the wall-clock time of execution

### Requirement: Four grades accepted
The scheduler SHALL accept exactly four grades — `again` (Опять), `hard` (Трудно), `good` (Хорошо), `easy` (Легко) — and SHALL record the applied grade as the review's `lastGrade`. Each grade SHALL deterministically transform `easeFactor`, `interval`, `repetitions`, `dueDate`, and `status`.

#### Scenario: Grade is recorded
- **WHEN** any grade is applied to a review
- **THEN** the returned review's `lastGrade` equals the applied grade

#### Scenario: Each grade is handled distinctly
- **WHEN** the same starting review state is graded `again`, `hard`, `good`, and `easy` separately
- **THEN** each grade produces its own distinct next review state per the rules in this spec

### Requirement: First review of a new card
When a card with status `new` is reviewed for the first time, the scheduler SHALL move it out of `new`. A passing grade (`hard`, `good`, or `easy`) SHALL set `repetitions` to 1 and assign a short initial interval that places `dueDate` on or shortly after "today", with `easy` yielding a longer first interval than `good`, and `good` longer than or equal to `hard`. A failing grade (`again`) on a `new` card SHALL follow the relearn rule.

#### Scenario: New card graded good
- **WHEN** a `new` card is graded `good` with "today" given
- **THEN** `repetitions` becomes 1 and `dueDate` is set to a short interval from "today" (a small number of days), and the card is no longer `new`

#### Scenario: New card graded easy gets a longer first interval
- **WHEN** a `new` card is graded `easy`
- **THEN** its first interval (and resulting `dueDate`) is longer than it would have been for `good`

#### Scenario: New card graded again enters relearning
- **WHEN** a `new` card is graded `again`
- **THEN** the card follows the `again` relearn rule (status `learning`, `repetitions` 0, short relearn interval)

### Requirement: Again resets and relearns
A grade of `again` SHALL reset `repetitions` to 0, set `status` to `learning`, and schedule a short relearn interval so the card becomes due again within the same day or the next day (`dueDate` close to "today"). The `easeFactor` SHALL be reduced (but never below the floor). A card already in `review` that is graded `again` is treated as lapsed and follows this same rule.

#### Scenario: Again resets repetitions and moves to learning
- **WHEN** a card in `review` with `repetitions` of 4 is graded `again`
- **THEN** `repetitions` becomes 0, `status` becomes `learning`, and `dueDate` is a short relearn interval from "today"

#### Scenario: Again lowers ease but respects the floor
- **WHEN** a card is graded `again`
- **THEN** `easeFactor` is reduced and is never set below the floor (≈1.3)

### Requirement: Graduating from learning to review
A card in `learning` that receives a passing grade (`good` or `easy`) and meets the graduation condition SHALL transition to status `review`, with `repetitions` incremented and an interval consistent with the review-growth rule. A `hard` grade on a learning card SHALL keep it progressing through learning (or graduate with a smaller interval, per the algorithm) without dropping it back to `new`.

#### Scenario: Learning card graduates on good
- **WHEN** a card in `learning` that meets the graduation condition is graded `good`
- **THEN** its `status` becomes `review` and its `repetitions` is incremented

#### Scenario: Learning card never returns to new
- **WHEN** a card in `learning` is graded with any grade
- **THEN** its resulting `status` is one of `learning` or `review`, never `new`

### Requirement: EaseFactor floor
The scheduler SHALL never set `easeFactor` below a floor of approximately 1.3. Any computation that would drop ease below the floor SHALL clamp it to the floor.

#### Scenario: Repeated hard/again clamps to floor
- **WHEN** a card is graded `hard` or `again` enough times that the computed ease would fall below 1.3
- **THEN** `easeFactor` is clamped to the floor (≈1.3) and never goes lower

### Requirement: Review interval growth
For a card in `review` graded `good`, the next `interval` SHALL grow by approximately the current `interval` multiplied by the current `easeFactor`, and `dueDate` SHALL be "today" plus that interval. `repetitions` SHALL be incremented. The `easeFactor` SHALL be unchanged or adjusted per the `good` rule (no decrease for `good`).

#### Scenario: Good multiplies the interval by ease
- **WHEN** a `review` card with `interval` 10 days and `easeFactor` 2.5 is graded `good`
- **THEN** the next `interval` is approximately 25 days (10 × 2.5) and `dueDate` is "today" plus that interval

#### Scenario: Repetitions increment on good
- **WHEN** a `review` card is graded `good`
- **THEN** `repetitions` is incremented by 1

### Requirement: Hard lowers ease and yields a smaller interval
A grade of `hard` SHALL reduce `easeFactor` (clamped to the floor) and SHALL produce a smaller next `interval` than `good` would for the same starting state — growing more slowly than the full ease multiplier (or not at all beyond a small factor).

#### Scenario: Hard interval is smaller than good interval
- **WHEN** the same `review` card is graded `hard` versus `good`
- **THEN** the `hard` result has a smaller next `interval` than the `good` result

#### Scenario: Hard reduces ease
- **WHEN** a `review` card is graded `hard`
- **THEN** its `easeFactor` is lower than before (clamped at the floor)

### Requirement: Easy grants a bonus
A grade of `easy` SHALL increase `easeFactor` and SHALL produce a larger next `interval` than `good` would for the same starting state, applying an additional easy bonus on top of the ease multiplier.

#### Scenario: Easy interval exceeds good interval
- **WHEN** the same `review` card is graded `easy` versus `good`
- **THEN** the `easy` result has a larger next `interval` than the `good` result

#### Scenario: Easy raises ease
- **WHEN** a `review` card is graded `easy`
- **THEN** its `easeFactor` is higher than before

### Requirement: Suspended cards excluded from scheduling
Cards with status `suspended` SHALL be excluded from scheduling. The scheduler SHALL treat applying a grade to a `suspended` card as a no-op for scheduling: it SHALL NOT change `easeFactor`, `interval`, `repetitions`, `dueDate`, or `status`. Selecting due cards SHALL never include `suspended` cards regardless of their `dueDate`.

#### Scenario: Grading a suspended card is a no-op
- **WHEN** a `suspended` card is passed to the scheduler with any grade
- **THEN** its `easeFactor`, `interval`, `repetitions`, `dueDate`, and `status` are unchanged

#### Scenario: Suspended cards are not due
- **WHEN** due cards are selected for a given "today"
- **THEN** no `suspended` card is included even if its `dueDate` is on or before "today"

### Requirement: DueDate computed from injected clock
The scheduler SHALL compute `dueDate` as the injected "today" advanced by the resulting `interval`, using whole-day granularity. The "today" value SHALL be supplied by the caller (clock injection); the scheduler SHALL NOT call `Date.now` or any other ambient time source.

#### Scenario: DueDate is today plus interval
- **WHEN** a grade produces an `interval` of N days for a given "today"
- **THEN** `dueDate` equals "today" advanced by N days

#### Scenario: Clock injection drives the result
- **WHEN** the scheduler is run with two different "today" values but otherwise identical inputs
- **THEN** the resulting `dueDate` values differ by exactly the difference between the two "today" values

### Requirement: Apply a grade and persist the review
There SHALL be an operation that, given a card id, a grade, and an injected "today", loads the existing `CardReview` for that card (or initializes a `new` review if none exists), applies the scheduler, and writes the updated `CardReview` back through the persistence layer defined in `app-foundation`. This operation SHALL reference the foundation `CardReview` model and SHALL NOT redefine it. The pure scheduler SHALL remain free of persistence imports; persistence access SHALL live behind the foundation's persistence boundary.

#### Scenario: Grading an unseen card initializes and persists it
- **WHEN** a grade is applied to a card that has no existing `CardReview`
- **THEN** a `new` review is initialized, the scheduler is applied, and the resulting `CardReview` is persisted

#### Scenario: Grading an existing card updates the persisted review
- **WHEN** a grade is applied to a card that already has a persisted `CardReview`
- **THEN** the loaded review is updated by the scheduler and the updated `CardReview` is written back through the persistence layer

#### Scenario: Persistence stays out of the pure scheduler
- **WHEN** the pure scheduler function is invoked
- **THEN** it neither reads nor writes persistence and operates only on the values passed to it

