## 0. Dependencies

- [x] 0.1 `spanish-audio` applied (speech synthesis, play / slow replay, voice availability, audio-session policy) and `learning-platform-foundation` applied

## 1. Content model & pipeline (TDD)

- [x] 1.1 Document `listen-choose`, `dictation`, `speak` fields and limits in `content/schema.md`
- [x] 1.2 Failing tests in `tools/test_pipeline.py`: required fields per new type, `answer` ∈ `options` for `listen-choose`, one-line and length limits for `audio`/`answer`, unknown type still rejected
- [x] 1.3 Implement in `tools/validate.py` and `tools/compile.py`; bundle carries `audio`, `options`, `answer`, `accept`

## 2. Domain (TDD)

- [x] 2.1 Failing tests: `ExerciseKind` decodes the three new types; `isAutoChecked` true for `listen-choose`/`dictation`, mode for `speak` depends on an injected recognition capability
- [x] 2.2 Failing tests for dictation normalisation (case, whitespace, punctuation incl. `¿ ¡`), accent-only difference → "почти"/Трудно, wrong → Опять with word diff
- [x] 2.3 Failing tests for transcript comparison: best transcript or any alternative matches `answer`/`accept` with diacritics ignored
- [x] 2.4 Implement in `ExerciseChecker`; keep it pure

## 3. Features

- [x] 3.1 `SpeechRecognizing` protocol + `SFSpeechRecognizer` implementation for `es-ES` with `requiresOnDeviceRecognition = true`; refuses to start unless `supportsOnDeviceRecognition`; fake for tests
- [x] 3.2 Permission flow: explanation screen, microphone + speech prompts on first `speak`, remembered denial; `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription` in `project.yml`
- [x] 3.3 Exercise screen affordances: play / replay / slow replay; mic button with level meter and transcript; reveal of audio text after submission; self-assessed fallback with reference playback and grade buttons
- [x] 3.4 «Не могу слушать сейчас» / «Не могу говорить сейчас» (15-minute session skip, ungraded); settings toggles; exercise selection respects both
- [x] 3.5 Unit tests with fake recognizer: match → Хорошо applied; two failed attempts → attempt recorded, review unchanged; self-assessed Опять → attempt only; unsupported device → self-assessed; denied permission → self-assessed; no request made when unsupported
- [x] 3.6 Exercise selector excludes `listen-choose`/`dictation` when `spanish-audio` reports no Spanish voice; Settings hint to download a voice; unit test with a fake voice provider
- [x] 3.7 (session switching implemented; the Silent-switch check is manual, owner) Audio sessions: listening playback through the `spanish-audio` listening policy; play-and-record during `speak` recording, previous session restored; manual check with the Silent switch on

## 4. Content

- [x] 4.1 (generated — нужна вычитка) Author listening and speaking exercises for A1 and A2 (at least one `listen-choose` or `dictation` per theme, `speak` for phrase-level cards)
- [x] 4.2 (generated — нужна вычитка) Author B1 set; run `python3 tools/compile.py`

## 5. Validation

- [x] 5.1 `swift test`, `python3 tools/test_pipeline.py` green
- [x] 5.2 `xcodebuild` build; UI tests for `listen-choose` and `dictation` flows (audio through the simulator voice; sessions narrowed with the UI-testing seam `-lorito-practice-types`)
- [ ] 5.3 (manual, owner) Manual on device: `speak` with on-device recognition; airplane mode still works; denied permission path
- [x] 5.4 `openspec validate listening-and-pronunciation --strict`
