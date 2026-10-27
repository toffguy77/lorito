## ADDED Requirements

### Requirement: Today screen week strip
The Today screen SHALL show the last seven calendar days ending today, each labeled with its short Russian weekday name and marked as studied when its daily activity count is greater than zero; today SHALL be visually distinguished as the current day, and shown as studied once it has at least one grade event.

#### Scenario: Studied days marked
- **WHEN** the user studied on five of the six previous days and not yet today
- **THEN** the strip shows those five days as studied, the other previous day as not studied, and today as the current, not-yet-studied day

#### Scenario: Today becomes studied
- **WHEN** the user grades a card and returns to the Today screen
- **THEN** today is shown as studied
