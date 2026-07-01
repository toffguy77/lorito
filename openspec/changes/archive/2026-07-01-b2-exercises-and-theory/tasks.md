# Tasks

B2 content pass: exercises (`multiple-choice` + `fill-in-the-blank` only) for every
B2 theme, plus clearer theory in the B2 card bodies. Same shape as A1/A2/B1.

## 1. Theme b2-1 — Subjuntivo: завершение системы (B2-01…B2-05)
- [x] 1.1 Clarify bodies of B2-01…B2-05, preserving frontmatter and callout sections
- [x] 1.2 Author MC + fill-in-the-blank exercises (ids `B2-EX-1xx`)
- [x] 1.3 Run `tools/validate.py`

## 2. Theme b2-2 — Условные и гипотетические (B2-06…B2-09)
- [x] 2.1 Clarify bodies of B2-06…B2-09
- [x] 2.2 Author exercises (ids `B2-EX-2xx`)
- [x] 2.3 Run `tools/validate.py`

## 3. Theme b2-3 — Сложный синтаксис придаточных (B2-10…B2-13)
- [x] 3.1 Clarify bodies of B2-10…B2-13
- [x] 3.2 Author exercises (ids `B2-EX-3xx`)
- [x] 3.3 Run `tools/validate.py`

## 4. Theme b2-4 — Глагол, залог, «se» (B2-14…B2-18)
- [x] 4.1 Clarify bodies of B2-14…B2-18
- [x] 4.2 Author exercises (ids `B2-EX-4xx`)
- [x] 4.3 Run `tools/validate.py`

## 5. Theme b2-5 — Лексика, словообразование, стиль (B2-19…B2-25)
- [x] 5.1 Clarify bodies of B2-19…B2-25
- [x] 5.2 Author exercises (ids `B2-EX-5xx`)
- [x] 5.3 Run `tools/validate.py`

## 6. Compile, verify, and confirm coverage
- [x] 6.1 Run `tools/compile.py` to refresh `content.json`
- [x] 6.2 Run `tools/test_pipeline.py` (green)
- [x] 6.3 Run `swift test` (green; bundle decodes, bodies parse, references resolve)
- [x] 6.4 Run `tools/validate.py --coverage B2` and confirm 25/25
- [x] 6.5 Run `openspec validate b2-exercises-and-theory --strict`
