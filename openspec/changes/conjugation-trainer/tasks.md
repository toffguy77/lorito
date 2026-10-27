## 0. Dependencies

- [ ] 0.1 `learning-platform-foundation` and `cloudkit-schema-release` applied

## 1. Content model & schema

- [ ] 1.1 Document `content/conjugation/` (tenses registry, verb files, person order, generated vs overriding forms) in `content/schema.md`
- [ ] 1.2 Author `content/conjugation/tenses.json`: each drillable tense/mood mapped to its grammar card (A1–C1), reviewed against the card list
- [ ] 1.3 Author the first 100 verb files ordered by rank from FrequencyWords (CC BY-SA 4.0; owner decision 2026-10-27: `content/conjugation/` is treated as an adaptation and ships with its own `LICENSE` (CC BY-SA 4.0); attribution in the About screen via `vocabulary-decks`), with `forms` overrides for stem-changing, orthographic-change and irregular verbs and `reflexive: true` where applicable

## 2. Pipeline (TDD)

- [ ] 2.1 Write failing tests in `tools/test_pipeline.py`: generated paradigms of `hablar`, `comer`, `vivir` for every registered tense match hand-checked tables; override replaces a generated tense
- [ ] 2.2 Write failing tests: validation errors for duplicate tense id, missing/wrong-level card, file name ≠ infinitive, duplicate rank, unknown model, unknown tense in `forms`, wrong form count, incomplete irregular verb
- [ ] 2.3 Implement `tools/conjugate.py` (stdlib only)
- [ ] 2.4 Extend `tools/validate.py` and `tools/compile.py`; bundle carries tenses + full paradigms; invalid content blocks the bundle
- [ ] 2.5 Run `python3 tools/compile.py`; commit the refreshed `content.json`

## 3. Domain (TDD)

- [ ] 3.1 Failing tests: conjugation types decode from the bundle; item id format `conj:<infinitive>:<tense-id>`
- [ ] 3.2 Failing tests for tense unlocking (studied card + included level; locked otherwise)
- [ ] 3.3 Failing tests for `ConjugationPlanner`: due cap 20 (most overdue, then id), new items ≤ quota by rank within earliest-unlocked tense, default 0 (off), spending against the combined budget (first study event today), determinism with injected "today"
- [ ] 3.4 Failing tests for person rotation by graded-event count (Spain set covered in three reviews; rotation continues after Опять; person set injected) and "worse answer decides"
- [ ] 3.5 Failing tests for `ConjugationChecker`: exact → Хорошо, accent-only difference → "почти"/Трудно, wrong → Опять; trimming and case; reflexive pronoun required ("почти"/Трудно when missing)
- [ ] 3.6 Failing test: a due `conj:` review never appears in the card queue or card counts (relies on foundation `ItemKind`)
- [ ] 3.7 Implement the above; `UserSettings.dailyConjugationCount` (default 0; enabling sets 3)

## 4. Features

- [ ] 4.1 Drill screen in focus mode: infinitive + translation, tense, two person fields, accent row, check, per-person feedback, link to the tense card
- [ ] 4.2 Grading writes the review via the scheduling operation and a study event under the item id
- [ ] 4.3 Today: «Спряжения» entry with count; catalog reader of a mapped tense card: «Тренировать спряжения»
- [ ] 4.4 Settings: «Тренажёр спряжений» switch and quota (0–20); enabling sets 3
- [ ] 4.5 Persistence per `cloudkit-schema-release`: optional defaulted field, both-way mapping in `SwiftDataUserDataStore`, store round-trip test, schema export

## 5. Validation

- [ ] 5.1 `swift test` green; `python3 tools/test_pipeline.py` green
- [ ] 5.2 `xcodebuild` build; UI test: study the present-tense card → «Спряжения» appears → answer two persons → feedback → item rescheduled
- [ ] 5.3 UI test: typing without accents shows "почти" and the accented form
- [ ] 5.4 `openspec validate conjugation-trainer --strict`
