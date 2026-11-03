# Spec Delta

## ADDED Requirements

### Requirement: Free practice started event
The app SHALL record a practice-started event when a free-practice session starts, carrying only the mode (mixed, weak, theme, level) and the number of exercises in the session. It SHALL NOT carry theme, level, card or exercise identifiers. Card-reader practice SHALL NOT record this event. Answers in either kind of practice continue to record the existing exercise-answered event.

#### Scenario: Mixed session started
- **WHEN** the user starts a «Смешанная» session of 20 exercises
- **THEN** a practice-started event with mode mixed and count 20 is recorded

#### Scenario: Reader practice not counted
- **WHEN** the user starts «Практика · 6» from a card's reader
- **THEN** no practice-started event is recorded
