## Why

Lorito records every grade as a `StudyLog` event but never shows the learner their progress. Spaced repetition is a habit, and the strongest habit lever is visible momentum: a daily streak and simple counts ("you studied N cards today", "M-day streak"). The data already exists (`StudyEvent` with `cardID`, `date`, `grade` via `UserDataStore.allEvents()`); this change surfaces it as a progress screen, with the streak/count math kept in a pure, testable `Domain` calculator.

## What Changes

- Add a pure **`Domain` stats calculator**: given the `StudyLog` events and an injected "today", it computes the current daily streak (consecutive days, up to and including today, with at least one study event), the best (longest) streak, and study counts (today, this week, all-time cards studied), with no I/O and no ambient clock.
- Add a **progress screen** (`Features`) that displays the current streak prominently, the best streak, and the counts, using design-system tokens/components.
- Define the **streak rules**: a day counts when it has ≥1 grade event; the current streak includes today if studied today, otherwise it reflects the run ending yesterday (today still "savable"); gaps reset the streak; day boundaries use the app's existing day calendar.
- Define the **empty state**: a learner with no study history sees a zero/encouraging state, not a broken screen.
- Wire the screen into the app as a top-level destination (a tab) alongside Today, Catalog, and Settings.

This change adds no new persistence, no new dependencies, and does not alter scheduling, the daily plan, or sync.

## Capabilities

### New Capabilities
- `stats-and-streak`: A progress view of study habits — a pure Domain calculator that derives the current daily streak, the best streak, and study counts (today / this week / all-time) from the `StudyLog` with an injected "today", plus a Features progress screen presenting them (including the empty state), wired in as a top-level destination.

### Modified Capabilities
<!-- None at the requirement level. This reads the existing app-foundation StudyLog (StudyEvent) and UserDataStore without changing them, and adds a new screen without altering existing flows. -->

## Impact

- **Code**: a pure `StatsCalculator` (+ value types) in `Domain` with unit tests; a progress screen in `Features` using `DesignSystem`; a tab entry in the main navigation. No `Persistence`/schema changes, no `Domain` model changes.
- **Foundation contracts consumed (not modified)**: `StudyEvent`/`StudyLog` and `UserDataStore.allEvents()` from `app-foundation`; `DesignSystem` tokens/components; the day-boundary calendar already used by the app.
- **No new dependencies.**
