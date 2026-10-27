## ADDED Requirements

### Requirement: Exam tracks
The app SHALL offer a «Путь к гражданству» section with two tracks, DELE A2 and CCSE, each showing its format, timing, pass rule, and the date on which these facts were last verified.

#### Scenario: Tracks listed
- **WHEN** the user opens «Путь к гражданству»
- **THEN** the DELE A2 and CCSE tracks are shown with their format, pass rule and verification date

### Requirement: DELE A2 mock exam format
A DELE A2 mock exam SHALL consist of four timed sections — reading (60 min), listening (40 min), writing and interaction (45 min), speaking and interaction (12 min plus 12 min preparation) — as defined in the exam content data, presented in that order.

#### Scenario: Sections and timing
- **WHEN** the user starts a full DELE A2 mock
- **THEN** the four sections run in order, each with its time limit from the exam definition

### Requirement: DELE A2 scoring by group
DELE A2 mock scoring SHALL be computed by a pure function: Group 1 = reading + writing, Group 2 = listening + speaking, each scaled to 50 points; the mock SHALL be marked passed only when each group reaches its threshold from the exam definition (30 of 50), with no overall-percentage rule.

#### Scenario: One group below threshold
- **WHEN** a mock scores 38/50 in Group 1 and 28/50 in Group 2
- **THEN** it is marked not passed and Group 2 is identified as the failing group

#### Scenario: Both groups at threshold
- **WHEN** a mock scores 30/50 in each group
- **THEN** it is marked passed

### Requirement: Self-assessed productive tasks
Writing and speaking tasks SHALL be scored by the user against a rubric of checklist items mapped to points, and results that include self-assessed points SHALL be labelled as self-assessed.

#### Scenario: Rubric scoring
- **WHEN** the user ticks four of six rubric items worth 2 points each on a writing task
- **THEN** the task scores 8 points and the result is labelled self-assessed

### Requirement: CCSE mock test
A CCSE mock test SHALL draw 25 questions from the CCSE bank, limit the attempt to 45 minutes, and mark it passed when at least 15 answers are correct, with thresholds taken from the exam definition.

#### Scenario: Pass at 15
- **WHEN** a CCSE mock ends with 15 correct answers out of 25
- **THEN** it is marked passed

#### Scenario: Time runs out
- **WHEN** 45 minutes elapse before the last answer
- **THEN** the attempt ends and unanswered questions count as incorrect

### Requirement: CCSE bank practice with spaced repetition
Each CCSE bank item SHALL be schedulable by the existing spaced-repetition engine with its own review state and a separate daily quota, so CCSE practice does not reduce the grammar daily plan unless the user enables exam mode.

#### Scenario: Separate quota
- **WHEN** the user practises CCSE items on a day with a grammar plan of 12 cards
- **THEN** the grammar plan still contains 12 cards

### Requirement: Timer survives backgrounding
A mock timer SHALL be computed from the attempt's persisted start time, so leaving the app does not pause it, and an abandoned mock SHALL be stored as incomplete and excluded from readiness.

#### Scenario: App backgrounded
- **WHEN** the user leaves the app for 10 minutes during a 40-minute section
- **THEN** 30 minutes or less remain on return

### Requirement: Readiness score
The app SHALL show a readiness score from 0 to 100 per DELE group and for CCSE, with a label "likely pass", "borderline" or "not yet", computed by a pure function from recent mock results and the mastery of mapped grammar cards or CCSE items. A DELE group without a mock attempt of its productive part SHALL NOT be labelled higher than "borderline".

#### Scenario: Deterministic readiness
- **WHEN** readiness is computed twice from the same attempts and review states
- **THEN** both results are identical

#### Scenario: No speaking attempt
- **WHEN** Group 2 has listening mocks but no speaking attempt
- **THEN** Group 2 is labelled at most "borderline"

### Requirement: Exam date countdown
When the user has set an exam date through the study goal, the exam section SHALL show the number of days remaining and the readiness per part next to it.

#### Scenario: Countdown shown
- **WHEN** the exam date is 40 days away
- **THEN** the section shows 40 days remaining

### Requirement: Content provenance and licensing gate
Every exam item SHALL declare a `source` and a `licence` in its front matter, and content validation SHALL fail when an item's source is not Lorito and its licence is not on the approved allow-list.

#### Scenario: Unapproved third-party item
- **WHEN** an item declares a third-party source with a licence missing from the allow-list
- **THEN** validation fails with a message naming the item id

### Requirement: Free preview and Pro gating
The exam section SHALL be available in full to Pro users and SHALL offer non-Pro users a free preview of one CCSE mock and one DELE A2 reading task; other content SHALL show the Pro offer instead of failing.

#### Scenario: Non-Pro user opens a second mock
- **WHEN** a non-Pro user who has used the free CCSE mock starts another
- **THEN** the Pro offer is shown and no attempt is created
