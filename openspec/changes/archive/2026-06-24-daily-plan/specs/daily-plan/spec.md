## ADDED Requirements

### Requirement: Pure deterministic composition
The daily-plan composer SHALL be a pure `Domain` function that, given a content snapshot, the current set of `CardReview` states, `UserSettings`, and an injected "today", returns a study queue and a count report. It SHALL perform no I/O, read no global clock, and produce identical output for identical input.

#### Scenario: Same inputs yield the same queue
- **WHEN** the composer is invoked twice with the same content snapshot, `CardReview` states, `UserSettings`, and injected "today"
- **THEN** both invocations return an identical ordered queue and identical counts

#### Scenario: Clock is injected, not read
- **WHEN** "today" is supplied as an argument while the system clock is at a different date
- **THEN** the composer uses the injected "today" for all due comparisons and ignores the system clock

### Requirement: Due-card selection
The composer SHALL include in the queue every card whose `CardReview` is due — `dueDate ≤ today` and status `review` or `learning`. Cards with status `suspended` SHALL be excluded. A card that has no `CardReview` state SHALL NOT be treated as due.

#### Scenario: Due review card is included
- **WHEN** a card has status `review` and `dueDate` on or before today
- **THEN** it is included in the queue as a due card

#### Scenario: Learning card due today is included
- **WHEN** a card has status `learning` and `dueDate` on or before today
- **THEN** it is included in the queue as a due card

#### Scenario: Not-yet-due card is excluded
- **WHEN** a card has status `review` and `dueDate` strictly after today
- **THEN** it is not included in the queue

#### Scenario: Suspended card is excluded
- **WHEN** a card has status `suspended` and `dueDate` on or before today
- **THEN** it is excluded from the queue

#### Scenario: Card without review state is not due
- **WHEN** a card has no `CardReview` state
- **THEN** it is not selected as a due card (it may instead be eligible as a new card)

### Requirement: New-card scope
The composer SHALL draw new cards only from the user's INCLUDED levels and `selectedThemes`. INCLUDED levels are the `UserSettings.targetLevel` and all lower levels in the order `A1<A2<B1<B2<C1<C2`. A card is eligible as new only if it has no `CardReview` state, its `level` is included, and its `theme` is in `selectedThemes`.

#### Scenario: Card above target level is not eligible
- **WHEN** the target level is B1 and a candidate new card has level B2
- **THEN** the card is not eligible as a new card

#### Scenario: Lower-level card is in scope
- **WHEN** the target level is B1 and a candidate new card has level A2
- **THEN** the card's level is included in scope

#### Scenario: Card outside selected themes is not eligible
- **WHEN** a candidate new card's `theme` is not in `selectedThemes`
- **THEN** the card is not eligible as a new card

#### Scenario: Already-reviewed card is not new
- **WHEN** a candidate card already has a `CardReview` state
- **THEN** it is not eligible as a new card

### Requirement: New-card count limit
The composer SHALL introduce at most `UserSettings.dailyNewCardCount` new cards in a single day's queue.

#### Scenario: New-card count is honored
- **WHEN** `dailyNewCardCount` is 1 and many cards are eligible as new
- **THEN** exactly one new card is added to the queue

#### Scenario: Fewer eligible than the limit
- **WHEN** `dailyNewCardCount` is 5 but only 2 cards are eligible as new
- **THEN** exactly those 2 new cards are added to the queue

### Requirement: New-card ordering by card order
Among eligible new cards, the composer SHALL introduce them in ascending `order`, so earlier-ordered cards are introduced before later ones within the user's selection.

#### Scenario: Lower order introduced first
- **WHEN** two cards are eligible as new with orders 3 and 7 and `dailyNewCardCount` is 1
- **THEN** the card with order 3 is the one introduced

### Requirement: Related-prerequisite enforcement
The composer SHALL respect `related` prerequisites: a new card SHALL NOT be introduced before the cards it depends on — those of its `related` cards that are themselves within the user's selection — have already been introduced. A prerequisite counts as introduced if it already has a `CardReview` state or is introduced earlier in the same day's queue. Prerequisite cards that fall outside the user's selection (excluded level or unselected theme) SHALL NOT block introduction.

#### Scenario: Prerequisite blocks a later card the same day
- **WHEN** card X lists card Y (in scope, not yet reviewed) in `related`, both are eligible, and `dailyNewCardCount` is 1
- **THEN** Y is introduced before X, so Y is the new card chosen today and X waits

#### Scenario: Already-learned prerequisite does not block
- **WHEN** card X lists prerequisite Y in `related` and Y already has a `CardReview` state
- **THEN** X may be introduced as a new card without re-introducing Y

#### Scenario: Out-of-scope prerequisite does not block
- **WHEN** card X lists prerequisite Y in `related` but Y's theme is not in `selectedThemes`
- **THEN** Y does not block X, and X may be introduced as a new card

#### Scenario: Two introduced together in dependency order
- **WHEN** card X depends on in-scope card Y, both are eligible, and `dailyNewCardCount` is 2
- **THEN** both are introduced today with Y ordered before X

### Requirement: Max-reviews-per-day cap with deferral
The composer SHALL enforce a configurable maximum number of due cards admitted to a single day's queue, with a sensible default. When the number of due cards exceeds the cap, the composer SHALL admit up to the cap and defer the remaining due cards to a later day; deferral SHALL NOT mutate any card's scheduling state.

#### Scenario: Due cards under the cap are all admitted
- **WHEN** the cap is 50 and 20 cards are due
- **THEN** all 20 due cards are admitted to the queue

#### Scenario: Overflow due cards are deferred
- **WHEN** the cap is 50 and 80 cards are due
- **THEN** exactly 50 due cards are admitted and the other 30 are not placed in today's queue

#### Scenario: Deferral leaves scheduling state untouched
- **WHEN** due cards are deferred because of the cap
- **THEN** the deferred cards' `CardReview` fields (`dueDate`, `status`, `interval`, etc.) are unchanged by the composer

#### Scenario: A default cap applies when none is configured
- **WHEN** no max-reviews-per-day value is configured
- **THEN** the composer applies its sensible default cap

### Requirement: Queue ordering
The composer SHALL place due cards (status `review`/`learning`) before new cards in the returned queue, so the learner reviews known material before meeting new material. New cards SHALL appear in the dependency-respecting ascending-`order` sequence defined above.

#### Scenario: Due cards precede new cards
- **WHEN** the queue contains both due cards and newly introduced cards
- **THEN** every due card appears before every new card in the returned order

### Requirement: Deterministic tie-breaking
The composer SHALL break ties deterministically so that ordering never depends on collection iteration order. Due cards SHALL be ordered by `dueDate` ascending, then by card `id` ascending; new cards SHALL be ordered as defined (dependency-respecting ascending `order`, then card `id` ascending) for any remaining ties.

#### Scenario: Equal due dates broken by id
- **WHEN** two due cards share the same `dueDate`
- **THEN** they are ordered by card `id` ascending

#### Scenario: Equal order broken by id
- **WHEN** two eligible new cards share the same `order`
- **THEN** they are ordered by card `id` ascending (subject to prerequisite constraints)

### Requirement: Empty-queue case
When no cards are due and no cards are eligible to be introduced as new, the composer SHALL return an empty queue with zero due and zero new counts, and SHALL signal that the queue is empty.

#### Scenario: Nothing due and nothing new
- **WHEN** no card is due and no card is eligible as new for the current selection and "today"
- **THEN** the composer returns an empty queue with due count 0 and new count 0 and indicates the empty state

### Requirement: Selection-exhausted case
When the user's selection contains no further new cards (all in-scope cards already have review state), the composer SHALL still admit due cards but introduce zero new cards, and SHALL signal that the new-card scope is exhausted.

#### Scenario: All in-scope cards already introduced
- **WHEN** every card within the included levels and `selectedThemes` already has a `CardReview` state, while some are due
- **THEN** the queue contains the due cards, the new count is 0, and the composer indicates the scope is exhausted

### Requirement: Count report
The composer SHALL provide a count report — at least the number of due cards and the number of new cards in the day's queue, and whether the queue is empty or the new-card scope is exhausted — derivable for use by reminders and the Today screen without requiring callers to walk the full queue.

#### Scenario: Counts match the composed queue
- **WHEN** a queue is composed with some due and some new cards
- **THEN** the report's due count equals the number of due cards and its new count equals the number of new cards in that queue

#### Scenario: Counts available for reminders
- **WHEN** a caller needs the new-vs-due breakdown for a notification
- **THEN** the count report exposes those numbers without the caller iterating the queue

### Requirement: Recomputation triggers
The day's plan SHALL be recomputed when any input that affects it changes: a new-day rollover (the injected "today" advances), a change to `UserSettings` (target level, selected themes, daily new-card count, or the reviews cap), and the completion of a grade (which mutates `CardReview` state). The composer being pure, recomputation is re-invoking it with the updated inputs.

#### Scenario: New day rollover recomputes
- **WHEN** "today" advances to the next day
- **THEN** re-invoking the composer reflects cards newly due on the new day

#### Scenario: Settings change recomputes
- **WHEN** the user changes target level, selected themes, daily new-card count, or the reviews cap
- **THEN** re-invoking the composer reflects the new selection and limits

#### Scenario: Grade completion recomputes
- **WHEN** a card is graded and its `CardReview` state changes
- **THEN** re-invoking the composer reflects the updated due/new membership
