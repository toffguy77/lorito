# Spec Delta

## MODIFIED Requirements

### Requirement: Practice result feeds the existing SRS
Practice SHALL NOT introduce a separate schedule for a card; it updates the same per-card review state used by the study session, through the `srs-engine` apply-and-persist operation (referenced, not redefined), whose first-grade-per-learning-day rule applies.

In **card-reader practice**, submitting an answer SHALL apply the resulting SM-2 grade (auto-mapped for auto-checkable types, user-chosen for self-assessed types) to the associated card's review and SHALL record a study event for the card and grade.

In **free practice** (`practice-hub`), only a failing result SHALL reach the card's review: an incorrect auto-checked answer or a self-assessed Опять SHALL apply the Опять grade and record a study event; a correct auto-checked answer or a self-assessed Трудно, Хорошо or Легко SHALL be recorded only as an exercise attempt, without changing the card's review state or recording a study event. The rule «Speaking never lapses a card» still applies, so `speak` exercises in free practice never change the card's review.

#### Scenario: Correct answer advances the card's schedule
- **WHEN** in card-reader practice the user answers an exercise correctly (or self-grades it passing)
- **THEN** the associated card's review is updated via the `srs-engine` apply-and-persist operation with the resulting grade and a study event is recorded

#### Scenario: Incorrect answer reschedules the card sooner
- **WHEN** in card-reader practice the user answers an auto-checkable exercise incorrectly
- **THEN** the associated card's review is updated via the `srs-engine` apply-and-persist operation with the Опять grade and a study event is recorded

#### Scenario: Free practice correct answer leaves the schedule
- **WHEN** in free practice the user answers an exercise of a card due in 30 days correctly
- **THEN** an attempt marked correct is recorded, no study event is recorded and the card is still due in 30 days

#### Scenario: Free practice mistake lapses the card
- **WHEN** in free practice the user answers an exercise incorrectly and the card has not been graded today
- **THEN** the Опять grade is applied to the card's review and a study event is recorded

#### Scenario: Second mistake on the same day
- **WHEN** in free practice the user misses an exercise of a card that was already graded today
- **THEN** the attempt and a study event are recorded and the card's review state is unchanged
