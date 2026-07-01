## ADDED Requirements

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
