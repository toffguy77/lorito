## Context

`spanish-audio` owns the synced setting `spanishVariant` (`spain` «Испания»,
default; `latinAmerica` «Латинская Америка») and requires other changes to
extend it rather than add another setting. `learning-platform-foundation`
moves `CardBodyParser` into `Domain` and defines Spanish spans with a
long-press context menu that includes «Варианты». Content is seeded from an
Obsidian vault, where `[[…]]` is the wiki-link syntax. The conjugation trainer
takes the person set as an input. Voseo replaces `tú` with `vos`: in the
present indicative the verb drops `-r`, adds `-s` and stresses the last vowel
(`hablás, comés, vivís`; `sos` for ser); affirmative commands drop `-r` with an
accent (`hablá, comé, viví`); preterite, imperfect and present subjunctive are
the same as `tú`, as described in
[LibreTexts: Vos](https://human.libretexts.org/Courses/Franklin_and_Marshall_College/Puertas_y_Puentes%3A_Intermediate_Spanish_I___2e/08%3A_Apendice/8.01%3A_Vos),
which also notes that voseo usage and forms vary by country.

## Goals / Non-Goals

**Goals:** one setting changes what the learner reads, practises, drills and
hears; content stays a single source with small, validated markup that is
safe in Obsidian.

**Non-Goals:** separate courses per country; Caribbean, Andean, Central
American or Chilean voseo paradigms; pronunciation coaching of
`yeísmo`/`sheísmo`; asking the variant during onboarding.

## Decisions

**Extend, don't duplicate.** `SpanishVariant` gains `rioplatense`
(«Риоплатский»). Markup uses short codes mapped to the setting: `es` → `spain`,
`am` → `latinAmerica`, `rio` → `rioplatense`. Persons: `spain` — tú + vosotros;
`latinAmerica` — tú + ustedes; `rioplatense` — vos + ustedes.

**When to ask.** After the first completed study session a one-time Today
prompt («Где вы учите испанский?») offers the three values; dismissing keeps
«Испания». The choice is always in Settings. Onboarding order belongs to
`placement-test-and-first-session` and is unchanged.

**Card markup.**
- Block: a line `:::variant <codes>` … a line `:::` around paragraphs, lists
  or tables. Content outside blocks applies to all variants.
- Inline: `{es: coche | am: carro | rio: auto}` — at least two codes; a missing
  code falls back to `es`. Braces with a `code:` prefix are reserved; plain
  braces elsewhere stay text. Neither form collides with Obsidian wiki-links
  (`[[…]]`) or callouts (`> [!note]`).
- Rendering: the learner's block or inline form is shown in place; other
  variants' blocks collapse into labelled notes («В Испании: …», «В Латинской
  Америке: …», «В Аргентине и Уругвае: …»); inline alternatives are Spanish
  spans whose «Варианты» menu action lists all forms.

**Exercises.** Optional frontmatter `variants: {am: {answer, accept, options},
rio: {…}}` overrides answer data per variant, and optional `only: [es]`
restricts an exercise to listed variants. Resolution is a pure function of the
exercise and the variant.

**Conjugation persons.** The person set passed to `conjugation-trainer`:
`spain` six persons; `latinAmerica` five (no vosotros); `rioplatense` vos
instead of tú, no vosotros. The pipeline generates `vos` forms for the present
indicative and affirmative imperative of regular verbs, copies `tú` forms for
other tenses, and verbs may override (`ser` → `sos`).

**Voice fallback.** `spanish-audio` maps `spain` → `es-ES` and
`latinAmerica` → `es-MX`; this change adds `rioplatense` → `es-AR`, falling back
to `es-MX` then `es-ES` when no voice in that language is installed (the
installed voice list differs per device). Recognition in
`listening-and-pronunciation` uses the same language when on-device
recognition supports it, else `es-ES`.

## Risks / Trade-offs

- [Markup noise in card files] → used only where usage differs; validator
  rejects malformed blocks and unknown codes.
- [Older app versions read an unknown `spanishVariant` value] → decoding falls
  back to `spain` per `cloudkit-schema-release` rules for enum fields.
- [Voseo norms vary by country] → scope limited to Rioplatense; the note
  explains it.
- [Changing variant mid-course] → review states stay valid; drills ask
  different persons from then on.

## Migration Plan

Additive. Existing users stay on their current `spanishVariant`; the Today
prompt appears once after their next completed session. Rollback: the parser
shows the `es` form and ignores blocks for other codes, so content with markup
stays readable.
