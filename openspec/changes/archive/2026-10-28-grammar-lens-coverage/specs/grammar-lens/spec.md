## ADDED Requirements

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
