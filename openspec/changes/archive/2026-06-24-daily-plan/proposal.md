## Why

Lorito teaches Spanish with spaced repetition, but the `srs-engine` change only decides *when an individual card is next due* — it does not decide *what to study today*. Each day the app must compose a single, bounded study queue: every card that has come due, plus a measured trickle of brand-new cards drawn from the levels and themes the user actually selected, ordered so a learner never meets a card before the prerequisite cards it depends on. Without this, the Today screen and reminders have no notion of "today's work," due cards could pile up without bound, and new material could appear out of order or outside the user's chosen scope.

This capability is the pure, deterministic planner that turns a content snapshot, the current `CardReview` states (as produced by `srs-engine`), and `UserSettings` into that ordered queue plus its counts. Like the scheduler, it lives in the pure `Domain` layer and takes "today" as an injected input, so every queue is reproducible and exhaustively unit-testable without a simulator, a clock, or persistence. It is consumed by `study-flow` (which presents the queue) and `reminders` (which reports the counts).

## What Changes

- Add the **daily-plan composer** as a pure `Domain` function: given a content snapshot, the current `CardReview` states, `UserSettings`, and an injected "today", it returns an ordered study queue plus a count breakdown (new vs due). It performs no I/O and reads no global clock.
- Define the **DUE selection**: all cards whose `CardReview` is due (`dueDate ≤ today`) with status `review` or `learning`; `suspended` cards are excluded; cards with no review state are not "due".
- Define the **NEW selection**: up to `UserSettings.dailyNewCardCount` cards that have no prior review state, drawn only from the user's INCLUDED levels (target level plus all lower levels) and `selectedThemes`, taken in ascending `order`, and **respecting `related` prerequisites** — a new card is not introduced before the cards it depends on (within the user's selection) have themselves been introduced (already in review or introduced earlier in the same plan).
- Define a **max-reviews-per-day cap** (a sensible default) that bounds how many DUE cards enter a single day's queue; overflow due cards are deferred to a later day (their scheduling state is untouched — they simply are not placed in today's queue).
- Define **queue ordering** (reviews/learning placed before new cards), the **empty-queue case** (nothing due and no eligible new cards), the **selection-exhausted / level-complete case** (no new cards remain in scope), and **deterministic tie-breaking** so the same inputs always yield the same queue.
- Define the **recomputation triggers**: a new-day rollover, a change to `UserSettings` (target level, selected themes, daily new-card count, caps), and the completion of a grade (which mutates `CardReview` state).
- Provide a **count report** (new vs due, and whether the queue is empty / scope exhausted) for use by `reminders` and the Today screen, derivable without building the full ordered queue.

This change delivers no end-user UI. It produces a tested planning capability consumed by the future `study-flow` (which presents and walks the queue) and `reminders` (which reports counts) changes.

## Capabilities

### New Capabilities
- `daily-plan`: The pure, deterministic Domain planner that composes the day's study queue from a content snapshot, current `CardReview` states, and `UserSettings` with an injected "today" — DUE selection (due `review`/`learning`, suspended excluded), bounded NEW selection from included levels and `selectedThemes` in ascending `order` respecting `related` prerequisites, a max-reviews-per-day cap with deferral of overflow, queue ordering and deterministic tie-breaking, the empty-queue and selection-exhausted cases, the recomputation triggers, and a new-vs-due count report for reminders and the Today screen.

### Modified Capabilities
<!-- None — the foundation specs (app-foundation, content-model, content-pipeline, design-system) and the adjacent srs-engine spec are not archived yet, so this change introduces no MODIFIED deltas. It builds on the foundation's CardReview / UserSettings models and the srs-engine scheduling semantics without redefining them. -->

## Impact

- **Code (added, not in scope to author here)**: a daily-plan composer in the `Domain` layer (pure Swift) plus its unit tests, and the input/output value types it operates over (a content snapshot view, the plan result, and the count report).
- **Foundation contracts consumed (not modified)**: the `CardReview` model and its `status ∈ {new, learning, review, suspended}` and `dueDate` from `app-foundation`; `UserSettings` (`targetLevel`, `selectedThemes`, `dailyNewCardCount`) from `app-foundation`; the ordered levels `A1<A2<B1<B2<C1<C2`, the per-level theme registry, and the card fields `level`/`theme`/`order`/`related` from `content-model`.
- **Adjacent contract consumed (not modified)**: `srs-engine` produces the `dueDate`/`status` scheduling state that the DUE selection reads; this change does not perform scheduling.
- **Downstream changes (not in scope here)**: `study-flow` presents and walks the composed queue and triggers recomputation after each grade; `reminders` uses the count report to drive due-aware local notifications.
- **No new dependencies, no backend, no schema changes**: the planner is pure Swift over already-defined model fields.
