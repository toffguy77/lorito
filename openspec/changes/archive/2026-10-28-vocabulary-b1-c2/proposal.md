## Why

The bundled vocabulary stops at A2 (~1 000 words), while grammar runs to C2. A B1+
learner who enables words gets only beginner words, and the deck screen has nothing
above A2. The owner asked to take vocabulary all the way to C2 (2026-10-28).

The deck-selection requirement says the decks of the learner's included levels up
to B2 are selected by default, but the code treats "no explicit selection" as
"every deck". With only A1–A2 decks this made no difference; with B1–C2 decks an A1
learner would eventually be fed C2 words.

## What Changes

- **Plan:** 36 new thematic decks, ~1 800 words.
  - B1: 10 decks (~500), work, study, health, feelings, travel, society, nature,
    culture, verbs, connectors.
  - B2: 10 decks (~500), economy, politics, science, media, law, art, psychology,
    business, verbs, argumentation.
  - C1: 8 decks (~400), academic, abstract, finance, social issues, medicine,
    verbs, evaluation and nuance, set expressions.
  - C2: 8 decks (~400), literary, legal, philosophy, scientific terms, near-synonyms,
    verbs, bookish vocabulary, idioms.
- Words chosen by FrequencyWords rank within each theme (B1 < 15 000, B2 < 25 000,
  C1–C2 within the 50k list, a few essential absent words allowed); one deck per
  word; examples at the deck's level.
- Default deck selection follows the existing requirement: with no explicit
  selection, the decks of the learner's included levels up to B2 are selected;
  C1–C2 decks are opt-in. Toggling a deck starts from that default.
- A content test pins the coverage: B1 and B2 ≥ 450 words, C1 and C2 ≥ 350, every
  deck ≥ 20.
- Generated content — separate commit, «нужна вычитка».

## Capabilities

### Modified Capabilities
- `vocabulary`: coverage requirement extended to B1–C2; default deck selection made
  explicit and testable.

## Impact

- `content/vocabulary/*.json`, `decks.json`; compiled `content.json`.
- `Domain/Vocabulary/Vocabulary.swift` (planner default), `Features/Vocabulary/VocabularyModels.swift`
  (deck toggles); `VocabularyTests`, `ContentTests`.
- No synced-schema change: `selectedDeckIDs` keeps its meaning (empty = default).
