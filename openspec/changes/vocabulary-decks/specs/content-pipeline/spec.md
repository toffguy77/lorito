## ADDED Requirements

### Requirement: Vocabulary integrity validation
The validation command SHALL fail with a non-zero exit when a deck id is duplicated or unknown, a deck file has no registry entry, a word id is duplicated, a required word field is missing or empty, a noun lacks `article` or `gender`, an `article` or `gender` value is not allowed, or a `rank` is not a positive integer.

#### Scenario: Unknown gender value
- **WHEN** a noun declares `gender: n`
- **THEN** validation exits non-zero and names the word

#### Scenario: Clean vocabulary passes
- **WHEN** all decks and words conform
- **THEN** validation exits zero

### Requirement: Vocabulary compiled into the bundle
The compile command SHALL write all decks and words into the bundled content artifact and SHALL produce no bundle when vocabulary validation fails.

#### Scenario: Bundle carries words
- **WHEN** compilation succeeds
- **THEN** the bundle contains every deck and every word with its fields

#### Scenario: Invalid word blocks the bundle
- **WHEN** vocabulary validation fails
- **THEN** compilation exits non-zero and writes no bundle
