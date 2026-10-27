## Why

The streak is Lorito's main retention hook, and it is brittle: one missed day
(a flight, a sick day) drops a 40-day streak to zero, and a user who loses a long
streak often stops altogether. Habit apps soften this with streak freezes and a
way back. Duolingo's June 2026 "Streak Revival" — earn back a lost streak by
completing three lessons — re-engaged more than 15 million lapsed learners
(BigGo, Q2 2026 earnings coverage). Lorito can do both without a server: the
rules can be computed purely from the study log we already store.

## What Changes

- **Streak freeze:** earned automatically, one per 7 consecutive study days,
  at most 2 stored; a stored freeze is used automatically for a missed day while
  a streak is active. A frozen day keeps the streak alive but does not add to it.
- **Streak revival:** when a streak is lost, studying on 3 consecutive days
  within the 7 days after the loss restores it (the gap is bridged); at most one
  revival per 30 days.
- **Visibility:** Today shows "серия спасена заморозкой" after a freeze was used
  and a revival banner with the days still needed; the progress screen shows
  freezes in stock.
- **Reminder copy:** the first reminder after a freeze was used says so.
- All rules are part of the pure stats calculation over the study log — no new
  persisted state.

## Capabilities

### New Capabilities
<!-- None. -->

### Modified Capabilities
- `stats-and-streak`: current and best streak account for frozen and revived
  days; ADDED requirements for freeze earning/use, revival, and their display.
- `reminders`: ADDED requirement for the "freeze used" line (does not modify
  the requirements changed by pending `streak-reminders`).

## Impact

- **Domain**: `StatsCalculator` gains freeze/revival accounting; new output
  fields (`freezesAvailable`, `frozenDays`, `revival` status); constants in
  `StreakConstants`.
- **Features**: Today banners; freeze stock on the progress screen (as an added
  element, without changing the pending `progress-insights` layout rules);
  reminder body line via the existing planner inputs.
- **Persistence**: none — everything is derived from `StudyLog` + injected today.
- **Widgets** (`home-screen-widgets`, pending): the snapshot's current streak
  already comes from the calculator and picks up the new rules for free.
