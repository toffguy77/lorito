## ADDED Requirements

### Requirement: Vocabulary deck registry
The content SHALL include `content/vocabulary/decks.json` listing each deck with a unique kebab-case `id`, `level`, Russian `title_ru` and `order` unique within its level.

#### Scenario: Deck order unique per level
- **WHEN** two A1 decks declare the same `order`
- **THEN** validation fails and names both decks

### Requirement: Word files
Each deck SHALL have `content/vocabulary/<deck-id>.json`, a list of words with: `id` (slug unique across all decks), `es`, `pos`, `ru`, `example_es`, `example_ru`, positive `rank`, optional `plural` and `forms`; nouns SHALL also declare `article` (`el`, `la`, `los`, `las`) and `gender` (`m`, `f`, `mf`).

#### Scenario: Noun without article rejected
- **WHEN** a word with `pos: noun` omits `article`
- **THEN** validation fails and names the word

#### Scenario: Duplicate word id rejected
- **WHEN** two decks contain a word with the same `id`
- **THEN** validation fails and names both decks

### Requirement: Documented vocabulary schema
`content/schema.md` SHALL document the vocabulary layout, deck and word fields, allowed values and the lookup role of `forms`.

#### Scenario: Schema covers vocabulary
- **WHEN** a contributor opens `content/schema.md`
- **THEN** they find the deck registry and word fields with allowed values
