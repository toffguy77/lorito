## ADDED Requirements

### Requirement: Grammar Lens events
The app SHALL record anonymous events `lens_opened` (with input source: paste, share, camera, photo), `lens_analyzed` (with a bucketed match count) and `lens_card_requested` (with card id), and SHALL NOT record the analysed text.

#### Scenario: Analysis recorded without text
- **WHEN** the user analyses a pasted paragraph with three matches
- **THEN** `lens_analyzed` is recorded with source paste and the match bucket, and no text
