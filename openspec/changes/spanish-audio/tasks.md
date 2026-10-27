## 0. Dependencies

- [ ] 0.1 `learning-platform-foundation` (spanish-text-interactions) and `cloudkit-schema-release` applied

## 1. Domain (TDD)

- [ ] 1.1 Write failing tests for `SpeakableText`: extract strips Markdown and keeps ¿ ¡; `isSpeakable` true for "el agua", "ñ", false for "1492", "«…»", "—", Russian-only text
- [ ] 1.2 Write failing tests for `AudioSessionPolicy`: content + silent off → ambient; content + silent on → playback/duckOthers; listening exercise → playback
- [ ] 1.3 Implement `SpeakableText`, `SpanishVariant` (`spain`, `latinAmerica`, locale mapping), `SpeechRate`, `AudioSessionPolicy`

## 2. Settings persistence

- [ ] 2.1 Add `spanishVariant`, `speechRate`, `playAudioWhenSilent` to `UserSettings` and as optional/defaulted `SettingsRecord` properties; map both ways in `SwiftDataUserDataStore`
- [ ] 2.2 Store round-trip test; export dev CloudKit schema to `cloudkit/schema.ckdb`

## 3. Features

- [ ] 3.1 `SpeechService` protocol + `SystemSpeechService`: voice by variant and quality with fallback, rate, stop-previous, category from `AudioSessionPolicy`; fake for tests
- [ ] 3.2 Register the «Произнести» / tap action with `spanish-text-interactions`; hide it for non-speakable spans and when no Spanish voice exists
- [ ] 3.3 One-time silence hint (device-local flag)
- [ ] 3.4 Settings section «Звук»: variant, speed, silent-mode toggle; hint when no Spanish voice

## 4. DesignSystem & screens

- [ ] 4.1 `SpeakButton` (44×44 pt, label "Произнести", speaking state) + gallery entry
- [ ] 4.2 Speaker buttons on recall prompt, revealed card, exercises with Spanish prompts

## 5. Validation

- [ ] 5.1 `swift test` green
- [ ] 5.2 `xcodebuild` build; UI test: speaker button on card front with its label; long-press menu shows «Произнести»
- [ ] 5.3 Manual on device: airplane mode, silent switch on/off, es-MX voice, VoiceOver
- [ ] 5.4 `openspec validate spanish-audio --strict`
