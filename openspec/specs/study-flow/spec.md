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
When the user grades the last card in the queue, the study session SHALL end to a completion state for the day rather than showing another card, and returning from it SHALL lead to the Today screen's all-done state.

#### Scenario: Session ends when queue exhausted
- **WHEN** the user grades the final card of the queue
- **THEN** the session shows a completion state instead of another card

#### Scenario: Completion returns to Today
- **WHEN** the user dismisses the completion state
- **THEN** the Today screen is shown reflecting that the day's cards are done

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

