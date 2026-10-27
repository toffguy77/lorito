## Context

After `plumaje-design-system` all Spanish text goes through `SpanishText` or
the Spanish style in `CardBodyView`'s MarkdownUI theme (emphasis → Instrument
Serif Italic, accent colour, `accessibilitySpeechLanguage("es-ES")`). That gives
one hook for audio. AVFoundation's `AVSpeechSynthesizer` speaks with system
voices selected by language code
(https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer).

## Goals / Non-Goals

**Goals:** hear any Spanish fragment in one tap; offline; consistent voice per
user; no surprise sound in silent mode.

**Non-Goals:** recorded native audio, listening exercises / dictation and
pronunciation scoring (→ `listening-and-pronunciation`), auto-play on every
card, regional content variants (→ `regional-variants`).

## Decisions

**What is speakable.** A pure `SpeakableText.extract(markdown:)` returns the
Spanish runs of a Markdown string — the emphasis spans the Spanish style
renders — with Markdown markers removed and ¿ ¡ kept. For `SpanishText` the
whole string is speakable. Russian text is never sent to the synthesizer.

**Voice selection.** `SpeechService` picks, for the chosen variant (`es-ES`
default, or `es-MX`), the highest-quality installed voice
(`AVSpeechSynthesisVoice.speechVoices()` filtered by language, sorted by
`quality`); if none for that region, any `es-*` voice; if no Spanish voice,
the speak affordances are hidden and Settings explains how to download a voice
in iOS Settings. Chosen voice identifier is cached per launch.

**Rate.** Two steps mapped onto `AVSpeechUtterance.rate`: "обычно" =
`AVSpeechUtteranceDefaultSpeechRate`, "медленно" = 0.8 × default. Exact
values tuned by ear in implementation; stored as an enum, not a float.

**Silent switch.** Audio session category `.ambient` by default (silenced by
the Ring/Silent switch, mixes with other audio); `.playback` with
`.duckOthers` only when "Звук в беззвучном режиме" is on. Category is set just
before speaking, not at launch, to avoid interrupting other apps.

**Interaction.** Tap on a Spanish run speaks it and shows a short highlight;
tapping again stops. Speaking a new fragment stops the previous one. A
`SpeakButton` (speaker icon, 44×44 pt, label "Произнести") appears on the
recall prompt, on the revealed card next to the title area, and on exercises
with Spanish prompts. With VoiceOver running, tap-to-speak on text is
disabled (VoiceOver already reads Spanish with the es-ES speech language);
the explicit buttons remain.

## Risks / Trade-offs

- [Voice quality differs by device; enhanced voices need a download] → pick
  best installed; Settings hint links to iOS voice settings.
- [Tap on text conflicts with text selection / links] → card bodies have no
  links in Spanish runs; tap target limited to emphasis runs.
- [Synth mispronounces abbreviations] → content guideline: write out Spanish
  examples in full; no runtime fixes.

## Migration Plan

Additive. Settings fields default to es-ES / обычно / respect silent. Rollback:
hide affordances behind a single feature flag in `SpeechService`.
