## 1. Pipeline checks (TDD)

- [x] 1.1 Failing tests in `tools/test_pipeline.py`: example without the word fails (non-verbs; listed forms count; verbs exempt); `el` + feminine passes only before stressed a-/ha-
- [x] 1.2 Implement both checks in `tools/vocab.py`

## 2. Content (generated — нужна вычитка)

- [x] 2.1 Data fixes: *jóvenes*, *exámenes*, *agua* / *hambre* feminine, *buen* as a form of *bueno*
- [x] 2.2 Expand the 7 A1 and 6 A2 decks (+230 words)
- [x] 2.3 New A1 decks: descripciones, ropa, naturaleza, numeros (208 words)
- [x] 2.4 New A2 decks: compras, tecnologia, caracter, verbos, conectores (233 words)
- [x] 2.5 Ranks from FrequencyWords; no duplicates across decks; `validate.py` and `compile.py` clean
- [ ] 2.6 (manual, owner) Human review of the ~1 000 entries (translations, examples, Spain-only words flagged in the report)

## 3. Verify

- [x] 3.1 Content test: ≥ 450 words per level, ≥ 20 per deck, unique ids
- [x] 3.2 `swift test`; `python3 tools/test_pipeline.py`; `openspec validate vocabulary-a1-a2-completion --strict`
