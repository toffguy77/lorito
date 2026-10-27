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
The calculator SHALL compute the current streak as the number of studied learning days (local calendar days, per `learning-platform-foundation`, with at least one grade event) in the current run, ending at today (if studied today) or yesterday. A run continues across frozen and revived days, which do not add to its length. A missed day that is neither frozen nor revived breaks the streak.

#### Scenario: Studied today extends the streak through today
- **WHEN** the user studied today and on each of the preceding 4 days
- **THEN** the current streak is 5

#### Scenario: Not studied today but studied yesterday
- **WHEN** the user has not studied today but studied yesterday and the 2 days before it
- **THEN** the current streak is 3 (today is still "savable", not yet lost)

#### Scenario: Gap resets the streak
- **WHEN** the user last studied 3 days ago with no activity since and has no freezes
- **THEN** the current streak is 0

#### Scenario: Frozen day keeps the streak
- **WHEN** the user studied 10 days in a row, missed one day while holding a freeze, and studied today
- **THEN** the current streak is 11

#### Scenario: No history
- **WHEN** there are no study events
- **THEN** the current streak is 0

### Requirement: Best (longest) streak
The calculator SHALL compute the best streak as the longest run of studied learning days anywhere in the history, where runs continue across frozen and revived days without counting them.

#### Scenario: Best streak from history
- **WHEN** the history contains a 7-day run and the current run is 2 days
- **THEN** the best streak is 7 and the current streak is 2

#### Scenario: Protected run counts as one
- **WHEN** the history contains 6 studied days, one frozen day, then 6 studied days
- **THEN** the best streak is 12

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

### Requirement: Streak freezes
The calculator SHALL derive freezes from the study log: one freeze is earned for every 7 consecutive studied days in a run, at most 2 are held, and a held freeze is consumed automatically for each missed past day while the current run is longer than zero, marking that day frozen. It SHALL report the number of freezes held and whether yesterday was frozen.

#### Scenario: Freeze earned
- **WHEN** the user studied 7 consecutive days and held no freezes
- **THEN** freezes held is 1

#### Scenario: Cap at two
- **WHEN** the user studied 21 consecutive days without missing a day
- **THEN** freezes held is 2

#### Scenario: Freeze consumed
- **WHEN** the user holds 1 freeze, has an active streak, and missed yesterday
- **THEN** yesterday is frozen, freezes held is 0, and the streak is not lost

### Requirement: Streak revival
When a run of at least 2 days is lost, the calculator SHALL restore it if the user studies on 3 consecutive learning days within the 7 days after the first lost day; missed days are then marked revived and the run continues from its previous length. At most one revival SHALL occur per 30 days. While a revival is in progress the current streak SHALL be the new run only, and the calculator SHALL report the revival status and the lost length.

#### Scenario: Streak revived
- **WHEN** a 40-day streak was lost on day L and the user studied on days L+2, L+3 and L+4
- **THEN** the current streak is 43

#### Scenario: Window missed
- **WHEN** a 40-day streak was lost on day L and the user's 3 consecutive study days end on day L+9
- **THEN** the streak is not revived and counts from the new run only

#### Scenario: Revival in progress
- **WHEN** a 40-day streak was lost on day L and the user has studied on L+1 and L+2
- **THEN** the current streak is 2 and revival status is in progress with 2 of 3 days done, deadline L+7 and lost length 40

### Requirement: Streak protection is visible
The Today screen SHALL show "Серия спасена заморозкой" on the first visit after a frozen day and, while a revival is in progress, a banner with the lost streak length and the study days still needed. The progress screen SHALL show the number of freezes held.

#### Scenario: Freeze banner
- **WHEN** yesterday was frozen and the user opens Today
- **THEN** Today shows "Серия спасена заморозкой"

#### Scenario: Revival banner
- **WHEN** revival is in progress for a 40-day streak with 1 of 3 days done
- **THEN** Today shows that 2 more study days restore the 40-day streak

### Requirement: Weeks start on Monday
Every week-based value computed by the stats calculator, including cards studied this week, SHALL use Monday–Sunday weeks of local learning days, independent of the calendar's default first weekday.

#### Scenario: Sunday belongs to the ending week
- **WHEN** the user studied 3 cards on Sunday and 2 on the following Monday, and today is that Monday
- **THEN** cards studied this week is 2

#### Scenario: Monday starts a new week
- **WHEN** today is Monday and the user has not studied yet today
- **THEN** cards studied this week is 0

