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
The app SHALL present a progress screen that displays the current streak prominently, the best streak, and the study counts, reachable as a top-level destination. With no study history it SHALL show an encouraging empty/zero state rather than an error.

#### Scenario: Stats are shown
- **WHEN** the user opens the progress screen with existing study history
- **THEN** it shows the current streak, best streak, and the today/this-week/all-time counts

#### Scenario: Empty state
- **WHEN** the user opens the progress screen with no study history
- **THEN** it shows a zero/encouraging state (e.g., streak 0) and no error

