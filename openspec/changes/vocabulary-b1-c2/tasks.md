## 1. Default selection (TDD)

- [x] 1.1 Failing tests: empty selection = decks of included levels up to B2 (A2 target → A1–A2; C2 target → A1–B2; no target → A1–B2); toggling a C1 deck keeps the default decks; the planner and `isSelected` agree
- [x] 1.2 Pure `VocabularySelection` in Domain; planner and `VocabularyModel` use it

## 2. Content (generated — нужна вычитка)

- [ ] 2.1 36 decks B1–C2 in `decks.json` with orders per level
- [ ] 2.2 ~1 800 words: ranks from FrequencyWords, no duplicates across decks, `validate.py` and `compile.py` clean
- [ ] 2.3 (manual, owner) Human review of the B1–C2 entries

## 3. Verify

- [ ] 3.1 Content test: B1/B2 ≥ 450, C1/C2 ≥ 350, ≥ 20 per deck
- [ ] 3.2 `swift test`; `python3 tools/test_pipeline.py`; `openspec validate vocabulary-b1-c2 --strict`
