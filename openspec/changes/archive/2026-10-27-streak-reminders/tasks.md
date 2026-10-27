## 1. Streak-aware planning decision (Domain, TDD)

- [x] 1.1 Write failing tests: `body(due:new:streak:)` weaves a Russian streak line when the streak is active (e.g. "Серия: 5 дней 🔥 — 3 на повторение"); no streak line when streak is 0; counts wording unchanged
- [x] 1.2 Write failing tests: skip rule is narrowed — a day with due=0, new=0 and streak-at-risk (streak>0 && !studiedToday) yields a "save your streak" request; a day with due=0, new=0 and not-at-risk (streak 0 OR studiedToday) yields no request
- [x] 1.3 Write failing tests: determinism holds with the new streak input (identical times+counts+streak+now → identical requests); other days in the horizon unaffected by a skipped day
- [x] 1.4 Extend `ReminderPlanner.requests(...)` to accept per-day streak state (currentStreak + studiedToday) alongside the counts closure; implement body composition and the narrowed skip rule; keep it pure (no clock, no I/O)
- [x] 1.5 Run `swift test` for Domain until the new tests pass with no regressions

## 2. Wire streak state into the scheduler (Features, TDD)

- [x] 2.1 Write failing tests: `ReminderService.reschedule` feeds the current streak and "studied today" (from the `stats-and-streak` calculator over reviews/StudyLog, using injected "now") into the planner
- [x] 2.2 Resolve streak + studiedToday inside `reschedule`, reusing the reviews fetch already used for counts; pass them to `ReminderPlanner.requests`
- [x] 2.3 Verify with the fake scheduler that a save-streak nudge is scheduled on an empty-but-at-risk day and suppressed once studiedToday is true

## 3. Fix reminders reactivity & persistence (Features, TDD)

- [x] 3.1 Write failing test: after `addTime`, the service's observed config exposes the new time (mutations are observable, not recomputed on each read)
- [x] 3.2 Make `ReminderService` hold `ReminderConfig` in an `@Observable` stored property, loaded once and updated write-through on enable/disable/add/remove
- [x] 3.3 Replace `try? store.saveSettings(...)` so a failed save is not silently dropped (surface/log; keep in-memory config authoritative); add a test that a save failure is observable
- [x] 3.4 Update `RemindersView` to bind to the observed config (drop the local `@State enabled` mirror); verify adding a second time appears in the list and the enabled state persists across re-entry
- [x] 3.5 Acceptance automated at two levels: (a) real SwiftData relaunch unit test — a second `ReminderService` from a fresh container observes enabled + both times; (b) `RemindersSettingsUITests` XCUITest drives Settings → Напоминания: enable shows the seeded time, add yields a second row (bug #1), and re-entry keeps the toggle on with both times (bug #2). Added `remindersEnabledToggle`/`reminderTimeRow` a11y ids + inline wheel picker for drivability.

## 4. Onboarding reminder-time step (Features, TDD)

- [x] 4.1 Write failing tests: confirming a time in onboarding persists `reminderConfig` (enabled=true + chosen time) and drives authorization; skipping leaves enabled=false and requests no authorization; onboarding completes either way
- [x] 4.2 Add the reminder-time screen at the end of onboarding (default 20:00, skippable), using DesignSystem tokens and Russian copy
- [x] 4.3 Wire the screen to the existing `ReminderService` authorization + persistence path (reuse, do not duplicate scheduling); handle the denied branch per `reminders` guidance without blocking completion
- [x] 4.4 Scheduling-from-onboarding covered by tests (onboarding suite: confirm enables + schedules via fake scheduler with correct body; skip/denied do not schedule). Residual: actual OS notification delivery at fire time is not unit-testable — manual/device only.

## 5. Validation & wrap-up

- [x] 5.1 `swift test` green across Domain/Content/Persistence/Features (161 tests)
- [x] 5.2 `xcodebuild` app build + `build-for-testing` succeed; `RemindersSettingsUITests` passes on simulator (69.985s); modified `PracticeFlowUITests` onboarding path re-verified green (testAboutScreen). Residual (irreducible): real OS notification delivery at fire time is device-only.
- [x] 5.3 Run `openspec validate streak-reminders --strict` and fix until valid
