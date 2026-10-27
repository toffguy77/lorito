## ADDED Requirements

### Requirement: Recall prompt before the answer
The study session SHALL first present each card's front side — its level/theme chip, its title, and a recall prompt — without the card body and without grade buttons. The recall prompt SHALL be the card's `recall` field rendered as Markdown when present, and otherwise a generic Russian prompt built from the card title. A primary "Показать ответ" action SHALL reveal the card body and the grade buttons. The revealed state SHALL reset when the session advances to the next card.

#### Scenario: Card opens on the front side
- **WHEN** the study session presents a card
- **THEN** it shows the chip, title and recall prompt, and does not show the card body or the grade buttons

#### Scenario: Reveal shows answer and grades
- **WHEN** the user taps "Показать ответ"
- **THEN** the card body and the four grade buttons are shown

#### Scenario: Fallback prompt without recall field
- **WHEN** the current card has no `recall` field
- **THEN** the front side shows a generic prompt that includes the card title

#### Scenario: Next card starts unrevealed
- **WHEN** the user grades a revealed card and another card remains
- **THEN** the next card is presented on its front side

### Requirement: Grade buttons preview the next interval
After reveal, each grade button SHALL show, as its caption, when the card would next be due if that grade were chosen. The interval SHALL be computed by a pure `Domain` function that applies the `srs-engine` scheduling operation for that grade to the card's current review state (or a new state if none) with the injected "today", without persisting anything.

#### Scenario: Captions match the scheduler
- **WHEN** the grade buttons are shown for a card in a given review state
- **THEN** for every grade the caption equals the formatted interval returned by the scheduler for that state and grade

#### Scenario: Again on a reviewed card says today
- **WHEN** the scheduler's interval for Опять is 0 days
- **THEN** the Опять caption reads "сегодня"

#### Scenario: Preview does not change state
- **WHEN** the captions are computed and the user then exits without grading
- **THEN** the card's `CardReview` is unchanged and no `StudyLog` entry is written

### Requirement: Interval captions are formatted in Russian
Interval captions SHALL read "сегодня" for 0 days and otherwise a grammatically correct Russian count of days (e.g. "1 день", "3 дня", "8 дней").

#### Scenario: Russian plural forms
- **WHEN** intervals of 1, 3, 8 and 21 days are formatted
- **THEN** they read "1 день", "3 дня", "8 дней" and "21 день"

### Requirement: Trap of the day on the Today screen
The Today screen SHALL show a "Ловушка дня" card with the first item of the "Частые ошибки" section of one card from the user's included scope and that card's identifier, and SHALL open that card in the card reader when tapped. The card SHALL be chosen by a pure function of the candidate cards and the calendar day, preferring cards the user has already studied. When no card in scope has a mistakes section, the trap card SHALL NOT be shown.

#### Scenario: Same day, same trap
- **WHEN** the Today screen is opened twice on the same calendar day with the same scope
- **THEN** the same trap is shown both times

#### Scenario: Prefers studied cards
- **WHEN** candidate cards include both studied and never-studied cards with mistakes sections
- **THEN** the trap is chosen from the studied cards

#### Scenario: No candidates
- **WHEN** no card in the included scope has a mistakes section
- **THEN** no trap card is shown

## MODIFIED Requirements

### Requirement: Study session completion state
When the user grades the last card in the queue, the study session SHALL end to a completion state for the day rather than showing another card, and returning from it SHALL lead to the Today screen's all-done state. The completion state SHALL show a session summary computed by a pure function from the session's grades and the current stats: the number of distinct cards graded, the share of cards whose first grade in the session was Хорошо or Легко, the current streak (marked as a new record when it equals the best streak and is greater than 1), and up to three themes to revisit, being the themes of cards graded Опять or Трудно in the session ordered by count.

#### Scenario: Session ends when queue exhausted
- **WHEN** the user grades the final card of the queue
- **THEN** the session shows a completion state instead of another card

#### Scenario: Completion returns to Today
- **WHEN** the user dismisses the completion state
- **THEN** the Today screen is shown reflecting that the day's cards are done

#### Scenario: Summary reflects the session
- **WHEN** a session of 10 cards ends in which 8 cards were first graded Хорошо or Легко and 2 cards of theme "Род существительных" were graded Опять
- **THEN** the completion state shows 10 cards, 80% remembered on the first grade, the current streak, and "Род существительных" among the themes to revisit

#### Scenario: New record
- **WHEN** the current streak after the session equals the best streak and is greater than 1
- **THEN** the completion state marks the streak as a new record
