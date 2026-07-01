## Why

Lorito today is read-only flashcards: the user reads a card and self-grades it (Опять / Трудно / Хорошо / Легко). The `bootstrap-foundation` change explicitly named `practice-exercises` as the sixth and final MVP change, and deliberately modeled review state "so that later practice results can update it" (`app-foundation`). This change delivers that capability: short, auto-checkable practical exercises that turn passive recall into active recall and feed their result back into the existing SM-2 schedule for the associated card.

Active-recall drilling (fill a blank, pick the right article/form) is the missing half of effective spaced repetition. The source workbook (`Практическая_грамматика.pdf`) already pairs each grammar topic with an exercise page, giving us authored, level-appropriate material to adapt.

## What Changes

- Introduce an **exercise content format**: exercises authored one-file-per-unit under `content/<LEVEL>/exercises/<id>.md`, with YAML frontmatter (`id`, `level`, `theme`, `card` reference, `type`, plus type-specific answer fields) and a Markdown prompt/explanation body. Document it in `content/schema.md`.
- Support **two auto-checkable, text-only exercise types** for v1:
  - **multiple-choice** — a prompt and a list of options with exactly one correct option;
  - **fill-in-the-blank** — a prompt with a gap; the typed answer is compared to the expected answer(s) by a **normalized** match (case-, diacritic-, and surrounding-whitespace-insensitive), with optional accepted alternatives.
  - Picture-matching is **explicitly deferred** (needs bundled image assets) to a later change.
- Extend the **content pipeline** (`validate.py`, `compile.py`) to validate exercises against the format and compile them into the embedded content bundle alongside cards.
- Add a pure-`Domain` **`Exercise` model** and an **exercise-checking service** that, given an exercise and a user's answer, decides correct/incorrect and maps that outcome to an SM-2 **grade** for the exercise's associated card.
- **Integrate with the existing SRS**: a correct/incorrect answer updates the associated card's existing `CardReview` via the already-defined `srs-engine` apply-and-persist operation, and records a study event. No new scheduler and no new scheduling axis are introduced — practice feeds the same per-card schedule.
- Persist **exercise attempts** through the existing user-data store (SwiftData record; CloudKit behind the existing flag).
- Add an **interactive exercise screen** in the study surface: present prompt → user selects/types an answer → submit → immediate correct/incorrect feedback with the explanation → continue.
- Ship **pilot content**: real exercises for one or two already-authored A1 noun themes (gender / number) so the format, pipeline, engine, and UI are exercised end-to-end.

## Capabilities

### New Capabilities
- `practice-exercises`: The exercise domain model and its two v1 types (multiple-choice, fill-in-the-blank with normalized answer matching); the checking service that decides correctness and maps it to an SM-2 grade for the associated card; the recording of an attempt and the application of that grade to the card's existing `CardReview` through `srs-engine` (referenced, not redefined); and the interactive exercise screen (prompt → answer → checked feedback with explanation → continue).

### Modified Capabilities
- `content-model`: Adds the exercise file format and frontmatter schema (a new authored content type living under `content/<LEVEL>/exercises/`), and extends the documented schema. Card requirements are unchanged.
- `content-pipeline`: Adds validation and bundle compilation of exercises (integrity rules for exercise frontmatter, resolution of each exercise's `card`/`theme` references, inclusion in the compiled bundle).

## Impact

- **Content (added)**: `content/<LEVEL>/exercises/<id>.md` files; pilot exercises for A1 noun themes; updated `content/schema.md`.
- **Pipeline (modified)**: `tools/validate.py` and `tools/compile.py` learn the exercise type; `tools/test_pipeline.py` gains coverage. Stays Python stdlib-only.
- **Domain (added)**: an `Exercise` value type and an exercise-checking service (pure Swift, no SwiftUI/SwiftData/CloudKit), unit-tested via `swift test`. Reuses the existing `Grade`/`GradingService` and `ReviewState`.
- **Content loading (modified)**: `ContentLoader`/`ContentCatalog` expose exercises from the bundle.
- **Persistence (added)**: a SwiftData attempt record and `UserDataStore` methods to append/read attempts; reuses `upsertReview`/`appendEvent`. CloudKit behind the existing `PersistenceConfig.cloudKitEnabled` flag.
- **Features (added)**: an interactive exercise screen reusing DesignSystem tokens/components; entry point into practice from the study surface.
- **Consumed, not modified**: `srs-engine` (apply-and-persist a grade), `app-foundation` (`CardReview`, `StudyEvent`, store), `design-system` (grade/feedback components).
- **No new third-party dependencies; no backend.**
- **Out of scope (follow-up changes)**: authoring exercises for all levels A1–C2; rewriting/clarifying theory card bodies; picture-matching exercises.
