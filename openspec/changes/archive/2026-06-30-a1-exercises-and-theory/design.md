## Context

`practice-exercises` froze the exercise format (`content/<LEVEL>/exercises/<id>.md`, JSON-valued frontmatter), the Domain model, the checking service, and the interactive UI — but the app today renders only `multiple-choice` and `fill-in-the-blank`; the other four types are specified-but-deferred (Phase 2). The A1 pilot authored exercises for two themes (`A1-EX-01`…`A1-EX-10`, cards A1-07/A1-08).

This change is the first **per-level content pass**. The user chose: one change per level (A1 first), each covering **both** exercises and theory clarification. The source workbook (`Практическая_грамматика.pdf`) is image-only (no text layer); it is read by rendering pages with `pdftoppm` and viewing them. The existing A1 cards are the source of truth for the curriculum; the workbook supplies exercise inspiration and extra examples.

## Goals / Non-Goals

**Goals:**
- Every A1 card/theme has a solid set of working exercises (`multiple-choice` + `fill-in-the-blank` only, so they run in the shipped app).
- A1 card theory is clearer and more example-rich for Russian speakers, without changing structure or frontmatter.
- A visible, non-blocking coverage signal so per-level progress (and what's left) is obvious.
- Bundle recompiled; all existing tests stay green.

**Non-Goals:**
- A2–C2 (each a separate per-level change).
- Authoring `matching` / `word-order` / `picture-matching` / `free-response` (their engine/UI is Phase 2 of `practice-exercises`).
- Any app/Swift/UI change beyond the pipeline report and the recompiled bundle.
- Changing the exercise format or the SRS mapping.

## Decisions

### Restrict authored types to what the app renders
Only `multiple-choice` and `fill-in-the-blank` are authored. **Why:** authoring `matching`/`word-order`/etc. now would create content the app cannot present (their UI is deferred), i.e. dead content and a misleading coverage signal. When Phase 2 lands, later passes (or a revisit) can enrich types. The validator still accepts all six, so nothing breaks if a future type appears.

### Theory rewrite is identity-preserving
Bodies are revised in place; frontmatter (`id`, `level`, `theme`, `order`, `title`, `related`) and the four callout sections stay. **Why:** the catalog, SRS, theme grouping, and cross-references key off frontmatter and ids; the design-system renderer keys off the callout headings. Mirrors the existing `content-pipeline` "enrichment preserves identity" requirement (id/level/order unchanged, body longer-or-equal). Card-body parser tests (`CardBodyCorpusTests`) guard that every bundled body still parses with valid callouts/tables.

### Coverage report is informational, not a gate
A `--coverage` mode (or function) in the pipeline lists cards/themes without exercises and prints covered/total; it always exits zero and is independent of `validate`/`compile`. **Why:** mid-authoring, most themes legitimately lack exercises; a failing gate would block every compile until the whole level is done. The report guides work; it doesn't police it. Lives next to the existing pipeline, stdlib-only.

### Exercise ids continue the level scheme
New A1 exercises extend `A1-EX-NN` (after the pilot's `A1-EX-10`), unique across exercises. Each `card` references an existing A1 card of the same level (enforced by the existing validator).

## Risks / Trade-offs

- **Theory edits silently breaking rendering or references** → mitigated by `validate.py` (frontmatter, related, theme contiguity) + `swift test` (`CardBodyCorpusTests` parses every bundled body; `ContentTests` checks references resolve). Frontmatter is left untouched by construction.
- **Spanish/answer inaccuracy in authored exercises** → ground every exercise in the card it drills; rely on normalized matching + `accept` for legitimate variants; keep prompts unambiguous (single correct answer). Self-review each theme's answers.
- **Volume / partial completion** → the change is scoped to A1 only; the coverage report makes remaining gaps explicit so the change can be applied across sessions without losing track. Per-theme tasks bound each work chunk.
- **Authoring throughput from an image-only PDF** → `pdftoppm` render + visual read per theme; the cards (readable as text) carry the actual rules, so exercises don't depend on flawless OCR.

## Migration Plan

1. Add the coverage report + its test to the pipeline (no content yet) — green tests, report shows the current near-empty A1 coverage.
2. Per A1 theme (`a1-1`…`a1-5`): read the workbook theory+exercise pages, revise that theme's card bodies, author its exercises; run `validate.py` after each theme.
3. Recompile `content.json`; run `test_pipeline.py` and `swift test`.
4. Additive and reversible: revert restores prior bodies and removes the new exercise files; no data migration (review state keys off ids, which are unchanged).

## Open Questions

- Exact per-card exercise target (3–6) — treat as guidance, not a hard rule; the coverage report tracks presence, not count. Revisit if some cards are too thin to support 3 good items.
