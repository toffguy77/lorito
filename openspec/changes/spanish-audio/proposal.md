## Why

Lorito teaches a spoken language without making a sound. Every competitor in
the audit (Duolingo, Babbel, Anki decks, niche RU apps) plays audio; a learner
who cannot hear *el agua fría* will keep a second app open, and eventually only
that one. iOS ships offline Spanish speech synthesis, so audio costs us no
server, no recordings and no licensing.

## What Changes

- **Tap to hear:** every Spanish fragment rendered in the Spanish voice
  (`SpanishText`, Markdown emphasis in card bodies, exercise options and
  tokens, recall prompts) can be tapped to be spoken.
- **Speaker buttons:** on the card front (recall prompt), on the revealed card
  (title example / first Spanish example) and on exercises whose prompt
  contains Spanish.
- **Offline synthesis:** `AVSpeechSynthesizer` with an es-ES or es-MX voice;
  best available quality installed on the device, fallback to any `es-*`.
- **Settings:** voice variant (Испания / Мексика), speed (медленно / обычно),
  and "Звук в беззвучном режиме" (off by default — audio respects the
  Ring/Silent switch).
- **Accessibility:** speaking does not interrupt VoiceOver; Spanish text keeps
  `es-ES` speech language for VoiceOver; buttons have labels.

## Capabilities

### New Capabilities
- `spanish-audio`: on-device text-to-speech for Spanish content, playback
  controls, audio settings.

### Modified Capabilities
<!-- None: existing rendering is unchanged; audio is an added affordance. -->

## Impact

- **Domain**: `SpeechVariant` enum, pure `SpeakableText` extraction (strip
  Markdown, keep Spanish punctuation ¿ ¡), `UserSettings` gains
  `speechVariant`, `speechRate`, `playAudioWhenSilent` (additive defaults).
- **Features**: `SpeechService` (wraps `AVSpeechSynthesizer`, audio session
  category), injected into study, exercise and catalog views; Settings rows.
- **DesignSystem**: `SpeakButton` component; tappable affordance on
  `SpanishText` and in the MarkdownUI theme (emphasis runs).
- No network, no bundled audio files, no binary size change beyond code.
- Prepares the voice setting later reused by `regional-variants`.
