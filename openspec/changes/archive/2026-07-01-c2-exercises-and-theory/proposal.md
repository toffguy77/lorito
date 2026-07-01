## Why

The per-level content passes bring each CEFR level to full exercise coverage and clearer theory. A1–C1 are done and archived; this change completes the curriculum with **C2** — residual grammar/syntax subtleties, high-level lexis, phraseology & imagery mastery, rhetoric/style/genres, and sociolinguistics/pragmatics/mediation. With C2 done, **all six levels A1–C2 are fully covered**. The exercise engine, content format, and coverage report already exist; this is pure content against the frozen format.

## What Changes

- Author practice **exercises for every C2 theme** (`c2-1`…`c2-5`), each referencing an existing C2 card, restricted to the app-rendered types **`multiple-choice`** and **`fill-in-the-blank`**. ~3–4 per card, each with a single unambiguous answer.
- **Clarify the C2 theory**: revise the C2 card bodies (`C2-01`…`C2-25`) with fuller explanations, more examples, and common-mistake notes for Russian speakers — preserving each card's frontmatter and the callout conventions.
- Recompile the bundle and keep `validate.py`, `test_pipeline.py`, and `swift test` green; confirm C2 reaches 25/25 (and all six levels are now covered) via the coverage report.

No app-code/UI/pipeline change — content only.

## Capabilities

### New Capabilities
<!-- None. -->

### Modified Capabilities
- `content-model`: Updates the "Exercise coverage of cards" requirement to record that level C2 is now fully covered — completing coverage of all six levels (A1–C2).

## Impact

- **Content (added)**: `content/C2/exercises/*.md` covering all C2 themes.
- **Content (modified)**: `content/C2/C2-01.md` … `C2-25.md` — clearer theory; frontmatter unchanged.
- **Bundle (regenerated)**: `content.json` recompiled — exercises now span every card in every level.
- **Consumed, not modified**: the `practice-exercises` format/engine, `content-pipeline` (incl. coverage report), design-system rendering.
- **No new dependencies; no Swift/app/UI/pipeline source changes.**
- **Out of scope (separate work)**: the Phase-2 exercise types and their engine/UI (`matching`, `word-order`, `picture-matching`, `free-response`) — once they ship, the lexical/stylistic C1–C2 cards can be enriched with `free-response` items.
