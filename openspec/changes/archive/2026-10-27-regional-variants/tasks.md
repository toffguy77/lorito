## 0. Dependencies

- [x] 0.1 `spanish-audio`, `learning-platform-foundation`, `cloudkit-schema-release` and `conjugation-trainer` applied; coordinate the recognition locale with `listening-and-pronunciation`

## 1. Content model & pipeline (TDD)

- [x] 1.1 Document codes, block/inline markup (and the Obsidian `[[…]]` reason), exercise `variants`/`only`, verb `vos` forms in `content/schema.md`
- [x] 1.2 Failing tests in `tools/test_pipeline.py`: unclosed/nested block, unknown code, inline with one code or a repeated code, plain braces accepted, override violating type schema, `only` with unknown code
- [x] 1.3 Failing tests: voseo generation (`hablás`, `comés`, `vivís`, `hablá`), `tú` copy for other tenses, `ser` → `sos` override
- [x] 1.4 Implement in `tools/validate.py`, `tools/conjugate.py`, `tools/compile.py`; check `tools/migrate.py` leaves the markup intact

## 2. Content

- [x] 2.1 Audit all 159 cards; add variant blocks/inline alternatives where usage differs (second person plural, imperatives, lexical items)
- [x] 2.2 Add `variants` overrides / `only` to exercises that drill `vosotros` or variant-specific words
- [x] 2.3 Add `vos` overrides for irregular verbs in the conjugation set; run `python3 tools/compile.py`

## 3. Domain (TDD)

- [x] 3.1 Failing tests: `SpanishVariant.rioplatense`; code mapping `es`/`am`/`rio`; unknown stored value decodes as `spain`
- [x] 3.2 Failing tests: Domain `CardBodyParser` splits variant blocks and inline alternatives; resolution per variant with `es` fallback; plain braces untouched
- [x] 3.3 Failing tests: exercise answer resolution and `only` filtering per variant
- [x] 3.4 Failing tests: person set per variant (Rioplatense uses `vos` forms)
- [x] 3.5 Failing tests: Rioplatense voice order `es-AR` → `es-MX` → `es-ES`
- [x] 3.6 Implement

## 4. Features

- [x] 4.1 Settings: «Риоплатский» value in the existing variant picker
- [x] 4.2 Today: one-time variant prompt after the first completed session; optional/defaulted «prompt shown» settings field per `cloudkit-schema-release`
- [x] 4.3 Card rendering: in-place variant content, collapsed notes for other variants, inline alternatives as Spanish spans with «Варианты»
- [x] 4.4 Pass the variant's person set to the conjugation trainer; voice fallback in `spanish-audio`; recognition locale to `listening-and-pronunciation`

## 5. Validation

- [x] 5.1 `swift test`, `python3 tools/test_pipeline.py` green
- [x] 5.2 `xcodebuild`; UI tests: first session → variant prompt → choose Rioplatense → a card shows the `rio` form and «В Испании» note; drill asks vos
- [ ] 5.3 (manual, owner) Manual: voice fallback on a device without an `es-AR` voice; a card with markup opens cleanly in Obsidian
- [x] 5.4 `openspec validate regional-variants --strict`
