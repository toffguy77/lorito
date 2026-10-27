## Context

`SpacedRepetitionScheduler.schedule(state:grade:today:)` is a pure SM-2 variant
with constants in `SRSConstants`; `ReviewState` stores `easeFactor`,
`interval`, `repetitions`, `dueDate`, `lastGrade`, `status`.
`IntervalPreview` (from `recall-first-study`) runs the scheduler per grade to
caption the grade buttons. `daily-plan` selects due cards by `dueDate` and
status. Persistence is SwiftData with optional CloudKit sync.

`learning-platform-foundation` (dependency) defines: the learning day as the
user's local calendar day; only the FIRST graded review of an item per
learning day updates its memory state (later same-day grades are logged only);
cards graded Опять are re-shown once at the end of the session.
`cloudkit-schema-release` (dependency) defines how new synced fields ship.

FSRS reference: FSRS-6 with 21 default parameters; stability S is the interval
at which retrievability is 90%, difficulty D is on a 1–10 scale, grades map
Again=1 … Easy=4, and retrievability follows R(t,S) = (1 + factor·t/S)^(−w₂₀)
with factor = 0.9^(−1/w₂₀) − 1
(https://github.com/open-spaced-repetition/awesome-fsrs/wiki/The-Algorithm).

## Goals / Non-Goals

**Goals:** FSRS-6 scheduling with default parameters; purity, determinism and
day granularity; lossless and repeatable migration; safe with mixed app
versions; user-tunable desired retention; ordered captions.

**Non-Goals:** per-user parameter optimisation, interval fuzz, sub-day
learning steps, same-day memory updates (excluded by the foundation),
changes to daily-plan limits.

## Decisions

**Same call shape, new model.** `schedule(state:grade:today:retention:)`
returns the next `ReviewState`. Review interval = round(S′ / factor ·
(r^(−1/w₂₀) − 1)) days (inverse of the curve above), clamped to
[1, maxInterval]; with r = 0.9 this equals S′. Parameters: the 21 FSRS-6
defaults copied verbatim from a reference implementation listed in
awesome-fsrs, pinned by a test.

**Elapsed time.** `ReviewState.lastReviewDate` (optional) is set to "today"
on every memory-updating grade. Elapsed t = whole learning days between
`lastReviewDate` and "today" (local calendar, per foundation). Because only
the first grade per learning day updates memory, t ≥ 1 for every update after
the first day and the FSRS same-day formula is not needed.

**Per-grade behavior by status.**
- `new`: initial S, D from defaults for the grade; Опять → learning, due today.
- `learning` + Опять → stays learning, interval 0; + Трудно → stays learning,
  repetitions unchanged, interval ≥ 1 day (consistent with the unchanged
  "Graduating from learning to review", which allows hard to keep progressing
  through learning); + Хорошо/Легко → graduates to `review`, repetitions + 1.
- `review` + Опять → lapse: learning, repetitions 0, interval 0, post-lapse S,
  higher D (≤ 10); + Трудно/Хорошо/Легко → retention-based interval.
An Опять card is due "today"; the foundation re-shows it once at the end of
the session, which makes the «сегодня» caption true.

**No fuzz.** Omitted to keep the scheduler deterministic.

**Ordering guard and cap.** After computing per-grade intervals: hard ≤ good;
easy ≥ good + 1 unless good is already at `maxInterval` (365), where easy =
good. Captions may then coincide; this is specified explicitly.

**ReviewState changes.** Optional `stability`, `difficulty`, `lastReviewDate`,
`schedulerVersion` (`2` = FSRS) and `fsrsDueDate` (the due date FSRS last
computed). `easeFactor` is kept untouched for rollback.

**Mixed app versions.** An older SM-2 build on another device does not know
the new fields; SwiftData/CloudKit leave them as they were while the old build
rewrites `interval`, `dueDate`, `easeFactor`. A state is treated as valid FSRS
only if `schedulerVersion == 2` and `fsrsDueDate == dueDate`; otherwise it is
re-migrated from the current SM-2 fields before grading.

**Migration from SM-2 (pure, lazy).** `SM2Migration.memoryState(from:)`: S =
max(interval, 1) days (SM-2 cards are reviewed near the end of their
interval, a reasonable proxy for the 90 %-recall point); D = clamp(1…10) of a
linear map ease 2.5 → 5, 1.3 → 9; `lastReviewDate` = `dueDate` − `interval`
days when absent (documented approximation). `new` and `suspended` cards need
no migration.

**Desired retention.** `UserSettings.desiredRetention` in [0.80, 0.95],
default 0.90, stored as an optional/defaulted `SettingsRecord` property per
`cloudkit-schema-release`; Settings row «Целевая запоминаемость». Affects only
intervals computed afterwards.

## Risks / Trade-offs

- [Migration heuristic mis-estimates some cards] → clamps; FSRS corrects after
  one review; tests on representative states.
- [Different intervals surprise users] → plain release note; captions show the
  new intervals before grading.
- [CloudKit schema change] → optional fields; production deploy gate from
  `cloudkit-schema-release`.
- [Older devices keep using SM-2 until updated] → consistency check re-migrates
  their writes; no data loss either way.

## Migration Plan

1. Ship scheduler, lazy migration and consistency check; old fields preserved.
2. Deploy the CloudKit schema with the new optional fields before release
   (gate in `cloudkit-schema-release`).
3. Rollback: switch the call site back to the SM-2 scheduler, which still reads
   `easeFactor`, `interval`, `repetitions`, `dueDate`, `status`.
