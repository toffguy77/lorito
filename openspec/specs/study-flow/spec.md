# study-flow Specification

## Purpose
TBD - created by archiving change study-flow. Update Purpose after archive.
## Requirements
### Requirement: Today screen shows the day's queue summary
The Today screen SHALL obtain the day's queue from `daily-plan` and SHALL present its composition using the design-system segmented day-progress indicator together with the due and new counts (e.g. "N на повторение + M новых"). It SHALL NOT compute the queue itself.

#### Scenario: Counts and progress reflect the queue
- **WHEN** the Today screen is shown and `daily-plan` reports N due cards and M new cards remaining for today
- **THEN** the screen displays the counts as "N на повторение + M новых" and the segmented day-progress indicator reflects studied-versus-remaining progress for the day

#### Scenario: Progress updates after returning from a session
- **WHEN** the user returns to the Today screen after grading some cards in a session
- **THEN** the displayed counts and the day-progress indicator update to reflect the cards already studied

### Requirement: Today screen start action
The Today screen SHALL provide a primary action to start studying that is enabled only when the day's queue contains at least one card, and SHALL open the study session on the first card of the queue.

#### Scenario: Start a session
- **WHEN** the queue is non-empty and the user taps the primary start action
- **THEN** the study session opens showing the first card of the day's queue

#### Scenario: Start action disabled when nothing to study
- **WHEN** the day's queue is empty
- **THEN** the primary start action is unavailable

### Requirement: Today screen empty and all-done states
The Today screen SHALL render a distinct empty / all-done state for the day when the queue contains no cards, distinguishing "nothing due yet" from "all of today's cards completed", and SHALL NOT present a startable session in that state.

#### Scenario: All cards done for the day
- **WHEN** the user has studied every card in today's queue
- **THEN** the Today screen shows an all-done state for the day rather than an active session start

#### Scenario: Nothing due
- **WHEN** there are no due cards and no new cards available for today
- **THEN** the Today screen shows an empty state indicating there is nothing to study today

### Requirement: Study session renders the current card
The study session SHALL render the current card using the design-system study-card container, showing the card's level/theme chip, its title, and its Markdown body. The displayed card SHALL be the current card of the queue supplied by `daily-plan`.

#### Scenario: Current card displayed
- **WHEN** the study session presents the current card
- **THEN** it shows the card's level/theme chip, the card title, and the rendered Markdown body within the study-card container

### Requirement: Study session grade buttons apply a grade and advance
The study session SHALL present the four design-system SM-2 grade buttons (Опять / Трудно / Хорошо / Легко). Tapping a grade SHALL apply the `srs-engine` grade operation to the current card's `CardReview` (reference; not redefined here), SHALL write a `StudyLog` entry recording the card and grade, and SHALL advance to the next card in the queue.

#### Scenario: Grading advances to the next card
- **WHEN** the user taps one of the four grade buttons on the current card and another card remains in the queue
- **THEN** the `srs-engine` update is applied to that card's `CardReview`, a `StudyLog` entry for the card and grade is written, and the session shows the next card

#### Scenario: Each grade is recorded distinctly
- **WHEN** the user taps Опять versus Легко on a card
- **THEN** the `StudyLog` entry records the specific grade chosen for that card

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

### Requirement: Mid-session exit preserves progress
The study session SHALL allow the user to exit before the queue is exhausted, and all grades applied before exiting SHALL already be persisted (via the `srs-engine` apply-and-persist operation and the written `StudyLog` entries) so that no graded card is repeated and re-entering study resumes on the next ungraded card.

#### Scenario: Exit after partial progress
- **WHEN** the user grades some cards and then exits the session before finishing
- **THEN** the grades and `StudyLog` entries for the already-graded cards remain persisted

#### Scenario: Resume continues from where left off
- **WHEN** the user re-enters study after a mid-session exit
- **THEN** the session resumes without re-showing cards already graded today

### Requirement: Markdown rendering of card bodies
The app SHALL render card Markdown bodies such that the callout sections Суть, Ключевые моменты, Ошибки, and Полезно display as the corresponding design-system callout blocks, and Markdown tables render as tables. This rendering SHALL be used by both the study session and the catalog card reader.

#### Scenario: Callouts render as callout blocks
- **WHEN** a card body contains the Суть, Ключевые моменты, Ошибки, or Полезно sections
- **THEN** each section renders as its corresponding design-system callout block

#### Scenario: Tables render
- **WHEN** a card body contains a Markdown table
- **THEN** the table is rendered as a table

#### Scenario: Same rendering in catalog and session
- **WHEN** the same card is opened from the catalog reader and shown in the study session
- **THEN** its callouts and tables render identically in both

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

### Requirement: Today screen week strip
The Today screen SHALL show the last seven calendar days ending today, each labeled with its short Russian weekday name and marked as studied when its daily activity count is greater than zero; today SHALL be visually distinguished as the current day, and shown as studied once it has at least one grade event.

#### Scenario: Studied days marked
- **WHEN** the user studied on five of the six previous days and not yet today
- **THEN** the strip shows those five days as studied, the other previous day as not studied, and today as the current, not-yet-studied day

#### Scenario: Today becomes studied
- **WHEN** the user grades a card and returns to the Today screen
- **THEN** today is shown as studied

