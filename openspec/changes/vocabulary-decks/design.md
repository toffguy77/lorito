## Context

The review store keys `ReviewState` by a string id and is synced through
CloudKit. `conjugation-trainer` establishes namespaced review ids and makes the
card plan ignore non-card ids. Spanish text in cards is rendered through
`SpanishText` / Markdown emphasis (archived `plumaje-design-system`), which
gives a natural hook for long-press lookup.

## Goals / Non-Goals

**Goals:** a vocabulary course that shares the daily habit and the SRS with
grammar; words met in context can be saved in one gesture; audio everywhere.

**Non-Goals:** a full bilingual dictionary; morphological analysis of every
inflected form (lookup matches lemma and listed forms only; `grammar-lens`
may add NLP lemmatisation later); images for words beyond existing A1 assets;
user-shared decks.

## Decisions

**Content format.** `content/vocabulary/decks.json`: `[{id, level, title_ru,
order}]`. `content/vocabulary/<deck-id>.json`: `[{id, es, pos, article?,
gender?, plural?, forms?, ru, example_es, example_ru, rank}]`. `id` is a
stable slug (`casa`, `problema-n`), unique across decks; `article` and `gender`
are required for nouns; `forms` lists inflected forms used for lookup.

**Frequency source.** Rank comes from an openly licensed frequency list, e.g.
[FrequencyWords](https://github.com/hermitdave/FrequencyWords) built from
OpenSubtitles (content CC BY-SA 4.0); only rank numbers are stored and the
source is credited in About › licences. Translations and examples are authored
(drafted by `enrich.py`, reviewed by a human).

**Two review modes, one item.** One review item per word (`word:<id>`). While
the item's repetition count is below 2 the review is recognition: Spanish word
+ audio → reveal translation and example → self-grade with the four buttons.
From repetition 2 it is production: Russian → typed Spanish, checked with the
accent-aware rule (exact → Хорошо, accents only → "почти"/Трудно, otherwise
Опять); nouns require the article (`la mano`), and a wrong article is reported
as a gender mistake.

**Personal words.** Saving a bundled word just adds it to the learner's
personal deck (a selection, stored as a set of word ids in settings). Saving an
unknown word creates a `PersonalWord` record (`es`, optional `ru`, source card
id, created date) and a review item `word:p-<uuid>`. Only this record type is
new in persistence.

**Planner.** `VocabularyPlanner` is pure: due words from selected decks and the
personal deck, then up to `dailyNewWordCount` new words — personal words first,
then decks in level/order and word rank order. The daily plan's count report
gains `wordsDue` and `wordsNew`; the card queue is unchanged.

**Long-press lookup.** Long press on a word inside `SpanishText` or Markdown
emphasis → normalise (lowercase, strip punctuation) → match `es` or `forms` in
the bundle → word sheet (audio, translation, example, «В мои слова»). No match
→ sheet with the word, audio and a translation field.

## Risks / Trade-offs

- [New CloudKit record type] → deploy schema to production before release;
  personal words work locally if sync is off.
- [Lookup misses inflected forms] → `forms` for frequent irregulars;
  "save anyway" path; later NLP lemmatisation.
- [Quota overload with grammar + conjugation + words] → defaults sized for
  ~10 minutes; Today shows each block separately; any quota can be 0.
- [Content quality of ~1 000 entries] → pipeline checks + human review task;
  ship A1 first if needed.

## Migration Plan

Additive. Decks of the learner's included levels (up to B2) are selected by
default for new and existing users; existing users see a one-time note on
Today and can change the selection or set the word quota to 0 in settings. Rollback: remove the feature;
`word:` review items are ignored by the card plan.
