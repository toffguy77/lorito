## 1. Importer

- [x] 1.1 Failing tests: forms of 25 by the per-tarea distribution; re-import keeps explanation and `preview`, updates edition
- [x] 1.2 `tools/exams.py` import: assign forms; keep explanation and `preview` of existing items

## 2. Content

- [x] 2.1 Transcribe the 2026 manual to `content/exams/ccse/source/2026.md` (300 questions, answer key from «Soluciones»); import; mark form 1 `preview`
- [x] 2.2 Russian explanations for all questions (generated — нужна вычитка)
- [ ] 2.3 (manual, owner) Review the explanations
- [x] 2.4 `SOURCE.md`: edition, NIPO, download date and URL

## 3. Verify

- [x] 3.1 `validate.py`, `compile.py`, `test_pipeline.py`, `swift test`; `openspec validate ccse-bank-import --strict`
