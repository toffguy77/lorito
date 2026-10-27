## 0. Dependencies

- [ ] 0.1 `conjugation-trainer` applied (card plan ignores non-card ids; accent-aware checker) and `spanish-audio` applied

## 1. Content model & pipeline (TDD)

- [ ] 1.1 Document decks and word fields in `content/schema.md`; confirm the frequency source licence and add it to About › licences
- [ ] 1.2 Failing tests in `tools/test_pipeline.py`: deck registry (duplicate/unknown id, order per level), words (duplicate id, missing fields, noun without article/gender, bad values, rank)
- [ ] 1.3 Implement in `tools/validate.py` and `tools/compile.py`; `tools/enrich.py --vocab` drafts translations and examples for review

## 2. Content

- [ ] 2.1 A1 decks (~500 words) with translations, examples, gender; human review
- [ ] 2.2 A2 decks (~500 words); human review
- [ ] 2.3 B1–B2 decks (follow-up; may ship in a later release)

## 3. Domain (TDD)

- [ ] 3.1 Failing tests: `Word`/`Deck` decode; deck and rank ordering
- [ ] 3.2 Failing tests: review mode is recognition below 2 repetitions, production from 2; production check with article and gender-mistake reporting
- [ ] 3.3 Failing tests for `VocabularyPlanner`: due words, quota, personal-first ordering, deck selection, quota 0, determinism
- [ ] 3.4 Failing test: daily plan count report exposes `wordsDue` / `wordsNew`; card queue unchanged
- [ ] 3.5 Failing tests for lookup normalisation and matching against `es` and `forms`
- [ ] 3.6 Implement; `UserSettings.dailyNewWordCount` (default 10) and selected decks

## 4. Persistence

- [ ] 4.1 `PersonalWord` SwiftData model + `UserDataStore` operations; tests on the in-memory store
- [ ] 4.2 CloudKit: add the record type to the development schema; note production deployment for release

## 5. Features

- [ ] 5.1 Word session (recognition and production layouts, audio, accent row) in focus mode
- [ ] 5.2 Word sheet on long press in `SpanishText`/Markdown emphasis; «В мои слова»; unknown-word save with translation
- [ ] 5.3 Decks screen (select/deselect, progress per deck, personal deck); settings quota
- [ ] 5.4 Today: «Слова» block with due/new counts

## 6. Validation

- [ ] 6.1 `swift test`, `python3 tools/test_pipeline.py` green
- [ ] 6.2 `xcodebuild`; UI tests: learn a new word (recognition), production typing with wrong article, long-press save from a card
- [ ] 6.3 `openspec validate vocabulary-decks --strict`
