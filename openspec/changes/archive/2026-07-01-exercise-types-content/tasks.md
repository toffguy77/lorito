# Tasks

Author `matching`, `word-order`, and `free-response` exercises broadly across
every theme A1–C2, grounded in the existing card bodies. Distinct id blocks per
type (`<LEVEL>-EX-M/W/F NN`) so nothing collides with existing exercises.
`picture-matching` is deferred (no image assets). One level per parallel agent.

## 1. A1 — new-type exercises for every theme (a1-1…a1-5)
- [x] 1.1 Author matching / word-order / free-response for A1 cards (~2–4 of each type per theme), referencing existing A1 cards
- [x] 1.2 Run `tools/validate.py`; fix any issues

## 2. A2 — new-type exercises for every theme (a2-1…a2-5)
- [x] 2.1 Author matching / word-order / free-response for A2 cards
- [x] 2.2 Run `tools/validate.py`

## 3. B1 — new-type exercises for every theme (b1-1…b1-5)
- [x] 3.1 Author matching / word-order / free-response for B1 cards
- [x] 3.2 Run `tools/validate.py`

## 4. B2 — new-type exercises for every theme (b2-1…b2-5)
- [x] 4.1 Author matching / word-order / free-response for B2 cards
- [x] 4.2 Run `tools/validate.py`

## 5. C1 — new-type exercises for every theme (c1-1…c1-5)
- [x] 5.1 Author matching / word-order / free-response for C1 cards (free-response especially for lexical/stylistic cards)
- [x] 5.2 Run `tools/validate.py`

## 6. C2 — new-type exercises for every theme (c2-1…c2-5)
- [x] 6.1 Author matching / word-order / free-response for C2 cards (free-response especially for lexical/stylistic cards)
- [x] 6.2 Run `tools/validate.py`

## 7. Compile & verify
- [x] 7.1 Run `tools/compile.py` to refresh `content.json`
- [x] 7.2 Run `tools/test_pipeline.py` (green)
- [x] 7.3 Run `cd Packages/LoritoKit && swift test` (green; bundle decodes, every exercise→card reference resolves)
- [x] 7.4 Confirm each level now has matching / word-order / free-response exercises (spot-check the bundle)
- [x] 7.5 Run `openspec validate exercise-types-content --strict`
