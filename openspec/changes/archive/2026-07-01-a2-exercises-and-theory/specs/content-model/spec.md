## ADDED Requirements

### Requirement: Exercise coverage of cards
Every card SHOULD have at least one practice exercise so learners can actively drill its grammar point, and a level is **fully covered** when every one of its cards is referenced by at least one exercise. Coverage is produced by the content-pipeline coverage report and improved level by level; an authored exercise's `card` MUST reference the card it drills.

#### Scenario: A fully covered level has an exercise for every card
- **WHEN** a level's content pass is complete
- **THEN** every card in that level is referenced by at least one exercise and the coverage report shows N/N for that level

#### Scenario: An exercise drills its referenced card
- **WHEN** an exercise exists
- **THEN** its `card` field resolves to a card of the same level and the exercise tests that card's grammar point
