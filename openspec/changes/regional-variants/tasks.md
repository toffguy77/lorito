## 0. Dependencies

- [ ] 0.1 `conjugation-trainer` and `spanish-audio` applied; coordinate recognition locale with `listening-and-pronunciation`

## 1. Content model & pipeline (TDD)

- [ ] 1.1 Document variants, block/inline markup, exercise `variants`/`only`, verb `vos` forms in `content/schema.md`
- [ ] 1.2 Failing tests in `tools/test_pipeline.py`: unclosed/nested block, unknown variant, inline with one variant, override violating type schema, `only` with unknown variant
- [ ] 1.3 Failing tests: voseo generation (`hablás`, `comés`, `vivís`, `hablá`), `tú` copy for other tenses, `ser` → `sos` override
- [ ] 1.4 Implement in `tools/validate.py`, `tools/conjugate.py`, `tools/compile.py`

## 2. Content

- [ ] 2.1 Audit all 159 cards; add variant blocks/inline alternatives where usage differs (second person plural, imperatives, lexical items)
- [ ] 2.2 Add `variants` overrides / `only` to exercises that drill `vosotros` or variant-specific words
- [ ] 2.3 Add `vos` overrides for irregular verbs in the conjugation set; run `python3 tools/compile.py`

## 3. Domain (TDD)

- [ ] 3.1 Failing tests: `Variant` enum, default `spain`; settings round-trip
- [ ] 3.2 Failing tests: `CardBodyParser` splits variant blocks and inline alternatives; resolution for each variant with Spain fallback
- [ ] 3.3 Failing tests: exercise answer resolution and `only` filtering per variant
- [ ] 3.4 Failing tests: conjugation person set per variant; Rioplatense uses `vos` forms
- [ ] 3.5 Failing tests: preferred voice language and fallback order
- [ ] 3.6 Implement

## 4. Features

- [ ] 4.1 Onboarding variant step and settings picker (Russian copy)
- [ ] 4.2 Card rendering: in-place variant content, collapsed notes for other variants, tappable inline alternatives
- [ ] 4.3 Pass voice language to `spanish-audio`; recognition locale to `listening-and-pronunciation`
- [ ] 4.4 Persistence: settings field in the CloudKit development schema; note production deployment

## 5. Validation

- [ ] 5.1 `swift test`, `python3 tools/test_pipeline.py` green
- [ ] 5.2 `xcodebuild`; UI test: switch to Rioplatense → a card shows Rioplatense form and «В Испании» note; drill asks `vos`
- [ ] 5.3 Manual: voice fallback on a device without `es-AR` voice
- [ ] 5.4 `openspec validate regional-variants --strict`
