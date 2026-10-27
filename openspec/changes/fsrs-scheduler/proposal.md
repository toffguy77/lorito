## Why

Lorito schedules reviews with a fixed SM-2 variant (ease factor, ease floor,
hard/easy multipliers). SM-2 does not model how likely a card is to be
remembered, so it cannot target a retention level, and it tends to over- or
under-review depending on the card. FSRS, the open-source scheduler now
available in Anki, models stability, difficulty and retrievability and picks the
interval that hits a desired retention. Switching gives fewer reviews for the
same memory (the main daily cost for our users) and a credible answer to
"anki people" comparing apps. Interval captions on grade buttons make the
scheduler visible, so its quality now matters to every session.

## What Changes

- **BREAKING (spec behavior):** replace the SM-2 rules in `srs-engine` with an
  FSRS-6 scheduler: per-card stability and difficulty, interval derived from a
  desired retention; ease factor, ease floor and the hard/easy multiplier rules
  are removed.
- **Pure and deterministic** as before: no fuzz, injected "today", whole-day
  intervals, same-day relearn (interval 0 → «сегодня»).
- **Desired retention setting:** «Целевая запоминаемость», 80–95%, default
  90%, applied to future intervals only.
- **Migration:** existing SM-2 states are converted to FSRS memory state by a
  pure, tested function on first use; no data loss; old fields kept for
  rollback.
- **Interval ordering guaranteed:** for any state, Опять ≤ Трудно ≤ Хорошо <
  Легко, so the captions from `recall-first-study` stay meaningful.
- Maximum interval constant (default 365 days).

## Capabilities

### New Capabilities
<!-- None. -->

### Modified Capabilities
- `srs-engine`: scheduling model changes from SM-2 to FSRS; ease-specific
  requirements removed; new requirements for memory state, desired retention,
  migration, interval ordering and maximum interval.

## Impact

- **Domain**: new `FSRSScheduler` (pure) replacing
  `SpacedRepetitionScheduler.schedule` behind the same call shape;
  `FSRSParameters` (21 defaults); `ReviewState` gains optional `stability`,
  `difficulty`; `SM2Migration`; `IntervalPreview` keeps working unchanged
  (it calls the scheduler).
- **Persistence**: SwiftData record gains two optional `Double` fields —
  additive, CloudKit-compatible; schema deployed to CloudKit production.
- **Features**: Settings row for desired retention.
- `UserSettings` gains `desiredRetention: Double = 0.9`.
- Tests: scheduler, migration, preview captions, daily-plan due selection
  regression.
