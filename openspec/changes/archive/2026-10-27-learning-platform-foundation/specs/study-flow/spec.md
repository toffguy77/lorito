## ADDED Requirements

### Requirement: In-session relearn of lapsed cards
When the user grades a card Опять during a study session, the session SHALL show that card once more after the last card of the session queue, on its front side. The second grade SHALL be recorded as a study event and SHALL NOT change the card's review state (per `review-items` first grade per day). A card SHALL be re-shown at most once per session.

#### Scenario: Опять card returns at the end
- **WHEN** the user grades card A Опять and two more cards remain
- **THEN** after those two cards the session shows card A again on its front side

#### Scenario: Only once
- **WHEN** the user grades the re-shown card A Опять again
- **THEN** the session does not show card A a third time
