## Context

Platform facts:
- `NLTagger` segments text and tags words with lexical class and lemma among other
  schemes; which schemes exist for a language on a device is queried at runtime with
  `availableTagSchemes(for:language:)`, and missing assets can be requested with
  `requestAssets(for:tagScheme:)` ([NLTagger docs](https://developer.apple.com/documentation/naturallanguage/nltagger);
  [NLTagScheme.lemma](https://developer.apple.com/documentation/naturallanguage/nltagscheme/lemma)).
  Apple's pages do not publish a per-language matrix, so Spanish lemma support is
  treated as runtime-detected, not assumed.
- An `NLTagger` instance is not safe for concurrent use; one instance per queue
  (same page).
- Live Text capture is available through VisionKit (`DataScannerViewController` for
  live camera, `ImageAnalysisInteraction` for photos) on supported devices.

Cards already carry structured "Частые ошибки" sections and `related` links; the
pipeline is Python stdlib.

## Goals / Non-Goals

**Goals:** fully offline; deterministic highlights; every highlight justified by an
authored rule and linked to a card; rules testable in CI without a device.

**Non-Goals:** translation; full parsing or grammatical error correction; any cloud
or LLM call; Spanish OCR of handwriting beyond what Live Text returns.

## Decisions

**Two-stage pipeline: tokenizer adapter → pure matcher.** The adapter uses
`NLTagger`/`NLTokenizer` only to split sentences and words, and fills each token's
lemma from the compiled lemma table, producing `[LensToken]` (surface, lowercased
form, lemma or nil, sentence index, range). `LensMatcher.match(tokens:rules:) -> [LensMatch]` is pure and
unit-tested with hand-written token fixtures, so Domain stays free of
NaturalLanguage, consistent with CLAUDE.md.

**Rule format.** Each rule: `id`, `cards` (1+ card IDs), `pattern` (a short sequence
of token predicates: surface or lemma in a set, optional gap ≤ N tokens, sentence
boundary — lexical-class predicates are forbidden because the stdlib validator cannot
evaluate them; the validator rejects them), `requires` (context predicates that must also hold), and
`examples.positive` / `examples.negative`. Example — subjunctive trigger: lemma in
{querer, esperar} + "que" + verb within 3 tokens, cards B1 subjunctive. Gender
exceptions are lexical: surface in {el problema, la mano, el día…} → A1-07.

**Lemma table, not the system lemma model.** Lemmas come from a table compiled from
`content/lens/lemmas.tsv` and the conjugation data of `conjugation-trainer`
(form → lemma for every word rules reference). The system `.lemma` scheme is not used,
so results do not vary by device or OS, and the Python validator reproduces app
behaviour exactly. Validation fails if a rule references a lemma missing from the table.

**Precision first.** A match needs every predicate in `pattern` and `requires`.
Overlapping matches keep the longest; ties keep the rule with more specific
predicates. Validation fails when any negative example matches or any positive
example does not.

**Inputs.** Paste screen (text field + «Разобрать»); camera via
`DataScannerViewController` (text recognition, Spanish recognition language),
photo via `ImageAnalysisInteraction`; Action extension receives plain text and
opens the results inside the extension with a link into the app. Text is never
stored unless the user saves a card to review.

**Adding to review.** «Добавить в повторение» on a card with no review state stores
`requestedAt` for that item; the daily planner (new `daily-plan` requirement) puts
requested items first among today's new introductions, inside the combined daily
new-introduction budget of `learning-platform-foundation`. A card that already has a
review state is never moved (moving due dates would corrupt the scheduler's
last-review history); the lens shows «Уже в повторении — через N дней» instead.

## Risks / Trade-offs

- [Low recall disappoints] → empty-state copy explains what Lens recognises and
  lists covered topics; coverage grows by adding rule files.
- [Tokenizer differences across OS versions] → only boundaries come from the system;
  cross-check tests against the Python reference on every rule example.
- [Camera permission friction] → paste and share work without camera access.

## Migration Plan

Additive; new content folder, new extension target. Rollback: remove entry points
and the extension; stored `requestedAt` values of unstarted items are simply ignored by the planner if the requirement is reverted.
