## Why

Lorito teaches a spoken language without making a sound. Every competitor in
the audit (Duolingo, Babbel, Anki decks, niche RU apps) plays audio; a learner
who cannot hear *el agua fría* will keep a second app open, and eventually only
that one. iOS ships offline Spanish speech synthesis, so audio costs us no
server, no recordings and no licensing.

## What Changes

- **Tap to hear:** every Spanish span (`SpanishText`, emphasized Spanish in
  card bodies and recall prompts, exercise options and tokens) speaks on tap,
  through the tap / long-press contract of `spanish-text-interactions`
  (long-press menu item «Произнести»).
- **Speakable-span rule:** only spans that contain at least one Latin letter
  are spoken; numbers, quotes and other italic non-Spanish text are not.
- **Speaker buttons:** on the card front (recall prompt), on the revealed card
  and on exercises whose prompt contains Spanish.
- **Offline synthesis:** `AVSpeechSynthesizer`, best installed voice for the
  variant, fallback to any `es-*`.
- **Spanish variant setting (owner of the setting):** `spanishVariant` —
  «Испания» (es-ES) or «Латинская Америка» (es-MX) — drives the voice;
  `regional-variants` later extends the same setting.
- **Audio-session policy (owner):** content playback uses `.ambient` and
  respects the Ring/Silent switch unless «Звук в беззвучном режиме» is on;
  listening exercises use `.playback`. A one-time hint explains silence.
- **Speed:** «Обычно» / «Медленно».

## Capabilities

### New Capabilities
- `spanish-audio`: on-device text-to-speech for Spanish spans, speakable-span
  rule, Spanish variant setting, audio-session policy, speed.

### Modified Capabilities
<!-- None: rendering is unchanged; interactions come from
spanish-text-interactions. -->

## Impact

- **Domain**: `SpanishVariant` (`spain`, `latinAmerica`; extensible),
  `SpeechRate`, pure `SpeakableText` (extract + Latin-letter rule),
  `AudioSessionPolicy` (pure mapping context → category).
- **Features**: `SpeechService` (`AVSpeechSynthesizer`, session category per
  policy), registered as the «Произнести» action of
  `spanish-text-interactions`; speaker buttons; Settings section «Звук».
- **DesignSystem**: `SpeakButton`.
- **Persistence**: settings `spanishVariant`, `speechRate`,
  `playAudioWhenSilent` as optional/defaulted `SettingsRecord` properties per
  `cloudkit-schema-release`.
- **Depends on:** `learning-platform-foundation` (spanish-text-interactions),
  `cloudkit-schema-release`. Used by `regional-variants` and
  `listening-and-pronunciation`.
