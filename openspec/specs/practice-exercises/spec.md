# practice-exercises Specification

## Purpose
Interactive practical exercises that turn passive card review into active recall and feed the same per-card SM-2 schedule. Six exercise types (auto-checkable: multiple-choice, fill-in-the-blank, matching, word-order, picture-matching; self-assessed: free-response), a pure-Domain checking service, persisted attempts, and an interactive exercise screen.

## Requirements

### Requirement: Exercise domain model
The system SHALL define an `Exercise` value type in the pure `Domain` layer (no SwiftUI/SwiftData/CloudKit imports) carrying at least: a unique `id`, a `level`, a `theme`, the associated card id (`card`), a `type`, a Markdown prompt, an explanation, and the type-specific answer data. Each exercise SHALL be associated with exactly one existing card whose `level` equals the exercise's `level`.

#### Scenario: Exercise references a card
- **WHEN** an exercise is loaded
- **THEN** it exposes its associated card id, and that id resolves to a card of the same level in the catalog

#### Scenario: Domain stays portable
- **WHEN** the `Domain` target is built
- **THEN** the `Exercise` model and checking service compile without importing SwiftUI, SwiftData, or CloudKit

### Requirement: Exercise type taxonomy
The system SHALL support the following exercise `type` values, each either **auto-checkable** (the system decides correctness) or **self-assessed** (the user reveals the reference answer and grades themselves):

| `type` | mode | answer data |
|--------|------|-------------|
| `multiple-choice` | auto | `options` (≥2) + one correct `answer` |
| `fill-in-the-blank` | auto | expected `answer` + optional `accept` alternatives |
| `matching` | auto | ordered list of `pairs` (left ↔ right) |
| `word-order` | auto | `tokens` to arrange into the correct `answer` sentence |
| `picture-matching` | auto | `options`, each pairing an image asset with a label, + correct mapping |
| `free-response` | self-assessed | a reference `answer` (and optional `accept`) shown for self-grading |

An exercise's `type` SHALL be one of these values; an unknown type SHALL be rejected by validation (see content-pipeline).

#### Scenario: Each supported type loads
- **WHEN** an exercise of any supported `type` is loaded from the bundle
- **THEN** the model exposes that type and its type-specific answer data

#### Scenario: Auto vs self-assessed mode is known per type
- **WHEN** the checking service receives an exercise
- **THEN** it knows whether the type is auto-checkable or self-assessed and handles submission accordingly

### Requirement: Multiple-choice exercise type
A `multiple-choice` exercise SHALL consist of a prompt and a list of answer options of which **exactly one** is correct. Checking SHALL mark the answer correct only when the chosen option is the correct option.

#### Scenario: Correct option chosen
- **WHEN** the user selects the option marked correct
- **THEN** the checking service reports the answer as correct

#### Scenario: Wrong option chosen
- **WHEN** the user selects any option other than the correct one
- **THEN** the checking service reports the answer as incorrect

### Requirement: Fill-in-the-blank exercise type
A `fill-in-the-blank` exercise SHALL consist of a prompt with a gap, one expected answer, and an optional list of additional accepted answers. (Conjugation / "раскройте скобки" / transform tasks use this type.) The typed answer SHALL be compared by a **normalized** match that is insensitive to letter case, to diacritics (e.g. `é`≈`e`, `ñ`≈`n` for matching purposes), and to leading/trailing whitespace. A typed answer equal under normalization to the expected answer or to any accepted alternative SHALL be correct; otherwise incorrect.

#### Scenario: Exact answer accepted
- **WHEN** the user types the expected answer exactly
- **THEN** the checking service reports the answer as correct

#### Scenario: Case and whitespace ignored
- **WHEN** the user types the expected answer with different letter case and surrounding spaces
- **THEN** the checking service reports the answer as correct

#### Scenario: Accepted alternative
- **WHEN** the exercise lists an accepted alternative and the user types that alternative
- **THEN** the checking service reports the answer as correct

#### Scenario: Wrong answer rejected
- **WHEN** the user types an answer that matches neither the expected answer nor any accepted alternative under normalization
- **THEN** the checking service reports the answer as incorrect

### Requirement: Matching exercise type
A `matching` exercise SHALL present two columns of items (e.g. question ↔ answer, sentence start ↔ end) and SHALL be correct only when every left item is paired with its correct right item. The correct pairing SHALL be defined by the authored `pairs` and SHALL NOT depend on their presentation order.

#### Scenario: All pairs correct
- **WHEN** the user pairs every left item with its authored counterpart
- **THEN** the checking service reports the answer as correct

#### Scenario: Any pair wrong
- **WHEN** at least one left item is paired with the wrong right item
- **THEN** the checking service reports the answer as incorrect

### Requirement: Word-order exercise type
A `word-order` exercise SHALL present a set of `tokens` to be arranged into a target sentence. The arranged sequence SHALL be correct when it equals the authored `answer` under the same normalized comparison used for fill-in-the-blank (case/diacritic/whitespace-insensitive), and an exercise MAY declare additional accepted orderings.

#### Scenario: Correct order
- **WHEN** the user arranges the tokens into the authored target sentence
- **THEN** the checking service reports the answer as correct

#### Scenario: Wrong order
- **WHEN** the arranged sequence matches neither the authored answer nor any accepted ordering under normalization
- **THEN** the checking service reports the answer as incorrect

### Requirement: Picture-matching exercise type
A `picture-matching` exercise SHALL pair words with bundled images and SHALL be correct only when every label is matched to its correct image. Its image assets SHALL be compiled into the content bundle and referenced by the exercise.

#### Scenario: All labels matched
- **WHEN** the user matches every label to its authored image
- **THEN** the checking service reports the answer as correct

#### Scenario: Missing image asset fails validation
- **WHEN** a picture-matching exercise references an image asset absent from the bundle
- **THEN** content validation fails and reports the missing asset

### Requirement: Free-response (self-assessed) exercise type
A `free-response` exercise (e.g. translation, open question — "переведите", "ответьте на вопросы") SHALL let the user enter free text, then reveal an authored reference answer, then **self-grade** using the four SM-2 grade buttons. The system SHALL NOT auto-decide correctness for this type.

#### Scenario: Reference revealed for self-grading
- **WHEN** the user submits a free-response answer
- **THEN** the screen reveals the reference answer and presents the four SM-2 grade buttons for self-assessment

#### Scenario: Self-grade is the outcome
- **WHEN** the user picks one of the four grade buttons for a free-response exercise
- **THEN** that chosen grade is the SM-2 grade applied to the associated card

### Requirement: Auto-checked outcome maps to an SM-2 grade
For auto-checkable types, the checking service SHALL map an answer outcome to one of the four SM-2 grades for the exercise's associated card: a correct answer SHALL map to a passing grade (Хорошо by default) and an incorrect answer SHALL map to the failing grade (Опять). The mapping SHALL be a pure function with no I/O.

#### Scenario: Correct answer yields a passing grade
- **WHEN** the checking service evaluates a correct answer for an auto-checkable exercise
- **THEN** it returns a passing SM-2 grade for the associated card

#### Scenario: Incorrect answer yields the failing grade
- **WHEN** the checking service evaluates an incorrect answer for an auto-checkable exercise
- **THEN** it returns the Опять grade for the associated card

### Requirement: Practice result feeds the existing SRS
Submitting an answer SHALL apply the resulting SM-2 grade (auto-mapped for auto-checkable types, user-chosen for self-assessed types) to the associated card's existing `CardReview` through the `srs-engine` apply-and-persist operation (referenced, not redefined) and SHALL record a study event for the card and grade. Practice SHALL NOT introduce a separate schedule for the card; it updates the same per-card review state used by the study session.

#### Scenario: Correct answer advances the card's schedule
- **WHEN** the user answers an exercise correctly (or self-grades it passing)
- **THEN** the associated card's `CardReview` is updated via the `srs-engine` apply-and-persist operation with the resulting grade and a study event is recorded

#### Scenario: Incorrect answer reschedules the card sooner
- **WHEN** the user answers an auto-checkable exercise incorrectly
- **THEN** the associated card's `CardReview` is updated via the `srs-engine` apply-and-persist operation with the Опять grade and a study event is recorded

### Requirement: Exercise attempts are persisted
The system SHALL persist each exercise attempt (at least: exercise id, associated card id, timestamp, the resulting grade, and whether it was auto-marked correct) through the user-data store so attempts survive app restarts and sync through the existing CloudKit path when enabled.

#### Scenario: Attempt is recorded
- **WHEN** the user submits an answer to an exercise
- **THEN** an attempt record for that exercise is appended to the user-data store

#### Scenario: Attempts survive a restart
- **WHEN** the app is relaunched after attempts were recorded
- **THEN** the previously recorded attempts are still readable from the store

### Requirement: Interactive exercise screen
The system SHALL present an interactive exercise screen that renders the exercise prompt using design-system components and offers the input affordance matching the exercise type: option selection (multiple-choice / picture-matching), text entry (fill-in-the-blank / free-response), pair selection (matching), or token arrangement (word-order). It SHALL provide a submit action; after submission it SHALL show the outcome — for auto-checkable types, correct/incorrect feedback with the correct answer and explanation; for self-assessed types, the reference answer, explanation, and the four grade buttons — and SHALL provide a continue action that advances to the next exercise or to a completion state when none remain.

#### Scenario: Submitting an auto-checkable exercise reveals feedback
- **WHEN** the user submits an answer to an auto-checkable exercise
- **THEN** the screen shows whether the answer was correct, the correct answer, and the explanation

#### Scenario: Submitting a self-assessed exercise reveals the reference
- **WHEN** the user submits a free-response answer
- **THEN** the screen reveals the reference answer and explanation and presents the four grade buttons

#### Scenario: Continue advances
- **WHEN** the user taps continue after an exercise is resolved
- **THEN** the screen advances to the next exercise or to a completion state if none remain

#### Scenario: Submit unavailable without an answer
- **WHEN** the user has not provided an answer for the current exercise
- **THEN** the submit action is unavailable
