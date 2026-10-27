## 0. Dependency

- [x] 0.1 `streak-reminders` applied (reminder planner takes streak state) — the freeze line builds on its inputs
- [x] 0.2 `learning-platform-foundation` applied (local learning day replaces UTC in the calculator)

## 1. Domain: freezes (TDD)

- [x] 1.1 Write failing tests: earn 1 per 7 consecutive studied days; cap 2; frozen days pause the earning counter; earning at cap is lost
- [x] 1.2 Write failing tests: missed past day with active streak and stock → frozen, stock −1, run continues without growing; consecutive misses consume one each; empty stock breaks the run; today never frozen
- [x] 1.3 Write failing tests: existing streak scenarios (5, 3 savable, gap → 0, no history) still pass unchanged
- [x] 1.4 Implement freeze accounting in `StatsCalculator` with `StreakConstants`

## 2. Domain: revival (TDD)

- [x] 2.1 Write failing tests: revive a 40-day streak with 3 consecutive days inside (L, L+7]; window missed; run shorter than 2 not revivable; second loss within 30 days not revivable
- [x] 2.2 Write failing tests: revival status none / in progress (k of 3, deadline, lost length) / completed; displayed streak during revival = new run only, then lost + 3
- [x] 2.3 Write failing tests: best streak counts bridged runs once (6 + frozen + 6 = 12) — tested as 7 + frozen + 5 = 12: "6 + frozen + 6" cannot arise from a log (a freeze needs 7 studied days earlier in the run; a run only breaks with an empty stock)
- [x] 2.4 Implement revival and bridged best-streak; determinism test with identical log + today

## 3. Features

- [x] 3.1 Today: "Серия спасена заморозкой" once after a frozen day; revival banner with lost length and days left
- [x] 3.2 Progress screen: freezes held indicator (inside the streak tile) (added element; coordinate with `progress-insights` layout)
- [x] 3.3 Reminders: pass `frozenYesterday` to the planner; add the freeze line to the first reminder of the day; planner test
- [x] 3.4 Reschedule reminders on scene foreground (in addition to launch / rollover / session completion); test that the trigger calls reschedule; document best-effort staleness

## 4. Validation

- [x] 4.1 `swift test` green
- [x] 4.2 `xcodebuild` build; UI test with a seeded log: missed day + freeze → Today banner and unchanged streak
- [x] 4.3 Release note draft: streaks may increase once after the update because past gaps can be frozen
- [x] 4.4 `openspec validate streak-protection --strict`
