## Context

`bootstrap-foundation` established the persisted user-data model, including `CardReview` with the fields needed for SM-2 — `easeFactor`, `interval`, `repetitions`, `dueDate`, `lastGrade`, and `status ∈ {new, learning, review, suspended}` — but intentionally left the scheduling algorithm unspecified. This change fills that gap with the scheduler itself.

The product agreed on SM-2 with four self-grading buttons (Опять / Трудно / Хорошо / Легко) surfaced by the `design-system`. The scheduler lives in the pure `Domain` layer so it is exhaustively unit-testable without a simulator and portable. It is consumed downstream by `daily-plan` (which reads `dueDate`/`status` to compose the day's queue) and `study-flow` (which applies a grade when the user taps a grade button). This change does not build any UI or queue composition — only the algorithm and the thin apply-and-persist bridge.

## Goals / Non-Goals

**Goals:**
- A pure, deterministic SM-2 scheduler in `Domain` mapping the four grades to next review state.
- Full coverage of the required transitions: first review of a `new` card; `again` reset/relearn; `learning` → `review` graduation; ease floor (≈1.3); review-interval growth (≈ interval × ease); `hard` (lower ease, smaller interval); `easy` (bonus); `suspended` exclusion.
- Clock injection (a supplied "today") so `dueDate` is reproducible in tests; no `Date.now`.
- A thin operation that loads/initializes a `CardReview`, applies the scheduler, and persists it through the foundation persistence layer.

**Non-Goals:**
- Daily-queue composition, new-card introduction limits, theme/prerequisite ordering (that is `daily-plan`).
- Any UI, the study screen, or wiring grade buttons (that is `study-flow`).
- Practice exercises and their result mapping (a later change).
- Redefining or migrating the `CardReview`/persistence model (owned by `app-foundation`).
- A configurable/learnable algorithm or per-user tuning beyond SM-2 constants.

## Decisions

- **SM-2 over FSRS (and over a fixed Leitner box).** SM-2 is simple, well-understood, fully deterministic, and trivially unit-testable with no training data — ideal for a v1 offline app with self-grading. FSRS schedules better but needs a fitted model and review-history weights, adding complexity and a data dependency we don't want for launch; the pure `Domain` boundary keeps the door open to swap in FSRS later behind the same interface. Plain Leitner is even simpler but ignores per-card ease, giving worse spacing. Rationale: best accuracy-to-complexity ratio for v1.

- **Pure function + clock injection.** The core is `schedule(state, grade, today) -> state` with no I/O and no ambient clock. "Today" (and the day-granularity calendar) is passed in. This makes every transition a pure table of inputs→outputs that tests can assert exactly, including `dueDate`. Alternative (reading `Date.now` inside) was rejected as untestable and non-deterministic.

- **Whole-day interval granularity.** Intervals and `dueDate` advance in whole days from "today". This matches a once-daily study cadence and avoids time-of-day flakiness. Sub-day relearn steps (the `again`/`learning` short interval) are represented as "due same day or next day" rather than minute-precise steps, keeping the model day-based while still re-surfacing lapsed cards quickly.

- **EaseFactor floor of 1.3, ease deltas per classic SM-2.** `easy` raises ease, `good` leaves it unchanged, `hard` lowers it, `again` lowers it more — all clamped at ≈1.3 so cards never collapse to near-zero intervals. These are the standard SM-2 constants; encoding them as named `Domain` constants (not magic numbers) keeps them reviewable and tunable.

- **Status state machine `new → learning → review`, with `again` lapsing back to `learning`; `suspended` is inert.** `new` is the unseen state; a first pass moves it forward; `again` always routes through `learning` with `repetitions = 0`; graduation on a passing grade promotes `learning → review`; a card never returns to `new`. `suspended` is excluded from scheduling and from due selection, and grading it is a no-op — this lets a user park a card without losing its state.

- **Apply-and-persist as a thin bridge, scheduler stays pure.** A separate operation (outside the pure function) loads or initializes the `CardReview`, calls `schedule(...)`, and writes back through the foundation's persistence boundary. The pure scheduler imports no persistence; persistence lives behind the existing protocol from `app-foundation`. This keeps `Domain` pure and the algorithm testable in isolation, while giving `study-flow` a single call site.

- **Initialize-on-grade for unseen cards.** If a card has no `CardReview` yet, the apply operation initializes a `new` review and then schedules it, so callers never need to pre-create review rows. This keeps `daily-plan`/`study-flow` simpler.

## Risks / Trade-offs

- **SM-2 spacing is coarser than FSRS** → Accepted for v1; the pure interface isolates the algorithm so it can be replaced without touching callers, models, or UI.
- **Whole-day granularity makes intra-day relearning approximate** → A lapsed card becomes due "same day or next day" rather than in N minutes; acceptable for a daily-study product and simpler to test deterministically.
- **Self-grading is subjective**, so ease can drift → The 1.3 ease floor and bounded interval growth prevent runaway short/long intervals; constants are centralized for tuning after real usage.
- **Constants chosen now may need tuning** (initial intervals, easy bonus, hard factor, relearn step) → Centralize them as named `Domain` constants and cover them with tests so adjustments are localized and visible.
- **Drift from the foundation `CardReview` model** → This change references those fields and must not redefine them; tests should construct review state via the foundation model to catch divergence early.

## Open Questions

- Exact numeric constants (initial `good`/`easy` intervals, easy bonus multiplier, hard interval factor, relearn step length) — pick standard SM-2 defaults during implementation and pin them in tests; tunable later without interface change.
- Whether the apply-and-persist operation also appends to `StudyLog` here, or whether `study-flow` owns that — leaning toward `study-flow` owning logging so this change stays focused on scheduling; confirm when `study-flow` is specced.
