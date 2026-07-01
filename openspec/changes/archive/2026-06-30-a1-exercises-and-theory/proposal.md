## Why

The `practice-exercises` change shipped the interactive-exercise engine and froze the content format, then delivered only a two-theme A1 pilot. Learners need exercises across the whole curriculum, and the existing A1 card theory — the first thing every user sees — can be clearer and more example-rich for Russian speakers. This change is the first **per-level content pass**: it brings level **A1** to full coverage (exercises for every theme) and improves its theory. Later changes repeat the pass for A2–C2.

Doing one level per change keeps each unit reviewable and shippable: a self-contained, validated content drop against a stable format, with no app-code risk.

## What Changes

- Author practice **exercises for every A1 theme** (`a1-1`…`a1-5`), each referencing an existing A1 card, using the frozen exercise format. Restricted to the two types the app renders today — **`multiple-choice`** and **`fill-in-the-blank`** (the other four types remain Phase 2 of `practice-exercises`). Target a solid set per card (~3–6).
- **Clarify the A1 theory**: revise the A1 card bodies (`A1-01`…`A1-30`) to explain more and show more examples and common-mistake notes for Russian-speaking learners, preserving each card's frontmatter (`id`, `level`, `theme`, `order`, `title`, `related`), the callout conventions (Суть / Ключевые моменты / Частые ошибки / Полезно), and the id/semantic-token rules.
- Add an **informational exercise-coverage report** to the content pipeline that lists cards/themes lacking exercises, so per-level progress is visible. It is **non-failing** — it never blocks `validate`/`compile`.
- Recompile the content bundle (`content.json`) and keep `validate.py`, `test_pipeline.py`, and `swift test` green.

This change delivers **no app-code or UI change** beyond the pipeline report; it is content plus one pipeline reporting helper.

## Capabilities

### New Capabilities
<!-- None. The exercise format, Domain model, checking, and UI already exist from practice-exercises. -->

### Modified Capabilities
- `content-pipeline`: Adds an exercise-coverage report (an informational listing of cards/themes without exercises) that does not affect the pass/fail result of validation or compilation.

## Impact

- **Content (added)**: `content/A1/exercises/*.md` — exercises covering all A1 themes (extending the pilot's `A1-EX-01`…`A1-EX-10`).
- **Content (modified)**: `content/A1/A1-01.md` … `A1-30.md` — clearer, fuller theory bodies; frontmatter unchanged.
- **Pipeline (modified)**: `tools/` gains a coverage-report helper (e.g. a `--coverage` mode / function) plus `tools/test_pipeline.py` coverage; stays Python stdlib-only.
- **Bundle (regenerated)**: `Packages/LoritoKit/Sources/Content/Resources/content.json` recompiled with the new exercises and revised bodies.
- **Consumed, not modified**: the `practice-exercises` format/engine, `content-model`, the design-system callout rendering.
- **No new dependencies; no app/UI/Swift source changes** (Swift tests still run to prove the bundle still decodes and renders).
- **Out of scope (separate future changes)**: levels A2, B1, B2, C1, C2 (one per-level change each); the Phase-2 exercise types and their engine/UI; picture-matching image assets.
