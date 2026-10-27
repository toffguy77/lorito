## Why

Lorito asks "how many new cards per day?" but never "what for, and by when?".
Learners with a deadline — a move, a job, the DELE A2 exam for Spanish
citizenship — have no way to see whether their daily pace gets them there, and
learners without one have nothing to pull them back on a lazy day. A goal with a
date turns the daily plan into a visible countdown and gives the app an honest
"on track / behind" signal, the strongest everyday motivator after the streak.

## What Changes

- **Optional study goal** with a target level and a target date. Presets:
  "Закрыть уровень" (any level in scope) and "DELE A2" (target level A2, the
  user picks the exam date); custom: any level + any future date.
- **Pacing:** while a goal is active, the daily new-card count is derived from
  the cards still to introduce up to the target level divided by the days left,
  clamped to a minimum and maximum; without a goal the existing setting applies.
- **Countdown and status on Today:** days left, cards left, and "в графике" /
  "отстаёте на N карточек" computed by a pure function.
- **Goal management** in Settings: create, edit, remove; reaching the goal or
  passing the date resolves it with a clear end state.
- Goal offered as an optional step after the level choice in onboarding.

## Capabilities

### New Capabilities
- `study-goal`: goal model, pacing function, progress status, lifecycle
  (active / achieved / expired), Today countdown, Settings management.

### Modified Capabilities
- `daily-plan`: ADDED requirement — the new-card limit fed to the composer is
  the goal pace while a goal is active.

## Impact

- **Domain**: `StudyGoal` value type; `GoalPacing` pure functions (pace,
  status, lifecycle) with injected "today".
- **Persistence**: `UserSettings.goal: StudyGoal?` — optional, defaults to nil,
  CloudKit-compatible.
- **Features**: Today countdown card; Settings → "Цель"; optional onboarding
  step (after level/themes, before the pending `streak-reminders` reminder step).
- **Reminders**: none in this change (goal-aware reminder copy can follow).
- Related: `exam-path-dele-ccse` (sibling) can create a DELE goal; this change
  only provides the generic goal.
