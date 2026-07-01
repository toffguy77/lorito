## Context

`practice-exercises` froze the exercise format and engine (app renders `multiple-choice` + `fill-in-the-blank`; the other four types are Phase 2). A1 and A2 content passes are complete and archived. This change repeats the pass for **B1** — pure content against the frozen format, no behavior change beyond recording B1's coverage in the `content-model` requirement.

B1 spans five themes: subjuntivo formation & triggers (b1-1), subjuntivo in subordinate clauses + imperfecto de subjuntivo (b1-2), deepened tenses (b1-3), conditionals/reported-speech/passive (b1-4), B1 constructions & lexis (b1-5); cards B1-01…B1-25. The existing B1 cards are the source of truth.

## Goals / Non-Goals

**Goals:** every B1 card/theme has a solid set of working exercises (MC + fill only); clearer, example-rich B1 theory for Russian speakers; B1 coverage 25/25; all tests green.

**Non-Goals:** B2–C2 (separate per-level changes); the four Phase-2 exercise types; any app/Swift/UI/pipeline source change beyond the recompiled bundle.

## Decisions

Same constraints as the A1/A2 passes: restrict authored types to `multiple-choice` + `fill-in-the-blank`; identity-preserving theory rewrites (edit only the body, preserve the frontmatter block byte-for-byte and the callout/section style). Exercise ids use per-theme hundreds blocks (`B1-EX-1xx`…`5xx`) so parallel authoring can't collide. B1 leans on subjuntivo, so indicativo-vs-subjuntivo contrasts are authored as `multiple-choice` and conjugate-in-subjuntivo items as `fill-in-the-blank`, with `accept` covering the `-ra`/`-se` imperfecto-de-subjuntivo variants. Accent-sensitive items use `multiple-choice` (the fill checker normalizes diacritics away).

## Risks / Trade-offs

- **Subjuntivo answer correctness** (trickier than A1/A2) → ground every item in its card; exactly one correct answer; `accept` for legitimate `-ra`/`-se` variants; verified centrally by `validate.py` + `swift test` (`CardBodyCorpusTests` parses every body, `ContentTests` resolves every exercise→card reference).
- **Theory edits breaking rendering/references** → frontmatter untouched by construction; central validation guards it.

## Migration Plan

Per B1 theme: revise the cards, author exercises, validate. Recompile `content.json`; run `test_pipeline.py` and `swift test`; confirm 25/25. Additive and reversible; ids unchanged so review state is unaffected.

## Open Questions

None — same shape as the validated A1/A2 passes.
