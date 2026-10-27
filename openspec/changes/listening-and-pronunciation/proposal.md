## Why

Lorito trains reading and writing only. Half of every real exam (DELE A2:
listening and speaking are one of the two pass groups) and most of daily life
in Spain or Latin America is hearing and speaking. The product audit ranked
"no audio, no listening, no pronunciation" as the gap where every competitor
beats us. With on-device text-to-speech (sibling change `spanish-audio`) and
on-device speech recognition, Lorito can add listening and speaking practice
with no backend, no recordings to host and no audio leaving the device.

## What Changes

- **Three new exercise types** in the existing practice system:
  - `listen-choose` — hear a Spanish phrase, pick the matching option (auto).
  - `dictation` — hear a phrase, type it (auto, punctuation-insensitive,
    accent differences reported as "почти").
  - `speak` — say a target phrase; on-device recognition (es-ES) compares the
    transcript with the target (auto). When on-device recognition is
    unavailable or permission is denied, it falls back to self-assessment
    against the reference audio.
- **Privacy by construction:** speech recognition requests require on-device
  recognition; if the device cannot recognise Spanish offline, the app never
  falls back to server recognition.
- **"Can't listen / can't speak now"** skips audio or speaking exercises for
  15 minutes without grading; a setting turns them off entirely.
- **Content & pipeline:** new frontmatter fields (`audio`, `answer`,
  `options`, `accept`) for the new types, validated and compiled; authoring
  tasks for A1–B1.

## Capabilities

### New Capabilities
<!-- None: extends practice-exercises. -->

### Modified Capabilities
- `practice-exercises`: the exercise type taxonomy gains `listen-choose`,
  `dictation` and `speak`; new requirements for audio playback, dictation
  checking, speech checking with fallback, permissions and skipping.
- `content-model`: the exercise frontmatter schema gains the fields of the new
  types.
- `content-pipeline`: exercise integrity validation covers the new types.

## Impact

- **Domain**: `ExerciseKind` gains three cases; `ExerciseChecker` gains
  dictation and transcript comparison (pure).
- **Features**: exercise screen affordances (play/replay, slow replay, mic
  button with live level, transcript display); permission flow for microphone
  and speech recognition; skip and settings.
- **App target**: `NSMicrophoneUsageDescription` and
  `NSSpeechRecognitionUsageDescription` in Info.plist (`project.yml`).
- **Content**: new exercises under `content/<LEVEL>/exercises/`; `content/schema.md`.
- **Dependencies**: sibling `spanish-audio` (speech synthesis service and voice
  choice) is required; `regional-variants` later selects the voice per variant;
  `product-analytics` records exercise outcomes. Builds on archived
  `plumaje-design-system`.
