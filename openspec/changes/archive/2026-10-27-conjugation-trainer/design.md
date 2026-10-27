## Context

Lorito's grammar cards already explain every tense and mood from A1 to C2
(e.g. A1 "Presente: правильные глаголы -ar -er -ir"), and `practice-exercises`
uses `fill-in-the-blank` for a few hand-written conjugation prompts. There is no
systematic drill of verb forms. The SRS (`srs-engine`) schedules `ReviewState`
values keyed by a string `cardID`; the daily plan (`DailyPlanner`) currently
treats every due `ReviewState` in the store as a due card (`request.reviews`
filtered by `DueSelection.isDue`). Study events (`StudyEvent.cardID`) feed the
streak and counts. CloudKit sync is on for the private database. `learning-platform-foundation`
defines review-item kinds (`conj:` ids), card-only counting, the combined daily
new-introduction budget, the local learning day and the rule that only the
first graded review of an item per learning day updates memory.

## Goals / Non-Goals

**Goals:**
- Drill verb forms with spaced repetition, scoped to tenses the learner has
  studied, with the paradigm data generated and validated by the pipeline.
- Reuse the scheduling operation, review store and study events; no new
  persisted type, no backend.
- Strict, explainable checking: accents matter in Spanish verb forms
  (`hablo` ≠ `habló`).

**Non-Goals:**
- Voseo and other regional paradigms (→ `regional-variants`, which extends the
  paradigm data with a `vos` person).
- Compound tenses beyond those listed in the tenses registry; imperatives with
  clitics (`dímelo`) — later.
- Free sentence production; audio output is optional via `spanish-audio`.

## Decisions

**SRS unit = verb × tense, persons rotate.** One review item per
`(verb, tense)`, id `conj:<infinitive>:<tense-id>`. Each review asks two
persons chosen deterministically from the item id and the number of graded
study events recorded for the item (pure function), cycling through the
variant's person set over time. The event count is used rather than
`repetitions`, which resets to 0 on Опять and would repeat the same persons. Alternative — one item per
verb × tense × person — would create 6× more items (100 verbs × 14 tenses ×
6 persons = 8 400) and flood the queue with near-duplicates. The grade of a
review is the worse of the two answers.

**Namespaced ids in the existing review store.** `ReviewState.cardID` and
`StudyEvent.cardID` are plain strings; conjugation items use the `conj:`
prefix defined by `learning-platform-foundation`, which also makes the card
plan, card counts and catalog statuses consider `.card` items only. No new
record type is needed. Study events of drills count toward the streak —
practising is studying — but not toward card counts.

**Person set per variant.** Spain asks yo, tú, él, nosotros, vosotros, ellos.
Latin America and Rioplatense person sets are defined by `regional-variants`
(no vosotros; vos instead of tú for Rioplatense). The trainer takes the person
set as an input and never hard-codes it.

**Reflexive verbs.** Forms of reflexive verbs (`levantarse`) are expected with
the pronoun (`me levanto`). An answer whose verb form is right but lacks or
misplaces the pronoun is reported as "почти" with the full form and graded
Трудно; the prompt shows the person and «(возвратный)».

**Tense unlocking follows the grammar card.** `tenses.json` maps each tense to
the card that teaches it (e.g. `presente` → the A1 present-tense card). A tense
is unlocked when (a) its card's level is in the learner's included levels and
(b) that card has a `ReviewState` (studied at least once). Pure function of
catalog + review states + settings.

**Opt-in quota and due cap.** `UserSettings` gains `dailyConjugationCount`:
0 (off) for everyone until the learner enables the trainer, then 3 by default.
New conjugation items count against the combined daily new-introduction
budget of `learning-platform-foundation` (an item counts as new on the learning
day of its first study event). New items are introduced in verb frequency
order within unlocked tenses, earliest-unlocked tense first. Due conjugation
reviews are capped at 20 per learning day (most overdue first, then id) so
100 verbs × 14 tenses can never flood a session; the rest wait. Only the first
graded review of an item per learning day updates its memory state.

**Accent-aware checking.** `ConjugationChecker.check(expected:typed:)`:
1. exact match after trimming and lowercasing → correct, grade Хорошо;
2. match only after removing diacritics (á→a, ñ→n, ü→u) → "почти" with the
   accented form highlighted, grade Трудно;
3. otherwise → incorrect, grade Опять, the correct form shown.
Rationale: written accents distinguish forms (`hablo` present vs `habló`
preterite), so they cannot be ignored as in `fill-in-the-blank`; but treating a
missing tilde as a full failure punishes typing on a Russian keyboard layout.
The keyboard row offers `á é í ó ú ñ ü` buttons.

**Content format: JSON, generated regulars.**
- `content/conjugation/tenses.json`: `[{id, es, ru, mood, level, card, order}]`.
- `content/conjugation/verbs/<infinitive>.json`:
  `{infinitive, rank, ru, model: "ar"|"er"|"ir"|"irregular", reflexive?,
  forms?: {<tense-id>: [yo, tú, él, nosotros, vosotros, ellos]}}`.
  For `model` ar/er/ir the pipeline generates every tense; `forms` overrides
  any tense (stem-changing and irregular verbs). A verb with `model:
  irregular` must list `forms` for every tense in the registry.
- Generation lives in `tools/conjugate.py` (stdlib), unit-tested against
  hand-checked paradigms of `hablar`, `comer`, `vivir`.
- Frequency rank: from an openly licensed list, e.g. the OpenSubtitles-derived
  [FrequencyWords](https://github.com/hermitdave/FrequencyWords) (content
  CC BY-SA 4.0) — owner decision 2026-10-27: even rank-only use is treated as an adaptation, so `content/conjugation/` is licensed CC BY-SA 4.0 with a `LICENSE` file; only the rank number is stored; attribution goes to the
  About screen's licenses list.

**Explanation link.** Every drill item shows a link to its tense's grammar
card; after an incorrect answer the card's relevant table is one tap away.

## Risks / Trade-offs

- [Generated forms wrong for edge cases (orthographic changes: `buscar` →
  `busqué`, `llegar` → `llegué`)] → model these as `forms` overrides, plus
  pipeline tests on a fixed list of orthographic-change verbs.
- [Namespaced ids leak into grammar views] → `ItemKind` filtering from
  `learning-platform-foundation`; a test that a `conj:` review never appears in
  the card queue.
- [Queue overload] → opt-in, low default, combined budget and a 20/day due cap.
- [`dailyConjugationCount` is a new field on the synced settings record] →
  optional with an inline default, mapped both ways and released per
  `cloudkit-schema-release` (schema export, production deploy before release).
- [Accent rule feels harsh/lenient] → grade mapping is one pure function;
  revisit with `product-analytics` data.

## Migration Plan

Additive. Existing review states are untouched; the trainer is off until the
learner enables it, and items appear only after a tense is unlocked. Rollback: remove the feature; leftover `conj:`
review states are ignored by the card plan by design.
