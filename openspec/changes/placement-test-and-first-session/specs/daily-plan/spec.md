## ADDED Requirements

### Requirement: Placement-known levels introduced last
When `placementKnownLevel` is set, the composer SHALL introduce eligible new cards of included levels above that level before any new card of that level or below, keeping ascending `order` within each group. When it is unset, new-card ordering SHALL be unchanged.

#### Scenario: Higher level first
- **WHEN** `placementKnownLevel` is A2, the target is B1, and A1 and B1 cards are eligible as new
- **THEN** B1 cards are introduced before any A1 card

#### Scenario: Known levels after exhaustion
- **WHEN** no B1 card is eligible as new and A2 cards are
- **THEN** A2 cards are introduced in ascending order

#### Scenario: Unset keeps order
- **WHEN** `placementKnownLevel` is unset
- **THEN** new cards are introduced in ascending order across included levels
