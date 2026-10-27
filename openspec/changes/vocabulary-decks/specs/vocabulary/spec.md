## ADDED Requirements

### Requirement: Word model and decks
The system SHALL model a word with a unique id, Spanish form, part of speech, article and gender for nouns, optional plural and inflected forms, Russian translation, an example sentence with translation, frequency rank, deck and level, loaded from the content bundle into the pure `Domain` layer. Decks SHALL be ordered by level and deck order, and words within a deck by rank.

#### Scenario: Noun carries gender
- **WHEN** the word `problema` is loaded
- **THEN** it exposes article `el`, gender masculine and its Russian translation

#### Scenario: Deck order
- **WHEN** an A1 deck is listed
- **THEN** its words appear in ascending frequency rank

### Requirement: Words are reviewed with the shared scheduler
Each word SHALL be a review item with id `word:<word-id>` stored in the existing review store and scheduled by the `srs-engine` scheduling operation. Grading a word SHALL write a study event under the item id.

#### Scenario: Word graded
- **WHEN** the user grades the word `casa` Хорошо
- **THEN** the review state `word:casa` is updated by the scheduling operation and a study event is written

### Requirement: Recognition then production
While a word's repetition count is below 2, its review SHALL be recognition: the Spanish word with audio, then reveal of translation and example, then self-grading. From repetition 2 the review SHALL be production: the Russian translation is shown and the Spanish form is typed and checked with the accent-aware rule; nouns SHALL require the article, and a wrong article SHALL be reported as a gender mistake.

#### Scenario: New word is recognised first
- **WHEN** a word is reviewed for the first time
- **THEN** the Spanish form is shown with audio and the user self-grades after revealing the meaning

#### Scenario: Wrong article
- **WHEN** in production mode the expected answer is `la mano` and the user types `el mano`
- **THEN** the answer is incorrect, graded Опять, and reported as a gender mistake

### Requirement: Vocabulary planner
A pure `VocabularyPlanner` SHALL return all due word items from the selected decks and the personal deck, plus at most `dailyNewWordCount` new words — personal words first, then selected decks in level, deck and rank order. Identical inputs and injected "today" SHALL yield identical output; a quota of 0 SHALL introduce no new words.

#### Scenario: Personal words first
- **WHEN** the quota is 10 and the personal deck has 3 unseen words
- **THEN** those 3 are planned first, followed by 7 deck words by rank

#### Scenario: Quota zero
- **WHEN** `dailyNewWordCount` is 0
- **THEN** no new words are planned and due words still are

### Requirement: Save words from context
A long press on a Spanish word in a card, exercise or example SHALL open a word sheet. If the normalised word matches a bundled word's form or listed forms, the sheet SHALL show its entry with audio and «В мои слова»; otherwise it SHALL show the word with audio and an optional translation field, and saving SHALL create a personal word record.

#### Scenario: Known word saved
- **WHEN** the user long-presses `problema` and taps «В мои слова»
- **THEN** the bundled word is added to the personal deck

#### Scenario: Unknown word saved
- **WHEN** the user long-presses a word missing from the bundle, types a translation and saves
- **THEN** a personal word record is stored and the word becomes a review item

### Requirement: Deck selection
The learner SHALL be able to select and deselect decks; by default the decks of their included levels up to B2 SHALL be selected. Only selected decks and the personal deck SHALL feed the vocabulary planner.

#### Scenario: Deselected deck excluded
- **WHEN** the learner deselects the A1 «Еда» deck
- **THEN** none of its unseen words are introduced and its already introduced words remain reviewable from the decks screen
