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

### Requirement: Recall prompt validation
The content validation step SHALL accept the optional `recall` card field and SHALL fail with a non-zero exit when a `recall` value is not a string, is empty after trimming, spans more than one line, or exceeds 200 characters. The compile step SHALL write `recall` into the compiled bundle only for cards that declare it.

#### Scenario: Valid recall passes
- **WHEN** a card declares a one-line `recall` of 60 characters
- **THEN** validation passes and the compiled bundle contains the prompt for that card

#### Scenario: Overlong recall fails
- **WHEN** a card declares a `recall` longer than 200 characters
- **THEN** validation fails with a message naming the card id

#### Scenario: Missing recall is fine
- **WHEN** no card declares `recall`
- **THEN** validation passes and the compiled bundle has no `recall` keys

### Requirement: Regular paradigm generation
The pipeline SHALL generate, with the Python standard library only, the six forms of every registered tense for verbs of model `ar`, `er` and `ir`, and SHALL let a verb's explicit `forms` for a tense replace the generated forms for that tense.

#### Scenario: Generated present of hablar
- **WHEN** the paradigm of `hablar` in `presente` is generated
- **THEN** it is `hablo, hablas, habla, hablamos, habláis, hablan`

#### Scenario: Override wins
- **WHEN** `buscar.json` lists explicit `forms` for `preterito-indefinido`
- **THEN** the compiled paradigm for that tense equals the listed forms

### Requirement: Conjugation integrity validation
The validation command SHALL fail with a non-zero exit when: a tense id is duplicated or maps to a missing card or a card of another level; a verb file name differs from its `infinitive`; a `rank` is duplicated or not positive; a `model` is unknown; a `forms` entry names an unknown tense or does not have exactly six non-empty strings; or an `irregular` verb lacks a registered tense.

#### Scenario: Wrong number of forms
- **WHEN** a verb lists five forms for a tense
- **THEN** validation exits non-zero and names the verb and tense

#### Scenario: Clean conjugation content passes
- **WHEN** all tenses and verbs conform
- **THEN** validation exits zero

### Requirement: Paradigms compiled into the bundle
The compile command SHALL write the tenses registry and every verb's complete paradigms (generated or overridden) into the bundled content artifact, and SHALL produce no bundle when conjugation validation fails.

#### Scenario: Bundle carries paradigms
- **WHEN** compilation succeeds
- **THEN** the bundle contains each verb with six forms for every registered tense

#### Scenario: Invalid verb blocks the bundle
- **WHEN** conjugation validation fails
- **THEN** compilation exits non-zero and writes no bundle

