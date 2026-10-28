## Why

Vocabulary entries carry one Spanish form, written for Spain. The learner's variant
setting (`regional-variants`) already drives cards, exercises, drills and audio, but
not words: a Latin American learner is taught *el ordenador*, *conducir* and
*el zumo* and is then marked wrong for nothing in their own Spanish. The A1–A2
review flagged Spain-leaning entries (jersey, vaqueros, bolso, gafas, deberes), and
there was no field to put the regional word in.

## What Changes

- A word MAY carry regional forms for `am` (Latin America) and `rio` (Argentina and
  Uruguay); nouns carry their own article (*el bolso* → *la cartera*). The Spain form
  stays the word id, so review history, planning and the synced personal deck are
  unchanged.
- Word sessions resolve the word for the learner's variant: the front, audio and the
  expected production answer use the learner's form; after reveal the other forms are
  listed with their region. In production every listed regional form is accepted as
  correct, with the article of that form.
- Example sentences mark the Spain form with the existing inline-alternative syntax
  (`{es: el ordenador | am: la computadora}`) and render resolved for the variant.
- «В мои слова» recognises regional forms as the same bundled word.
- Pipeline: variant codes limited to `am`/`rio`; nouns need an article in each form;
  a word with variants must mark its form in the example; a variant equal to the
  Spain form is rejected.
- Content: regional forms for existing A1–A2 entries where everyday usage differs
  (generated — «нужна вычитка»); the B1–C2 decks are authored with the field.

## Capabilities

### Modified Capabilities
- `vocabulary`: regional word forms, resolved by the learner's variant; entry checks
  extended.

## Impact

- `Domain/Vocabulary/Vocabulary.swift` (`Word.variants`, resolution, checker,
  lookup); `Features/Vocabulary` (session view and model read the variant).
- `tools/vocab.py`, `tools/test_pipeline.py`, `content/schema.md`.
- `content/vocabulary/*.json` (generated forms — separate commit).
- No synced-schema change; no change to item ids.
