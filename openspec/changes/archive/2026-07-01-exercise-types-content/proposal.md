## Why

`practice-exercises` Phase 2 shipped the engine and UI for four more exercise types (`matching`, `word-order`, `picture-matching`, `free-response`), but no content uses them — all 700 authored exercises are `multiple-choice` / `fill-in-the-blank`. This change authors the three asset-free new types **broadly across every theme A1–C2**, so learners drill with varied interaction modes (pair-matching, sentence assembly, translation) instead of only single-form questions. `picture-matching` needs bundled images that cannot be sourced now, so it stays deferred.

## What Changes

- Author exercises of **`matching`**, **`word-order`**, and **`free-response`** across every theme of all levels (a1-1…c2-5), each referencing an existing card of the same level, using the frozen exercise format. Target ~2–4 of each new type per theme where the material suits it:
  - `matching` — pair items (verb↔meaning, question↔answer, Spanish↔Russian, phrase start↔end).
  - `word-order` — «составьте предложение из слов» (tokens → target sentence; `accept` for legit orderings).
  - `free-response` — «переведите» / «ответьте на вопрос», self-assessed (reference `answer`), especially for lexical/stylistic C1–C2 cards.
- Use a distinct id block per new type so nothing collides with the existing `<LEVEL>-EX-NN` exercises.
- Recompile the bundle; keep `validate.py`, `test_pipeline.py`, and `swift test` green.

Content-only — the engine already renders and checks these three types (verified on the simulator).

## Capabilities

### New Capabilities
<!-- None. -->

### Modified Capabilities
- `content-model`: Adds an "Exercise-type variety" expectation — where the material suits it, a level SHOULD offer auto-checkable variety (matching, word-order) and self-assessed free-response, not only single-form multiple-choice / fill-in-the-blank drills.

## Impact

- **Content (added)**: `content/<LEVEL>/exercises/*.md` — matching / word-order / free-response exercises for every theme A1–C2.
- **Bundle (regenerated)**: `Packages/LoritoKit/Sources/Content/Resources/content.json`.
- **Consumed, not modified**: the `practice-exercises` format/engine/UI, `content-pipeline`, design-system rendering.
- **No new dependencies; no Swift/app/UI/pipeline source changes.**
- **Deferred (separate future work)**: `picture-matching` content — engine and pipeline are ready, but it needs bundled image assets that cannot be sourced now.
