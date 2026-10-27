## Context

`practice-exercises` defines six types, a pure `ExerciseChecker` and an
interactive screen; outcomes feed the card's SM-2 review. The sibling change
`spanish-audio` provides an offline Spanish speech-synthesis service
(`AVSpeechSynthesizer`). Apple's Speech framework can keep recognition on the
device: `SFSpeechRecognitionRequest.requiresOnDeviceRecognition` prevents audio
from being sent over the network, but is honoured only when the recognizer's
`supportsOnDeviceRecognition` is true, and on-device results are less accurate
([Apple docs](https://developer.apple.com/documentation/speech/sfspeechrecognitionrequest/requiresondevicerecognition)).

## Goals / Non-Goals

**Goals:** listening comprehension, dictation and pronunciation practice inside
the existing exercise flow and SRS; no network, no hosted audio; graceful
behaviour on devices or settings where recognition is not possible.

**Non-Goals:** phoneme-level pronunciation scoring; recorded native-speaker
audio; long listening passages (DELE-style dialogues come with
`exam-path-dele-ccse`); regional voices (→ `regional-variants`).

## Decisions

**Audio text lives in content, sound is synthesised.** `audio` is the Spanish
text to speak. No audio files in the bundle; the voice and rate come from the
`spanish-audio` service. A "slow" replay uses a reduced rate.

**Dictation checking.** Normalise both strings: lowercase, trim, collapse
whitespace, strip punctuation including `¿ ¡`. Equal → correct (Хорошо).
Equal only after removing diacritics → "почти" with the differences shown,
grade Трудно (same rule as `conjugation-trainer`, because accents are spelling).
Otherwise incorrect (Опять) with a word-level diff.

**Speech checking.** Recognition runs only if the recognizer for `es-ES`
reports `supportsOnDeviceRecognition`, the user granted microphone and speech
permissions, and the request sets `requiresOnDeviceRecognition = true`. The
best transcript and up to four alternatives are compared to `answer` and
`accept` with the dictation normalisation, ignoring diacritics entirely
(recognisers do not "hear" missing written accents). Match → Хорошо; no match
after two attempts → the user may accept the outcome (Опять) or self-grade
after hearing the reference. If any precondition fails, the exercise runs in
self-assessed mode: the user speaks, plays the reference and grades with the
four buttons. Pure comparison lives in `Domain`; the recognizer wrapper in
`Features` behind a protocol so tests use a fake.

**Permissions asked in context.** Microphone and speech-recognition prompts
appear the first time a `speak` exercise starts, after a one-screen
explanation; denial is remembered and never re-prompted automatically.

**Skip and opt-out.** «Не могу слушать сейчас» / «Не могу говорить сейчас»
hide that kind for 15 minutes (session-scoped, not graded, the exercise
returns later). Settings toggles turn listening or speaking exercises off; the
exercise planner then never selects those types.

## Risks / Trade-offs

- [On-device Spanish recognition not available on some devices/locales] →
  self-assessed fallback keeps the exercise usable; analytics measure the
  fallback rate.
- [Recognition accuracy on accented speech of learners] → generous
  comparison (alternatives, diacritics ignored), two attempts, self-grade
  escape hatch.
- [Synthesised voice quality] → depends on `spanish-audio`'s voice choice
  (enhanced voices when installed).
- [Silent mode / headphones] → playback uses the `.playback` audio session
  category set by `spanish-audio`; a hint appears if output volume is 0.

## Migration Plan

Additive. Older content keeps working; new types appear as authored. Rollback:
remove the types; validation rejects them again, so content must be reverted
with the code.
