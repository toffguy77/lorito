## ADDED Requirements

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

## MODIFIED Requirements

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
