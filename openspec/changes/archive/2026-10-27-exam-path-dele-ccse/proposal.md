## Why

The audit identified Russian speakers living in Spain as the segment where Lorito's
value is highest and who can pay (116.8k Russian citizens with residence permits in
Spain per Eurostat via The Moscow Times). Spanish nationality by residence requires
two exams for most applicants: DELE A2 and CCSE; DELE A2 is also asked for by
employers and programmes. Both exams have a date, a fee and a failure cost (a DELE
A2 retake costs the full fee, ≈ €130). Our 159 grammar cards and 892 exercises
already cover most of what DELE A2 tests; what is missing is the exam format, the
CCSE civics content, and a readiness signal.

## What Changes

- New section «Экзамены DELE и CCSE». Inside it, the track «Путь к гражданству»
  bundles DELE A2 + CCSE for nationality applicants; DELE A2 is also usable on its
  own (e.g. for work).
- **DELE A2:** practice and timed mock exams in the official four-part format
  (reading 60 min, listening 40 min, writing and interaction 45 min, speaking and
  interaction 12 min + 12 min preparation; 25 points each), scored per group with
  "≥ 30/50 in Group 1 (reading + writing) and ≥ 30/50 in Group 2 (listening +
  speaking)". Writing and speaking are self-assessed against rubrics; speaking
  recordings stay on the device.
- **CCSE:** the official Instituto Cervantes question bank imported with source
  attribution (owner decision 2026-10-27), practised with spaced repetition as
  `ccse:<id>` review items, and 25-question mock tests in 45 minutes, pass at ≥ 15.
- **Exam date and readiness:** exam date and kind come from `study-goal`
  (`examDate`, `examKind`); a countdown and a readiness score per part, labelled
  «Скорее сдадите» / «На грани» / «Пока рано».
- **Pro:** the section is the Lorito Pro feature (`lorito-pro`); a fixed free
  preview set (one CCSE mock, one DELE A2 reading task) stays free.

## Capabilities

### New Capabilities
- `exam-path`: exam tracks, item types, mock timing, scoring and expiry, CCSE bank
  practice and quota, readiness, exam date countdown, preview set, attribution.

### Modified Capabilities
<!-- None: review items, quotas and learning days come from learning-platform-foundation. -->

## Impact

- **Content**: `content/exams/` — exam definitions (sections, timings, groups,
  thresholds, `verifiedOn`), DELE A2 tasks, CCSE items imported from the Cervantes
  manual with `source` and `edition`; importer + validator in `tools/`.
- **Domain**: `ExamDefinition`, `ExamItem`, `MockScorer`, `MockTimer`,
  `ReadinessCalculator` (pure); CCSE items are `ItemKind.ccse` review items.
- **Persistence**: `MockAttemptRecord` and a `ccseDailyNewLimit` setting, synced per
  `cloudkit-schema-release`; speaking audio files local only.
- **Features**: section entry on Today and Catalog; mock runner; results; rubric
  self-assessment; attribution screen.
- **Depends on**: `learning-platform-foundation` (review items, combined new-item
  budget, local learning day), `cloudkit-schema-release`, `study-goal`,
  `spanish-audio`, `listening-and-pronunciation`, `lorito-pro`, `product-analytics`.
