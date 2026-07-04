## MODIFIED Requirements

### Requirement: Pure scheduling decision
The set of notification requests to schedule SHALL be produced by a pure decision function in the `Domain` layer that takes the reminder times, the due/new counts for the relevant day(s), the streak state for the relevant day(s) (the current streak length and whether a grade event has already occurred that day), and an injected "now"/clock, and returns the exact set of notification requests (each with a stable identifier, a calendar trigger date, and a localized title and body). The decision function SHALL NOT perform I/O, SHALL NOT call any system notification API, and SHALL NOT read any ambient clock (e.g. `Date.now`); for identical inputs it SHALL return identical output.

#### Scenario: Same inputs produce same requests
- **WHEN** the decision function is called twice with the same times, the same counts, the same streak state, and the same injected "now"
- **THEN** both calls return identical sets of notification requests (identifiers, trigger dates, titles, bodies)

#### Scenario: No hidden clock or I/O
- **WHEN** the decision function computes trigger dates
- **THEN** the result depends only on the injected "now" and the inputs (times, counts, streak state), and the function performs no notification-API or persistence access

#### Scenario: A request per future configured time
- **WHEN** reminders are enabled with times 09:00 and 20:00 and at least one count is non-zero for those days
- **THEN** the returned requests include one request per configured time within the scheduling horizon, each triggering at that local time

#### Scenario: Streak state is part of the inputs
- **WHEN** the decision function is called with two different streak states but otherwise identical inputs
- **THEN** the resulting notification bodies may differ, and each call is still deterministic for its own inputs

### Requirement: Content reflects the day's counts
Each scheduled notification's body SHALL reflect the due/new counts for the day it fires, expressed in Russian (e.g. "5 тем на повторение + 1 новая"). The wording SHALL distinguish the review (due) count from the new-card count, and SHALL use grammatically appropriate Russian for the counts. When a streak is active for the day the notification fires, the body SHALL additionally weave in a Russian streak line reflecting the current streak length (e.g. "Серия: 5 дней 🔥 — 3 на повторение"), composed within the same single notification body by the pure decision function.

#### Scenario: Body shows due and new counts
- **WHEN** a reminder is scheduled for a day with 5 due reviews and 1 new card
- **THEN** the notification body conveys both 5 reviews and 1 new card in Russian

#### Scenario: Only reviews due
- **WHEN** a reminder is scheduled for a day with due reviews and no new cards
- **THEN** the notification body conveys the review count and does not assert a new card is available

#### Scenario: Body weaves in the active streak
- **WHEN** a reminder is scheduled for a day with an active streak of 5 and some cards due
- **THEN** the notification body conveys the streak length (5 days) in Russian alongside the due/new counts, in a single notification

#### Scenario: No streak line when streak is zero
- **WHEN** a reminder is scheduled for a day and the current streak is 0
- **THEN** the notification body conveys the counts without asserting a streak

### Requirement: Skip reminders when nothing is due
When the due count and the new-card count for a given day are both zero, the decision function SHALL produce no notification request for that day ONLY IF the streak is not at risk on that day. The streak is "at risk" for a day when the current streak is active (greater than zero) and no grade event has yet occurred on that day, so studying is still needed to preserve it. When nothing is due and the streak is at risk, the decision function SHALL produce a "save your streak / keep learning" nudge for that day instead of skipping it. When nothing is due and the streak is not at risk (streak is zero, or the user has already studied that day), the day SHALL be skipped.

#### Scenario: Nothing due and streak not at risk means no notification
- **WHEN** a day has 0 due reviews, 0 new cards, and the streak is not at risk (streak is 0 or already studied today)
- **THEN** the decision function returns no notification request for that day

#### Scenario: Nothing due but streak at risk fires a save-streak nudge
- **WHEN** a day has 0 due reviews and 0 new cards, the current streak is active, and no grade event has occurred yet that day
- **THEN** the decision function returns a notification request whose Russian body urges the user to keep learning to preserve the streak

#### Scenario: Already studied today skips even with an active streak
- **WHEN** a day has 0 due reviews and 0 new cards, the streak is active, and a grade event has already occurred that day
- **THEN** the decision function returns no notification request for that day (the streak is safe)

#### Scenario: Other days unaffected by a skipped day
- **WHEN** one day in the horizon has nothing due and no streak risk but a later day has cards due
- **THEN** the skipped day yields no request while the later day still yields its request(s)
