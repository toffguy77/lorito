# content-model Specification

## Purpose
TBD - created by archiving change bootstrap-foundation. Update Purpose after archive.
## Requirements
### Requirement: Card file format
Each study card SHALL be stored as a single UTF-8 Markdown file containing YAML frontmatter followed by a Markdown body. Files SHALL be located at `content/<LEVEL>/<id>.md`, where `<LEVEL>` is one of `A1`, `A2`, `B1`, `B2`, `C1`, `C2`.

#### Scenario: Valid card file
- **WHEN** a card file is parsed
- **THEN** it yields frontmatter fields and a non-empty Markdown body

#### Scenario: File location matches level
- **WHEN** a card declares `level: B1`
- **THEN** the file resides under `content/B1/`

### Requirement: Card frontmatter schema
Card frontmatter SHALL include the fields: `id` (string, unique, matching `^[A-C][12]-[0-9]{2}$`), `level` (one of the six levels), `theme` (kebab-case string), `order` (integer ≥ 1, unique within its level), `title` (non-empty string). Frontmatter MAY include `aliases` (list of strings), `related` (list of card ids), and `tags` (list of strings).

#### Scenario: Required fields present
- **WHEN** a card omits a required field
- **THEN** validation fails and names the missing field

#### Scenario: Id format enforced
- **WHEN** a card has `id: A1-7`
- **THEN** validation fails because the id does not match the two-digit pattern `A1-07`

### Requirement: Level taxonomy and inclusion
The model SHALL define exactly six ordered levels A1 < A2 < B1 < B2 < C1 < C2. Selecting a target level SHALL include that level and all lower levels.

#### Scenario: Lower levels included
- **WHEN** the target level is `B1`
- **THEN** the included levels are `A1`, `A2`, and `B1`

### Requirement: Theme grouping within a level
Each card SHALL belong to exactly one theme within its level. A theme SHALL group an ordered, contiguous set of cards. The set of valid themes per level SHALL be declared in a single registry.

#### Scenario: Theme declared in registry
- **WHEN** a card declares a `theme` not present in its level's theme registry
- **THEN** validation fails and names the unknown theme

### Requirement: Cross-card references resolve
Every id listed in a card's `related` SHALL refer to an existing card.

#### Scenario: Dangling reference
- **WHEN** a card lists `related: [A1-99]` and no `A1-99` card exists
- **THEN** validation fails and reports the unresolved reference

### Requirement: Documented schema
The repository SHALL contain `content/schema.md` describing every frontmatter field, the level/theme taxonomy, and the body conventions (callout sections Суть / Ключевые моменты / Ошибки / Полезно).

#### Scenario: Schema document exists
- **WHEN** a contributor opens `content/schema.md`
- **THEN** they find the full field list and body conventions

### Requirement: Exercise coverage of cards
Every card SHOULD have at least one practice exercise so learners can actively drill its grammar point, and a level is **fully covered** when every one of its cards is referenced by at least one exercise. Coverage is produced by the content-pipeline coverage report and improved level by level; an authored exercise's `card` MUST reference the card it drills. Fully covered levels: **A1, A2, B1, B2, C1, C2** (all levels).

#### Scenario: A fully covered level has an exercise for every card
- **WHEN** a level's content pass is complete
- **THEN** every card in that level is referenced by at least one exercise and the coverage report shows N/N for that level

#### Scenario: An exercise drills its referenced card
- **WHEN** an exercise exists
- **THEN** its `card` field resolves to a card of the same level and the exercise tests that card's grammar point


### Requirement: Exercise file format
Each practical exercise SHALL be stored as a single UTF-8 Markdown file containing YAML frontmatter followed by a Markdown body. Files SHALL be located at `content/<LEVEL>/exercises/<id>.md`, where `<LEVEL>` is one of `A1`, `A2`, `B1`, `B2`, `C1`, `C2`. The Markdown body SHALL hold the exercise prompt and an explanation shown after the answer is checked or revealed.

#### Scenario: Valid exercise file
- **WHEN** an exercise file is parsed
- **THEN** it yields frontmatter fields and a non-empty Markdown body

#### Scenario: File location matches level
- **WHEN** an exercise declares `level: A1`
- **THEN** the file resides under `content/A1/exercises/`

### Requirement: Exercise frontmatter schema
Exercise frontmatter SHALL include the common fields: `id` (string, unique across all exercises), `level` (one of the six levels), `theme` (kebab-case string present in the level's theme registry), `card` (an existing card id of the same level), and `type` (one of `multiple-choice`, `fill-in-the-blank`, `matching`, `word-order`, `picture-matching`, `free-response`). Type-specific fields SHALL be:

- `multiple-choice`: `options` (list of ≥2 strings) and `answer` (the exact correct option, which MUST appear in `options`).
- `fill-in-the-blank`: `answer` (expected string) and optional `accept` (list of additional accepted strings).
- `matching`: `pairs` (list of `{left, right}` objects, ≥2 pairs).
- `word-order`: `tokens` (list of strings) and `answer` (the target sentence); optional `accept` (additional accepted orderings). The multiset of `tokens` MUST be able to form `answer`.
- `picture-matching`: `options` (list of `{image, label}` objects, ≥2) where each `image` names an asset bundled with the content.
- `free-response`: `answer` (reference string) and optional `accept` (list of accepted strings); self-assessed, so no auto-correctness is derived.

#### Scenario: Required fields present
- **WHEN** an exercise omits a required field for its type
- **THEN** validation fails and names the missing field

#### Scenario: Multiple-choice answer is one of the options
- **WHEN** a `multiple-choice` exercise declares an `answer` not present in its `options`
- **THEN** validation fails and reports that the answer is not among the options

#### Scenario: Word-order tokens can form the answer
- **WHEN** a `word-order` exercise's `tokens` cannot be arranged into its `answer`
- **THEN** validation fails and reports the mismatch between tokens and answer

#### Scenario: Exercise card reference resolves
- **WHEN** an exercise declares `card: A1-99` and no `A1-99` card exists
- **THEN** validation fails and reports the unresolved card reference

#### Scenario: Unknown type rejected
- **WHEN** an exercise declares a `type` not in the supported set
- **THEN** validation fails and reports the unknown type

### Requirement: Documented exercise schema
The repository `content/schema.md` SHALL document the exercise file location, the common and type-specific frontmatter fields for every supported type, the auto-checkable vs self-assessed distinction, and the answer-matching (normalization) rules.

#### Scenario: Schema document covers exercises
- **WHEN** a contributor opens `content/schema.md`
- **THEN** they find the exercise file layout, every type's frontmatter fields, and how answers are matched
