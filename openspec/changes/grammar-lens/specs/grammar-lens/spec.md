## ADDED Requirements

### Requirement: Text input sources
Grammar Lens SHALL accept Spanish text from three sources: pasted or typed text, text shared from another app through the system share sheet, and text recognised by Live Text from the camera or a photo. Paste and share SHALL work without camera permission.

#### Scenario: Shared text
- **WHEN** the user shares a Spanish paragraph from another app to Lorito
- **THEN** Grammar Lens analyses that paragraph

#### Scenario: Camera denied
- **WHEN** camera access is denied
- **THEN** paste and share remain available and the camera option explains how to enable access

### Requirement: On-device analysis
All analysis SHALL run on the device without network access, using the system natural-language tagger for tokens and lexical classes, and a compiled lemma table whenever the system lemma scheme is unavailable for Spanish.

#### Scenario: Offline analysis
- **WHEN** the device has no network and the user analyses text
- **THEN** results are produced

#### Scenario: No system lemma model
- **WHEN** the system reports no lemma scheme for Spanish
- **THEN** the matcher uses the compiled lemma table and produces the same matches for covered words

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
From a highlight the user SHALL be able to choose «Добавить в повторение»: a card without review state becomes a new card queued for today ahead of other new cards, and an already scheduled card becomes due today. The spaced-repetition calculations SHALL NOT change.

#### Scenario: Scheduled card brought forward
- **WHEN** the user adds a card that is due in 9 days
- **THEN** the card is due today and its ease and interval history are unchanged

### Requirement: Rule content validation
Lens rules SHALL be authored as content files with card IDs, a pattern, context predicates and positive and negative example sentences. Content validation SHALL fail when a rule references an unknown card, when a positive example does not match, or when a negative example matches.

#### Scenario: Negative example matches
- **WHEN** a rule's negative example "Espero el autobús" matches the rule
- **THEN** validation fails naming the rule id

### Requirement: Text privacy
Analysed text SHALL NOT be stored or sent anywhere; only the card a user explicitly adds to review is persisted.

#### Scenario: Leaving the lens
- **WHEN** the user closes Grammar Lens without adding a card
- **THEN** no trace of the analysed text remains in the app's storage
