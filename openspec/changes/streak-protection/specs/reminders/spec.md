## ADDED Requirements

### Requirement: Reminder mentions a used freeze
When the stats calculator reports that yesterday was frozen, the body of the first reminder scheduled for today SHALL include the Russian line "Заморозка спасла вашу серию" in addition to its other content. The line SHALL be composed by the pure reminder planning code from an input flag, with no clock or I/O.

#### Scenario: Freeze line added
- **WHEN** yesterday was frozen and reminders are scheduled for today at 09:00 and 20:00
- **THEN** the 09:00 reminder body includes "Заморозка спасла вашу серию" and the 20:00 body does not

#### Scenario: No freeze, no line
- **WHEN** yesterday was not frozen
- **THEN** no reminder body includes the freeze line
