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

### Requirement: Documented exercise schema
The repository `content/schema.md` SHALL document the exercise file location, the common and type-specific frontmatter fields for every supported type, the auto-checkable vs self-assessed distinction, and the answer-matching (normalization) rules.

#### Scenario: Schema document covers exercises
- **WHEN** a contributor opens `content/schema.md`
- **THEN** they find the exercise file layout, every type's frontmatter fields, and how answers are matched

### Requirement: Exercise-type variety
Where the material suits it, a level's exercise set SHALL include variety beyond `multiple-choice` / `fill-in-the-blank` — namely the auto-checkable `matching` and `word-order` types and the self-assessed `free-response` type — rather than only single-form drills. Each such exercise MUST conform to the exercise frontmatter schema for its type and MUST reference an existing card of the same level. `picture-matching` variety is **enabled** where suitable vocabulary and bundled image assets exist (its image assets are compiled into the content bundle and MUST resolve at runtime via the app's resource bundle).

#### Scenario: A level offers more than one interaction mode
- **WHEN** a level's exercises are inspected after its content passes
- **THEN** they include, beyond multiple-choice / fill-in-the-blank, at least the `matching`, `word-order`, and `free-response` types across its themes

#### Scenario: Each new-type exercise remains well-formed
- **WHEN** a `matching`, `word-order`, or `free-response` exercise is added
- **THEN** it conforms to the exercise frontmatter schema for its type and references an existing card of the same level

#### Scenario: Picture-matching assets resolve at runtime
- **WHEN** a `picture-matching` exercise's image is referenced by the app
- **THEN** the bundled asset resolves from the app's resource bundle and renders

### Requirement: Optional recall prompt on cards
A card MAY declare a `recall` field in its front matter: a single-line Markdown string of at most 200 characters that poses the question the card answers (e.g. `recall: "**¿el или la?** *problema, mano, canción, agua*"`). The compiled bundle SHALL carry the field when present, and the `Card` domain type SHALL expose it as an optional value. Cards without the field SHALL remain valid.

#### Scenario: Card with recall prompt
- **WHEN** a card declares `recall` in its front matter and the content is compiled
- **THEN** the loaded `Card` exposes that prompt text

#### Scenario: Card without recall prompt
- **WHEN** a card has no `recall` field
- **THEN** the card loads successfully and its recall prompt is absent

### Requirement: Conjugation tenses registry
The content SHALL include `content/conjugation/tenses.json` listing each drillable tense or mood with: a unique kebab-case `id`, Spanish name `es`, Russian name `ru`, `mood`, `level`, `order`, and `card` — the id of an existing card of that level that teaches it.

#### Scenario: Tense maps to its card
- **WHEN** the tense `presente` declares `card: A1-19`
- **THEN** `A1-19` exists and has level `A1`

#### Scenario: Unknown card rejected
- **WHEN** a tense declares a card id that does not exist
- **THEN** validation fails and names the tense

### Requirement: Verb files
Each drillable verb SHALL be stored as `content/conjugation/verbs/<infinitive>.json` with: `infinitive`, unique positive integer `rank` (frequency order), Russian translation `ru`, `model` (`ar`, `er`, `ir` or `irregular`), optional `reflexive`, and optional `forms` mapping a tense id to six forms in the order yo, tú, él/ella/usted, nosotros, vosotros, ellos/ustedes. A verb with model `irregular` SHALL list `forms` for every registered tense.

#### Scenario: Regular verb needs no forms
- **WHEN** `hablar.json` declares `model: ar` and no `forms`
- **THEN** the verb is valid and its paradigms are generated

#### Scenario: Irregular verb must be complete
- **WHEN** `ser.json` declares `model: irregular` but omits a registered tense
- **THEN** validation fails and names the verb and the missing tense

### Requirement: Documented conjugation schema
`content/schema.md` SHALL document the conjugation directory, the tenses registry fields, the verb file fields, the person order, and how generated and overriding forms combine.

#### Scenario: Schema covers conjugation
- **WHEN** a contributor opens `content/schema.md`
- **THEN** they find the conjugation file layout, all fields and the person order

### Requirement: Vocabulary deck registry
The content SHALL include `content/vocabulary/decks.json` listing each deck with a unique kebab-case `id`, `level`, Russian `title_ru` and `order` unique within its level.

#### Scenario: Deck order unique per level
- **WHEN** two A1 decks declare the same `order`
- **THEN** validation fails and names both decks

### Requirement: Word files
Each deck SHALL have `content/vocabulary/<deck-id>.json`, a list of words with: `id` (lemma slug unique across all decks), `es`, `pos`, `ru`, `example_es`, `example_ru`, positive `rank`, optional `plural` and `forms`; nouns SHALL also declare `article` (`el`, `la`, `los`, `las`) and `gender` (`m`, `f`, `mf`).

#### Scenario: Noun without article rejected
- **WHEN** a word with `pos: noun` omits `article`
- **THEN** validation fails and names the word

#### Scenario: Duplicate word id rejected
- **WHEN** two decks contain a word with the same `id`
- **THEN** validation fails and names both decks

### Requirement: Vocabulary dataset licence
`content/vocabulary/` SHALL contain a `LICENSE` file stating that the vocabulary dataset is licensed under CC BY-SA 4.0 and derived from FrequencyWords; the dataset SHALL be kept in that directory, separate from cards and exercises.

#### Scenario: Licence file present
- **WHEN** the vocabulary folder is inspected
- **THEN** it contains a CC BY-SA 4.0 `LICENSE` naming FrequencyWords as the source

### Requirement: Documented vocabulary schema
`content/schema.md` SHALL document the vocabulary layout, deck and word fields, allowed values, the lookup role of `forms`, and the dataset licence.

#### Scenario: Schema covers vocabulary
- **WHEN** a contributor opens `content/schema.md`
- **THEN** they find the deck registry and word fields with allowed values

### Requirement: Card variant markup
Card bodies MAY contain variant blocks — a line `:::variant` followed by one or more codes `es`, `am`, `rio`, the block content, and a closing line `:::` — and inline alternatives `{es: … | am: … | rio: …}` with at least two codes. The parser SHALL treat content outside markup as applying to all variants and SHALL treat braces not starting with a known `code:` prefix as plain text.

#### Scenario: Valid block
- **WHEN** a card contains a `:::variant am rio` block closed by `:::`
- **THEN** the card is valid and the block applies to Latin America and Rioplatense

#### Scenario: Unknown code
- **WHEN** a card contains `{es: coche | mx: carro}`
- **THEN** validation fails and names the card and the unknown code

#### Scenario: Plain braces stay text
- **WHEN** a card contains `{1, 2, 3}`
- **THEN** it is rendered as text and validation passes

### Requirement: Exercise variant fields
Exercises MAY declare `variants`, a map from `am` or `rio` to overrides of `answer`, `accept` and `options`, and `only`, a non-empty list of codes the exercise applies to; when present, these fields SHALL be validated against the exercise type's schema.

#### Scenario: Override follows the type schema
- **WHEN** a `multiple-choice` exercise's `am` override sets an `answer` not in its `options`
- **THEN** validation fails and names the exercise

### Requirement: Voseo forms in conjugation content
Verb files MAY declare `vos` forms per tense; for regular verbs without them the compiled paradigms SHALL contain a `vos` person — present indicative and affirmative imperative generated by the voseo rule, other tenses equal to `tú`.

#### Scenario: Override for ser
- **WHEN** `ser.json` declares `vos: sos` for `presente`
- **THEN** the compiled paradigm uses `sos`

### Requirement: Documented variant schema
`content/schema.md` SHALL document the variant codes, the card block and inline markup (and why `[[…]]` is not used), the exercise `variants` and `only` fields, and `vos` forms in verb files.

#### Scenario: Schema covers variants
- **WHEN** a contributor opens `content/schema.md`
- **THEN** they find the variant markup and fields with examples

