## MODIFIED Requirements

### Requirement: Deck selection
The learner SHALL be able to select and deselect decks; by default the decks of their included levels up to B2 SHALL be selected. Only selected decks and the personal deck SHALL feed new words to the planner; already introduced words of a deselected deck SHALL stay reviewable. An empty stored selection SHALL mean the default; a learner without a target level SHALL get the A1–B2 decks by default. C1 and C2 decks SHALL be selected only explicitly.

#### Scenario: Deselected deck excluded
- **WHEN** the learner deselects the A1 «Еда» deck
- **THEN** none of its unseen words are introduced and its introduced words remain due as scheduled

#### Scenario: Default follows the target level
- **WHEN** a learner with target level A2 has never changed the deck selection
- **THEN** only A1 and A2 decks feed new words, and B1–C2 decks show as not selected

#### Scenario: Advanced decks are opt-in
- **WHEN** a learner with target level C2 has never changed the deck selection
- **THEN** the A1–B2 decks are selected and the C1 and C2 decks are not

#### Scenario: Selecting an advanced deck
- **WHEN** that learner selects a C1 deck
- **THEN** the A1–B2 decks stay selected and the C1 deck is added

## ADDED Requirements

### Requirement: B1–C2 deck coverage
The bundled vocabulary SHALL contain at least 450 B1 words, 450 B2 words, 350 C1 words and 350 C2 words, with every deck holding at least 20 words and every word id unique across decks.

#### Scenario: Coverage pinned by a test
- **WHEN** the bundled content is loaded
- **THEN** each of B1–C2 meets its minimum and no deck has fewer than 20 words
