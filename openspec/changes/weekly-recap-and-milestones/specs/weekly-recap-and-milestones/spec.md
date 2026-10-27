## ADDED Requirements

### Requirement: Weekly recap facts
A pure `Domain` function SHALL compute, for the week ending on the most recent Sunday and using the stats calculator's day boundaries, the number of days studied, the number of cards first studied in that week, the current long-term memory count, and the top trap of the week when one exists.

#### Scenario: Recap numbers
- **WHEN** in the week the user studied on 5 days and first studied 4 cards
- **THEN** the recap reports 5 days studied and 4 new rules

#### Scenario: No trap
- **WHEN** no card failed during the week
- **THEN** the recap has no top trap

#### Scenario: Deterministic
- **WHEN** the function runs twice with the same data and injected today
- **THEN** both recaps are identical

### Requirement: Weekly recap on Today
On the first visit to the Today screen on or after Sunday of each week, the app SHALL show the weekly recap card once; dismissing it SHALL record that week as seen so it does not reappear. A week with no study days SHALL show an encouraging message instead of a zero table.

#### Scenario: Shown once per week
- **WHEN** the user opens Today on Sunday, dismisses the recap, and opens Today again on Monday
- **THEN** the recap is not shown again until the next week

#### Scenario: Empty week
- **WHEN** the user did not study during the week
- **THEN** the recap shows an encouraging message rather than only zeros

### Requirement: Level milestone detection
A pure function SHALL report a level as newly closed when it is an included level, every non-suspended card of that level is in long-term memory as defined by the stats calculator, and the level has not been celebrated before.

#### Scenario: Level closed
- **WHEN** all 30 non-suspended A1 cards are in long-term memory and A1 was never celebrated
- **THEN** A1 is reported as newly closed

#### Scenario: Already celebrated
- **WHEN** A1 is closed and already in the celebrated levels
- **THEN** A1 is not reported again

### Requirement: Milestone celebration
When a level is newly closed, the app SHALL show a one-time celebration "A1 закрыт" (with the level's name) offering a shareable certificate image, and SHALL then record the level as celebrated. A celebrated level SHALL stay celebrated even if some of its cards later leave long-term memory.

#### Scenario: Celebrate once
- **WHEN** A1 becomes closed and the user opens the app
- **THEN** the celebration is shown once and A1 is recorded as celebrated

### Requirement: Share images contain no personal data
Recap and certificate share images SHALL be rendered on device and SHALL contain only the brand mark, the numbers or level being shared, and the month and year; they SHALL NOT contain the user's name, account, or device identifiers, and SHALL NOT present the result as an official exam certificate.

#### Scenario: Certificate content
- **WHEN** the user shares the A1 certificate
- **THEN** the image shows the brand mark, "A1", and the month and year, and no personal data
