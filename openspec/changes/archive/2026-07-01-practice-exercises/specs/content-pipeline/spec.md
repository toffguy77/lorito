## ADDED Requirements

### Requirement: Exercise integrity validation
The validation command SHALL fail (non-zero exit) if any exercise violates the content-model: duplicate exercise ids; unknown level or theme; an unresolved `card` reference; a `card` whose level differs from the exercise's level; an unknown `type`; a missing type-specific field; (for `multiple-choice`) an `answer` not present in `options`; (for `word-order`) `tokens` that cannot form the `answer`; or (for `picture-matching`) an `image` asset absent from the content sources.

#### Scenario: Validation catches an unresolved card reference
- **WHEN** an exercise references a `card` id that does not exist
- **THEN** the validation command exits non-zero and reports the unresolved card reference

#### Scenario: Validation catches a multiple-choice answer not in options
- **WHEN** a `multiple-choice` exercise's `answer` is not one of its `options`
- **THEN** the validation command exits non-zero and reports the mismatch

#### Scenario: Validation catches a missing picture-matching asset
- **WHEN** a `picture-matching` exercise references an image asset that is not present in the content sources
- **THEN** the validation command exits non-zero and reports the missing asset

#### Scenario: Clean exercises pass
- **WHEN** all exercises conform to the exercise content-model
- **THEN** the validation command exits zero

### Requirement: Exercises compiled into the bundle
The compilation command SHALL include all valid exercises in the single bundled content artifact embedded by the app, alongside cards, carrying each exercise's type, prompt, explanation, type-specific answer data, and associated card id. Image assets referenced by `picture-matching` exercises SHALL be bundled so the app can render them. Compilation SHALL run exercise validation first and SHALL fail (producing no bundle) if validation fails.

#### Scenario: Build includes exercises
- **WHEN** compilation succeeds
- **THEN** the bundled content artifact contains every valid exercise with its type, prompt, answer data, and associated card id

#### Scenario: Invalid exercise blocks the bundle
- **WHEN** exercise validation fails during compilation
- **THEN** no bundle is produced and the command exits non-zero
