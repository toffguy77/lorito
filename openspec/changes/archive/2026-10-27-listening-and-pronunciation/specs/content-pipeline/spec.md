## MODIFIED Requirements

### Requirement: Exercise integrity validation
The validation command SHALL fail (non-zero exit) if any exercise violates the content-model: duplicate exercise ids; unknown level or theme; an unresolved `card` reference; a `card` whose level differs from the exercise's level; an unknown `type`; a missing type-specific field; (for `multiple-choice` and `listen-choose`) an `answer` not present in `options`; (for `word-order`) `tokens` that cannot form the `answer`; (for `picture-matching`) an `image` asset absent from the content sources; or (for `listen-choose`, `dictation` and `speak`) an `audio` or `answer` value that is empty, spans more than one line, or exceeds its length limit.

#### Scenario: Validation catches an unresolved card reference
- **WHEN** an exercise references a `card` id that does not exist
- **THEN** the validation command exits non-zero and reports the unresolved card reference

#### Scenario: Validation catches a multiple-choice answer not in options
- **WHEN** a `multiple-choice` exercise's `answer` is not one of its `options`
- **THEN** the validation command exits non-zero and reports the mismatch

#### Scenario: Validation catches a missing picture-matching asset
- **WHEN** a `picture-matching` exercise references an image asset that is not present in the content sources
- **THEN** the validation command exits non-zero and reports the missing asset

#### Scenario: Validation catches a multi-line audio text
- **WHEN** a `dictation` exercise's `audio` spans two lines
- **THEN** the validation command exits non-zero and names the exercise

#### Scenario: Clean exercises pass
- **WHEN** all exercises conform to the exercise content-model
- **THEN** the validation command exits zero
