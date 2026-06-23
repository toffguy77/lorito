## ADDED Requirements

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
