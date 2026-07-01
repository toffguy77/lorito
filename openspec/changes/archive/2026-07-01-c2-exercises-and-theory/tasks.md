# Tasks

C2 content pass (final level): exercises (`multiple-choice` + `fill-in-the-blank`
only) for every C2 theme, plus clearer theory in the C2 card bodies. Same shape
as A1–C1.

## 1. Theme c2-1 — Остаточные тонкости грамматики и синтаксиса (C2-01…C2-05)
- [x] 1.1 Clarify bodies of C2-01…C2-05, preserving frontmatter and callout sections
- [x] 1.2 Author MC + fill-in-the-blank exercises (ids `C2-EX-1xx`)
- [x] 1.3 Run `tools/validate.py`

## 2. Theme c2-2 — Лексика высокого уровня (C2-06…C2-10)
- [x] 2.1 Clarify bodies of C2-06…C2-10
- [x] 2.2 Author exercises (ids `C2-EX-2xx`)
- [x] 2.3 Run `tools/validate.py`

## 3. Theme c2-3 — Фразеология и образность (C2-11…C2-15)
- [x] 3.1 Clarify bodies of C2-11…C2-15
- [x] 3.2 Author exercises (ids `C2-EX-3xx`)
- [x] 3.3 Run `tools/validate.py`

## 4. Theme c2-4 — Риторика, стиль, жанры (C2-16…C2-20)
- [x] 4.1 Clarify bodies of C2-16…C2-20
- [x] 4.2 Author exercises (ids `C2-EX-4xx`)
- [x] 4.3 Run `tools/validate.py`

## 5. Theme c2-5 — Социолингвистика, прагматика, медиация (C2-21…C2-25)
- [x] 5.1 Clarify bodies of C2-21…C2-25
- [x] 5.2 Author exercises (ids `C2-EX-5xx`)
- [x] 5.3 Run `tools/validate.py`

## 6. Compile, verify, and confirm coverage
- [x] 6.1 Run `tools/compile.py` to refresh `content.json`
- [x] 6.2 Run `tools/test_pipeline.py` (green)
- [x] 6.3 Run `swift test` (green; bundle decodes, bodies parse, references resolve)
- [x] 6.4 Run `tools/validate.py --coverage C2` and confirm 25/25 (all six levels now covered)
- [x] 6.5 Run `openspec validate c2-exercises-and-theory --strict`
