## ADDED Requirements

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
