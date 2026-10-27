# personal-traps Specification

## Purpose
TBD - created by archiving change personal-traps. Update Purpose after archive.
## Requirements
### Requirement: Personal traps derived from failures
A `.card` item SHALL be a personal trap when it has a «Частые ошибки» section and an unresolved failure, a failure being its first graded study event of a learning day with grade Опять. Evidence SHALL come only from study events (exercise answers count through the graded study event they write, never also through attempt records), and later same-day grades SHALL be ignored. The list SHALL be a pure `Domain` function with an injected today.

#### Scenario: Опять creates a trap
- **WHEN** the user's first grade of the day for card A1-07, which has a mistakes section, is Опять
- **THEN** A1-07 is a personal trap

#### Scenario: Failed exercise counted once
- **WHEN** the user answers an exercise of card A1-09 incorrectly, which writes an attempt record and an Опять study event
- **THEN** A1-09 is a personal trap with one failure

#### Scenario: Later same-day grade ignored
- **WHEN** the user's first grade of the day for a card is Хорошо and a later grade that day is Опять
- **THEN** no failure is counted for that day

#### Scenario: Трудно and missing section
- **WHEN** a card is graded Трудно, or graded Опять but has no mistakes section
- **THEN** the grade does not create a trap

### Requirement: Traps limited to the current scope
Personal traps SHALL be shown, counted and practised only for cards inside the user's current included scope; traps of cards outside it SHALL be hidden but kept, and SHALL reappear when the scope includes them again.

#### Scenario: Scope narrowed
- **WHEN** the user removes the theme of trap card A1-07 from the selection
- **THEN** A1-07 is not shown or counted as a trap

#### Scenario: Scope widened again
- **WHEN** the theme is selected again and A1-07 is still unresolved
- **THEN** A1-07 is shown as a trap again

### Requirement: Trap ranking
Personal traps SHALL be ordered by the learning day of their last failure, newest first, then by number of failures, highest first, then by card order.

#### Scenario: Most recent first
- **WHEN** card A failed yesterday and card B failed today
- **THEN** B is listed before A

### Requirement: Trap resolution
A trap SHALL be resolved after two passing outcomes after its last failure, a passing outcome being a first-of-day study grade of Хорошо or Легко, or «Ясно» in the traps session. A later failure SHALL reopen it.

#### Scenario: Two passes resolve
- **WHEN** a trap card is graded Хорошо on one day and marked «Ясно» in a later traps session
- **THEN** it is no longer a trap

#### Scenario: Failure reopens
- **WHEN** a resolved trap card's first grade on a later day is Опять
- **THEN** it is a trap again

### Requirement: Traps list screen
The app SHALL provide a «Мои ловушки» screen listing in-scope personal traps in ranked order with the card title, its «Частые ошибки» items and the failure count, opening the card in the reader on tap. Today SHALL show an entry «Мои ловушки · N» when N is greater than zero, with an accessibility label using the Russian plural form of «ловушка».

#### Scenario: Entry on Today
- **WHEN** the user has 4 unresolved in-scope traps
- **THEN** Today shows «Мои ловушки · 4» and its accessibility label reads «4 ловушки»

#### Scenario: No traps
- **WHEN** the user has no unresolved in-scope traps
- **THEN** Today shows no traps entry

### Requirement: Traps session outside the SRS
The traps session SHALL present up to 10 in-scope traps in ranked order, each showing its first «Частые ошибки» item before reveal and the full mistakes section after, with «Ещё путаю» and «Ясно» actions. Outcomes SHALL be stored as trap-practice events and SHALL NOT modify review state or write study events.

#### Scenario: Session limited to ten
- **WHEN** the user has 15 in-scope traps and starts the traps session
- **THEN** the session contains the top 10 traps

#### Scenario: SRS untouched
- **WHEN** the user marks a trap «Ясно»
- **THEN** a trap-practice event is stored and the card's review state is unchanged

