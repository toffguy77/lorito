## 0. Dependency

- [x] 0.1 `plumaje-design-system` applied (`heat0–heat3` tokens, tiles)

## 1. Domain (TDD)

- [x] 1.1 Failing tests for `dailyActivity(days:today:)`: length/order, zero days, midnight boundary identical to streak
- [x] 1.2 Failing tests for bucketing: zeros → 0, quartiles over non-zero counts, single non-zero value → 3
- [x] 1.3 Failing tests for `longTermMemory`: threshold 21 inclusive, suspended excluded, only included levels
- [x] 1.4 Implement in `StatsCalculator`; add `StatsConstants.longTermIntervalDays = 21`

## 2. Features

- [x] 2.1 `StatsModel` exposes series, buckets, total in window, memory rows
- [x] 2.2 `StatsView`: heatmap (`Grid`, 7×12, legend, per-cell a11y value + grid summary), memory bars per level (mockup `Progress.dc.html`)
- [x] 2.3 `TodayModel`/`TodayView`: week strip from the last 7 entries of the series (mockup `Today.dc.html`)

## 3. Validation

- [x] 3.1 `swift test` green
- [x] 3.2 UI test: grade one card → Today strip marks today; Progress shows heatmap with today's cell non-zero
- [x] 3.3 `openspec validate progress-insights --strict`
