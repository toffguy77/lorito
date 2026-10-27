# stats-and-streak Specification

## Purpose
TBD - created by archiving change stats-and-streak. Update Purpose after archive.
## Requirements
### Requirement: Pure deterministic stats calculation
The streak and counts SHALL be computed by a pure `Domain` calculator that takes the `StudyLog` events and an injected "today" and returns the current streak, best streak, and study counts. It SHALL perform no I/O, read no ambient clock, and return identical output for identical input.

#### Scenario: Same inputs yield same stats
- **WHEN** the calculator is called twice with the same events and injected "today"
- **THEN** both calls return identical streak and count values

#### Scenario: Clock is injected
- **WHEN** "today" is supplied as an argument
- **THEN** all day/week boundaries are computed against that injected day, not the system clock

### Requirement: Current daily streak
The calculator SHALL compute the current streak as the number of consecutive calendar days, ending at today (if studied today) or yesterday, on which at least one grade event occurred. A day with no event breaks the streak.

#### Scenario: Studied today extends the streak through today
- **WHEN** the user studied today and on each of the preceding 4 days
- **THEN** the current streak is 5

#### Scenario: Not studied today but studied yesterday
- **WHEN** the user has not studied today but studied yesterday and the 2 days before it
- **THEN** the current streak is 3 (today is still "savable", not yet lost)

#### Scenario: Gap resets the streak
- **WHEN** the user last studied 3 days ago with no activity since
- **THEN** the current streak is 0

#### Scenario: No history
- **WHEN** there are no study events
- **THEN** the current streak is 0

### Requirement: Best (longest) streak
The calculator SHALL compute the best streak as the longest run of consecutive study days anywhere in the history.

#### Scenario: Best streak from history
- **WHEN** the history contains a 7-day run and the current run is 2 days
- **THEN** the best streak is 7 and the current streak is 2

### Requirement: Study counts
The calculator SHALL report study counts: cards studied today, cards studied this week, and cards studied all-time, using the same day/week boundaries as the streak.

#### Scenario: Counts reflect the log
- **WHEN** the user graded 3 cards today and 10 cards earlier this week (13 this week total) and 50 all-time
- **THEN** studiedToday is 3, studiedThisWeek is 13, and studiedAllTime is 50

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

