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

- **Bundled thematic decks, A1–B2,** ordered by word frequency from the
  FrequencyWords list (content CC BY-SA 4.0): each word has Spanish form,
  article and gender for nouns, part of speech, Russian translation, an example
  sentence with translation, and frequency rank.
- **Separate, share-alike dataset:** `content/vocabulary/` is an adaptation of
  the frequency list and is published under CC BY-SA 4.0 with its own
  `LICENSE` file; the rest of Lorito's content is unaffected. The About screen
  credits FrequencyWords.
- **Opt-in words:** the new-word quota is 0 (off) until the learner enables
  words; when enabled the default is 5 per learning day, inside the combined
  daily new-introduction budget of `learning-platform-foundation`.
- **Word review in the SRS:** words are review items `word:<lemma>` scheduled
  by the `srs-engine` operation. Recognition (Spanish → meaning, self-graded)
  until two consecutive passing reviews, then production (Russian → Spanish,
  typed, accent-aware, article required for nouns; both articles accepted for
  `mf` nouns). An Опять returns the word to recognition.
- **«В мои слова»:** the long-press context menu on Spanish text
  (`learning-platform-foundation`) adds a bundled word to the personal deck or
  saves an unknown word with the learner's own translation; personal words can
  be deleted.
- **Audio** for every word and example through `spanish-audio`.

## Capabilities

### New Capabilities
- `vocabulary`: word model, decks, deck selection, opt-in quota, review modes,
  personal words, vocabulary planner, Today block.

### Modified Capabilities
- `content-model`: vocabulary deck and word files, schema and dataset licence.
- `content-pipeline`: vocabulary validation and compilation.
- `about`: FrequencyWords attribution and the vocabulary dataset licence.

## Impact

- **Content**: `content/vocabulary/decks.json`, one word file per deck,
  `content/vocabulary/LICENSE` (CC BY-SA 4.0); `content/schema.md`.
  Authoring: A1–A2 decks (~1 000 words) first, B1–B2 after.
- **tools/**: validate/compile/test extended; `enrich.py` gains a vocabulary
  mode to draft translations and examples for human review.
- **Domain**: `Word`, `Deck`, `VocabularyPlanner`, review-mode rule, word
  answer checking (reuses the accent-aware rule from `conjugation-trainer`).
- **Persistence**: new `PersonalWord` record and settings fields
  (`dailyNewWordCount`, selected decks, personal deck) — optional/defaulted,
  mapped both ways, released per `cloudkit-schema-release`.
- **Features**: word session, «В мои слова» action, decks screen with personal
  deck management, Today block, settings, About entry.
- **Dependencies**: `learning-platform-foundation` (item kinds, card-only
  counting, combined budget, learning day, first-review-per-day rule, Spanish
  text gestures), `cloudkit-schema-release`, `conjugation-trainer`
  (accent-aware checker), `spanish-audio` (audio), archived
  `plumaje-design-system`. Coordinates with `regional-variants` and
  `personal-traps` (gender mistakes).
