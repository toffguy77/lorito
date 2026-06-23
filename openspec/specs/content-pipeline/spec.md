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

