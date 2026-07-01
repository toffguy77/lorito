## ADDED Requirements

### Requirement: Exercise-type variety
Where the material suits it, a level's exercise set SHALL include variety beyond `multiple-choice` / `fill-in-the-blank` — namely the auto-checkable `matching` and `word-order` types and the self-assessed `free-response` type — rather than only single-form drills. Each such exercise MUST conform to the exercise frontmatter schema for its type and MUST reference an existing card of the same level. (`picture-matching` variety is optional and depends on the availability of bundled image assets.)

#### Scenario: A level offers more than one interaction mode
- **WHEN** a level's exercises are inspected after its content passes
- **THEN** they include, beyond multiple-choice / fill-in-the-blank, at least the `matching`, `word-order`, and `free-response` types across its themes

#### Scenario: Each new-type exercise remains well-formed
- **WHEN** a `matching`, `word-order`, or `free-response` exercise is added
- **THEN** it conforms to the exercise frontmatter schema for its type and references an existing card of the same level
