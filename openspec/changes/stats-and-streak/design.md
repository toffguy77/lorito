## Context

Every grade already writes a `StudyEvent` (`id` UUID, `cardID`, `date`, `grade`) via `GradingService` → `UserDataStore.appendEvent`, and `allEvents()` returns them. Nothing surfaces this. The app already standardizes day boundaries on a UTC `Calendar` (used by the planner, `DueSelection`, and the "graded today" logic in `TodayModel`). This change adds a pure calculator over the event log plus a screen — no new storage.

## Goals / Non-Goals

**Goals:**
- Pure, deterministic streak/count math in `Domain`, unit-testable with an injected "today".
- A progress screen showing current streak, best streak, and study counts.
- Correct, intuitive streak semantics around "today not yet studied".

**Non-Goals:**
- Charts, heatmaps, per-theme analytics, or goals/badges (possible later).
- New persistence or any change to scheduling/daily-plan/sync.
- Backfilling history beyond what `StudyLog` already contains.

## Decisions

- **Pure `StatsCalculator` over `[StudyEvent]` + injected `today`.** Returns a value type: `currentStreak`, `bestStreak`, `studiedToday`, `studiedThisWeek`, `studiedAllTime`. Rationale: mirrors the SM-2/daily-plan purity discipline; fully testable without a clock or store. The Features layer fetches events and calls it.
- **A "study day" = a calendar day (app day calendar) with ≥1 grade event.** Distinct days are derived by mapping each event's `date` to `startOfDay` and de-duplicating. Rationale: one calendar day with any activity keeps the streak alive.
- **Current streak includes today only if studied today; otherwise it counts the run ending yesterday.** If neither today nor yesterday has activity, the current streak is 0. Rationale: matches user intuition — you don't "lose" your streak until a full day passes; the screen can still nudge "study today to keep your N-day streak". *Alternative — reset at midnight regardless* feels punishing and is less motivating.
- **Counts use the same day/week boundaries.** `studiedToday` = events today; `studiedThisWeek` = events in the current calendar week; `studiedAllTime` = total events. "Cards studied" counts grade events (a card graded twice counts twice for effort; a distinct-cards variant can be added later if wanted). Rationale: simple, matches the "effort" framing of a streak.
- **Reuse the app's existing day calendar** (the shared UTC calendar) for all boundaries so stats agree with "graded today" on the Today screen. Rationale: consistency; avoid a second notion of "today".

## Risks / Trade-offs

- **Time-zone / travel edge cases** → like the rest of the app, boundaries use the injected day calendar; the calculator never reads the clock, so behavior is reproducible and matches Today's counts. Documented as a caller contract.
- **Large event logs** → counting/de-duping days is linear in events; fine for realistic volumes. If it ever matters, the calculator can pre-bucket by day.
- **"Cards studied" vs "reviews done"** → we count grade events (effort). If the team later wants distinct-card counts, it's an additive field on the result type.
