## 1. Rule content and pipeline (TDD)

- [ ] 1.1 Document `content/lens/` in `content/schema.md`: `id`, `title_ru`, `cards`, `pattern`, `requires`, `examples.positive`, `examples.negative`
- [ ] 1.2 Python reference tokenizer + matcher in `tools/lens.py` (stdlib only, whitespace/punctuation tokenizer + the compiled lemma table)
- [ ] 1.3 Failing tests in `tools/test_pipeline.py`: unknown card id fails; positive not matching fails; negative matching fails; compile emits `lens.json` and the lemma table
- [ ] 1.4 Author the first rule set (≥ 20 rules): ser/estar, subjuntivo triggers, pretérito/imperfecto markers, gender exceptions, por/para, gustar-type verbs — each with ≥ 3 positive and ≥ 2 negative examples

## 2. Domain (TDD)

- [ ] 2.1 `LensToken`, `LensRule`, `LensMatch`; decoding tests for `lens.json`
- [ ] 2.2 Failing tests for `LensMatcher.match`: predicate sequence with gaps, context requirements, longest-span overlap resolution, specificity tie-break, determinism; fixtures mirror the Python examples
- [ ] 2.3 Cross-check test: Swift matcher on compiled examples yields the same results as the pipeline

## 3. Features

- [ ] 3.1 `LensTokenizer` over `NLTagger` (`.tokenType`, `.lexicalClass`, `.lemma` when `availableTagSchemes` lists it for `.spanish`), one tagger per queue; fallback to the lemma table
- [ ] 3.2 Paste screen and results view: highlighted spans (Spanish voice), rule names in Russian, card links, «Добавить в повторение»
- [ ] 3.3 Camera (`DataScannerViewController`, Spanish recognition) and photo (`ImageAnalysisInteraction`) inputs; `NSCameraUsageDescription` in Russian; denied-permission state
- [ ] 3.4 Action extension target in `project.yml` accepting `public.plain-text`; results inside the extension + open-in-app link
- [ ] 3.5 «Добавить в повторение» via existing store operations (new → queued today first; scheduled → due today); tests that ease/interval are unchanged
- [ ] 3.6 Entry points: Today toolbar and Catalog search («Разобрать текст»)
- [ ] 3.7 Analytics via `product-analytics`: lens opened, source, match count bucket, card added (never the text)

## 4. Validation

- [ ] 4.1 `swift test`, `python3 tools/test_pipeline.py` green
- [ ] 4.2 `xcodebuild` build incl. the extension; UI test: paste "Espero que vengas" → highlight → open card → add to review → card due today
- [ ] 4.3 Manual: camera and photo on device; airplane mode; share from Safari and Mail
- [ ] 4.4 `openspec validate grammar-lens --strict`
