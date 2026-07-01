## Context

The `practice-exercises` capability (all phases) is complete and canonical: the app renders and checks six exercise types, and 700 `multiple-choice` / `fill-in-the-blank` exercises cover every A1–C2 card. Phase 2 added engine + UI for `matching`, `word-order`, `picture-matching`, and `free-response`, verified live on the simulator — but no content exercises those interaction modes. This change is content-only production against the frozen format.

## Goals / Non-Goals

**Goals:**
- Broad coverage of the three asset-free new types (`matching`, `word-order`, `free-response`) across every theme A1–C2.
- Varied, correct, self-contained exercises grounded in the existing card bodies (the source of truth).
- Bundle recompiled; all tests green.

**Non-Goals:**
- `picture-matching` content (needs image assets that cannot be sourced now — deferred).
- Any app/Swift/UI/pipeline source change — the engine already handles these types.
- Re-authoring or changing the existing 700 MC/fill exercises.

## Decisions

### Distinct per-type id blocks (no collisions)
Existing exercises use `<LEVEL>-EX-NN` up to the ~5xx range. New ones use a **letter-tagged** id per type so they never collide and are self-documenting:
- `matching` → `<LEVEL>-EX-M01…`
- `word-order` → `<LEVEL>-EX-W01…`
- `free-response` → `<LEVEL>-EX-F01…`

The exercise `id` only needs to be unique (the validator checks uniqueness, not a numeric width), so letter-tagged ids are valid.

### Type ↔ material fit
Author each type where it teaches well, grounded in the card:
- `matching` — verb↔meaning, question↔answer, term↔definition, Spanish↔Russian, phrase start↔end. ≥2 pairs, unambiguous.
- `word-order` — assemble a sentence that the card's grammar produces; the token multiset must form the `answer`; add `accept` for legitimate alternative word orders (Spanish is flexible).
- `free-response` — translation («переведите») or open question («ответьте»); self-assessed, so the `answer` is a model reference (and `accept` lists common equivalents). This is the natural home for the lexical/stylistic C1–C2 cards where a single auto-checkable answer is unfair.

### Parallel authoring, one agent per level
Six subagents (A1…C2) author the three new types across their level's themes into disjoint files, then a central pass validates, compiles, and runs the tests — mirroring the completed per-level content passes.

## Risks / Trade-offs

- **Ambiguous auto answers** (word-order especially — Spanish word order is flexible) → prefer short, unambiguous target sentences; use `accept` for genuinely valid alternative orderings; the validator enforces that `tokens` can form `answer`.
- **Free-response can't be auto-graded** → by design it is self-assessed; the reference answer must be a good model, and `accept` captures common equivalents for the learner's benefit.
- **Volume** → broad scope across 30 themes × 3 types is large; parallel per-level agents keep it tractable, and central `validate.py` + `swift test` (`CardBodyCorpusTests`, `ContentTests`) guard integrity. The coverage report already shows 25–30/25–30 per level for card coverage; this change adds breadth of type, not new card coverage.

## Migration Plan

1. Per level (A1…C2): author matching / word-order / free-response for each theme, referencing existing cards; validate.
2. Recompile `content.json`; run `test_pipeline.py` and `swift test`; confirm green.
3. Additive and reversible: revert removes the new exercise files; existing content and ids are untouched.

## Open Questions

- `picture-matching` remains deferred until image assets exist; when they do, a follow-up change authors it (engine + pipeline already support it).
