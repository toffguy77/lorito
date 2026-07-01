# Tasks

C1 content pass: exercises (`multiple-choice` + `fill-in-the-blank` only) for every
C1 theme, plus clearer theory in the C1 card bodies. Same shape as A1–B2.

## 1. Theme c1-1 — Тонкости глагольной системы и наклонений (C1-01…C1-05)
- [x] 1.1 Clarify bodies of C1-01…C1-05, preserving frontmatter and callout sections
- [x] 1.2 Author MC + fill-in-the-blank exercises (ids `C1-EX-1xx`)
- [x] 1.3 Run `tools/validate.py`

## 2. Theme c1-2 — Продвинутый синтаксис (C1-06…C1-10)
- [x] 2.1 Clarify bodies of C1-06…C1-10
- [x] 2.2 Author exercises (ids `C1-EX-2xx`)
- [x] 2.3 Run `tools/validate.py`

## 3. Theme c1-3 — Лексика и словообразование (C1-11…C1-15)
- [x] 3.1 Clarify bodies of C1-11…C1-15
- [x] 3.2 Author exercises (ids `C1-EX-3xx`)
- [x] 3.3 Run `tools/validate.py`

## 4. Theme c1-4 — Идиоматика, вариативность, регистр (C1-16…C1-20)
- [x] 4.1 Clarify bodies of C1-16…C1-20
- [x] 4.2 Author exercises (ids `C1-EX-4xx`)
- [x] 4.3 Run `tools/validate.py`

## 5. Theme c1-5 — Дискурс, прагматика, стиль (C1-21…C1-25)
- [x] 5.1 Clarify bodies of C1-21…C1-25
- [x] 5.2 Author exercises (ids `C1-EX-5xx`)
- [x] 5.3 Run `tools/validate.py`

## 6. Compile, verify, and confirm coverage
- [x] 6.1 Run `tools/compile.py` to refresh `content.json`
- [x] 6.2 Run `tools/test_pipeline.py` (green)
- [x] 6.3 Run `swift test` (green; bundle decodes, bodies parse, references resolve)
- [x] 6.4 Run `tools/validate.py --coverage C1` and confirm 25/25
- [x] 6.5 Run `openspec validate c1-exercises-and-theory --strict`
