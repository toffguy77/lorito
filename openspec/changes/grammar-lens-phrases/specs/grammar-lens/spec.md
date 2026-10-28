## ADDED Requirements

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
