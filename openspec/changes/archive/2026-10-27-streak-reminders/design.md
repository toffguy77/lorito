## Context

The `reminders` capability is implemented end to end: a pure `ReminderPlanner`
in `Domain`, a `NotificationScheduling` protocol with a `UNUserNotificationCenter`
backend, `ReminderService` (persist config, authorize, resolve counts, reschedule),
and `RemindersView` in Settings. Streaks are computed separately by the
`stats-and-streak` calculator and are not connected to reminders. Onboarding
(`onboarding-and-selection`) selects level + themes only.

Two defects were found in the shipped reminders UI while validating this change:

1. **Non-reactive config.** `RemindersView` derives its list from
   `ReminderService.config`, a *computed* property that reads `store.loadSettings()`
   on each access. `ReminderService` is `@Observable`, but the macro only tracks
   *stored* properties, so mutating the store (e.g. `addTime`) does not invalidate
   the view — added times never appear.
2. **Swallowed persistence.** `ReminderService` writes settings via
   `try? store.saveSettings(...)`, discarding any error, and the enabled state is
   mirrored into a local `@State` in the view rather than read back reactively, so
   the toggle can appear to reset on re-entry.

These block a trustworthy onboarding reminder step, so they are in scope here.

## Goals / Non-Goals

**Goals:**
- Make reminder notifications streak-aware: weave a streak line into the body and
  fire a "save your streak" nudge on otherwise-empty days when the streak is at risk.
- Keep the planning decision pure and deterministic, adding streak state as input.
- Add a skippable onboarding reminder-time step reusing the existing authorization flow.
- Fix the reactivity + persistence defects so the reminders UI reflects and retains state.

**Non-Goals:**
- No separate "streak" notification type (streak is woven into the single reminder).
- No change to the `reminderConfig` / `UserSettings` shape.
- No push notifications / entitlements (local notifications only).
- No change to how the streak itself is calculated (`stats-and-streak` stays the source).

## Decisions

**Streak state as a planner input.** `ReminderPlanner.requests(...)` gains a
per-day streak input alongside the existing per-day counts closure — modeled as a
value carrying `currentStreak: Int` and `studiedToday: Bool` (for the fire day).
The planner stays pure: no clock, no I/O. Rationale: keeps determinism and the
existing test contract; the caller (`ReminderService`) does the impure resolution
from `StudyLog`/reviews via the `stats-and-streak` calculator.

**Body composition in Domain.** `body(due:new:streak:)` composes the Russian text,
prepending a streak line ("Серия: N дней 🔥") when the streak is active, and
producing a distinct "keep your streak" message when counts are zero but the
streak is at risk. Rationale: one testable place for all wording; UI stays dumb.

**Narrowed skip rule.** The skip condition becomes
`due == 0 && new == 0 && !streakAtRisk`, where
`streakAtRisk = currentStreak > 0 && !studiedToday`. Rationale: directly encodes
the agreed behavior while leaving all non-empty days unchanged.

**Onboarding step reuses the reminder flow.** The onboarding reminder-time screen
calls the same authorization + `reminderConfig` persistence path as
`RemindersView` (via `ReminderService`), rather than duplicating scheduling logic.
Skipping writes `enabled = false`. Rationale: single source of truth for the
enable flow; onboarding just supplies the first time.

**Fix reactivity via observed state, not computed store reads.** `ReminderService`
holds the current `ReminderConfig` in an observed stored property that is loaded
once and updated on every mutation (enable/disable/add/remove), writing through to
the store. `RemindersView` binds to that property instead of a fresh
`store.loadSettings()` each render. Rationale: makes `@Observable` actually drive
the view; removes the local-`@State` mirror that desyncs from persistence.

**Surface persistence failures.** Replace `try? store.saveSettings(...)` in the
service with error-handling that does not silently drop a failed save (at minimum
log; keep the in-memory config authoritative). Rationale: a swallowed save is
exactly how bug #2 hides.

## Risks / Trade-offs

- **[Streak resolution cost on reschedule]** → reschedule already loads reviews for
  counts; reuse the same fetch to derive streak/`studiedToday`, avoiding extra I/O.
- **[Body length with streak + counts]** → keep the streak line short; verify it
  reads well in the notification banner during acceptance.
- **[Changing the observed-config shape could ripple into tests]** → keep the public
  `config` accessor; only its backing (stored vs computed) changes, so call sites
  and existing tests stay valid.
- **[Onboarding step adds a screen to a required flow]** → make it explicitly
  skippable and non-blocking so completion is never gated on notifications.

## Open Questions

- Exact Russian wording for the save-streak nudge and the streak line (finalize
  during implementation/acceptance).
