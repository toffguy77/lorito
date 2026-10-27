## Context

`SpacedRepetitionScheduler.schedule(state:grade:today:)` is a pure SM-2 variant
with constants in `SRSConstants`; `ReviewState` stores `easeFactor`,
`interval`, `repetitions`, `dueDate`, `lastGrade`, `status`.
`IntervalPreview` (from `recall-first-study`) runs the scheduler per grade to
caption the grade buttons. `daily-plan` selects due cards by `dueDate` and
status only. Persistence is SwiftData with optional CloudKit sync.

FSRS reference: the current version is FSRS-6 with 21 default parameters;
stability S is the interval at which retrievability is 90%, difficulty D is on
a 1–10 scale, grades map Again=1 … Easy=4, and retrievability follows
R(t,S) = (1 + factor·t/S)^(−w₂₀) with factor = 0.9^(−1/w₂₀) − 1
(https://github.com/open-spaced-repetition/awesome-fsrs/wiki/The-Algorithm).

## Goals / Non-Goals

**Goals:** FSRS-6 scheduling with default parameters; same purity,
determinism and day granularity; lossless migration; user-tunable desired
retention; ordered captions.

**Non-Goals:** per-user parameter optimisation (needs review logs and an
optimizer; later), interval fuzz, sub-day learning steps, changing daily-plan
limits.

## Decisions

**Same call shape, new model.** `schedule(state:grade:today:retention:)`
returns the next `ReviewState`. Next interval for review cards =
round(S′ / factor · (r^(−1/w₂₀) − 1)) days (the inverse of the curve above),
clamped to [1, maxInterval]; with r = 0.9 this equals S′ by definition.
`Again` on any card → status `learning`, `repetitions` 0, interval 0 (due
today), stability reduced by the FSRS post-lapse formula, difficulty raised
(clamped to 10). Parameters: the 21 FSRS-6 defaults copied verbatim from a
reference implementation listed in awesome-fsrs, stored in `FSRSParameters`
with a test pinning them.

**Day granularity.** Elapsed time t is computed in whole days between the last
review and the injected "today" (UTC calendar, as today). Same-day repeats use
the short-term stability formula from FSRS-6; we never schedule sub-day steps:
a relearning card is due "today" until graded Хорошо/Легко.

**No fuzz.** FSRS implementations usually add random fuzz to spread load; we
omit it to keep the scheduler deterministic (an existing requirement).

**Ordering guard.** After computing per-grade intervals for review cards, the
scheduler enforces hard ≤ good and easy ≥ good + 1, so captions never show
«Легко» shorter than or equal to «Хорошо».

**ReviewState changes.** Add `stability: Double?` and `difficulty: Double?`
(nil = not yet migrated / never reviewed) and keep `easeFactor` untouched for
rollback. Optional fields decode from old data and are additive for CloudKit.

**Migration from SM-2 (pure, lazy).** When a state with `stability == nil` and
status `review` or `learning` is scheduled, `SM2Migration.memoryState(from:)`
derives S = max(interval, 1) days (SM-2 cards were reviewed near the end of
their interval, a reasonable proxy for the 90%-recall point) and D from ease:
D = clamp(1…10) of a linear map from ease 2.5 → 5 to the floor 1.3 → 9. This is
a heuristic; FSRS self-corrects after the first real review. `new` and
`suspended` cards need no migration.

**Desired retention.** `UserSettings.desiredRetention` in [0.80, 0.95],
default 0.90; Settings row «Целевая запоминаемость» with a one-line
explanation of the trade-off (higher = more reviews). Changing it affects
only intervals computed afterwards.

**Maximum interval.** `FSRSParameters.maxInterval = 365` days so that rules
resurface at least yearly; a constant, not a user setting.

## Risks / Trade-offs

- [Migration heuristic mis-estimates some cards] → bounded by clamps and
  corrected after one review; covered by tests on representative states.
- [Behavior change surprises users (different intervals)] → release note in
  plain Russian; captions show the new intervals before grading.
- [CloudKit schema change] → optional fields only; deploy schema to production
  before release, as in `cloudkit-sync`.
- [Default parameters may not suit grammar cards] → later change: optimise
  parameters from anonymised aggregate logs, if analytics allows.

## Migration Plan

1. Ship scheduler + lazy migration; old fields preserved.
2. Deploy CloudKit schema with the two optional fields before the App Store
   release.
3. Rollback: switch the call site back to the SM-2 scheduler, which still
   reads `easeFactor`/`interval` (never modified by FSRS code paths except
   `interval`, `dueDate`, `repetitions`, `status`, which SM-2 also accepts).
