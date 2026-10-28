# grammar-lens Specification

## Purpose
TBD - created by archiving change grammar-lens. Update Purpose after archive.
## Requirements
### Requirement: Text input sources
Grammar Lens SHALL accept Spanish text from three sources: pasted or typed text, text shared from another app through the system share sheet, and text recognised by Live Text from the camera or a photo. Paste and share SHALL work without camera permission.

#### Scenario: Shared text
- **WHEN** the user shares a Spanish paragraph from another app to Lorito
- **THEN** Grammar Lens analyses that paragraph

#### Scenario: Camera denied
- **WHEN** camera access is denied
- **THEN** paste and share remain available and the camera option explains how to enable access

### Requirement: On-device analysis
All analysis SHALL run on the device without network access, using the system natural-language tokenizer only for sentence and word boundaries and the compiled lemma table shipped with the content for lemmas.

#### Scenario: Offline analysis
- **WHEN** the device has no network and the user analyses text
- **THEN** results are produced

#### Scenario: Same result on every device
- **WHEN** the same text is analysed on two devices with different OS versions
- **THEN** the same spans are highlighted

### Requirement: Deterministic rule matching
Matching SHALL be performed by a pure function over tokens and authored rules: a span is highlighted only when every pattern and context predicate of a rule holds; overlapping matches keep the longest span, and ties keep the more specific rule. Identical inputs SHALL produce identical matches.

#### Scenario: Subjunctive trigger
- **WHEN** the text contains "Espero que vengas mañana"
- **THEN** "Espero que vengas" is highlighted and linked to the subjunctive card mapped by the rule

#### Scenario: No guessing
- **WHEN** the text contains no construction covered by a rule
- **THEN** no span is highlighted and the empty state lists the covered topics

### Requirement: Highlights link to cards
Each highlight SHALL show the rule's short name in Russian and open the mapped card in the card reader when tapped; when a rule maps to several cards, all are listed.

#### Scenario: Open the card
- **WHEN** the user taps the highlight on "el problema"
- **THEN** card A1-07 opens in the card reader

### Requirement: Add to review
From a highlight on a card the user has not started, «Добавить в повторение» SHALL mark the card as user-requested so it is introduced through the daily plan. For a card that already has review state, the lens SHALL show when it is next due and SHALL NOT change its schedule.

#### Scenario: New card requested
- **WHEN** the user adds card A1-07 that has never been studied
- **THEN** A1-07 is marked user-requested

#### Scenario: Scheduled card not moved
- **WHEN** the user looks at a highlight for a card due in 9 days
- **THEN** the lens shows «Уже в повторении — через 9 дней» and the card's schedule is unchanged

### Requirement: Rule content validation
Lens rules SHALL use only surface-form and lemma predicates and include positive and negative examples. Validation SHALL fail when a rule references an unknown card, uses a lexical-class predicate, references a lemma missing from the lemma table, a positive example does not match, or a negative example matches.

#### Scenario: Lexical-class predicate
- **WHEN** a rule uses a lexical-class predicate
- **THEN** validation fails naming the rule id

#### Scenario: Negative example matches
- **WHEN** a rule's negative example "Espero el autobús" matches the rule
- **THEN** validation fails naming the rule id

### Requirement: Text privacy
Analysed text SHALL NOT be stored or sent anywhere; only the card a user explicitly adds to review is persisted.

#### Scenario: Leaving the lens
- **WHEN** the user closes Grammar Lens without adding a card
- **THEN** no trace of the analysed text remains in the app's storage

### Requirement: Card coverage map
Every bundled card SHALL either be linked by at least one Lens rule or be listed in the Lens coverage map with a non-empty reason why no surface rule can find it. Validation SHALL fail for a card that is neither, for a card that is both, and for an unknown card in the map.

#### Scenario: New card without a decision
- **WHEN** a card is added and no rule links it and the coverage map doesn't list it
- **THEN** validation fails naming the card

#### Scenario: Pronunciation card
- **WHEN** `A1-02` is listed in the coverage map with the reason «произношение — в тексте не видно»
- **THEN** validation passes without a rule for it

### Requirement: Composed surface sets
Surface sets SHALL be able to combine several conjugation tenses and to exclude the forms of other tenses, and generated participle sets SHALL be able to include feminine and plural forms; sets SHALL be expanded by the pipeline so the app receives plain form lists.

#### Scenario: Indefinido without present look-alikes
- **WHEN** a set takes the `preterito-indefinido` tense and excludes `presente`
- **THEN** it contains `habló` and `comió` but not `hablamos`

#### Scenario: Inflected participles
- **WHEN** the participle set is generated with inflection
- **THEN** it contains `cerrado`, `cerrada`, `cerrados` and `cerradas`

### Requirement: Phrase-list rules
A Lens rule file SHALL be able to list phrases — each with its text, Russian meaning and an example — instead of a pattern. The pipeline SHALL expand it into one rule per phrase whose steps match each word's surface (with `a|b` alternatives) or, for a word marked `~`, its lemma; the phrase's meaning SHALL be the rule title, its example the positive example, and the list's negative examples SHALL apply to every phrase. Validation SHALL require at least three phrases, each with text, meaning and a matching example, and SHALL reject a phrase list that also has a pattern.

#### Scenario: Proverb found in text
- **WHEN** a phrase list for card `C1-17` contains «más vale tarde que nunca» and the analysed text says «Llegó tarde, pero más vale tarde que nunca.»
- **THEN** the phrase is highlighted with its meaning and links to `C1-17`

#### Scenario: Inflected verb
- **WHEN** the phrase is `~echar de menos` and the text says «Te echo de menos.»
- **THEN** the phrase is highlighted

#### Scenario: Example that does not match
- **WHEN** a phrase's example does not contain the phrase
- **THEN** validation fails naming the generated rule

