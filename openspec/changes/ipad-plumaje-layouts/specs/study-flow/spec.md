## ADDED Requirements

### Requirement: Related cards on a revealed card
After reveal, the study session SHALL list the card's related cards (from its `related` field, resolved against the content catalog and skipping unknown identifiers) with their titles and identifiers. Tapping one SHALL open it in the card reader without ending the session. Related cards SHALL NOT be shown on the front side.

#### Scenario: Related cards after reveal
- **WHEN** card A1-07 with related A1-08, A1-09 and A1-11 is revealed
- **THEN** the session lists those three cards with their titles

#### Scenario: Hidden before reveal
- **WHEN** the front side of a card is shown
- **THEN** no related cards are listed

#### Scenario: Unknown related id
- **WHEN** a card's `related` field contains an identifier missing from the catalog
- **THEN** that identifier is skipped and the others are listed
