## ADDED Requirements

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
