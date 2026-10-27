## Context

Cards are Markdown files parsed by `CardBodyParser` into Markdown spans and
typed callouts; exercises are Markdown files with YAML frontmatter; the
conjugation trainer (pending sibling) stores six persons per tense
(yo, tú, él, nosotros, vosotros, ellos). Voseo replaces `tú` with `vos`: in
the present indicative the verb drops `-r`, adds `-s` and stresses the last
vowel (`hablás, comés, vivís`; `sos` for ser); affirmative commands drop `-r`
with an accent (`hablá, comé, viví`); preterite, imperfect and present
subjunctive are the same as `tú` in the standard Rioplatense norm described in
[LibreTexts: Vos](https://human.libretexts.org/Courses/Franklin_and_Marshall_College/Puertas_y_Puentes%3A_Intermediate_Spanish_I___2e/08%3A_Apendice/8.01%3A_Vos).
The same source notes that voseo usage and forms vary by country.

## Goals / Non-Goals

**Goals:** one setting changes what the learner reads, practises, drills and
hears; content stays a single source with small, validated markup.

**Non-Goals:** separate courses per country; Caribbean, Andean or Central
American voseo paradigms; Chilean voseo forms; pronunciation coaching of
`yeísmo`/`sheísmo`; variant-specific CEFR content.

## Decisions

**Three variants.** `spain` (tú + vosotros), `latam` (tú + ustedes as the only
second-person plural), `rioplatense` (vos + ustedes). Default `spain`, since the
course was written for it.

**Card markup.**
- Block: a fenced directive `:::variant spain` / `:::variant latam rioplatense`
  … `:::` around a paragraph, list or table. Content outside directives is
  common to all variants.
- Inline: `[[spain:coche|latam:carro|rioplatense:auto]]`; any variant may be
  omitted and falls back to `spain`.
- Rendering: the learner's variant block or inline form is shown normally;
  other variants' blocks collapse into a labelled note («В Испании: …»,
  «В Латинской Америке: …», «В Аргентине и Уругвае: …») so the learner still
  understands texts from other regions.

**Exercises.** Optional frontmatter `variants: {latam: {answer, accept,
options}, rioplatense: {…}}` overrides answer data per variant, and optional
`only: [spain]` restricts an exercise to listed variants (it is never selected
for others). Resolution is a pure function of the exercise and the variant.

**Conjugation persons.** `spain`: six persons. `latam`: five (no `vosotros`).
`rioplatense`: `vos` replaces `tú`, no `vosotros`. The pipeline generates `vos`
forms for the present indicative and affirmative imperative of regular verbs;
other tenses reuse the `tú` form; verbs may override (`ser` → `sos`).

**Voice selection.** The variant maps to a preferred voice language:
`spain` → `es-ES`, `latam` → `es-MX`, `rioplatense` → `es-AR`. At runtime the app
asks the speech service for a voice in that language and falls back to `es-MX`
then `es-ES` if none is installed (the installed voice list differs per
device). Speech recognition (`listening-and-pronunciation`) uses the same
language when on-device recognition supports it, else `es-ES`.

## Risks / Trade-offs

- [Markup noise in card files] → used only where usage differs; validator
  rejects malformed or unknown variants.
- [Voseo norms vary by country] → scope limited to Rioplatense; the note
  explains it.
- [Changing variant mid-course] → review states are per card/item and stay
  valid; drills simply ask different persons from then on.
- [New settings field] → CloudKit development schema change, production
  deployment before release; default keeps old records valid.

## Migration Plan

Additive. Existing users stay on `spain` (identical to today) and see the
option once in settings. Rollback: the parser ignores directives and shows
the `spain` form, so content with markup stays readable.
