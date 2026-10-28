# vocabulary Specification

## Purpose
TBD - created by archiving change vocabulary-decks. Update Purpose after archive.
## Requirements
### Requirement: Word model and decks
The system SHALL model a word with a lemma id, Spanish form, part of speech, article and gender for nouns, optional plural and inflected forms, Russian translation, an example sentence with translation, frequency rank, deck and level, loaded from the content bundle into the pure `Domain` layer. Decks SHALL be ordered by level and deck order, and words within a deck by rank.

#### Scenario: Noun carries gender
- **WHEN** the word `problema` is loaded
- **THEN** it exposes article `el`, gender masculine and its Russian translation

#### Scenario: Deck order
- **WHEN** an A1 deck is listed
- **THEN** its words appear in ascending frequency rank

### Requirement: Words are reviewed with the shared scheduler
Each word SHALL be a review item with id `word:<lemma>` (item kind per `learning-platform-foundation`) stored in the existing review store and scheduled by the `srs-engine` scheduling operation. Grading a word SHALL write a study event under the item id; words SHALL NOT be counted as cards.

#### Scenario: Word graded
- **WHEN** the user gives the word `casa` its first graded review of the learning day with Хорошо
- **THEN** the review state `word:casa` is updated by the scheduling operation and a study event is written

### Requirement: Recognition and production modes
A word's review mode SHALL be a pure function of its graded study events: production when its last two memory-updating reviews were Трудно or better, otherwise recognition. Recognition SHALL show the Spanish word with audio, then reveal translation and example for self-grading. Production SHALL show the Russian translation and check the typed Spanish with the accent-aware rule; nouns SHALL require an article.

#### Scenario: New word is recognised first
- **WHEN** a word is reviewed for the first time
- **THEN** the Spanish form is shown with audio and the user self-grades after revealing the meaning

#### Scenario: Lapse returns to recognition
- **WHEN** a word in production mode is graded Опять
- **THEN** its next review is in recognition mode

### Requirement: Article checking in production
In production mode a noun answer SHALL include an article: for `m` or `f` nouns only the word's article SHALL be accepted and a wrong article SHALL be reported as a gender mistake graded Опять; for `mf` nouns both `el` and `la` SHALL be accepted.

#### Scenario: Wrong article
- **WHEN** the expected answer is `la mano` and the user types `el mano`
- **THEN** the answer is incorrect, graded Опять, and reported as a gender mistake

#### Scenario: Common-gender noun
- **WHEN** the word is `estudiante` with gender `mf` and the user types `la estudiante`
- **THEN** the answer is correct

### Requirement: Opt-in word quota
The setting `dailyNewWordCount` SHALL default to 0 for all learners; enabling words SHALL set it to 5 unless the learner picks another value (0–20). New words SHALL count against the combined daily new-introduction budget of `learning-platform-foundation`.

#### Scenario: Off by default
- **WHEN** a learner has never enabled words
- **THEN** no new words are planned and Today shows no «Слова» block unless words are due

#### Scenario: Enabled default
- **WHEN** the learner enables words without changing the quota
- **THEN** at most 5 new words are introduced per learning day

### Requirement: Vocabulary planner
A pure `VocabularyPlanner` SHALL return all due word items from the selected decks and the personal deck, plus new words up to the quota — personal words first, then selected decks in level, deck and rank order. Identical inputs and injected "today" SHALL yield identical output. The Today screen SHALL show a «Слова» block with the due and new word counts when any are planned.

#### Scenario: Personal words first
- **WHEN** the quota is 5 and the personal deck has 3 unseen words
- **THEN** those 3 are planned first, followed by 2 deck words by rank

#### Scenario: Today block
- **WHEN** 4 words are due and 5 new words are planned
- **THEN** Today shows «Слова» with 4 due and 5 new

### Requirement: Save words from context
The «В мои слова» action of the Spanish-text context menu (`learning-platform-foundation`) SHALL add the word to the personal deck: if the normalised word matches a bundled word's form or listed forms, that bundled word is added; otherwise a sheet with audio and an optional translation field SHALL let the learner save a personal word record.

#### Scenario: Known word saved
- **WHEN** the user chooses «В мои слова» on `problema` in a card
- **THEN** the bundled word `problema` is added to the personal deck

#### Scenario: Unknown word saved
- **WHEN** the user chooses «В мои слова» on a word missing from the bundle, types a translation and saves
- **THEN** a personal word record is stored and the word becomes a review item

### Requirement: Delete personal words
The learner SHALL be able to delete a word from the personal deck. Deleting SHALL remove it from the personal deck, delete its personal word record if it has one, and remove its review state; its study events SHALL remain for statistics.

#### Scenario: Delete a saved word
- **WHEN** the learner deletes a personal word
- **THEN** it is no longer planned or listed and past study days still count

### Requirement: Deck selection
The learner SHALL be able to select and deselect decks; by default the decks of their included levels up to B2 SHALL be selected. Only selected decks and the personal deck SHALL feed new words to the planner; already introduced words of a deselected deck SHALL stay reviewable.

#### Scenario: Deselected deck excluded
- **WHEN** the learner deselects the A1 «Еда» deck
- **THEN** none of its unseen words are introduced and its introduced words remain due as scheduled

### Requirement: A1–A2 deck coverage
The bundled vocabulary SHALL contain at least 450 A1 words and at least 450 A2 words, with every deck holding at least 20 words and every word id unique across decks.

#### Scenario: Coverage pinned by a test
- **WHEN** the bundled content is loaded
- **THEN** A1 and A2 each have at least 450 words and no deck has fewer than 20

### Requirement: Word entry checks
The content pipeline SHALL reject a word whose example sentence contains neither the word nor one of its listed forms (verbs excepted, as their examples are conjugated), and a noun stored with `el` and feminine gender unless it begins with stressed *a-* or *ha-* (*el agua*). It SHALL also reject regional forms with a code other than `am` or `rio`, a noun's regional form without an article, a regional form equal to the Spain form, and a word with regional forms whose example contains the Spain form outside an inline alternative.

#### Scenario: Example without the word
- **WHEN** the noun `mesa` has the example "Es grande."
- **THEN** validation fails naming `mesa`

#### Scenario: Feminine noun with el
- **WHEN** `agua` is stored with article `el` and gender `f`
- **THEN** validation passes, while `mesa` stored the same way fails

#### Scenario: Regional noun without article
- **WHEN** `ordenador` has the form `am: computadora`
- **THEN** validation fails naming `ordenador`

#### Scenario: Unmarked example
- **WHEN** `ordenador` has an `am` form and the example "Uso el ordenador." without an inline alternative
- **THEN** validation fails naming `ordenador`

### Requirement: Regional word forms
A word SHALL be able to carry regional forms for Latin America (`am`) and Argentina–Uruguay (`rio`); a noun's regional form SHALL carry its own article and gender. The Spain form SHALL remain the word's id. Word sessions SHALL resolve the word for the learner's `spanishVariant` — the shown form, the audio and the expected production answer — falling back to the Spain form when the variant has none, and SHALL list the other forms with their region after the answer is revealed or checked. In production, any of the word's forms SHALL be accepted as correct with the article of that form. Example sentences SHALL render their inline alternatives for the learner's variant. «В мои слова» SHALL match a regional form to its bundled word.

#### Scenario: Latin American learner
- **WHEN** the word `ordenador` has the form `am: la computadora` and the variant is Latin America
- **THEN** the session shows `la computadora`, speaks it, and after reveal lists `el ordenador` (Испания)

#### Scenario: Any regional form accepted
- **WHEN** a Spain-variant learner is asked for `ordenador` in production and types `la computadora`
- **THEN** the answer is correct

#### Scenario: Article follows the form
- **WHEN** the word `bolso` has the form `am: la cartera` and a Latin American learner types `el cartera`
- **THEN** the answer is a gender mistake

#### Scenario: No regional form
- **WHEN** the word `casa` has no regional forms and the variant is Rioplatense
- **THEN** the session shows `la casa`

#### Scenario: Saving a regional form
- **WHEN** the learner chooses «В мои слова» on `computadora`
- **THEN** the bundled word `ordenador` is added to the personal deck

