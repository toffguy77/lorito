# Tasks

A2 content pass: exercises (`multiple-choice` + `fill-in-the-blank` only) for every
A2 theme, plus clearer theory in the A2 card bodies. Same shape as the completed
A1 pass. Each theme is self-contained — run `tools/validate.py` after each.

## 1. Theme a2-1 — Прошедшие времена (A2-01…A2-06)

- [x] 1.1 Clarify the bodies of A2-01…A2-06 (perfecto, indefinido regular/irregular, imperfecto, indefinido-vs-imperfecto, perfecto-vs-indefinido), preserving frontmatter and callout sections
- [x] 1.2 Author `multiple-choice` + `fill-in-the-blank` exercises for A2-01…A2-06 (ids `A2-EX-1xx`), each referencing its card
- [x] 1.3 Run `tools/validate.py`; fix any issues

## 2. Theme a2-2 — Будущее, условное, перифразы (A2-07…A2-11)

- [x] 2.1 Clarify bodies of A2-07…A2-11 (futuro simple, ir a + inf, condicional, estar + gerundio, perífrasis)
- [x] 2.2 Author exercises for A2-07…A2-11 (ids `A2-EX-2xx`), `multiple-choice` + `fill-in-the-blank`
- [x] 2.3 Run `tools/validate.py`; fix any issues

## 3. Theme a2-3 — Местоимения-дополнения и императив (A2-12…A2-16)

- [x] 3.1 Clarify bodies of A2-12…A2-16 (direct object lo/la/los/las, indirect le/les, combination se lo, affirmative & negative imperative)
- [x] 3.2 Author exercises for A2-12…A2-16 (ids `A2-EX-3xx`) — pronoun choice/placement as `multiple-choice`, imperative forms as `fill-in-the-blank`
- [x] 3.3 Run `tools/validate.py`; fix any issues

## 4. Theme a2-4 — Сравнение, наречия, связки (A2-17…A2-23)

- [x] 4.1 Clarify bodies of A2-17…A2-23 (comparatives, superlative & -ísimo, irregular comparisons, adverbs & -mente, indefinites, connectors, relatives)
- [x] 4.2 Author exercises for A2-17…A2-23 (ids `A2-EX-4xx`), `multiple-choice` + `fill-in-the-blank`
- [x] 4.3 Run `tools/validate.py`; fix any issues

## 5. Theme a2-5 — Конструкции и функциональные темы (A2-24…A2-29)

- [x] 5.1 Clarify bodies of A2-24…A2-29 (obligation hay que/tener que/deber, hace/desde/desde hace/llevar, gustar-type verbs, por vs para, ser vs estar advanced, A2 functional vocabulary)
- [x] 5.2 Author exercises for A2-24…A2-29 (ids `A2-EX-5xx`) — por/para & ser/estar contrasts as `multiple-choice`, time/obligation as `fill-in-the-blank`
- [x] 5.3 Run `tools/validate.py`; fix any issues

## 6. Compile, verify, and confirm coverage

- [x] 6.1 Run `tools/compile.py` to refresh `content.json`
- [x] 6.2 Run `tools/test_pipeline.py` and confirm green
- [x] 6.3 Run `cd Packages/LoritoKit && swift test` and confirm green (bundle decodes; every revised body parses; every exercise→card reference resolves)
- [x] 6.4 Run `tools/validate.py --coverage A2` and confirm 29/29 A2 cards have exercises
- [x] 6.5 Run `openspec validate a2-exercises-and-theory --strict` and fix until valid
