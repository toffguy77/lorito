## ADDED Requirements

### Requirement: Variant markup validation
The validation command SHALL fail with a non-zero exit when a card has an unclosed or nested variant block, a block or inline alternative uses an unknown code, an inline alternative has fewer than two codes or repeats a code, or an exercise's `variants`/`only` fields use unknown codes or overrides that violate the exercise type's schema.

#### Scenario: Unclosed block
- **WHEN** a card opens `:::variant es` without a closing `:::`
- **THEN** validation exits non-zero and names the card

#### Scenario: Clean markup passes
- **WHEN** all variant markup is well-formed
- **THEN** validation exits zero

### Requirement: Voseo paradigm generation
The pipeline SHALL generate, with the Python standard library only, the `vos` present indicative of regular verbs by replacing the final `-r` of the infinitive with `-s` and accenting the preceding vowel (`hablar` → `hablás`, `comer` → `comés`, `vivir` → `vivís`), the `vos` affirmative imperative by dropping `-r` and accenting the final vowel (`hablá`), and SHALL copy the `tú` forms for other tenses unless a verb overrides them.

#### Scenario: Regular voseo present
- **WHEN** the `vos` present of `comer` is generated
- **THEN** it is `comés`

### Requirement: Variant data compiled into the bundle
The compile command SHALL keep variant markup in card bodies for the app parser, include exercise `variants` and `only` fields and `vos` forms in the bundle, and SHALL produce no bundle when variant validation fails.

#### Scenario: Bundle carries overrides
- **WHEN** compilation succeeds
- **THEN** exercises with variant overrides carry them in the bundle
