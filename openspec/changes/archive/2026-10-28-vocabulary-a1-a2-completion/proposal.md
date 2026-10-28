## Why

`vocabulary-decks` shipped partial content: 13 decks, 340 words, against the
planned ~1 000 for A1–A2 (tasks 3.1/3.2 were left partial). A learner who keeps the
default 5 new words a day runs out of A1 words in about six weeks, and whole
everyday themes (numbers, clothes and colours, weather, shopping, phone and
internet, character) are missing. Some entries also had data mistakes: unaccented
plurals (*jovenes*, *examenes*) and *agua* / *hambre* stored as masculine.

## What Changes

- **Plan:** A1 to ~500 words, A2 to ~500, by expanding the 13 existing decks to
  40–50 words and adding 9 thematic decks:
  - A1: «Какой? Описания», «Одежда и цвета», «Погода и природа», «Числа и количество».
  - A2: «Покупки и деньги», «Связь и техника», «Характер и внешность»,
    «Глаголы A2», «Связки и наречия».
- Words chosen by FrequencyWords rank within each theme, one deck per word,
  examples at the deck's level, pan-Hispanic usage where variants differ.
- Data fixes: plural accents, `el` + feminine for nouns with stressed *a-*.
- Pipeline checks so the new volume stays consistent: a non-verb's example must
  contain the word or a listed form; `el` with feminine gender only before
  stressed *a-/ha-*.
- A content test pins the coverage (≥ 450 words per level, ≥ 20 per deck).
- Generated content — separate commit, «нужна вычитка».
- Not in scope: B1–B2 decks (next stage, per the original design).

## Capabilities

### Modified Capabilities
- `vocabulary`: coverage requirement for the bundled A1–A2 decks and entry checks.

## Impact

- `content/vocabulary/*.json`, `decks.json`; compiled `content.json`.
- `tools/vocab.py`, `tools/test_pipeline.py`; `ContentTests`.
- No code or schema changes: new decks are selected by default through the
  existing level rule.
