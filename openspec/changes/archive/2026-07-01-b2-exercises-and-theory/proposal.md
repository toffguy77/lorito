## Why

The per-level content passes bring each CEFR level to full exercise coverage and clearer theory. A1, A2, and B1 are done and archived; this change does the same for **B2** — completing the subjuntivo system, conditionals/hypotheticals, complex subordination, verb/voice/`se`, and B2 lexis/word-formation/style. The exercise engine, content format, and coverage report already exist; this is pure content against the frozen format.

## What Changes

- Author practice **exercises for every B2 theme** (`b2-1`…`b2-5`), each referencing an existing B2 card, restricted to the app-rendered types **`multiple-choice`** and **`fill-in-the-blank`**. ~3–5 per card.
- **Clarify the B2 theory**: revise the B2 card bodies (`B2-01`…`B2-25`) with fuller explanations, more examples, and common-mistake notes for Russian speakers — preserving each card's frontmatter and the callout conventions.
- Recompile the bundle and keep `validate.py`, `test_pipeline.py`, and `swift test` green; confirm B2 reaches 25/25 via the coverage report.

No app-code/UI/pipeline change — content only.

## Capabilities

### New Capabilities
<!-- None. -->

### Modified Capabilities
- `content-model`: Updates the "Exercise coverage of cards" requirement to record that level B2 is now fully covered (alongside A1, A2, B1).

## Impact

- **Content (added)**: `content/B2/exercises/*.md` covering all B2 themes.
- **Content (modified)**: `content/B2/B2-01.md` … `B2-25.md` — clearer theory; frontmatter unchanged.
- **Bundle (regenerated)**: `content.json` recompiled.
- **Consumed, not modified**: the `practice-exercises` format/engine, `content-pipeline` (incl. coverage report), design-system rendering.
- **No new dependencies; no Swift/app/UI/pipeline source changes.**
- **Out of scope (separate future changes)**: levels C1, C2; the Phase-2 exercise types and their engine/UI.
