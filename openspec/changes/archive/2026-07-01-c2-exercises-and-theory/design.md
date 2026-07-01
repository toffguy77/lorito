## Context

`practice-exercises` froze the exercise format and engine (app renders `multiple-choice` + `fill-in-the-blank`; the other four types are Phase 2). A1–C1 content passes are complete and archived. This change repeats the pass for **C2**, the final level — pure content against the frozen format, no behavior change beyond recording C2's coverage in the `content-model` requirement. After it, all six levels are fully covered.

C2 spans five themes: residual grammar/syntax subtleties (c2-1), high-level lexis (c2-2), phraseology & imagery mastery (c2-3), rhetoric/style/genres (c2-4), sociolinguistics/pragmatics/mediation (c2-5); cards C2-01…C2-25. The existing C2 cards are the source of truth.

## Goals / Non-Goals

**Goals:** every C2 card/theme has a solid set of working exercises (MC + fill only); clearer, example-rich C2 theory for Russian speakers; C2 coverage 25/25 and all six levels covered; all tests green.

**Non-Goals:** the four Phase-2 exercise types; any app/Swift/UI/pipeline source change beyond the recompiled bundle.

## Decisions

Same constraints as A1–C1: restrict authored types to `multiple-choice` + `fill-in-the-blank`; identity-preserving theory rewrites (edit only the body, preserve the frontmatter block byte-for-byte and the callout/section style). Exercise ids use per-theme hundreds blocks (`C2-EX-1xx`…`5xx`).

**C2 is the most stylistic/literary level**, so auto-checked items are constrained to single unambiguous, rule-based answers: RAE orthography/punctuation rules, identify-the-rhetorical-figure, correct specialized/technical term, complete a fixed locución culta/refrán, name a dialectal feature/region, or name a pragmatic phenomenon. Open interpretive judgement is avoided — those nuances are better served by the deferred `free-response` (self-assessed) type. Accent/punctuation-sensitive items use `multiple-choice`.

## Risks / Trade-offs

- **Debatable C2 answers** → restrict to rule-based, single-answer items; ground each in its card; central `validate.py` + `swift test` guard structure and references; genuinely open items deferred to the future `free-response` type.
- **Theory edits breaking rendering/references** → frontmatter untouched by construction; central validation guards it.

## Migration Plan

Per C2 theme: revise the cards, author exercises, validate. Recompile `content.json`; run `test_pipeline.py` and `swift test`; confirm 25/25 and full A1–C2 coverage. Additive and reversible; ids unchanged.

## Open Questions

- The lexical/stylistic C1–C2 cards would benefit from the deferred `free-response` (self-assessed) exercise type; revisit when Phase 2 of `practice-exercises` ships.
