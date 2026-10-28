## 1. Pipeline (TDD)

- [x] 1.1 Failing tests: a phrase list expands into one rule per phrase (ids, titles, steps, `~lemma`, shared negatives); the bundle carries plain rules; checks for too few phrases, a non-matching example, a matching negative, phrases with a pattern
- [x] 1.2 Implement in `tools/lens.py`; document in `content/schema.md`

## 2. Content (generated — нужна вычитка)

- [x] 2.1 Phrase lists for the lexical cards whose expressions the card teaches; those cards leave the coverage map
- [x] 2.2 Precision pass: run every rule over the vocabulary examples and the card bodies; drop or constrain phrases that misfire
- [ ] 2.3 (manual, owner) Review the phrase lists

## 3. Verify

- [x] 3.1 `validate.py`, `compile.py`; `swift test` (Lens cross-check); `openspec validate grammar-lens-phrases --strict`
