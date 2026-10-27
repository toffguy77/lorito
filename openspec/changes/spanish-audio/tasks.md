## 0. Dependencies

- [x] 0.1 `learning-platform-foundation` (spanish-text-interactions) and `cloudkit-schema-release` applied

## 1. Domain (TDD)

- [x] 1.1 Write failing tests for `SpeakableText`: extract strips Markdown and keeps ¿ ¡; `isSpeakable` true for "el agua", "ñ", false for "1492", "«…»", "—", Russian-only text
- [x] 1.2 Write failing tests for `AudioSessionPolicy`: content + silent off → ambient; content + silent on → playback/duckOthers; listening exercise → playback
- [x] 1.3 Implement `SpeakableText`, `SpanishVariant` (`spain`, `latinAmerica`, locale mapping), `SpeechRate`, `AudioSessionPolicy`

## 2. Settings persistence

- [x] 2.1 Add `spanishVariant`, `speechRate`, `playAudioWhenSilent` to `UserSettings` and as optional/defaulted `SettingsRecord` properties; map both ways in `SwiftDataUserDataStore`
- [x] 2.2 Store round-trip test; export dev CloudKit schema to `cloudkit/schema.ckdb` — (owner): run the app once with `-LoritoInitCloudKitSchema`, then `cktool export-schema` (see `cloudkit/README.md`)

## 3. Features

- [x] 3.1 `SpeechService` protocol + `SystemSpeechService`: voice by variant and quality with fallback, rate, stop-previous, category from `AudioSessionPolicy`; fake for tests
- [x] 3.2 Register the «Произнести» / tap action with `spanish-text-interactions`; hide it for non-speakable spans and when no Spanish voice exists
- [x] 3.3 One-time silence hint (device-local flag)
- [x] 3.4 Settings section «Звук»: variant, speed, silent-mode toggle; hint when no Spanish voice

## 4. DesignSystem & screens

- [x] 4.1 `SpeakButton` (44×44 pt, label "Произнести", speaking state) + gallery entry
- [x] 4.2 Speaker buttons on recall prompt, revealed card, exercises with Spanish prompts

## 5. Validation

- [x] 5.1 `swift test` green
- [x] 5.2 `xcodebuild` build; UI test: speaker button on card front with its label; long-press menu shows «Произнести»
- [ ] 5.3 (manual, owner) Manual on device: airplane mode, silent switch on/off, es-MX voice, VoiceOver
- [x] 5.4 `openspec validate spanish-audio --strict`
