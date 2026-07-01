# Tasks

B1 content pass: exercises (`multiple-choice` + `fill-in-the-blank` only) for every
B1 theme, plus clearer theory in the B1 card bodies. Same shape as A1/A2.

## 1. Theme b1-1 — Presente de subjuntivo: образование и триггеры (B1-01…B1-05)
- [x] 1.1 Clarify bodies of B1-01…B1-05, preserving frontmatter and callout sections
- [x] 1.2 Author MC + fill-in-the-blank exercises for B1-01…B1-05 (ids `B1-EX-1xx`)
- [x] 1.3 Run `tools/validate.py`

## 2. Theme b1-2 — Subjuntivo в придаточных + imperfecto de subjuntivo (B1-06…B1-10)
- [x] 2.1 Clarify bodies of B1-06…B1-10
- [x] 2.2 Author exercises (ids `B1-EX-2xx`)
- [x] 2.3 Run `tools/validate.py`

## 3. Theme b1-3 — Времена: углубление (B1-11…B1-14)
- [x] 3.1 Clarify bodies of B1-11…B1-14
- [x] 3.2 Author exercises (ids `B1-EX-3xx`)
- [x] 3.3 Run `tools/validate.py`

## 4. Theme b1-4 — Условные, косвенная речь, пассив (B1-15…B1-19)
- [x] 4.1 Clarify bodies of B1-15…B1-19
- [x] 4.2 Author exercises (ids `B1-EX-4xx`)
- [x] 4.3 Run `tools/validate.py`

## 5. Theme b1-5 — Конструкции и лексика (B1-20…B1-25)
- [x] 5.1 Clarify bodies of B1-20…B1-25
- [x] 5.2 Author exercises (ids `B1-EX-5xx`)
- [x] 5.3 Run `tools/validate.py`

## 6. Compile, verify, and confirm coverage
- [x] 6.1 Run `tools/compile.py` to refresh `content.json`
- [x] 6.2 Run `tools/test_pipeline.py` (green)
- [x] 6.3 Run `swift test` (green; bundle decodes, bodies parse, references resolve)
- [x] 6.4 Run `tools/validate.py --coverage B1` and confirm 25/25
- [x] 6.5 Run `openspec validate b1-exercises-and-theory --strict`
