## MODIFIED Requirements

### Requirement: Exercise frontmatter schema
Exercise frontmatter SHALL include the common fields: `id` (string, unique across all exercises), `level` (one of the six levels), `theme` (kebab-case string present in the level's theme registry), `card` (an existing card id of the same level), and `type` (one of `multiple-choice`, `fill-in-the-blank`, `matching`, `word-order`, `picture-matching`, `free-response`, `listen-choose`, `dictation`, `speak`). Type-specific fields SHALL be:

- `multiple-choice`: `options` (list of ≥2 strings) and `answer` (the exact correct option, which MUST appear in `options`).
- `fill-in-the-blank`: `answer` (expected string) and optional `accept` (list of additional accepted strings).
- `matching`: `pairs` (list of `{left, right}` objects, ≥2 pairs).
- `word-order`: `tokens` (list of strings) and `answer` (the target sentence); optional `accept` (additional accepted orderings). The multiset of `tokens` MUST be able to form `answer`.
- `picture-matching`: `options` (list of `{image, label}` objects, ≥2) where each `image` names an asset bundled with the content.
- `free-response`: `answer` (reference string) and optional `accept` (list of accepted strings); self-assessed, so no auto-correctness is derived.
- `listen-choose`: `audio` (Spanish text to be spoken, one line), `options` (list of ≥2 strings) and `answer` (MUST appear in `options`).
- `dictation`: `audio` (Spanish text to be spoken and typed back, one line, at most 120 characters) and optional `accept` (list of additional accepted strings).
- `speak`: `answer` (Spanish target phrase, one line, at most 80 characters) and optional `accept` (list of accepted strings).

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

#### Scenario: Listen-choose answer among options
- **WHEN** a `listen-choose` exercise declares an `answer` not present in its `options`
- **THEN** validation fails and reports the mismatch

#### Scenario: Overlong dictation rejected
- **WHEN** a `dictation` exercise's `audio` exceeds 120 characters
- **THEN** validation fails and names the exercise
