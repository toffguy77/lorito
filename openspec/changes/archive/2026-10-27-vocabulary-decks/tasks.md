## 0. Dependencies

- [x] 0.1 `learning-platform-foundation`, `cloudkit-schema-release`, `conjugation-trainer` (accent-aware checker) and `spanish-audio` applied

## 1. Licence & attribution

- [x] 1.1 Add `content/vocabulary/LICENSE` (CC BY-SA 4.0, derived from FrequencyWords, link to https://github.com/hermitdave/FrequencyWords)
- [x] 1.2 About / Licenses: FrequencyWords credit (source, CC BY-SA 4.0) and vocabulary dataset licence; UI test that the entry is shown
- [x] 1.3 (owner decision 2026-10-27 in ROADMAP: conjugation folder ships CC BY-SA with its own LICENSE) Keep the dataset separate: no other content generated from the list; `content/conjugation/` verb `rank` values also come from FrequencyWords — credit them in the same About entry and confirm with the owner whether rank numbers alone require CC BY-SA for that folder

## 2. Content model & pipeline (TDD)

- [x] 2.1 Document decks, word fields, `mf` gender, `forms` and the dataset licence in `content/schema.md`
- [x] 2.2 Failing tests in `tools/test_pipeline.py`: deck registry (duplicate/unknown id, order per level), words (duplicate id, missing fields, noun without article/gender, bad values, rank), missing `LICENSE`
- [x] 2.3 Implement in `tools/validate.py` and `tools/compile.py`; `tools/enrich.py --vocab` drafts translations and examples for review

## 3. Content

- [x] 3.1 (generation completed by `vocabulary-a1-a2-completion`: A1 ≈504 words; human review tracked there) A1 decks (~500 words) ranked from FrequencyWords, with translations, examples, gender; human review
- [x] 3.2 (generation completed by `vocabulary-a1-a2-completion`: A2 ≈507 words; human review tracked there) A2 decks (~500 words); human review
- [ ] 3.3 (later release) B1–B2 decks (follow-up; may ship in a later release)

## 4. Domain (TDD)

- [x] 4.1 Failing tests: `Word`/`Deck` decode; deck and rank ordering
- [x] 4.2 Failing tests: review mode from graded events (production after two passing memory-updating reviews; Опять returns to recognition)
- [x] 4.3 Failing tests: production check — article required, gender mistake reported, `mf` accepts `el`/`la`, accent-aware rule
- [x] 4.4 Failing tests for `VocabularyPlanner`: default quota 0, enabled 5, combined budget (first study event today), personal-first ordering, deck selection, determinism
- [x] 4.5 Failing tests for lookup normalisation and matching against `es` and `forms`
- [x] 4.6 Implement; settings `dailyNewWordCount` (default 0), selected decks, personal deck

## 5. Persistence

- [x] 5.1 `PersonalWord` SwiftData model + `UserDataStore` save/delete; deleting removes the review state and keeps study events; tests on the in-memory store
- [x] 5.2 (schema export — owner) Per `cloudkit-schema-release`: optional/defaulted fields, both-way mapping in `SwiftDataUserDataStore`, store round-trip test, schema export

## 6. Features

- [x] 6.1 Word session (recognition and production layouts, audio, accent row) in focus mode
- [x] 6.2 «В мои слова» handler for the foundation context menu; unknown-word sheet with translation
- [x] 6.3 Decks screen (select/deselect, progress per deck, personal deck with delete); settings «Слова» switch and quota
- [x] 6.4 Today: «Слова» block with due/new counts; one-time prompt to enable words

## 7. Validation

- [x] 7.1 `swift test`, `python3 tools/test_pipeline.py` green
- [x] 7.2 `xcodebuild`; UI tests: enable words → learn a new word (recognition), production typing with wrong article, «В мои слова» from a card, delete a personal word
- [x] 7.3 `openspec validate vocabulary-decks --strict`
