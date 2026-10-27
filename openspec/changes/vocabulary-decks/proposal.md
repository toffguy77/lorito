## Why

Lorito teaches grammar but has almost no vocabulary: 56 picture words at A1.
Learners keep a second app (Anki, Duolingo) just for words, and every session
there is a session not spent in Lorito. The audit marked vocabulary as a P1 gap.
Words are also where grammar becomes usable: gender and article (`el
problema`), irregular plurals, and verbs that feed the conjugation trainer. A
frequency-ordered, thematic word course with audio — plus a personal deck fed
from the words learners meet in cards — keeps learners in one app and one
daily habit.

## What Changes

- **Bundled thematic decks, A1–B2,** ordered by word frequency: each word has
  Spanish form, article and gender for nouns, part of speech, Russian
  translation, an example sentence with translation, and frequency rank.
- **Word review in the SRS:** words are review items `word:<id>` in the
  existing review store, scheduled by the `srs-engine` operation. Early
  reviews are recognition (Spanish → meaning, self-graded); after two passing
  reviews they switch to production (Russian → Spanish, typed, accent-aware,
  article required for nouns).
- **«В мои слова»:** a long press on any Spanish word in a card, exercise or
  example opens a word sheet (bundled entry if found, audio) with «В мои слова»;
  unknown words can be saved with the learner's own translation into a
  personal deck.
- **Own daily quota:** `dailyNewWordCount` (default 10) independent of the
  grammar card quota; the Today screen shows words alongside cards.
- **Audio** for every word and example through `spanish-audio`.

## Capabilities

### New Capabilities
- `vocabulary`: word model, decks, deck selection, word review modes,
  personal words, word sheet, vocabulary planner.

### Modified Capabilities
- `daily-plan`: the day's plan reports vocabulary due/new counts beside cards,
  with a separate new-word quota.
- `content-model`: vocabulary deck and word files and their schema.
- `content-pipeline`: vocabulary validation and compilation.

## Impact

- **Content**: `content/vocabulary/decks.json` and one word file per deck;
  `content/schema.md`. Authoring: A1–A2 decks (~1 000 words) first, B1–B2 after.
- **tools/**: validate/compile/test extended; `enrich.py` gains a vocabulary
  mode to draft translations and examples for human review.
- **Domain**: `Word`, `Deck`, `VocabularyPlanner`, word answer checking
  (reuses the accent-aware rule from `conjugation-trainer`).
- **Persistence**: new `PersonalWord` record (user-created words) → CloudKit
  development schema change and production deployment before release.
- **Features**: word session, word sheet on long press, decks screen, Today
  entry, settings.
- **Dependencies**: `conjugation-trainer` (the card plan ignores non-card
  review ids, accent-aware checker), `spanish-audio` (audio), archived
  `plumaje-design-system` (`SpanishText`). Coordinates with `regional-variants`
  (variant-specific words) and `personal-traps` (gender mistakes).
