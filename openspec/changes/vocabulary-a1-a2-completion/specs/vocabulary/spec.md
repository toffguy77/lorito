## ADDED Requirements

### Requirement: A1–A2 deck coverage
The bundled vocabulary SHALL contain at least 450 A1 words and at least 450 A2 words, with every deck holding at least 20 words and every word id unique across decks.

#### Scenario: Coverage pinned by a test
- **WHEN** the bundled content is loaded
- **THEN** A1 and A2 each have at least 450 words and no deck has fewer than 20

### Requirement: Word entry checks
The content pipeline SHALL reject a word whose example sentence contains neither the word nor one of its listed forms (verbs excepted, as their examples are conjugated), and a noun stored with `el` and feminine gender unless it begins with stressed *a-* or *ha-* (*el agua*).

#### Scenario: Example without the word
- **WHEN** the noun `mesa` has the example "Es grande."
- **THEN** validation fails naming `mesa`

#### Scenario: Feminine noun with el
- **WHEN** `agua` is stored with article `el` and gender `f`
- **THEN** validation passes, while `mesa` stored the same way fails
