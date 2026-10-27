## ADDED Requirements

### Requirement: Tap Spanish text to hear it
Every speakable Spanish span — in `SpanishText`, card bodies, recall prompts, exercise options and word-order tokens — SHALL be spoken when tapped and SHALL offer «Произнести» in its long-press menu, both through the `spanish-text-interactions` contract. Tapping a speaking span SHALL stop it; starting another span SHALL stop the previous one.

#### Scenario: Tap an example in a card
- **WHEN** the user taps the Spanish span "el agua fría" in a revealed card
- **THEN** the app speaks "el agua fría" with a Spanish voice

#### Scenario: Long-press menu
- **WHEN** the user long-presses a Spanish span
- **THEN** the context menu contains «Произнести», which speaks the span

### Requirement: Speakable-span rule
A pure `Domain` function SHALL decide which spans are speakable: a span SHALL be speakable only if it contains at least one Latin letter (including á, é, í, ó, ú, ü, ñ) and is not made only of digits, punctuation or quotation marks. Speakable text SHALL have Markdown markers removed and keep ¿ and ¡. Non-speakable spans SHALL get no speak affordance.

#### Scenario: Markdown markers removed
- **WHEN** the span is "*¿Cómo te **llamas**?*"
- **THEN** the speakable text is "¿Cómo te llamas?"

#### Scenario: Italic number not spoken
- **WHEN** a card body contains the italic span "*1492*"
- **THEN** that span is not speakable and tapping it produces no speech

#### Scenario: Russian text is not spoken
- **WHEN** the user taps a Russian explanation sentence
- **THEN** no speech is produced

### Requirement: Speaker buttons on study surfaces
The card front (recall prompt), the revealed card and each exercise whose prompt contains Spanish SHALL show a speaker button of at least 44×44 pt with the accessibility label "Произнести" that speaks the main Spanish content of that surface.

#### Scenario: Speak the recall prompt
- **WHEN** the user taps the speaker button on a card front whose recall prompt contains Spanish words
- **THEN** those Spanish words are spoken in order

### Requirement: Spanish variant setting
The app SHALL have a single setting `spanishVariant`, shown as «Испания» (es-ES, default) or «Латинская Америка» (es-MX), that selects the speech voice. Other changes that need a Spanish variant SHALL extend this setting rather than add another. It SHALL persist as a synced user setting.

#### Scenario: Latin American voice
- **WHEN** the user selects «Латинская Америка» and taps a Spanish span
- **THEN** it is spoken with an es-MX voice if one is installed

### Requirement: Offline voice selection
Speech SHALL be synthesized on device without network access, using the highest-quality installed voice for the selected variant and falling back to any installed Spanish voice. When no Spanish voice is installed, speak affordances SHALL be hidden and Settings SHALL explain how to install one.

#### Scenario: Works offline
- **WHEN** the device is in airplane mode and the user taps a Spanish span
- **THEN** it is spoken

#### Scenario: No Spanish voice installed
- **WHEN** no Spanish voice is available on the device
- **THEN** no speaker buttons or «Произнести» items are shown and Settings shows how to add a Spanish voice

### Requirement: Audio-session policy
Content speech (taps, speaker buttons) SHALL use an audio session that is silenced by the Ring/Silent switch and mixes with other audio, unless «Звук в беззвучном режиме» (off by default) is on, in which case it SHALL play in silent mode and duck other audio. Listening exercises SHALL always play regardless of the switch. The mapping SHALL be a pure function owned by this capability.

#### Scenario: Silent mode default
- **WHEN** the device is on silent, the setting is off, and the user taps a Spanish span
- **THEN** no sound is produced

#### Scenario: Listening exercise
- **WHEN** a listening exercise plays audio while the device is on silent
- **THEN** the audio is heard

### Requirement: Silence hint
The first time content speech is triggered on a device, the app SHALL show a one-time hint that silent mode can mute speech and how to enable «Звук в беззвучном режиме».

#### Scenario: First speech
- **WHEN** a user taps a Spanish span for the first time on a device
- **THEN** the silence hint is shown once and not again on that device

### Requirement: Speech speed
Settings SHALL let the user choose «Обычно» or «Медленно»; the choice SHALL persist as a synced setting and apply to the next spoken span.

#### Scenario: Slow speed
- **WHEN** the user selects «Медленно» and taps a Spanish span
- **THEN** it is spoken at the slower rate

### Requirement: Coexists with VoiceOver
When VoiceOver is running, Spanish spans SHALL keep the Spanish speech language for VoiceOver and speaker buttons SHALL remain available.

#### Scenario: VoiceOver user
- **WHEN** VoiceOver is on and the user activates a speaker button
- **THEN** the Spanish content is spoken by the synthesizer
