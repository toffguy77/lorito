## ADDED Requirements

### Requirement: Spanish spans are interactive
Spanish text in card bodies (Markdown emphasis containing at least one Latin letter) and in `SpanishText` views SHALL be rendered as interactive spans that keep the Spanish typographic style and carry no link underline. Emphasis without Latin letters (numbers, quotes) SHALL stay plain text.

#### Scenario: Spanish emphasis becomes a span
- **WHEN** a card body contains `*el problema*`
- **THEN** it is rendered in the Spanish style as an interactive span

#### Scenario: Numbers stay plain
- **WHEN** a card body contains `*1.000,50*`
- **THEN** it is rendered as plain emphasized text, not a span

### Requirement: One gesture contract
For every Spanish span, a tap SHALL perform the primary action (speak the span once spanish-audio is available; otherwise nothing) and a long press SHALL open a context menu whose items are contributed by features (e.g. «Произнести», «В мои слова», «Варианты»). Features SHALL NOT attach other gestures to Spanish text.

#### Scenario: Menu lists only available actions
- **WHEN** only spanish-audio is shipped and the user long-presses a span
- **THEN** the context menu shows «Произнести» and no other items

#### Scenario: Tap before audio ships
- **WHEN** spanish-audio is not shipped and the user taps a span
- **THEN** nothing happens and no error is shown

### Requirement: Accessible spans
Each Spanish span SHALL be read by VoiceOver as text in Spanish (speech language es) and SHALL expose the context-menu items as custom accessibility actions.

#### Scenario: VoiceOver actions
- **WHEN** VoiceOver focuses a Spanish span and the user opens actions
- **THEN** the same items as the context menu are offered
