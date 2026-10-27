## 1. Rule content and pipeline (TDD)

- [ ] 1.0 Dependencies applied: `learning-platform-foundation`, `cloudkit-schema-release`; conjugation data from `conjugation-trainer` if available (else lemma table hand-authored)
- [ ] 1.1 Document `content/lens/` in `content/schema.md`: `id`, `title_ru`, `cards`, `pattern` (surface/lemma predicates only), `requires`, `examples.positive`, `examples.negative`, and `lemmas.tsv`
- [ ] 1.2 Python reference tokenizer + matcher in `tools/lens.py` (stdlib only, whitespace/punctuation tokenizer + the lemma table)
- [ ] 1.3 Failing tests in `tools/test_pipeline.py`: unknown card id fails; lexical-class predicate fails; lemma missing from the table fails; positive not matching fails; negative matching fails; compile emits `lens.json` and the lemma table
- [ ] 1.4 Author the first rule set (≥ 20 rules): ser/estar, subjuntivo triggers, pretérito/imperfecto markers, gender exceptions, por/para, gustar-type verbs — each with ≥ 3 positive and ≥ 2 negative examples

## 2. Domain (TDD)

- [ ] 2.1 `LensToken`, `LensRule`, `LensMatch`; decoding tests for `lens.json`
- [ ] 2.2 Failing tests for `LensMatcher.match`: predicate sequence with gaps, context requirements, longest-span overlap resolution, specificity tie-break, determinism; fixtures mirror the Python examples
- [ ] 2.3 Cross-check test: Swift matcher on compiled examples yields the same results as the pipeline

## 3. Features

- [ ] 3.1 `LensTokenizer`: `NLTokenizer` for sentences/words (one instance per queue), lemmas from the compiled table; cross-check tests that Swift tokens equal the Python reference tokens on all rule examples
- [ ] 3.2 Paste screen and results view: highlighted spans (Spanish voice), rule names in Russian, card links, «Добавить в повторение»
- [ ] 3.3 Camera (`DataScannerViewController`, Spanish recognition) and photo (`ImageAnalysisInteraction`) inputs; `NSCameraUsageDescription` in Russian; denied-permission state
- [ ] 3.4 Action extension target in `project.yml` accepting `public.plain-text`; results inside the extension + open-in-app link
- [ ] 3.5 «Добавить в повторение»: persist `requestedAt` per `cloudkit-schema-release`; daily planner input `requestedItems`; failing tests: requested items come first among new introductions within the combined budget, older request first; an item with review state is never rescheduled
- [ ] 3.5a Lens shows «Уже в повторении — через N дней» for scheduled cards
- [ ] 3.6 Entry points: Today toolbar and Catalog search («Разобрать текст»)
- [ ] 3.7 Analytics per the `product-analytics` delta (never the analysed text)

## 4. Validation

- [ ] 4.1 `swift test`, `python3 tools/test_pipeline.py` green
- [ ] 4.2 `xcodebuild` build incl. the extension; UI test: paste "Espero que vengas" → highlight → open card → add to review → card appears first among today's new items
- [ ] 4.3 Manual: camera and photo on device; airplane mode; share from Safari and Mail
- [ ] 4.4 `openspec validate grammar-lens --strict`
