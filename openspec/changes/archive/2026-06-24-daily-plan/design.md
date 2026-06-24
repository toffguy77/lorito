## Context

Lorito studies cards with spaced repetition. The `bootstrap-foundation` change defined the persisted user-data model (`UserSettings`, `CardReview`, `StudyLog`) and the content model (ordered levels `A1<A2<B1<B2<C1<C2`, a per-level theme registry, cards with `id`/`level`/`theme`/`order`/`related`). The adjacent `srs-engine` change defined the SM-2 scheduler that, per grade, updates each card's `CardReview` (`dueDate`, `status ∈ {new, learning, review, suspended}`, etc.). What is still missing is the step between "each card knows when it is next due" and "the user sits down to study": composing one bounded, ordered queue for *today* from many cards.

This change is that composer. It is pure `Domain` logic — no SwiftUI, SwiftData, or CloudKit — and takes "today" as an injected argument, mirroring `srs-engine` so the queue is fully reproducible and unit-testable without a simulator. Its consumers are `study-flow` (presents/walks the queue, triggers recomputation after each grade) and `reminders` (uses the count report). Practice exercises are explicitly out of scope.

## Goals / Non-Goals

**Goals:**
- A pure, deterministic function that maps (content snapshot, `CardReview` states, `UserSettings`, injected "today") to an ordered study queue plus a new-vs-due count report.
- Correct DUE selection (due `review`/`learning`, `suspended` excluded, no-state cards not due).
- Bounded, in-order, prerequisite-respecting NEW selection scoped to included levels and `selectedThemes`.
- A max-reviews-per-day cap with well-defined overflow deferral that never mutates scheduling state.
- Defined behavior for empty-queue and selection-exhausted cases, deterministic tie-breaking, and clearly enumerated recomputation triggers.

**Non-Goals:**
- The SM-2 algorithm and grade transitions (owned by `srs-engine`).
- Persisting anything, reading the clock, or any I/O (the composer is pure; callers supply inputs and persist results elsewhere).
- UI: the Today screen, the study session walk, and notification scheduling (owned by `study-flow` / `reminders`).
- Practice exercises (later phase, separate change).
- Cross-day planning/forecasting beyond "today" (the composer plans a single day; deferral simply omits overflow from today).

## Decisions

- **Reviews-first ordering (due before new), not interleaving.** Due `review`/`learning` cards are placed ahead of newly introduced cards. Rationale: reviews are time-sensitive (overdue cards decay) and reinforce known material before cognitive load rises with new cards; it also makes the queue trivially explainable on the Today screen ("N reviews, then M new"). *Alternative — interleaving new among reviews* (e.g., spacing new cards through the session) can feel less monotonous but complicates determinism, the count report, and overflow reasoning; it can be revisited later as a presentation concern in `study-flow` without changing this contract.
- **Prerequisites derived from `related` ∩ selection, gated by introduction state.** A new card's prerequisites are exactly those of its `related` ids that are *within the user's current selection* (included level and selected theme). A prerequisite is satisfied when it already has a `CardReview` state (already introduced on a prior day) or is introduced earlier in the same plan. Rationale: `related` is the only dependency signal the content model exposes; restricting to the selection avoids dead-locking the learner on cards they will never see (out-of-scope prerequisites cannot be "introduced," so they must not block). *Alternative — treat ascending `order` alone as the prerequisite chain* is simpler but wrong when `related` crosses themes or skips orders; *alternative — require all `related` regardless of scope* would make some in-scope cards permanently unreachable.
- **`related` treated as a DAG within the selection; introduction is a topological pick under the daily cap.** Each day, eligible new cards are introduced in ascending `order`, but a card is held back until its in-scope prerequisites are introduced (prior day or earlier today). When `dailyNewCardCount` allows, a prerequisite and its dependent can both enter the same day in dependency order. Rationale: honors both the authored sequence (`order`) and explicit dependencies (`related`). *Assumption/Open Question:* `related` is assumed acyclic within a selection; a cycle is handled defensively (see Risks).
- **A configurable max-reviews-per-day cap with a sensible default, overflow deferred.** Due cards exceeding the cap are simply omitted from today's queue; their `CardReview` is untouched, so they remain due and naturally reappear on a subsequent day. Rationale: prevents an unbounded backlog from making a single day impossible, which is the classic SRS failure mode; deferral-by-omission keeps the composer pure (no rescheduling side effects). The cap default is chosen to be generous enough not to interfere with normal use (e.g., ~50/day) and is overridable via settings. *Alternative — reschedule overflow forward by mutating `dueDate`* was rejected: it makes the composer impure and entangles it with `srs-engine`'s scheduling authority.
- **Overflow chooses the most-overdue cards first.** When capping, due cards are ordered by `dueDate` ascending (then `id`), so the oldest-due cards are admitted and the freshest-due are deferred. Rationale: minimizes how stale the backlog gets.
- **Deterministic tie-breaking by `id`.** Wherever a primary sort key ties (equal `dueDate` for due cards, equal `order` for new cards), card `id` ascending is the final tiebreaker. Rationale: the inputs arrive as unordered collections from persistence; without a total order the queue (and tests) would be non-deterministic.
- **A count report derivable independently of the full queue walk.** The report exposes at least due count, new count, empty-queue, and scope-exhausted flags. Rationale: `reminders` needs counts cheaply (potentially in the background) without rendering a session; keeping counts consistent with the composed queue is guaranteed by deriving both from the same selection step.
- **No-state cards are "new," not "due."** A card with no `CardReview` is a candidate new card, never a due card; only `srs-engine`-produced states with `review`/`learning` and `dueDate ≤ today` are due. Rationale: keeps the two selection paths disjoint and matches the foundation's status model.
- **Recomputation = re-invocation, since the composer is pure.** The enumerated triggers (new-day rollover, settings change, grade completion) are simply the conditions under which callers re-run the function. Rationale: no caching contract to maintain inside `Domain`; any memoization is a caller/`study-flow` concern.

## Risks / Trade-offs

- **`related` cycles or self-references could deadlock new-card introduction** → Treat `related` within the selection as a DAG; if a cycle is detected, break it defensively (e.g., fall back to ascending `order` for the cycle members) so the planner always makes progress rather than starving. Content-pipeline validation already checks `related` resolvability; cycle-avoidance is the planner's safety net.
- **A large overdue backlog under the cap could feel like the learner "never catches up"** → The cap is configurable and admits the most-overdue first; tuning and any "catch-up" UX live in `study-flow`/settings, not in this pure contract.
- **Counts and queue drifting out of sync** → Derive both the report and the queue from a single selection pass so the report's numbers are exactly the admitted due/new cards.
- **Misclassifying suspended/no-state cards** → Explicitly excluded by requirements and covered by dedicated scenarios; the disjoint due-vs-new paths reduce the chance of double-counting.
- **Time-zone / day-boundary ambiguity for "today"** → The composer compares against an injected "today" and does not interpret time zones itself; callers are responsible for supplying the correct day boundary (documented as a caller contract, exercised via clock injection in tests).

## Open Questions

- Exact numeric default for the max-reviews-per-day cap (proposed ~50) — to confirm during implementation/tuning.
- Whether `reminders` needs a *forecast* of tomorrow's due count (multi-day projection) or only today's counts; current scope is today-only, and a projection could be a later additive requirement if `reminders` asks for it.
