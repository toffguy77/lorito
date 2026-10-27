## ADDED Requirements

### Requirement: Optional recall prompt on cards
A card MAY declare a `recall` field in its front matter: a single-line Markdown string of at most 200 characters that poses the question the card answers (e.g. `recall: "**¿el или la?** *problema, mano, canción, agua*"`). The compiled bundle SHALL carry the field when present, and the `Card` domain type SHALL expose it as an optional value. Cards without the field SHALL remain valid.

#### Scenario: Card with recall prompt
- **WHEN** a card declares `recall` in its front matter and the content is compiled
- **THEN** the loaded `Card` exposes that prompt text

#### Scenario: Card without recall prompt
- **WHEN** a card has no `recall` field
- **THEN** the card loads successfully and its recall prompt is absent
