# content-pipeline Specification

## Purpose
TBD - created by archiving change bootstrap-foundation. Update Purpose after archive.
## Requirements
### Requirement: Seed migration from vault
The pipeline SHALL provide a migration step that converts the source Obsidian notes into repository card files conforming to the content-model. The step SHALL strip Obsidian-specific syntax (Dataview blocks, `up:` backlink frontmatter, backlink query blocks) and preserve the instructional body (headings, tables, callouts, examples).

#### Scenario: Convert a vault note
- **WHEN** the migration runs on a vault note containing a Dataview block
- **THEN** the produced card file contains the body without the Dataview block and with valid frontmatter

#### Scenario: All source cards migrated
- **WHEN** the migration completes
- **THEN** every source note has a corresponding card file under `content/<LEVEL>/`

### Requirement: Theme assignment
The pipeline SHALL assign each card a `theme` value and maintain the per-level theme registry. Theme assignment SHALL preserve card `order` so that themes group contiguous cards.

#### Scenario: Cards grouped into themes
- **WHEN** theme assignment runs for a level
- **THEN** every card in that level has a theme present in the level's registry, and themes cover the cards without gaps in `order`

### Requirement: Enrichment step
The pipeline SHALL provide an enrichment step that expands a card's body using a consistent template (fuller explanations, more examples, common-mistake notes) while leaving frontmatter `id`, `level`, `order` unchanged. Enrichment output SHALL be reviewable before it is committed.

#### Scenario: Enrichment preserves identity
- **WHEN** a card is enriched
- **THEN** its `id`, `level`, and `order` are unchanged and its body is longer or equal

### Requirement: Integrity validation
The pipeline SHALL provide a validation command that fails (non-zero exit) if any card violates the content-model: duplicate ids, duplicate `order` within a level, unknown level or theme, unresolved `related` references, or missing required fields.

#### Scenario: Validation catches duplicates
- **WHEN** two cards share the same `id`
- **THEN** the validation command exits non-zero and reports the duplicate id

#### Scenario: Clean content passes
- **WHEN** all cards conform to the content-model
- **THEN** the validation command exits zero

### Requirement: Bundle compilation
The pipeline SHALL compile all cards into a single bundled content artifact that the app embeds at build time. Compilation SHALL run validation first and SHALL fail if validation fails.

#### Scenario: Build produces a bundle
- **WHEN** compilation succeeds
- **THEN** a bundled content artifact is written to the app resources and contains every valid card

#### Scenario: Invalid content blocks the bundle
- **WHEN** validation fails during compilation
- **THEN** no bundle is produced and the command exits non-zero

### Requirement: Exercise coverage report
The pipeline SHALL provide an **informational** coverage report that lists, for a level (or all levels), which cards and themes have no practice exercises. The report SHALL NOT change the pass/fail outcome of validation or compilation — it never blocks a build and always exits zero.

#### Scenario: Report lists cards without exercises
- **WHEN** the coverage report runs over content where some cards have exercises and others do not
- **THEN** it lists the cards (and themes) that have no exercises and reports the covered/total counts

#### Scenario: Report is non-failing
- **WHEN** the coverage report runs over content where some cards have no exercises
- **THEN** the command exits zero and neither `validate` nor `compile` is affected by the missing coverage


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
