## Context

`practice-exercises` froze the exercise format and engine (app renders `multiple-choice` + `fill-in-the-blank`; the other four types are Phase 2). A1, A2, B1 content passes are complete and archived. This change repeats the pass for **B2** — pure content against the frozen format, no behavior change beyond recording B2's coverage in the `content-model` requirement.

B2 spans five themes: subjuntivo completion (b2-1), conditionals/hypotheticals (b2-2), complex subordination (b2-3), verb/voice/`se` (b2-4), lexis/word-formation/style (b2-5); cards B2-01…B2-25. The existing B2 cards are the source of truth.

## Goals / Non-Goals

**Goals:** every B2 card/theme has a solid set of working exercises (MC + fill only); clearer, example-rich B2 theory for Russian speakers; B2 coverage 25/25; all tests green.

**Non-Goals:** C1–C2 (separate per-level changes); the four Phase-2 exercise types; any app/Swift/UI/pipeline source change beyond the recompiled bundle.

## Decisions

Same constraints as A1/A2/B1: restrict authored types to `multiple-choice` + `fill-in-the-blank`; identity-preserving theory rewrites (edit only the body, preserve the frontmatter block byte-for-byte and the callout/section style). Exercise ids use per-theme hundreds blocks (`B2-EX-1xx`…`5xx`). B2 leans heavily on the subjuntivo and conditionals: mood/tense contrasts are authored as `multiple-choice`; conjugate-in-subjuntivo items as `fill-in-the-blank` with `accept` covering the `-ra`/`-se` variants; accent-sensitive items use `multiple-choice`. Lexical themes (idioms, register, word-formation) use `multiple-choice` for choice items and `fill-in-the-blank` for derivation/fixed-expression gaps.

## Risks / Trade-offs

- **Answer correctness at B2** (subjuntivo, conditionals, government) → ground every item in its card; exactly one correct answer; `accept` for legitimate `-ra`/`-se` variants; verified centrally by `validate.py` + `swift test`.
- **Theory edits breaking rendering/references** → frontmatter untouched by construction; central validation guards it.

## Migration Plan

Per B2 theme: revise the cards, author exercises, validate. Recompile `content.json`; run `test_pipeline.py` and `swift test`; confirm 25/25. Additive and reversible; ids unchanged.

## Open Questions

None — same shape as the validated A1/A2/B1 passes.
