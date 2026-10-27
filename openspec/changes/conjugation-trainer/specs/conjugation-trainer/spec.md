## ADDED Requirements

### Requirement: Conjugation items
The system SHALL model a conjugation item as one verb in one tense, identified as `conj:<infinitive>:<tense-id>`, carrying the verb's full paradigm for that tense from the content bundle. Conjugation items SHALL be scheduled with the `srs-engine` scheduling operation and stored in the existing review store under their item id, without a new persisted record type.

#### Scenario: Item identity
- **WHEN** the verb `hablar` in tense `presente` is drilled
- **THEN** its review state is stored under the id `conj:hablar:presente`

#### Scenario: Shared scheduler
- **WHEN** a conjugation item is graded
- **THEN** its next review state is computed by the same scheduling operation used for cards

### Requirement: Tense unlocking
A tense SHALL be drillable only when the grammar card mapped to it in the tenses registry has a review state (has been studied at least once) and that card's level is among the learner's included levels. Unlocking SHALL be computed by a pure `Domain` function of the catalog, the review states and the settings.

#### Scenario: Locked until studied
- **WHEN** the card mapped to `preterito-indefinido` has never been studied
- **THEN** no item in that tense is offered

#### Scenario: Unlocked after study
- **WHEN** the mapped card has a review state and its level is included
- **THEN** items in that tense become eligible

### Requirement: Daily conjugation quota
The conjugation planner SHALL be a pure function that returns all due conjugation items in unlocked tenses plus at most `dailyConjugationCount` new items, introduced in ascending verb frequency rank within the earliest-unlocked tense first. A quota of 0 SHALL turn new conjugation items off while due items remain available.

#### Scenario: Quota honoured
- **WHEN** the quota is 5 and 40 new items are eligible
- **THEN** exactly 5 new items are planned, the most frequent verbs first

#### Scenario: Deterministic plan
- **WHEN** the planner runs twice with identical inputs and injected "today"
- **THEN** both runs return the same ordered items

### Requirement: Rotating persons per review
Each review of a conjugation item SHALL ask for two grammatical persons chosen by a pure deterministic function of the item id and its repetition count, so that all six persons are covered over successive reviews. The review's grade SHALL be the lower of the two answers' grades.

#### Scenario: Persons rotate
- **WHEN** an item is reviewed three times
- **THEN** the six persons asked across those reviews are all different

#### Scenario: Worse answer decides
- **WHEN** one answer is correct and the other incorrect
- **THEN** the item is graded Опять

### Requirement: Accent-aware answer checking
The conjugation checker SHALL compare a typed form with the expected form after trimming and lowercasing: an exact match SHALL grade Хорошо; a match only after removing diacritics SHALL be reported as "почти" with the accented form shown and grade Трудно; any other answer SHALL be incorrect, grade Опять, with the expected form shown.

#### Scenario: Exact form
- **WHEN** the expected form is `habló` and the user types `Habló `
- **THEN** the answer is correct and graded Хорошо

#### Scenario: Missing accent
- **WHEN** the expected form is `habló` and the user types `hablo`
- **THEN** the answer is reported as almost correct, `habló` is shown, and the grade is Трудно

#### Scenario: Wrong form
- **WHEN** the expected form is `habló` and the user types `hablé`
- **THEN** the answer is incorrect, graded Опять, and `habló` is shown

### Requirement: Conjugation drill screen
The app SHALL offer a conjugation drill from the Today screen and from the reader of each tense's grammar card, rendered in focus mode, showing the infinitive, its Russian translation, the tense, the requested persons with text fields, an accent row (`á é í ó ú ñ ü`), a check action, feedback per person, and a link to the tense's grammar card.

#### Scenario: Entry from Today
- **WHEN** conjugation items are planned for today
- **THEN** the Today screen offers «Спряжения» with their count and opens the drill

#### Scenario: Accent row inserts characters
- **WHEN** the user taps `ñ` on the accent row
- **THEN** `ñ` is inserted at the cursor of the focused field

### Requirement: Drills count as study
Grading a conjugation item SHALL write a study event under the item id, so drills count toward the daily streak and the study counts.

#### Scenario: Drill keeps the streak
- **WHEN** the user only completes conjugation drills on a day
- **THEN** that day counts as a studied day for the streak
