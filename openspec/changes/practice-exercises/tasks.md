# Tasks

The specs document **all six** exercise types. Implementation is **phased**:
Phase 1 ships `multiple-choice` + `fill-in-the-blank` + pilot content end-to-end.
Phase 2 tasks are specified now and built in later deliveries. Tasks tagged
`[Phase 2]` are out of scope for this change's first delivery.

## 1. Content format & schema docs

- [x] 1.1 Update `content/schema.md` with the exercise file layout (`content/<LEVEL>/exercises/<id>.md`), common frontmatter (`id`, `level`, `theme`, `card`, `type`), the per-type answer fields for all six types, the auto-checkable vs self-assessed distinction, and the normalization rules
- [x] 1.2 Decide and document the compiled `content.json` shape for exercises (an `exercises` collection alongside `cards`, carrying type-specific answer data and `card` reference)

## 2. Content pipeline (Python, stdlib-only)

- [x] 2.1 Write failing `tools/test_pipeline.py` cases: an exercise with all required common fields and valid type-specific fields validates clean
- [x] 2.2 Write failing tests: validation fails on duplicate exercise id, unknown level/theme, unresolved `card`, `card` of a different level, unknown `type`, and missing type-specific fields (named in the error)
- [x] 2.3 Write failing tests: `multiple-choice` `answer` not in `options` fails; `word-order` `tokens` that cannot form `answer` fails; `picture-matching` referencing a missing image asset fails
- [x] 2.4 Extend `tools/validate.py` to load and validate `content/<LEVEL>/exercises/*.md` for all six types until tests pass
- [x] 2.5 Extend `tools/compile.py` to include valid exercises in `content.json` (validation runs first; failure produces no bundle), and add tests asserting exercises appear in the compiled output and that invalid exercises block the bundle
- [x] 2.6 [Phase 2] Extend `tools/compile.py` to bundle image assets referenced by `picture-matching` exercises and validate their presence

## 3. Pilot content authoring

- [x] 3.1 From the source workbook (render pages with `pdftoppm`, read visually), author `multiple-choice` and `fill-in-the-blank` exercises for one A1 noun theme (gender), each referencing an existing card
- [x] 3.2 Author the same for a second A1 noun theme (number)
- [x] 3.3 Run `tools/compile.py` and confirm the pilot exercises validate and appear in `content.json`

## 4. Domain: Exercise model (pure Swift)

- [x] 4.1 Define an `Exercise` value type with a `type` discriminator (enum with associated values) covering all six types' payloads, decodable from the compiled bundle; no SwiftUI/SwiftData/CloudKit imports
- [x] 4.2 Write failing tests asserting each type's payload decodes from a representative bundle fragment and that an exercise exposes its `card` reference
- [x] 4.3 Implement decoding until tests pass; add a test asserting the Domain target imports none of SwiftUI/SwiftData/CloudKit

## 5. Domain: checking & grade mapping (TDD)

- [x] 5.1 Write failing tests: `multiple-choice` — choosing the correct option is correct; any other option is incorrect
- [x] 5.2 Write failing tests: `fill-in-the-blank` — exact match correct; case/diacritic/surrounding-whitespace differences still correct; an `accept` alternative is correct; a non-matching answer is incorrect
- [x] 5.3 Write failing tests: outcome→grade mapping — correct maps to the passing grade (Хорошо), incorrect maps to Опять; the mapping is a pure function (no I/O)
- [x] 5.4 Implement the checking service for `multiple-choice` + `fill-in-the-blank` and the pure normalization helper until tests pass
- [x] 5.5 [Phase 2] Write failing tests + implement checking for `matching` (all pairs correct), `word-order` (normalized order match incl. `accept`)
- [x] 5.6 [Phase 2] Define `free-response` handling (self-assessed: no auto-correctness; the user-chosen grade is the outcome) with tests
- [x] 5.7 [Phase 2] Write failing tests + implement checking for `picture-matching` (all labels matched)

## 6. SRS & persistence integration

- [x] 6.1 Write failing tests (against an in-memory user-data store double): submitting a correct auto-checkable answer applies the passing grade to the card's `CardReview` via the existing `srs-engine` apply-and-persist operation and appends a `StudyEvent`
- [x] 6.2 Write failing tests: submitting an incorrect answer applies Опять via the same operation and appends a `StudyEvent`; verify no new/separate schedule is created (the existing `CardReview` is the only review state touched)
- [x] 6.3 Define an exercise-attempt record and extend `UserDataStore` with append/read attempt methods (Domain protocol level); write tests for round-tripping attempts through the in-memory double
- [x] 6.4 Implement the submit-answer flow that checks the answer, records an attempt, and applies-and-persists the grade until tests pass
- [x] 6.5 Implement the SwiftData `@Model` attempt record + `SwiftDataUserDataStore` methods in Persistence; keep CloudKit behind the existing `PersistenceConfig.cloudKitEnabled` flag

## 7. Features: interactive exercise screen

- [x] 7.1 Build the exercise screen for `multiple-choice` (option selection) and `fill-in-the-blank` (text entry) reusing DesignSystem tokens/components; submit is unavailable until an answer is provided
- [x] 7.2 On submit, show correct/incorrect feedback with the correct answer and the explanation; provide a continue action that advances or reaches a completion state
- [x] 7.3 Wire a practice entry point into the study surface and load exercises for the relevant theme/cards from the catalog
- [x] 7.4 [Phase 2] Add input affordances + feedback for `matching`, `word-order`, `free-response` (reveal reference + four grade buttons), and `picture-matching`

## 8. Validation & wrap-up

- [x] 8.1 Run `cd Packages/LoritoKit && swift test` and confirm Domain/Persistence/Features suites are green
- [x] 8.2 Run `tools/validate.py` and `tools/test_pipeline.py` and confirm green
- [x] 8.3 Build the app target for the simulator and smoke-test the pilot practice flow end-to-end (answer → feedback → SRS update persists)
- [x] 8.4 Verify every scenario in `specs/practice-exercises/spec.md`, `specs/content-model/spec.md`, and `specs/content-pipeline/spec.md` is covered by a test or explicitly tagged `[Phase 2]`
- [x] 8.5 Run `openspec validate practice-exercises --strict` and fix issues until valid
