## Why

The per-level content passes bring each CEFR level to full exercise coverage and clearer theory. `a1-exercises-and-theory` completed **A1** (30/30 cards covered, theory revised). This change does the same for **A2** — the past tenses, future/conditional, object pronouns and imperative, comparatives/adverbs/connectors, and the A2 constructions. The exercise engine, content format, and the coverage report all already exist; this is pure content production against the frozen format.

One level per change keeps each unit reviewable and shippable, with no app-code risk.

## What Changes

- Author practice **exercises for every A2 theme** (`a2-1`…`a2-5`), each referencing an existing A2 card, using the frozen exercise format. Restricted to the two types the app renders today — **`multiple-choice`** and **`fill-in-the-blank`**. Target a solid set per card (~3–6).
- **Clarify the A2 theory**: revise the A2 card bodies (`A2-01`…`A2-29`) to explain more, with more examples and common-mistake notes for Russian-speaking learners — preserving each card's frontmatter (`id`, `level`, `theme`, `order`, `title`, `related`), the callout conventions (Суть / Ключевые моменты / Частые ошибки / Полезно), and the id/semantic-token rules.
- Recompile the content bundle (`content.json`) and keep `validate.py`, `test_pipeline.py`, and `swift test` green; confirm A2 coverage reaches 29/29 via the existing coverage report.

This change delivers **no app-code, UI, or pipeline change** — it is content only. The exercise-coverage report added in the A1 pass is reused as-is.

## Capabilities

### New Capabilities
<!-- None. -->

### Modified Capabilities
- `content-model`: Records the durable requirement that every card should have at least one practice exercise (a level is "fully covered" when all its cards do) and that an exercise's `card` resolves to a same-level card it drills. The exercise format/engine and the coverage report already exist; otherwise this change only adds content.

## Impact

- **Content (added)**: `content/A2/exercises/*.md` — exercises covering all A2 themes.
- **Content (modified)**: `content/A2/A2-01.md` … `A2-29.md` — clearer, fuller theory bodies; frontmatter unchanged.
- **Bundle (regenerated)**: `Packages/LoritoKit/Sources/Content/Resources/content.json` recompiled with the new exercises and revised bodies.
- **Consumed, not modified**: the `practice-exercises` format/engine, `content-model`, `content-pipeline` (incl. the coverage report), the design-system callout rendering.
- **No new dependencies; no Swift/app/UI/pipeline source changes** (Swift tests still run to prove the bundle decodes and every body parses).
- **Out of scope (separate future changes)**: levels B1, B2, C1, C2 (one per-level change each); the Phase-2 exercise types and their engine/UI.
