## ADDED Requirements

### Requirement: Personal traps derived from failures
A card SHALL be a personal trap when it has a «Частые ошибки» section and has at least one failure — a study grade of Опять or an incorrect exercise attempt — that is not yet resolved. The list SHALL be computed by a pure `Domain` function of study events, exercise attempts, trap-practice events, the content catalog and an injected today.

#### Scenario: Опять creates a trap
- **WHEN** the user grades card A1-07, which has a mistakes section, as Опять
- **THEN** A1-07 is in the personal traps list

#### Scenario: Failed exercise creates a trap
- **WHEN** the user answers an exercise of card A1-09 incorrectly and A1-09 has a mistakes section
- **THEN** A1-09 is in the personal traps list

#### Scenario: No mistakes section, no trap
- **WHEN** the user grades a card without a mistakes section as Опять
- **THEN** that card is not in the personal traps list

#### Scenario: Трудно is not a failure
- **WHEN** the user grades a card Трудно
- **THEN** the grade does not create a trap

### Requirement: Trap ranking
Personal traps SHALL be ordered by the date of their last failure, newest first, then by number of failures, highest first, then by card order.

#### Scenario: Most recent first
- **WHEN** card A failed yesterday and card B failed today
- **THEN** B is listed before A

### Requirement: Trap resolution
A trap SHALL be resolved after two passing outcomes recorded after its last failure, where a passing outcome is a study grade of Хорошо or Легко, a correct exercise attempt, or "Понял" in the traps session. A later failure SHALL reopen it.

#### Scenario: Two passes resolve
- **WHEN** a trap card is graded Хорошо and later "Понял" in the traps session
- **THEN** it leaves the personal traps list

#### Scenario: Failure reopens
- **WHEN** a resolved trap card is graded Опять again
- **THEN** it returns to the personal traps list

### Requirement: Traps list screen
The app SHALL provide a «Мои ловушки» screen listing personal traps in ranked order, each with the card title, its «Частые ошибки» items and the failure count, opening the card in the reader on tap. Today SHALL show an entry "Мои ловушки · N" when N is greater than zero.

#### Scenario: Entry on Today
- **WHEN** the user has 4 unresolved traps
- **THEN** Today shows "Мои ловушки · 4"

#### Scenario: No traps
- **WHEN** the user has no unresolved traps
- **THEN** Today shows no traps entry

### Requirement: Traps session outside the SRS
The traps session SHALL present up to 10 personal traps in ranked order, each showing its first «Частые ошибки» item before reveal and the full mistakes section after reveal, with "Ещё путаю" and "Понял" actions. Outcomes SHALL be stored as trap-practice events and SHALL NOT modify `CardReview` or write study events.

#### Scenario: Session limited to ten
- **WHEN** the user has 15 traps and starts the traps session
- **THEN** the session contains the top 10 traps

#### Scenario: SRS untouched
- **WHEN** the user marks a trap "Понял"
- **THEN** a trap-practice event is stored and the card's `CardReview` is unchanged
