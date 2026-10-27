# conjugation-trainer Specification

## Purpose
TBD - created by archiving change conjugation-trainer. Update Purpose after archive.
## Requirements
### Requirement: Conjugation items
The system SHALL model a conjugation item as one verb in one tense, identified as `conj:<infinitive>:<tense-id>` (item kind per `learning-platform-foundation`), carrying the verb's paradigm for that tense from the content bundle. Conjugation items SHALL be scheduled with the `srs-engine` scheduling operation and stored in the existing review store, without a new persisted record type.

#### Scenario: Item identity
- **WHEN** the verb `hablar` in tense `presente` is drilled
- **THEN** its review state is stored under the id `conj:hablar:presente`

#### Scenario: Shared scheduler
- **WHEN** a conjugation item receives its first graded review of the learning day
- **THEN** its next review state is computed by the same scheduling operation used for cards

### Requirement: Tense unlocking
A tense SHALL be drillable only when the grammar card mapped to it in the tenses registry has a review state (has been studied at least once) and that card's level is among the learner's included levels. Unlocking SHALL be computed by a pure `Domain` function of the catalog, the review states and the settings.

#### Scenario: Locked until studied
- **WHEN** the card mapped to `preterito-indefinido` has never been studied
- **THEN** no item in that tense is offered

#### Scenario: Unlocked after study
- **WHEN** the mapped card has a review state and its level is included
- **THEN** items in that tense become eligible

### Requirement: Opt-in conjugation quota
The setting `dailyConjugationCount` SHALL default to 0 (trainer off) for all learners; enabling the trainer SHALL set it to 3 unless the learner picks another value (0–20). New conjugation items SHALL count against the combined daily new-introduction budget of `learning-platform-foundation` and SHALL be introduced in ascending verb rank within the earliest-unlocked tense first.

#### Scenario: Off by default
- **WHEN** a learner has never enabled the trainer
- **THEN** no new conjugation items are planned and Today shows no «Спряжения» block

#### Scenario: Enabled default
- **WHEN** the learner enables the trainer without changing the quota
- **THEN** at most 3 new conjugation items are planned per learning day, most frequent verbs first

### Requirement: Daily cap on conjugation reviews
A pure conjugation planner SHALL return at most 20 due conjugation items per learning day, most overdue first and then by item id, plus the new items allowed by the quota; identical inputs and injected "today" SHALL yield identical output.

#### Scenario: Cap applies
- **WHEN** 45 conjugation items are due on a learning day
- **THEN** 20 are planned and the other 25 remain due for later days

#### Scenario: Deterministic plan
- **WHEN** the planner runs twice with identical inputs and injected "today"
- **THEN** both runs return the same ordered items

### Requirement: Rotating persons per review
Each review of a conjugation item SHALL ask for two persons from the variant's person set, chosen by a pure function of the item id and the number of graded study events recorded for that item, so that successive reviews cycle through the whole person set even after an Опять. The review's grade SHALL be the lower of the two answers' grades. The person set SHALL be an input provided by `regional-variants` (Spain: yo, tú, él, nosotros, vosotros, ellos).

#### Scenario: Persons rotate in Spain
- **WHEN** an item has been reviewed three times with the Spain person set
- **THEN** the six persons asked across those reviews are all different

#### Scenario: Rotation survives a lapse
- **WHEN** an item's second review is graded Опять
- **THEN** the third review asks persons not asked in the first two reviews

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

### Requirement: Reflexive verb answers
For reflexive verbs the expected answer SHALL include the reflexive pronoun before the form (`me levanto`). An answer with the correct verb form but a missing or wrong pronoun SHALL be reported as "почти" with the full expected answer and graded Трудно. The prompt SHALL mark the verb as reflexive.

#### Scenario: Pronoun included
- **WHEN** the expected answer is `me levanto` and the user types `me levanto`
- **THEN** the answer is correct

#### Scenario: Pronoun missing
- **WHEN** the expected answer is `me levanto` and the user types `levanto`
- **THEN** the answer is reported as almost correct with `me levanto` shown and graded Трудно

### Requirement: Conjugation drill screen
The app SHALL offer a conjugation drill from the Today screen when items are planned and from the reader of each mapped tense card, rendered in focus mode, showing the infinitive, its Russian translation, the tense, the requested persons with text fields, an accent row (`á é í ó ú ñ ü`), a check action, feedback per person, and a link to the tense's grammar card. The trainer SHALL be available to all learners at no cost.

#### Scenario: Entry from Today
- **WHEN** conjugation items are planned for today
- **THEN** the Today screen offers «Спряжения» with their count and opens the drill

#### Scenario: Accent row inserts characters
- **WHEN** the user taps `ñ` on the accent row
- **THEN** `ñ` is inserted at the cursor of the focused field

### Requirement: Drills keep the streak
Grading a conjugation item SHALL write a study event under the item id, so a day with only conjugation drills counts as a studied day for the streak; drills SHALL NOT be counted as studied cards.

#### Scenario: Drill keeps the streak
- **WHEN** the user only completes conjugation drills on a learning day
- **THEN** that day counts as a studied day and the studied-cards count is unchanged

