## ADDED Requirements

### Requirement: Daily activity series
The stats calculator SHALL provide, as a pure deterministic function of the study events and an injected "today", the number of grade events for each of the last N calendar days (N = 84 for the progress screen), ordered oldest first and using the same day boundary as the streak calculation. It SHALL also map each day to one of four intensity buckets: bucket 0 for days without events, and buckets 1–3 for days with events according to the quartiles of the non-zero counts within the window.

#### Scenario: Series length and order
- **WHEN** the series is requested for 84 days with a given "today"
- **THEN** it contains 84 entries, the last being "today" and the first being 83 days earlier

#### Scenario: Day without study
- **WHEN** a day in the window has no grade events
- **THEN** its count is 0 and its bucket is 0

#### Scenario: Same day boundary as the streak
- **WHEN** a grade event falls just before local midnight
- **THEN** it is counted on the same day for both the series and the streak

### Requirement: Long-term memory by level
The stats calculator SHALL compute, as a pure function of the review states and the content catalog, for each included level the number of that level's non-suspended cards whose review status is `review` with an interval of at least 21 days, and the total number of that level's non-suspended cards.

#### Scenario: Card counts as long-term
- **WHEN** an A1 card has status `review` and interval 21
- **THEN** it is counted in A1's long-term number

#### Scenario: Short interval not counted
- **WHEN** an A1 card has status `review` and interval 20
- **THEN** it is not counted in A1's long-term number but is counted in A1's total

#### Scenario: Suspended excluded
- **WHEN** a card is suspended
- **THEN** it is counted in neither the long-term number nor the total of its level

## MODIFIED Requirements

### Requirement: Progress screen
The app SHALL present a progress screen that displays the current streak prominently, the best streak, the study counts, a 12-week activity heatmap built from the daily activity series together with the total number of grade events in that window, and the long-term memory breakdown for each included level, reachable as a top-level destination. With no study history it SHALL show an encouraging empty/zero state rather than an error.

#### Scenario: Stats are shown
- **WHEN** the user opens the progress screen with existing study history
- **THEN** it shows the current streak, best streak, and the today/this-week/all-time counts

#### Scenario: Heatmap and memory are shown
- **WHEN** the user opens the progress screen with existing study history
- **THEN** it shows an 84-day heatmap colored by intensity bucket and, for each included level, the long-term count out of the level total

#### Scenario: Empty state
- **WHEN** the user opens the progress screen with no study history
- **THEN** it shows a zero/encouraging state (e.g., streak 0) and no error
