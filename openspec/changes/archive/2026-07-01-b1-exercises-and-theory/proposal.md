## Why

The per-level content passes bring each CEFR level to full exercise coverage and clearer theory. A1 and A2 are done and archived; this change does the same for **B1** — the subjuntivo system (formation and triggers, subordinate clauses, imperfecto de subjuntivo), the deepened tense system, conditionals/reported-speech/passive, and the B1 constructions and lexis. The exercise engine, content format, and coverage report already exist; this is pure content against the frozen format.

## What Changes

- Author practice **exercises for every B1 theme** (`b1-1`…`b1-5`), each referencing an existing B1 card, restricted to the app-rendered types **`multiple-choice`** and **`fill-in-the-blank`**. Target ~3–5 per card.
- **Clarify the B1 theory**: revise the B1 card bodies (`B1-01`…`B1-25`) with fuller explanations, more examples, and common-mistake notes for Russian speakers — preserving each card's frontmatter and the callout conventions.
- Recompile the bundle and keep `validate.py`, `test_pipeline.py`, and `swift test` green; confirm B1 reaches 25/25 via the coverage report.

No app-code/UI/pipeline change — content only.

## Capabilities

### New Capabilities
<!-- None. -->

### Modified Capabilities
- `content-model`: Updates the "Exercise coverage of cards" requirement to record that level B1 is now fully covered (alongside A1 and A2).

## Impact

- **Content (added)**: `content/B1/exercises/*.md` covering all B1 themes.
- **Content (modified)**: `content/B1/B1-01.md` … `B1-25.md` — clearer theory; frontmatter unchanged.
- **Bundle (regenerated)**: `content.json` recompiled.
- **Consumed, not modified**: the `practice-exercises` format/engine, `content-pipeline` (incl. coverage report), design-system rendering.
- **No new dependencies; no Swift/app/UI/pipeline source changes.**
- **Out of scope (separate future changes)**: levels B2, C1, C2; the Phase-2 exercise types and their engine/UI.
