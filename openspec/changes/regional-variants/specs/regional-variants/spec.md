## ADDED Requirements

### Requirement: Variant setting
The learner SHALL choose one Spanish variant — Spain, Latin America or Rioplatense — in onboarding and in settings; the default SHALL be Spain. The variant SHALL be stored in the synced user settings.

#### Scenario: Default variant
- **WHEN** a learner completes onboarding without changing the variant
- **THEN** the variant is Spain

#### Scenario: Change in settings
- **WHEN** the learner switches to Rioplatense in settings
- **THEN** cards, exercises, drills and audio use Rioplatense from then on

### Requirement: Variant-aware card rendering
Card bodies SHALL render the variant block and inline alternative of the learner's variant in place, and SHALL show the other variants' blocks as labelled notes («В Испании: …», «В Латинской Америке: …», «В Аргентине и Уругвае: …»). Inline alternatives missing a form for a variant SHALL fall back to the Spain form.

#### Scenario: Inline alternative
- **WHEN** a card contains `[[spain:coche|latam:carro|rioplatense:auto]]` and the variant is Latin America
- **THEN** the card shows `carro` with a tappable note listing `coche` (Spain) and `auto` (Rioplatense)

#### Scenario: Other-variant block as note
- **WHEN** a card has a block for Spain only and the variant is Rioplatense
- **THEN** that block is shown collapsed under «В Испании»

### Requirement: Exercises follow the variant
Exercise answer data SHALL be resolved by a pure function of the exercise and the variant: a variant override replaces `answer`, `accept` and `options` for that variant, and an exercise restricted with `only` SHALL never be selected for variants not listed.

#### Scenario: Override applied
- **WHEN** an exercise defines a Latin America override answer `ustedes hablan` and the variant is Latin America
- **THEN** that answer is expected

#### Scenario: Restricted exercise skipped
- **WHEN** an exercise declares `only: [spain]` and the variant is Rioplatense
- **THEN** the exercise is never selected for practice

### Requirement: Conjugation persons per variant
Conjugation drills SHALL ask only the persons of the learner's variant: Spain — yo, tú, él, nosotros, vosotros, ellos; Latin America — the same without vosotros; Rioplatense — vos instead of tú and without vosotros, using the compiled `vos` forms.

#### Scenario: No vosotros in Latin America
- **WHEN** the variant is Latin America
- **THEN** no drill asks for a vosotros form

#### Scenario: Voseo form asked
- **WHEN** the variant is Rioplatense and the present of `hablar` is drilled for `vos`
- **THEN** the expected form is `hablás`

### Requirement: Voice follows the variant
Spanish audio SHALL use a voice in the variant's preferred language — `es-ES` for Spain, `es-MX` for Latin America, `es-AR` for Rioplatense — falling back to `es-MX` and then `es-ES` when no voice in the preferred language is installed.

#### Scenario: Fallback voice
- **WHEN** the variant is Rioplatense and the device has no `es-AR` voice
- **THEN** audio is spoken with an `es-MX` voice
