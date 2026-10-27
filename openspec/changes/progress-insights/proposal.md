## Why

The progress screen shows three numbers and a streak. It tells the user they
were busy, not that they are learning: there is no picture of consistency over
time and no sign that cards are moving into long-term memory. Both are the
strongest motivators in spaced repetition and both are already derivable from
data we store (`StudyLog`, `CardReview`). They also make the best screenshots
for the App Store and for investor demos.

## What Changes

- **Activity heatmap:** the last 12 weeks of study as a 7×12 grid, four
  intensity buckets, plus the total number of reviews in that window.
- **Long-term memory per level:** for each included level, how many cards have
  a review interval of at least 21 days out of the level's cards.
- **Week strip on Today:** the last seven days as studied/not studied with
  today marked, from the same daily series.
- All numbers come from pure, deterministic functions with an injected "today".

## Capabilities

### New Capabilities
<!-- None. -->

### Modified Capabilities
- `stats-and-streak`: adds the daily activity series, the long-term memory
  breakdown, and extends the progress screen to show them.
- `study-flow`: the Today screen shows the seven-day week strip.

## Impact

- **Domain**: `StatsCalculator` gains `dailyActivity(days:today:)` and
  `longTermMemory(reviews:catalog:levels:)`; constant `longTermIntervalDays = 21`.
- **Features**: `StatsModel`/`StatsView` (heatmap, memory bars),
  `TodayModel`/`TodayView` (week strip).
- **DesignSystem**: uses `heat0–heat3` tokens from `plumaje-design-system`
  (depends on it).
- No persistence changes.
- Out of scope: streak freezes ("заморозки") shown in an early mockup — needs
  its own change with rules for earning/spending.
