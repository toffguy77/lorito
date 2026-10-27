## MODIFIED Requirements

### Requirement: Trap of the day on the Today screen
The Today screen SHALL show a "Ловушка дня" card with the first item of the "Частые ошибки" section of one card from the user's included scope and that card's identifier, and SHALL open that card in the card reader when tapped. The card SHALL be chosen by a pure function of the candidate cards and the calendar day, choosing among the user's personal traps when there are any, otherwise preferring cards the user has already studied. When no card in scope has a mistakes section, the trap card SHALL NOT be shown.

#### Scenario: Same day, same trap
- **WHEN** the Today screen is opened twice on the same calendar day with the same scope
- **THEN** the same trap is shown both times

#### Scenario: Prefers studied cards
- **WHEN** the user has no personal traps and candidate cards include both studied and never-studied cards with mistakes sections
- **THEN** the trap is chosen from the studied cards

#### Scenario: Prefers personal traps
- **WHEN** the user has personal traps
- **THEN** the trap of the day is one of the personal trap cards

#### Scenario: No candidates
- **WHEN** no card in the included scope has a mistakes section
- **THEN** no trap card is shown
