## ADDED Requirements

### Requirement: Card plan ignores non-card review items
The daily-plan composer SHALL consider only review states whose id resolves to a card in the content snapshot when selecting due cards, applying the reviews cap, and determining which cards are already introduced. Review states of other item kinds stored in the same review store (e.g. ids prefixed `conj:` or `word:`) SHALL NOT appear in the card queue or the card count report.

#### Scenario: Conjugation item not in the card queue
- **WHEN** a review state `conj:hablar:presente` is due today
- **THEN** it does not appear in the composed card queue and does not change the due card count

#### Scenario: Unknown id ignored
- **WHEN** the store holds a due review state whose id matches no card
- **THEN** the composer ignores it without error
