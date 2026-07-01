## Context

`practice-exercises` froze the exercise format and engine (app renders `multiple-choice` + `fill-in-the-blank`; the other four types are Phase 2). A1–B2 content passes are complete and archived. This change repeats the pass for **C1** — pure content against the frozen format, no behavior change beyond recording C1's coverage in the `content-model` requirement.

C1 spans five themes: verb-system/mood subtleties (c1-1), advanced syntax (c1-2), advanced lexis & word-formation (c1-3), idiomatics/variation/register (c1-4), discourse/pragmatics/style (c1-5); cards C1-01…C1-25. The existing C1 cards are the source of truth.

## Goals / Non-Goals

**Goals:** every C1 card/theme has a solid set of working exercises (MC + fill only); clearer, example-rich C1 theory for Russian speakers; C1 coverage 25/25; all tests green.

**Non-Goals:** C2 (a separate per-level change); the four Phase-2 exercise types; any app/Swift/UI/pipeline source change beyond the recompiled bundle.

## Decisions

Same constraints as A1–B2: restrict authored types to `multiple-choice` + `fill-in-the-blank`; identity-preserving theory rewrites (edit only the body, preserve the frontmatter block byte-for-byte and the callout/section style). Exercise ids use per-theme hundreds blocks (`C1-EX-1xx`…`5xx`).

**C1 is advanced and partly lexical/stylistic, where a "correct answer" can be debatable.** To keep auto-checked items fair, each exercise is constrained to a single unambiguous, rule-based answer: queísmo/dequeísmo (que vs de que), collocations (which verb collocates), false friends (correct meaning), connectors (which logical relation), refranes (complete the fixed proverb), and connector-governed mood. Open stylistic judgement calls are avoided (those would suit the deferred `free-response` type). Accent-sensitive items use `multiple-choice`; `-ra`/`-se` subjuntivo variants use `accept`.

## Risks / Trade-offs

- **Debatable C1 answers** → restrict to rule-based, single-answer items; ground each in its card; central `validate.py` + `swift test` guard structure and references. Genuinely open items are deferred to the future `free-response` type rather than forced into auto-checking.
- **Theory edits breaking rendering/references** → frontmatter untouched by construction; central validation guards it.

## Migration Plan

Per C1 theme: revise the cards, author exercises, validate. Recompile `content.json`; run `test_pipeline.py` and `swift test`; confirm 25/25. Additive and reversible; ids unchanged.

## Open Questions

- Some C1 stylistic/register nuances are better drilled with the deferred `free-response` (self-assessed) type; revisit those cards when Phase 2 of `practice-exercises` ships.
