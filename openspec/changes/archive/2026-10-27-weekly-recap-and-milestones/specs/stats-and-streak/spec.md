## ADDED Requirements

### Requirement: Weeks start on Monday
Every week-based value computed by the stats calculator, including cards studied this week, SHALL use Monday–Sunday weeks of local learning days, independent of the calendar's default first weekday.

#### Scenario: Sunday belongs to the ending week
- **WHEN** the user studied 3 cards on Sunday and 2 on the following Monday, and today is that Monday
- **THEN** cards studied this week is 2

#### Scenario: Monday starts a new week
- **WHEN** today is Monday and the user has not studied yet today
- **THEN** cards studied this week is 0
