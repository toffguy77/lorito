## 1. Domain (TDD)

- [ ] 1.1 Write failing tests for `SpeakableText.extract(markdown:)`: emphasis runs only, nested bold inside italics, ¿ ¡ kept, Russian text excluded, empty result when no Spanish
- [ ] 1.2 Implement `SpeakableText`; `SpeechVariant` (`es-ES`, `es-MX`), `SpeechRate` (`normal`, `slow`)
- [ ] 1.3 Extend `UserSettings` with `speechVariant`, `speechRate`, `playAudioWhenSilent` (defaults es-ES / normal / false); test decoding of old settings

## 2. Features

- [ ] 2.1 `SpeechService` protocol + `SystemSpeechService` (`AVSpeechSynthesizer`): voice selection by variant and quality with fallback, rate mapping, stop-previous, audio session category per setting; fake service for tests
- [ ] 2.2 Tests with the fake: tapping a new fragment stops the previous; no Spanish voice → `isAvailable == false`
- [ ] 2.3 Settings section "Звук": variant, speed, silent-mode toggle; hint when no Spanish voice

## 3. DesignSystem & screens

- [ ] 3.1 `SpeakButton` (44×44 pt, label "Произнести", speaking state)
- [ ] 3.2 Tap-to-speak on `SpanishText` and on emphasis runs in the MarkdownUI theme; disabled while VoiceOver is running
- [ ] 3.3 Speaker buttons on recall prompt, revealed card, exercises with Spanish prompts; tokens and options speak on tap
- [ ] 3.4 Gallery entries for `SpeakButton` and speakable text

## 4. Validation

- [ ] 4.1 `swift test` green
- [ ] 4.2 `xcodebuild` build; UI test: speaker button exists on card front and has the label
- [ ] 4.3 Manual on device: airplane mode, silent switch on/off, es-MX voice, VoiceOver
- [ ] 4.4 `openspec validate spanish-audio --strict`
