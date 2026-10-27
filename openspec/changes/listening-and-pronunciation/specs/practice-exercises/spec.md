## MODIFIED Requirements

### Requirement: Exercise type taxonomy
The system SHALL support the following exercise `type` values, each either **auto-checkable** (the system decides correctness) or **self-assessed** (the user reveals the reference answer and grades themselves):

| `type` | mode | answer data |
|--------|------|-------------|
| `multiple-choice` | auto | `options` (≥2) + one correct `answer` |
| `fill-in-the-blank` | auto | expected `answer` + optional `accept` alternatives |
| `matching` | auto | ordered list of `pairs` (left ↔ right) |
| `word-order` | auto | `tokens` to arrange into the correct `answer` sentence |
| `picture-matching` | auto | `options`, each pairing an image asset with a label, + correct mapping |
| `free-response` | self-assessed | a reference `answer` (and optional `accept`) shown for self-grading |
| `listen-choose` | auto | Spanish `audio` text + `options` (≥2) + one correct `answer` |
| `dictation` | auto | Spanish `audio` text (the expected answer) + optional `accept` |
| `speak` | auto when on-device recognition is available, otherwise self-assessed | target `answer` + optional `accept` |

An exercise's `type` SHALL be one of these values; an unknown type SHALL be rejected by validation (see content-pipeline).

#### Scenario: Each supported type loads
- **WHEN** an exercise of any supported `type` is loaded from the bundle
- **THEN** the model exposes that type and its type-specific answer data

#### Scenario: Auto vs self-assessed mode is known per type
- **WHEN** the checking service receives an exercise
- **THEN** it knows whether the type is auto-checkable or self-assessed and handles submission accordingly

#### Scenario: Speak mode depends on recognition availability
- **WHEN** a `speak` exercise starts on a device where on-device Spanish recognition is unavailable
- **THEN** the exercise runs in self-assessed mode

## ADDED Requirements

### Requirement: Listen-choose exercise type
A `listen-choose` exercise SHALL play its `audio` text through the Spanish speech service without showing the text, offer play, replay and slow replay, and SHALL be correct only when the chosen option equals `answer`. After submission the `audio` text SHALL be shown.

#### Scenario: Correct option after listening
- **WHEN** the user listens and selects the option equal to `answer`
- **THEN** the answer is correct and the spoken text is revealed

#### Scenario: Text hidden before answering
- **WHEN** a `listen-choose` exercise is displayed
- **THEN** its `audio` text is not visible until submission

### Requirement: Dictation exercise type
A `dictation` exercise SHALL play its `audio` text and accept a typed answer. Both SHALL be normalised (lowercase, trimmed, collapsed whitespace, punctuation including `¿` and `¡` removed). Equal normalised strings SHALL be correct (Хорошо); strings equal only after removing diacritics SHALL be reported as "почти" with the differences and graded Трудно; otherwise the answer SHALL be incorrect (Опять) with a word-level difference shown.

#### Scenario: Punctuation ignored
- **WHEN** the audio is `¿Cómo te llamas?` and the user types `cómo te llamas`
- **THEN** the answer is correct

#### Scenario: Missing accent
- **WHEN** the audio is `¿Cómo te llamas?` and the user types `como te llamas`
- **THEN** the answer is reported as almost correct and graded Трудно

### Requirement: Speak exercise type
A `speak` exercise SHALL record the user saying the target `answer` and, in auto mode, SHALL compare the recognised transcript and its alternatives with `answer` and `accept` using the dictation normalisation with diacritics ignored. A match SHALL grade Хорошо. After two non-matching attempts the user SHALL be able to continue or play the reference audio and self-grade.

#### Scenario: Recognised correctly
- **WHEN** the transcript of the user's speech equals the target after normalisation
- **THEN** the exercise is correct and graded Хорошо

#### Scenario: Two failed attempts
- **WHEN** two attempts do not match
- **THEN** the user can continue or hear the reference and self-grade

### Requirement: Speaking never lapses a card
A `speak` exercise SHALL NOT apply the Опять grade to its card: non-matching attempts and a self-assessed Опять SHALL be recorded as exercise attempts only, without updating the card's review state. Self-assessed grades of Трудно or better SHALL be applied as for other exercises.

#### Scenario: Failed recognition keeps the card
- **WHEN** both attempts of a `speak` exercise do not match and the user continues
- **THEN** an attempt is recorded and the card's review state is unchanged

#### Scenario: Self-assessed Опять is not applied
- **WHEN** in self-assessed mode the user picks Опять
- **THEN** an attempt is recorded and the card's review state is unchanged

### Requirement: Listening requires an installed voice
When no Spanish speech-synthesis voice is installed on the device, `listen-choose` and `dictation` exercises SHALL be excluded from practice sessions without being graded, and Settings SHALL explain how to download a Spanish voice.

#### Scenario: No Spanish voice
- **WHEN** the device has no Spanish voice and a session is composed
- **THEN** it contains no `listen-choose` or `dictation` exercises and none is graded

### Requirement: Audio sessions for listening and speaking
Listening and dictation playback SHALL use the `spanish-audio` listening policy, which plays regardless of the Ring/Silent switch. Recording for a `speak` exercise SHALL use a play-and-record audio session only while recording and SHALL restore the previous session afterwards.

#### Scenario: Silent switch on
- **WHEN** the Silent switch is on and a `dictation` exercise plays its audio
- **THEN** the audio is audible

#### Scenario: Session restored
- **WHEN** a `speak` recording ends
- **THEN** the audio session returns to the configuration in use before recording

### Requirement: On-device speech recognition only
Speech recognition SHALL run only with on-device recognition required and supported for Spanish, and only after the user granted microphone and speech-recognition permission. Audio SHALL never be sent for server recognition. When any of these conditions is not met, `speak` exercises SHALL run in self-assessed mode.

#### Scenario: Permission denied
- **WHEN** the user denies microphone or speech-recognition permission
- **THEN** `speak` exercises run in self-assessed mode and the permission prompt is not shown again automatically

#### Scenario: No server fallback
- **WHEN** on-device recognition is not supported on the device
- **THEN** no recognition request is made and the exercise is self-assessed

### Requirement: Skip and turn off audio exercises
During a session the user SHALL be able to choose «Не могу слушать сейчас» or «Не могу говорить сейчас», which removes listening or speaking exercises from the session for 15 minutes without grading them. Settings SHALL let the user turn listening or speaking exercises off; turned-off types SHALL never be selected for practice.

#### Scenario: Temporary skip
- **WHEN** the user taps «Не могу слушать сейчас»
- **THEN** no `listen-choose` or `dictation` exercise is shown for 15 minutes and none is graded

#### Scenario: Turned off in settings
- **WHEN** speaking exercises are turned off
- **THEN** no `speak` exercise is selected for practice
