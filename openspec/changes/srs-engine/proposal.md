## Why

Lorito schedules study cards with spaced repetition: after a user reads a card and self-grades it (Опять / Трудно / Хорошо / Легко), the app must decide when that card is due again. The `bootstrap-foundation` change already defined the persisted `CardReview` state (easeFactor, interval, repetitions, dueDate, lastGrade, status) but deliberately did **not** define the algorithm that transforms it. This change adds that algorithm — a pure, deterministic SM-2 scheduler in the `Domain` layer — so that later changes can compose study queues and persist grading results on top of a stable, unit-tested contract.

Putting the scheduler in pure `Domain` (no SwiftUI/SwiftData/CloudKit) means it can be exhaustively unit-tested without a simulator, kept portable, and reasoned about in isolation. Making "today" an injected input rather than reading `Date.now` keeps every scheduling decision reproducible in tests.

## What Changes

- Add the **SM-2 scheduling algorithm** as a pure `Domain` function: given a card's current review state, a grade (again/hard/good/easy), and an injected "today", it returns the next review state (easeFactor, interval, repetitions, dueDate, status). It performs no I/O and reads no global clock.
- Define how each of the four grades transforms state, covering: the first review of a `new` card; `again` resetting repetitions and moving the card to `learning` with a short relearn interval; graduating from `learning` to `review`; the easeFactor floor (≈1.3); review-interval growth (≈ interval × easeFactor); `hard` lowering ease and yielding a smaller interval; and `easy` granting a bonus.
- Define that `suspended` cards are excluded from scheduling, and that applying a grade to a `suspended` card is a no-op for scheduling.
- Define the **persistence integration**: a `Domain`-facing operation that, given a card id, a grade, and "today", loads the existing `CardReview` (or initializes a `new` one), applies the algorithm, and writes the updated `CardReview` back through the existing persistence layer. This references the foundation `CardReview` model; it does not redefine it.

This change delivers no end-user UI. It produces a tested scheduling capability consumed by the future `daily-plan` (which builds each day's queue from due dates and statuses) and `study-flow` (which calls into it when the user grades a card) changes.

## Capabilities

### New Capabilities
- `srs-engine`: The pure, deterministic SM-2 spaced-repetition scheduler operating on `CardReview` state — grade-to-state transitions (again/hard/good/easy), new/learning/review/suspended status handling, the easeFactor floor and interval growth, clock injection for testability, and the operation that applies a grade and persists the updated `CardReview` through the persistence layer.

### Modified Capabilities
<!-- None — the foundation specs (app-foundation, content-model, content-pipeline, design-system) are not archived yet, so this change introduces no MODIFIED deltas. It builds on the foundation's CardReview model without redefining it. -->

## Impact

- **Code (added, not in scope to author here)**: a scheduler in the `Domain` layer (pure Swift) plus its unit tests, and a thin apply-and-persist operation that bridges `Domain` and the existing `Persistence` layer.
- **Foundation contracts consumed (not modified)**: the `CardReview` model and its `status ∈ {new, learning, review, suspended}` from `app-foundation`; the four grade labels (Опять / Трудно / Хорошо / Легко) surfaced by the `design-system` grade buttons.
- **Downstream changes (not in scope here)**: `daily-plan` consumes due dates and statuses to compose the daily queue; `study-flow` invokes the apply-and-persist operation when the user grades a card.
- **No new dependencies, no backend, no schema changes**: the algorithm is pure Swift over the already-defined model fields.
