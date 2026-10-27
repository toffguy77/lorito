## Context

After `plumaje-design-system` all Spanish text goes through `SpanishText` or
the Spanish style of `CardBodyView`'s MarkdownUI theme (emphasis → Instrument
Serif Italic). `learning-platform-foundation` turns those spans into links of a
custom URL scheme handled by `OpenURLAction` (`spanish-text-interactions`):
tap = speak, long-press = context menu with «Произнести», «В мои слова»,
«Варианты», each item present only when its feature exists. This change
provides the speak action. Synthesis uses `AVSpeechSynthesizer`
(https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer).

## Goals / Non-Goals

**Goals:** hear any Spanish span in one tap; offline; one variant setting for
the whole app; a clear audio-session rule; no surprise sound in silent mode.

**Non-Goals:** recorded native audio; listening/dictation exercises and
pronunciation scoring (→ `listening-and-pronunciation`, which follows the
session policy defined here); content differences between variants
(→ `regional-variants`); auto-play.

## Decisions

**Speak action via the interaction contract.** `SpeechService` registers as
the handler of the "speak" interaction of `spanish-text-interactions`; no
gesture recognisers are added to text in this change.

**Speakable-span rule.** Italic is not a reliable Spanish marker (numbers and
«…» quotations can be italic too). A pure `SpeakableText.isSpeakable(_:)`
accepts a span only if it contains at least one Latin letter (a–z, á é í ó ú
ü ñ in either case) and is not only digits, punctuation or quotation marks.
Non-speakable spans get no speak affordance. `SpeakableText.extract` strips
Markdown markers and keeps ¿ ¡.

**Variant setting (single source of truth).** `spanishVariant` with cases
`spain` («Испания», es-ES) and `latinAmerica` («Латинская Америка», es-MX).
`regional-variants` extends the same enum (e.g. Rioplatense) and adds
content behavior; no second variant setting may exist. Voice selection: best
installed voice for the variant's locale by `quality`, fallback any `es-*`;
with no Spanish voice, speak affordances are hidden and Settings explains how
to download one.

**Audio-session policy (owned here).** A pure `AudioSessionPolicy` maps the
playback context to a category: `.content` (taps, speaker buttons) →
`.ambient` (silenced by the Ring/Silent switch, mixes with other audio)
unless «Звук в беззвучном режиме» is on → `.playback` with `.duckOthers`;
`.listeningExercise` → always `.playback` (the exercise is meaningless
silently). Category is set just before playback. iOS offers no public API to
read the switch, so the first time content speech is triggered on a device a
one-time hint says: «Нет звука? Выключите беззвучный режим или включите «Звук
в беззвучном режиме» в настройках».

**Rate.** «Обычно» = `AVSpeechUtteranceDefaultSpeechRate`; «Медленно» ≈ 0.8 ×
default, tuned by ear; stored as an enum.

**VoiceOver.** With VoiceOver running, the link activation reads normally and
the speaker buttons remain the way to hear the synthesizer; Spanish spans keep
`es-ES` speech language.

**Settings persistence.** `spanishVariant`, `speechRate`,
`playAudioWhenSilent` are optional/defaulted `SettingsRecord` properties
mapped both ways in `SwiftDataUserDataStore`, per `cloudkit-schema-release`.

## Risks / Trade-offs

- [Voice quality varies; enhanced voices need a download] → best installed;
  Settings hint.
- [Spanish words that look like Russian transliteration] → rule only needs
  one Latin letter; content stays responsible for marking Spanish.
- [Synth mispronounces abbreviations] → content guideline: write examples in full.

## Migration Plan

Additive. Defaults: `spain`, `normal`, silent respected. Rollback: unregister
the speak action and hide speaker buttons behind one flag.
