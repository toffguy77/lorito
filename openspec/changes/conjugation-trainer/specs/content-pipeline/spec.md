## ADDED Requirements

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
