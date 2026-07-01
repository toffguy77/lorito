## Context

`practice-exercises` froze the exercise format, Domain model, checking service, and UI (the app renders `multiple-choice` and `fill-in-the-blank`; the other four types are deferred Phase 2). `a1-exercises-and-theory` completed the A1 content pass and added the informational coverage report (now canonical in `content-pipeline`). This change repeats the pass for **A2** — pure content production against the frozen format, no behavior change, so it carries **no spec deltas**.

A2 spans five themes: past tenses (a2-1), future/conditional/periphrases (a2-2), object pronouns & imperative (a2-3), comparison/adverbs/connectors (a2-4), and A2 constructions (a2-5); cards A2-01…A2-29. The existing A2 cards are the source of truth; the workbook (`Практическая_грамматика.pdf`, image-only) supplies extra examples.

## Goals / Non-Goals

**Goals:**
- Every A2 card/theme has a solid set of working exercises (`multiple-choice` + `fill-in-the-blank` only, so they run in the shipped app).
- A2 card theory is clearer and more example-rich for Russian speakers, without changing structure or frontmatter.
- A2 coverage reaches 29/29 (verified by the existing coverage report); all tests stay green.

**Non-Goals:**
- B1–C2 (each a separate per-level change).
- Authoring `matching` / `word-order` / `picture-matching` / `free-response` (engine/UI is Phase 2).
- Any app/Swift/UI/pipeline source change beyond the recompiled bundle.

## Decisions

### Same constraints as the A1 pass
Restrict authored types to `multiple-choice` + `fill-in-the-blank` (the only types the app renders), and keep theory rewrites identity-preserving: edit only the body, preserve the frontmatter block byte-for-byte and the callout/section style. **Why:** consistency with the shipped A1 pass; the catalog/SRS/theme-grouping key off frontmatter and ids, and the renderer keys off the callout headings. Verified centrally by `validate.py` + `swift test` (`CardBodyCorpusTests` parses every body; `ContentTests` resolves every exercise→card reference).

### Exercise ids use per-theme ranges
A2 exercises use `A2-EX-NN` with a disjoint hundreds-block per theme (a2-1 → 1xx, a2-2 → 2xx, …, a2-5 → 5xx) so parallel authoring can't collide and ids stay unique across the level.

### No spec deltas
The exercise format, model, checking, UI, and the coverage report already exist. This change asserts no new or modified requirements — it is content only. (Mirrors how `srs-engine` recorded "Modified Capabilities: None.")

## Risks / Trade-offs

- **Theory edits breaking rendering/references** → mitigated by `validate.py` (frontmatter, related, theme contiguity) + `swift test`; frontmatter left untouched by construction.
- **Spanish/answer inaccuracy** (A2 has trickier contrasts: indefinido vs imperfecto, ser vs estar, por vs para) → ground every exercise in the card it drills; ensure exactly one correct answer; use `multiple-choice` for accent- or contrast-discrimination items (fill-in-the-blank normalizes case/diacritics); self-review per theme.
- **Volume / partial completion** → scoped to A2 only; the coverage report makes remaining gaps explicit so work can span sessions.

## Migration Plan

1. Per A2 theme (`a2-1`…`a2-5`): read the cards (and workbook where helpful), revise that theme's card bodies, author its exercises; validate after each.
2. Recompile `content.json`; run `test_pipeline.py` and `swift test`; confirm 29/29 coverage.
3. Additive and reversible: revert restores prior bodies and removes the new exercise files; review state keys off ids, which are unchanged.

## Open Questions

- None. Same shape as the validated A1 pass.
