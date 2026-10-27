## Context

The review store keys `ReviewState` by a string id and is synced through
CloudKit. `learning-platform-foundation` defines item kinds (`word:<lemma>`),
card-only counting, one combined daily new-introduction budget, the local
learning day, the first-graded-review-per-day rule, and the gesture contract
for Spanish spans (tap = speak; long press = context menu with «Произнести»,
«В мои слова», «Варианты»). `cloudkit-schema-release` defines how new synced
fields and records ship.

## Goals / Non-Goals

**Goals:** a vocabulary course that shares the daily habit and the SRS with
grammar; words met in context can be saved in one gesture; audio everywhere;
licence-clean use of an open frequency list.

**Non-Goals:** a full bilingual dictionary; morphological analysis of every
inflected form (lookup matches lemma and listed forms only; `grammar-lens`
may add NLP lemmatisation later); images for words beyond existing A1 assets;
user-shared decks.

## Decisions

**Content format.** `content/vocabulary/decks.json`: `[{id, level, title_ru,
order}]`. `content/vocabulary/<deck-id>.json`: `[{id, es, pos, article?,
gender?, plural?, forms?, ru, example_es, example_ru, rank}]`. `id` is the
lemma slug (`casa`, `problema`), unique across decks; nouns require `article`
and `gender` (`m`, `f`, `mf`); `forms` lists inflected forms used for lookup.

**Frequency source and licence.** Ranks come from
[FrequencyWords](https://github.com/hermitdave/FrequencyWords) (OpenSubtitles;
content CC BY-SA 4.0, code MIT — owner confirmed). The deck dataset derived
from it is an adaptation, so `content/vocabulary/` is published under
CC BY-SA 4.0 with a `LICENSE` file and kept as a separate dataset: grammar
cards and exercises are not derived from the list and keep their own terms.
The conjugation verb list (`conjugation-trainer`) also orders verbs by
FrequencyWords rank; it is credited in the same About entry, and whether rank
numbers alone make that folder an adaptation is an open question for the owner.
The About screen credits FrequencyWords with licence and source; no contact
with the author is required. Translations and examples are authored (drafted
by `enrich.py`, reviewed by a human) and become part of the CC BY-SA dataset.

**Review modes.** One item per word (`word:<lemma>`). The mode is a pure
function of the word's graded study events: production when the last two
memory-updating reviews were passing (Трудно or better), otherwise
recognition. Recognition: Spanish word + audio → reveal translation and
example → self-grade. Production: Russian → typed Spanish, accent-aware rule
(exact → Хорошо, accents only → "почти"/Трудно, otherwise Опять); nouns require
the article; for `mf` nouns either `el` or `la` is accepted; a wrong article is
reported as a gender mistake. An Опять therefore returns the word to
recognition until it passes twice again.

**Opt-in quota.** `dailyNewWordCount` defaults to 0 for everyone; enabling
words in Settings or from the Today prompt sets it to 5 (0–20 allowed). New
words count against the combined daily budget; a word counts as new on the
learning day of its first study event.

**Personal words.** Saving a bundled word adds its id to the personal deck
(a synced set in settings). Saving an unknown word creates a `PersonalWord`
record (`es`, optional `ru`, source card id, created date) and a review item
`word:p-<uuid>`. Deleting a personal word removes it from the personal deck,
deletes the record if any, and removes its review state; its study events stay
for statistics.

**Planner.** `VocabularyPlanner` is pure: due words from selected decks and
the personal deck, then new words up to the quota — personal words first, then
decks in level, order and rank. Today shows a «Слова» block with due and new
counts when the quota is above 0 or words are due.

## Risks / Trade-offs

- [New CloudKit record type and fields] → optional/defaulted, mapped both
  ways, round-trip test, schema export and production deploy per
  `cloudkit-schema-release`.
- [Share-alike spreading to other content] → the dataset lives in its own
  folder with its own `LICENSE`; nothing else is generated from it.
- [Lookup misses inflected forms] → `forms` for frequent irregulars; "save
  anyway" path; later NLP lemmatisation.
- [Content quality of ~1 000 entries] → pipeline checks + human review task.

## Migration Plan

Additive and opt-in: nothing changes for existing users until they enable
words. Rollback: remove the feature; `word:` review items are ignored by card
planning per `learning-platform-foundation`.
