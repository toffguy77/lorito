# regional-variants Specification

## Purpose
TBD - created by archiving change regional-variants. Update Purpose after archive.
## Requirements
### Requirement: Rioplatense variant value
The `spanishVariant` setting owned by `spanish-audio` SHALL gain the value «Риоплатский» (`rioplatense`) next to «Испания» (`spain`, default) and «Латинская Америка» (`latinAmerica`). No other variant setting SHALL exist; the setting SHALL drive cards, exercises, drills and audio.

#### Scenario: Single setting
- **WHEN** the learner switches to «Риоплатский» in Settings
- **THEN** cards, exercises, drills and audio use Rioplatense from then on

#### Scenario: Unknown value from a newer version
- **WHEN** an app version without Rioplatense reads the value `rioplatense`
- **THEN** it behaves as `spain`

### Requirement: Variant prompt after the first session
After the learner's first completed study session the Today screen SHALL show a one-time prompt to choose the variant; dismissing it SHALL keep the current value. The variant SHALL NOT be asked during onboarding and SHALL always be changeable in Settings.

#### Scenario: Prompt once
- **WHEN** the learner completes their first session and returns to Today
- **THEN** the variant prompt is shown, and it is not shown again after a choice or dismissal

#### Scenario: Not in onboarding
- **WHEN** a new learner goes through onboarding
- **THEN** no variant question is asked

### Requirement: Variant-aware card rendering
Card bodies SHALL render the block and inline form of the learner's variant in place and SHALL show other variants' blocks as labelled notes («В Испании: …», «В Латинской Америке: …», «В Аргентине и Уругвае: …»). Inline alternatives SHALL be Spanish spans whose «Варианты» context-menu action lists every form, and a missing form SHALL fall back to the Spain form.

#### Scenario: Inline alternative
- **WHEN** a card contains `{es: coche | am: carro | rio: auto}` and the variant is Latin America
- **THEN** the card shows `carro`, and «Варианты» lists `coche` (Испания) and `auto` (Аргентина и Уругвай)

#### Scenario: Other-variant block as note
- **WHEN** a card has a block for `es` only and the variant is Rioplatense
- **THEN** that block is shown collapsed under «В Испании»

### Requirement: Exercises follow the variant
Exercise answer data SHALL be resolved by a pure function of the exercise and the variant: an override for the variant's code replaces `answer`, `accept` and `options`, and an exercise restricted with `only` SHALL never be selected for variants not listed.

#### Scenario: Override applied
- **WHEN** an exercise defines an `am` override answer `ustedes hablan` and the variant is Latin America
- **THEN** that answer is expected

#### Scenario: Restricted exercise skipped
- **WHEN** an exercise declares `only: [es]` and the variant is Rioplatense
- **THEN** the exercise is never selected for practice

### Requirement: Conjugation person set per variant
The person set given to the conjugation trainer SHALL be: Spain — yo, tú, él, nosotros, vosotros, ellos; Latin America — yo, tú, él, nosotros, ellos; Rioplatense — yo, vos, él, nosotros, ellos, using the compiled `vos` forms.

#### Scenario: No vosotros in Latin America
- **WHEN** the variant is Latin America
- **THEN** no drill asks for a vosotros form

#### Scenario: Voseo form asked
- **WHEN** the variant is Rioplatense and the present of `hablar` is drilled for vos
- **THEN** the expected form is `hablás`

### Requirement: Rioplatense voice fallback
For the Rioplatense variant, Spanish audio SHALL use an `es-AR` voice when one is installed, otherwise an `es-MX` voice, otherwise an `es-ES` voice.

#### Scenario: Fallback voice
- **WHEN** the variant is Rioplatense and the device has no `es-AR` voice
- **THEN** audio is spoken with an `es-MX` voice

### Requirement: Variant coverage in card content
Content validation SHALL fail for a card whose conjugation table has a *vosotros* row or column outside a Spain-only block unless the card carries variant notes for Latin America (`am`) and the Rioplatense variant (`rio`), and for an example sentence using *coger* outside a Spain-only block or an inline alternative. The card that compares the variants themselves is exempt.

#### Scenario: Table without notes
- **WHEN** a card shows a present-tense table with a `vosotros/as` row and has no `am` or `rio` block
- **THEN** validation fails naming the card and the missing variants

#### Scenario: Spain-only table
- **WHEN** the table sits inside a `:::variant es` block
- **THEN** no notes are required

#### Scenario: Coger in an example
- **WHEN** a card example reads *Cogí el autobús.* outside a Spain block
- **THEN** validation fails until it is wrapped in a Spain block or an inline alternative

