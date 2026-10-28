## 1. Pipeline (TDD)

- [x] 1.1 Failing tests: vosotros row and header column need `am` and `rio` notes; a Spain-only block or prose needs nothing; partial coverage names the missing code; *coger* in a multi-word example needs a Spain block or inline alternative (single-word mentions are exempt)
- [x] 1.2 `variants.check_coverage` and `REFERENCE_CARDS` (C1-18); wired into `validate.py`

## 2. Content (generated — нужна вычитка)

- [x] 2.1 `am` / `rio` notes after the conjugation tables of A1-12, A1-16, A1-18, A1-20 (am), A1-21, A2-01, A2-02, A2-04, A2-07, A2-08, A2-09, A2-16, B1-01, B1-10, B1-11, B2-01, B2-02, C1-03
- [x] 2.2 B1-13 neutral example; C1-15 inline alternative for *coger el toro*
- [x] 2.3 A1-30 glossary of 13 lexical differences as inline alternatives
- [x] 2.4 `validate.py` / `compile.py` clean
- [ ] 2.5 (manual, owner) Review the notes; check rendering in Obsidian

## 3. Verify

- [x] 3.1 `swift test`; `python3 tools/test_pipeline.py`
- [ ] 3.2 Full UI suite (regional-variants UI test still green); `openspec validate regional-variants-coverage --strict`
