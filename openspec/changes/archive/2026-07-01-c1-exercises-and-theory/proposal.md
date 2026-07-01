## Why

The per-level content passes bring each CEFR level to full exercise coverage and clearer theory. A1–B2 are done and archived; this change does the same for **C1** — verb-system & mood subtleties, advanced syntax, advanced lexis & word-formation, idiomatics/variation/register, and discourse/pragmatics/style. The exercise engine, content format, and coverage report already exist; this is pure content against the frozen format.

## What Changes

- Author practice **exercises for every C1 theme** (`c1-1`…`c1-5`), each referencing an existing C1 card, restricted to the app-rendered types **`multiple-choice`** and **`fill-in-the-blank`**. ~3–4 per card, each with a single unambiguous answer.
- **Clarify the C1 theory**: revise the C1 card bodies (`C1-01`…`C1-25`) with fuller explanations, more examples, and common-mistake notes for Russian speakers — preserving each card's frontmatter and the callout conventions.
- Recompile the bundle and keep `validate.py`, `test_pipeline.py`, and `swift test` green; confirm C1 reaches 25/25 via the coverage report.

No app-code/UI/pipeline change — content only.

## Capabilities

### New Capabilities
<!-- None. -->

### Modified Capabilities
- `content-model`: Updates the "Exercise coverage of cards" requirement to record that level C1 is now fully covered (alongside A1, A2, B1, B2).

## Impact

- **Content (added)**: `content/C1/exercises/*.md` covering all C1 themes.
- **Content (modified)**: `content/C1/C1-01.md` … `C1-25.md` — clearer theory; frontmatter unchanged.
- **Bundle (regenerated)**: `content.json` recompiled.
- **Consumed, not modified**: the `practice-exercises` format/engine, `content-pipeline` (incl. coverage report), design-system rendering.
- **No new dependencies; no Swift/app/UI/pipeline source changes.**
- **Out of scope (separate future change)**: level C2; the Phase-2 exercise types and their engine/UI.
