## Context

Lorito's foundation (`bootstrap-foundation`) named `practice-exercises` as the sixth and final MVP change and modeled review state "so that later practice results can update it". The SRS already exists: `srs-engine` provides a pure SM-2 scheduler plus an apply-and-persist operation; `app-foundation` defines `CardReview`, `StudyEvent`, and the `UserDataStore` protocol (`upsertReview`, `appendEvent`). The content pipeline (`tools/*.py`, stdlib-only) compiles `content/<LEVEL>/<id>.md` cards into a single `content.json` the app embeds; `ContentLoader`/`ContentCatalog` expose them. The study UI is read-then-self-grade flashcards.

The source material (`Практическая_грамматика.pdf`) is an image-only scanned workbook: each grammar ТЕМА is followed by an УПРАЖНЕНИЯ page. Surveying pages across the book, the recurring exercise formats are: fill-the-gap incl. verb conjugation ("вставьте", "раскройте скобки"), multiple-choice ("выберите вариант"), text-pair matching ("соедините"), sentence assembly from words ("составьте предложение"), word↔picture matching, and translation / open questions ("переведите", "ответьте"). The PDF has no text layer (markitdown/pdftotext return only the `@espanolgram` watermark), so authoring reads pages by rendering to PNG (`pdftoppm`) and reading them visually.

Per direction, the **specs document the complete functionality** (all six exercise types) while **implementation is phased** — only `multiple-choice` and `fill-in-the-blank`, plus a pilot, ship in this change's first delivery.

## Goals / Non-Goals

**Goals:**
- A pure-`Domain` `Exercise` model + checking service that decides correctness for auto-checkable types and maps outcomes to SM-2 grades — fully unit-testable via `swift test`.
- An exercise content format (one file per exercise, sibling to cards) validated and compiled by the existing Python pipeline.
- Practice that feeds the **existing** per-card SRS (no new scheduler, no second schedule axis), via the existing `srs-engine` apply-and-persist operation, recording attempts and study events.
- An interactive exercise screen reusing DesignSystem components.
- Specs that fully describe all six exercise types so later deliveries need no spec changes.
- A working first slice: `multiple-choice` + `fill-in-the-blank` + pilot A1 noun exercises, end-to-end.

**Non-Goals:**
- Authoring exercises for all levels A1–C2 (separate follow-up change(s)).
- Rewriting/clarifying the theory card bodies (separate follow-up change).
- Implementing `matching`, `word-order`, `picture-matching`, `free-response` in this change's first delivery — they are **specified** but built in later deliveries (picture-matching also needs an image-asset pipeline).
- Any backend or new third-party dependency.

## Decisions

### Exercises are keyed to a card and feed that card's existing schedule
Each exercise carries a `card` reference. Submitting an answer produces an SM-2 grade applied to that card's existing `CardReview` through `srs-engine`'s apply-and-persist op. **Why:** the foundation explicitly designed review state to absorb practice results; reusing it means practice and reading reinforce one schedule, with zero new scheduling logic. *Alternative considered:* a separate per-exercise schedule — rejected as redundant scheduling surface and divergent state for the same grammar point.

### Outcome→grade mapping is fixed and minimal for v1
Auto-checkable: correct → Хорошо, incorrect → Опять. **Why:** the four-grade SM-2 contract already exists; a binary correct/incorrect maps cleanly onto pass/fail without inventing nuance. Self-assessed (`free-response`) defers to the user's own four-button grade, exactly like a flashcard. *Alternative:* map correctness to all four grades via response time/streaks — deferred (YAGNI) but the mapping lives in one pure function, so it can evolve without touching callers.

### Content format: one file per exercise, sibling to cards
`content/<LEVEL>/exercises/<id>.md` with YAML frontmatter + Markdown prompt/explanation, mirroring the card convention. **Why:** consistency with the existing pipeline (glob, parse, validate, compile), git-friendly, and reviewable per exercise. The compiler extends `content.json` with an `exercises` collection alongside `cards`. *Alternative:* embed exercises inside card files — rejected; it bloats card bodies and couples authoring of the two.

### Type-tagged model; auto-checkable vs self-assessed is intrinsic to the type
A single `Exercise` type with a `type` discriminator and type-specific payload (modeled as a Swift enum with associated values, decoded from the bundle). The checking service switches on type. **Why:** keeps one loadable model and one screen with per-type affordances; new types extend the enum and the validator without schema-wide churn.

### Normalized matching for typed answers
Case-, diacritic-, and surrounding-whitespace-insensitive comparison, with an `accept` alternatives list. Shared by `fill-in-the-blank` and `word-order`. **Why:** Spanish learners shouldn't fail on `á` vs `a` or casing; an explicit `accept` list covers legitimate variants. Translation/open-ended answers are too open to auto-grade reliably, hence `free-response` is self-assessed.

### Pipeline stays Python stdlib-only
Exercise validation/compilation extends `validate.py`/`compile.py`; `test_pipeline.py` gains coverage. **Why:** preserve the "no external deps" pipeline decision.

## Implementation phasing (within this change)

The specs cover all six types; this change's tasks deliver them in order:
1. **Phase 1 (this delivery):** format + pipeline (all type *validation* where cheap), `Exercise` model, checking service for `multiple-choice` + `fill-in-the-blank`, SRS/persistence integration, the exercise screen for those two types, and pilot A1 noun exercises. Ships and is testable end-to-end.
2. **Phase 2 (later deliveries / follow-up changes):** `matching`, `word-order`, `free-response`, then `picture-matching` (which adds an image-asset bundling step). Each reuses the already-specified contracts.

Tasks below mark Phase 1 vs later so the partial first delivery is explicit while the full plan is recorded.

## Risks / Trade-offs

- **Over-broad spec vs. partial build** → Phasing is explicit in tasks and design; Phase-1 acceptance only requires the two shipped types, so unbuilt types don't block the change. Validation for unbuilt types is added only where it's cheap and prevents bad authored content.
- **Picture-matching needs assets the app doesn't bundle yet** → fully specified but explicitly Phase 2; the image-asset pipeline is called out as its own task so it isn't smuggled into Phase 1.
- **Auto-grading false negatives** (a valid answer rejected) → mitigated by the `accept` alternatives list and normalization; `free-response` exists precisely for answers too open to auto-check.
- **Authoring throughput from an image-only PDF** → reading is via `pdftoppm` render + visual read; pilot scope is 1–2 themes, so this change isn't gated on bulk authoring (deferred to follow-up changes).
- **CloudKit schema growth** (new attempt record) → follows the existing flagged pattern; the new record is additive and behind `PersistenceConfig.cloudKitEnabled`, consistent with prior changes.

## Migration Plan

1. Land the format + pipeline + `content/schema.md` update with the pilot exercises; `tools/compile.py` regenerates `content.json`.
2. Land Domain model + checking service + tests; then Persistence (attempt record) and Features (exercise screen); wire the practice entry point into the study surface.
3. No data migration: the change is additive (new content collection, new attempt record). Rollback = revert the change and recompile the bundle without exercises; existing card review state is untouched.
4. Follow-up changes author exercises for all levels and (separately) clarify theory bodies; Phase-2 types extend this same change or a successor without spec changes.

## Open Questions

- Exact passing-grade default (Хорошо vs Легко) for auto-correct answers — start with Хорошо; revisit after dogfooding the pilot.
- Whether practice is surfaced as its own entry on Today or interleaved into the existing session — resolve during the Features task; the spec only requires an interactive screen and continue/completion flow.
