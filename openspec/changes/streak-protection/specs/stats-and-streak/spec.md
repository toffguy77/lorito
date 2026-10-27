## MODIFIED Requirements

### Requirement: Current daily streak
The calculator SHALL compute the current streak as the number of studied calendar days (days with at least one grade event) in the current run, ending at today (if studied today) or yesterday. A run continues across frozen and revived days, which do not add to its length. A missed day that is neither frozen nor revived breaks the streak.

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
The calculator SHALL compute the best streak as the longest run of studied days anywhere in the history, where runs continue across frozen and revived days without counting them.

#### Scenario: Best streak from history
- **WHEN** the history contains a 7-day run and the current run is 2 days
- **THEN** the best streak is 7 and the current streak is 2

#### Scenario: Protected run counts as one
- **WHEN** the history contains 6 studied days, one frozen day, then 6 studied days
- **THEN** the best streak is 12

## ADDED Requirements

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
When a run of at least 2 days is lost, the calculator SHALL restore it if the user studies on 3 consecutive days that all fall within the 7 days after the first lost day; the missed days are then marked revived and the run continues from its previous length. At most one revival SHALL occur within any 30-day period. The calculator SHALL report revival status: none, in progress with days done and deadline, or completed.

#### Scenario: Streak revived
- **WHEN** a 40-day streak was lost on day L and the user studied on days L+2, L+3 and L+4
- **THEN** the current streak is 43

#### Scenario: Window missed
- **WHEN** a 40-day streak was lost on day L and the user's 3 consecutive study days end on day L+9
- **THEN** the streak is not revived and counts from the new run only

#### Scenario: Revival in progress
- **WHEN** a streak was lost on day L and the user has studied on L+1 and L+2
- **THEN** revival status is in progress with 2 of 3 days done and deadline L+7

### Requirement: Streak protection is visible
The Today screen SHALL show "Серия спасена заморозкой" on the first visit after a frozen day and, while a revival is in progress, a banner with the lost streak length and the study days still needed. The progress screen SHALL show the number of freezes held.

#### Scenario: Freeze banner
- **WHEN** yesterday was frozen and the user opens Today
- **THEN** Today shows "Серия спасена заморозкой"

#### Scenario: Revival banner
- **WHEN** revival is in progress for a 40-day streak with 1 of 3 days done
- **THEN** Today shows that 2 more study days restore the 40-day streak
