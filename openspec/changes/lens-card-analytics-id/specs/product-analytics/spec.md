## MODIFIED Requirements

### Requirement: Closed anonymous event taxonomy
The app SHALL record product events only from a closed, enumerated set defined in the `Domain` layer, whose payloads contain only enumerated values, integers, booleans and — only where an event's requirement names it — a bundled grammar card id matching `^[A-C][12]-\d{2}$`. Events SHALL NOT contain personal data, free text, other item identifiers (words, conjugation drills, CCSE questions, personal words) or content text, and the app SHALL NOT require or create an account for analytics.

#### Scenario: Grade event carries no content
- **WHEN** the user grades a card
- **THEN** the recorded event contains the item kind, the grade and whether the card was revealed, and no item identifier or card text

#### Scenario: No account needed
- **WHEN** a new user installs and studies without signing in anywhere
- **THEN** events are recorded without any account or login

#### Scenario: Only catalog card ids
- **WHEN** code tries to build a card-id payload from a word id or free text
- **THEN** no card-id value is produced and nothing is recorded with it

### Requirement: Grammar Lens events
The app SHALL record anonymous events `lens_opened` (with input source: paste, share, camera, photo), `lens_analyzed` (with a bucketed match count) and `lens_card_requested` (with the bundled card id as `card`), and SHALL NOT record the analysed text.

#### Scenario: Analysis recorded without text
- **WHEN** the user analyses a pasted paragraph with three matches
- **THEN** `lens_analyzed` is recorded with source paste and the match bucket, and no text

#### Scenario: Requested card recorded with its id
- **WHEN** the user adds card `B1-03` to review from a Lens highlight
- **THEN** `lens_card_requested` is recorded with `card` = `B1-03` and no text
