## Why

Reminders today only nudge the user about the day's due/new card counts, and go
silent on any day with nothing due — exactly the days a hard-won streak is most
likely to be lost. The streak is the app's main retention hook, yet notifications
never mention it, and new users are never prompted to pick a reminder time, so
most never enable reminders at all. This change makes reminders streak-aware and
puts the reminder-time choice in front of the user during onboarding.

## What Changes

- Notification bodies gain a **streak line** woven into the existing text
  (e.g. "Серия: 5 дней 🔥 — 3 на повторение"). Still one notification per fire,
  still a pure `Domain` function.
- **BREAKING (spec behavior):** the "skip reminders when nothing is due" rule is
  narrowed. A day is now skipped only when there is nothing due **and** the streak
  is not at risk. When the streak is active and the user has not studied yet today
  (streak "savable" but at risk), a "save your streak / keep learning" nudge fires
  even with `due=0 && new=0`.
- The pure reminder-planning decision gains **streak state** as an input (current
  streak length + whether today already has a grade event), alongside the injected
  "now". No ambient clock, no I/O — same determinism contract.
- Onboarding gains a final **reminder-time step**: pick a first reminder time
  (default 20:00), which requests notification authorization and writes
  `reminderConfig` (enabled + the chosen time). The step is skippable; skipping
  leaves reminders off. Reuses the existing `reminders` authorization flow.

## Capabilities

### New Capabilities
<!-- None — this extends existing capabilities. -->

### Modified Capabilities
- `reminders`: notification body includes a streak line; the "skip when nothing
  due" requirement is narrowed to also consider streak-at-risk; the pure planning
  decision takes streak state as an additional input.
- `onboarding-and-selection`: adds a skippable reminder-time step that sets the
  first reminder time and drives the notification authorization flow.

## Impact

- **Domain**: `ReminderPlanner` gains a streak-state input; `body(...)` composes a
  streak line; the skip condition is extended. Consumes streak values already
  produced by the `stats-and-streak` calculator.
- **Features**: `ReminderService` resolves current streak + "studied today" and
  feeds them into the planner; the onboarding flow adds a reminder-time screen
  wired to the existing authorization helper and `reminderConfig` persistence.
- **DesignSystem**: reuse existing components for the onboarding time-picker screen
  (semantic tokens, Russian copy).
- No new entitlements (still local notifications only). No `UserSettings` model
  redefinition — `reminderConfig` shape is unchanged.
