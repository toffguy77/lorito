# exam-path Specification

## Purpose
TBD - created by archiving change exam-path-dele-ccse. Update Purpose after archive.
## Requirements
### Requirement: Exam section and tracks
The app SHALL offer a section «Экзамены DELE и CCSE» containing the DELE A2 and CCSE tracks and the combined track «Путь к гражданству», each showing format, timing, pass rule and the date the facts were last verified.

#### Scenario: Section opened
- **WHEN** the user opens «Экзамены DELE и CCSE»
- **THEN** DELE A2, CCSE and «Путь к гражданству» are shown with format, pass rule and verification date

### Requirement: DELE A2 mock exam format
A DELE A2 mock exam SHALL consist of four timed sections in order — reading (60 min), listening (40 min), writing and interaction (45 min), speaking and interaction (12 min plus 12 min preparation) — each worth 25 points, with timings taken from the exam definition.

#### Scenario: Sections and timing
- **WHEN** the user starts a full DELE A2 mock
- **THEN** the four sections run in order with their time limits from the exam definition

### Requirement: DELE A2 scoring by group
DELE A2 mock scoring SHALL be a pure function: Group 1 = reading + writing, Group 2 = listening + speaking, each out of 50; the mock SHALL pass only when each group reaches its threshold from the exam definition (30), with no overall-percentage rule.

#### Scenario: One group below threshold
- **WHEN** a mock scores 38/50 in Group 1 and 28/50 in Group 2
- **THEN** it is not passed and Group 2 is identified as failing

#### Scenario: Both groups at threshold
- **WHEN** a mock scores 30/50 in each group
- **THEN** it is passed

### Requirement: Self-assessed productive tasks
Writing and speaking tasks SHALL be scored by the user against a rubric of checklist items mapped to points, and results containing self-assessed points SHALL be labelled «Самооценка».

#### Scenario: Rubric scoring
- **WHEN** the user ticks four of six rubric items worth 2 points each
- **THEN** the task scores 8 points and the result is labelled «Самооценка»

### Requirement: Speaking recordings stay local
Speaking recordings SHALL be stored only on the device, never synced, limited to 2 minutes per task with the latest 20 kept, and deleted with their mock attempt.

#### Scenario: Recording not synced
- **WHEN** the user records a speaking answer on a device with sync enabled
- **THEN** the recording is not available on the user's other devices

### Requirement: CCSE mock test
A CCSE mock test SHALL present 25 questions from the CCSE bank within 45 minutes and pass when at least 15 answers are correct, with thresholds from the exam definition.

#### Scenario: Pass at 15
- **WHEN** a CCSE mock ends with 15 correct answers
- **THEN** it is passed

### Requirement: Mock expiry
Mock time SHALL be computed from the persisted section start, so leaving the app does not pause it. When a section's time runs out it SHALL be submitted as is with unanswered items counted incorrect, also on the next launch if the app was not running.

#### Scenario: Expired while closed
- **WHEN** the user closes the app during a CCSE mock and reopens it after 45 minutes
- **THEN** the attempt is closed and scored with unanswered questions counted incorrect

### Requirement: CCSE bank with attribution
The CCSE bank SHALL be imported from the official Instituto Cervantes question bank, each item recording its source and edition, and the app SHALL show this attribution in the CCSE track. Validation SHALL fail for an item without source, edition or a valid answer key.

#### Scenario: Item without edition
- **WHEN** a CCSE item lacks its edition
- **THEN** validation fails naming the item id

### Requirement: CCSE spaced repetition and quota
Each CCSE question SHALL be a review item with id `ccse:<id>` scheduled by the spaced-repetition engine. New CCSE items SHALL be introduced from the shared daily new-introduction budget, never more per learning day than the setting `ccseDailyNewLimit` (default 5; 0 disables CCSE introductions).

#### Scenario: Cap respected
- **WHEN** `ccseDailyNewLimit` is 5 and the shared budget allows 12 new items
- **THEN** at most 5 new CCSE items are introduced that learning day

### Requirement: Readiness score
The app SHALL show readiness from 0 to 100 per DELE group and for CCSE, labelled «Скорее сдадите», «На грани» or «Пока рано», computed by a pure function from complete mocks and item mastery. A DELE group without a productive-part attempt SHALL NOT be labelled above «На грани».

#### Scenario: No speaking attempt
- **WHEN** Group 2 has listening mocks but no speaking attempt
- **THEN** Group 2 is labelled at most «На грани»

### Requirement: Exam date countdown
When the study goal has an exam kind and exam date, the exam section SHALL show the days remaining next to readiness.

#### Scenario: Countdown shown
- **WHEN** the goal's exam date is 40 days away
- **THEN** the section shows 40 days remaining

### Requirement: Content-based free preview
Exam content marked as preview (one CCSE mock and one DELE A2 reading task) SHALL be available without Pro; all other exam content SHALL present the Pro offer when opened without Pro. Preview availability SHALL NOT depend on usage counters.

#### Scenario: Non-Pro user opens non-preview content
- **WHEN** a non-Pro user opens a second CCSE mock
- **THEN** the Pro offer is shown and no attempt is created

#### Scenario: Preview after reinstall
- **WHEN** a non-Pro user reinstalls the app
- **THEN** the same preview content is available

