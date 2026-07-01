# Tasks

A1 content pass: exercises (`multiple-choice` + `fill-in-the-blank` only) for every
A1 theme, plus clearer theory in the A1 card bodies. The pilot already covers
cards A1-07 / A1-08 (`A1-EX-01`…`A1-EX-10`); extend from there. Each theme is a
self-contained unit — run `tools/validate.py` after each.

## 1. Pipeline: coverage report

- [x] 1.1 Write a failing `tools/test_pipeline.py` case: a coverage helper lists cards with no exercises and reports covered/total counts, and exits zero even when coverage is incomplete
- [x] 1.2 Implement an informational coverage report in `tools/` (e.g. `validate.py --coverage` or a `coverage()` helper) that lists cards/themes without exercises and prints covered/total; it MUST NOT affect `validate`/`compile` pass/fail
- [x] 1.3 Confirm `validate.py` and `compile.py` still pass/fail exactly as before (report is independent)

## 2. Theme a1-1 — Орфография и фонетика (A1-01…A1-06)

- [x] 2.1 Render & read the workbook pages for this theme; clarify the bodies of A1-01…A1-06 (fuller explanations, more examples, common-mistake notes for Russophones), preserving frontmatter and the callout sections
- [x] 2.2 Author `multiple-choice` + `fill-in-the-blank` exercises for A1-01…A1-06 (alphabet/letter names, sounds, syllables/diphthongs, stress & tilde, capitalization, ¿ ¡ punctuation), each referencing its card
- [x] 2.3 Run `tools/validate.py`; fix any issues

## 3. Theme a1-2 — Существительное и его окружение (A1-07…A1-13)

- [x] 3.1 Clarify bodies of A1-09…A1-13 (articles, al/del, adjectives agreement/position, possessives, demonstratives); A1-07/A1-08 already revised-or-pilot — review and top up
- [x] 3.2 Author exercises for A1-09…A1-13 (and add more for A1-07/A1-08 if thin), `multiple-choice` + `fill-in-the-blank`
- [x] 3.3 Run `tools/validate.py`; fix any issues

## 4. Theme a1-3 — Глагол — ядро A1 (A1-14…A1-22)

- [x] 4.1 Clarify bodies of A1-14…A1-22 (pronouns, ser, estar/ser-vs-estar, hay, tener, presente regular, common irregulars, reflexives, gustar)
- [x] 4.2 Author exercises for A1-14…A1-22 — conjugation gaps as `fill-in-the-blank` (раскрытие форм), ser/estar & gustar choices as `multiple-choice`
- [x] 4.3 Run `tools/validate.py`; fix any issues

## 5. Theme a1-4 — Служебные слова и конструкции (A1-23…A1-26)

- [x] 5.1 Clarify bodies of A1-23…A1-26 (negation, question words, basic prepositions, muy vs mucho)
- [x] 5.2 Author exercises for A1-23…A1-26 (`multiple-choice` for muy/mucho & question words, `fill-in-the-blank` for prepositions/negation)
- [x] 5.3 Run `tools/validate.py`; fix any issues

## 6. Theme a1-5 — Числа, время и быт (A1-27…A1-30)

- [x] 6.1 Clarify bodies of A1-27…A1-30 (numbers, telling time, days/months/dates, everyday vocabulary)
- [x] 6.2 Author exercises for A1-27…A1-30 (`fill-in-the-blank` for numbers/time/dates, `multiple-choice` where a single answer fits)
- [x] 6.3 Run `tools/validate.py`; fix any issues

## 7. Compile, verify, and confirm coverage

- [x] 7.1 Run `tools/compile.py` to refresh `Packages/LoritoKit/Sources/Content/Resources/content.json`
- [x] 7.2 Run `tools/test_pipeline.py` and confirm green
- [x] 7.3 Run `cd Packages/LoritoKit && swift test` and confirm green (bundle still decodes; `CardBodyCorpusTests` parses every revised body; `ContentTests` resolves all exercise→card references)
- [x] 7.4 Run the coverage report and confirm every A1 card has at least one exercise (no A1 gaps remain)
- [x] 7.5 Verify each scenario in `specs/content-pipeline/spec.md` is covered by a test
- [x] 7.6 Run `openspec validate a1-exercises-and-theory --strict` and fix until valid
