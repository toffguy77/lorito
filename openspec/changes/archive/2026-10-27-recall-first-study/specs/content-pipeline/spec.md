## ADDED Requirements

### Requirement: Recall prompt validation
The content validation step SHALL accept the optional `recall` card field and SHALL fail with a non-zero exit when a `recall` value is not a string, is empty after trimming, spans more than one line, or exceeds 200 characters. The compile step SHALL write `recall` into the compiled bundle only for cards that declare it.

#### Scenario: Valid recall passes
- **WHEN** a card declares a one-line `recall` of 60 characters
- **THEN** validation passes and the compiled bundle contains the prompt for that card

#### Scenario: Overlong recall fails
- **WHEN** a card declares a `recall` longer than 200 characters
- **THEN** validation fails with a message naming the card id

#### Scenario: Missing recall is fine
- **WHEN** no card declares `recall`
- **THEN** validation passes and the compiled bundle has no `recall` keys
