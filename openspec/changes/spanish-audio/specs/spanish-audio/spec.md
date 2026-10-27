## ADDED Requirements

### Requirement: Tap Spanish text to hear it
Every Spanish fragment rendered in the Spanish text style — `SpanishText`, emphasis runs in card bodies and recall prompts, exercise options and word-order tokens — SHALL be playable as speech by tapping it. Tapping a fragment while it is speaking SHALL stop it, and starting a new fragment SHALL stop the previous one. Russian text SHALL never be spoken by this feature.

#### Scenario: Tap an example in a card
- **WHEN** the user taps the emphasized example "el agua fría" in a revealed card
- **THEN** the app speaks "el agua fría" with a Spanish voice

#### Scenario: Russian text is not spoken
- **WHEN** the user taps a Russian explanation sentence
- **THEN** no speech is produced

### Requirement: Speakable text extraction is pure
The Spanish text to be spoken SHALL be produced by a pure `Domain` function that extracts the Spanish runs from Markdown, removes Markdown markers, and keeps Spanish punctuation such as ¿ and ¡. For identical input it SHALL return identical output.

#### Scenario: Markdown markers removed
- **WHEN** the input is "*¿Cómo te **llamas**?*"
- **THEN** the speakable text is "¿Cómo te llamas?"

### Requirement: Speaker buttons on study surfaces
The card front (recall prompt), the revealed card and each exercise whose prompt contains Spanish SHALL show a speaker button of at least 44×44 pt with the accessibility label "Произнести" that speaks the main Spanish content of that surface.

#### Scenario: Speak the recall prompt
- **WHEN** the user taps the speaker button on a card front whose recall prompt contains Spanish words
- **THEN** those Spanish words are spoken in order

### Requirement: Offline voice selection
Speech SHALL be synthesized on device without network access, using the highest-quality installed voice for the selected variant (es-ES by default, or es-MX), falling back to any installed Spanish voice. When no Spanish voice is installed, speak affordances SHALL be hidden and Settings SHALL explain how to install one.

#### Scenario: Works offline
- **WHEN** the device is in airplane mode and the user taps a Spanish fragment
- **THEN** it is spoken

#### Scenario: No Spanish voice installed
- **WHEN** no Spanish voice is available on the device
- **THEN** no speaker buttons are shown and Settings shows how to add a Spanish voice

### Requirement: Audio settings
Settings SHALL let the user choose the voice variant ("Испания" or "Мексика"), the speed ("Обычно" or "Медленно"), and whether audio plays in silent mode ("Звук в беззвучном режиме", off by default). Choices SHALL persist in user settings and apply to the next spoken fragment.

#### Scenario: Slow speed
- **WHEN** the user selects "Медленно" and taps a Spanish fragment
- **THEN** it is spoken at the slower rate

### Requirement: Respect the silent switch
By default, speech SHALL be silenced when the device's Ring/Silent switch is set to silent and SHALL mix with other audio. Only when "Звук в беззвучном режиме" is on SHALL speech play in silent mode, ducking other audio while speaking.

#### Scenario: Silent mode default
- **WHEN** the device is on silent and the setting is off
- **THEN** tapping a Spanish fragment produces no sound

### Requirement: Coexists with VoiceOver
When VoiceOver is running, tap-to-speak on text SHALL be disabled so it does not conflict with VoiceOver gestures, Spanish text SHALL keep the Spanish speech language for VoiceOver, and speaker buttons SHALL remain available.

#### Scenario: VoiceOver user
- **WHEN** VoiceOver is on and the user activates a speaker button
- **THEN** the Spanish content is spoken by the synthesizer
