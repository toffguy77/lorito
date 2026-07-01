## ADDED Requirements

### Requirement: Exercise coverage report
The pipeline SHALL provide an **informational** coverage report that lists, for a level (or all levels), which cards and themes have no practice exercises. The report SHALL NOT change the pass/fail outcome of validation or compilation — it never blocks a build and always exits zero.

#### Scenario: Report lists cards without exercises
- **WHEN** the coverage report runs over content where some cards have exercises and others do not
- **THEN** it lists the cards (and themes) that have no exercises and reports the covered/total counts

#### Scenario: Report is non-failing
- **WHEN** the coverage report runs over content where some cards have no exercises
- **THEN** the command exits zero and neither `validate` nor `compile` is affected by the missing coverage
