## Context

Exam facts (checked 2026-10-27; fees and schedules change — confirm before shipping copy):

| Exam | Format | Pass rule | Fee |
| --- | --- | --- | --- |
| DELE A2 (2020 version) | Reading 60 min, 4 tasks, 25 pts · Listening 40 min, 4 tasks, 25 pts · Writing & interaction 45 min, 2 tasks, 25 pts · Speaking & interaction 12 min + 12 min prep, 3 tasks, 25 pts ([Instituto Cervantes](https://examenes.cervantes.es/es/dele/examenes/a2)) | ≥ 30/50 in Group 1 (reading + writing) AND ≥ 30/50 in Group 2 (listening + speaking); no overall 60% threshold ([Jobbatical](https://www.jobbatical.com/es/blog/guide-passing-spain-ccse-dele-a2-exams)) | ≈ €130, retake = full fee |
| CCSE | 25 multiple-choice / true-false questions, 45 min | ≥ 15 correct (60%) ([Jobbatical](https://www.jobbatical.com/es/blog/guide-passing-spain-ccse-dele-a2-exams)) | €85, one free second attempt within 18 months |

Segment: 116.8k Russian citizens with residence permits in Spain
([The Moscow Times, Eurostat](https://ru.themoscowtimes.com/2026/10/06/v-evrosoyuz-posle-nachala-voini-uehali-bolee-100-000-rossiyan-a207888)).

**Owner decision 2026-10-27:** Instituto Cervantes materials MAY be used. The CCSE
bank imports the official Cervantes question bank (the CCSE preparation manual) with
source attribution in content and in the app.

Platform contract from `learning-platform-foundation`: review item ids
(`A1-07`, `conj:…`, `word:…`, `ccse:<id>`), one combined daily new-introduction
budget across kinds, quotas spent against items whose first StudyEvent is on the
current learning day, learning day = local calendar day, only the first graded
review per item per learning day updates memory. Synced fields follow
`cloudkit-schema-release`.

## Goals / Non-Goals

**Goals:** realistic mock exams with correct timing and scoring; the official CCSE
bank practised with SRS; a readiness score users trust; clear attribution.

**Non-Goals:** automatic grading of writing or speech (self-assessment in v1); DELE
levels other than A2; official affiliation with Instituto Cervantes; exam booking.

## Decisions

**Two tracks, one engine.** `MockExam` = ordered sections with a time limit and
`ExamItem`s; DELE groups sections into scoring groups; CCSE is one section.
`MockScorer.score(attempt) -> MockResult` is pure. Thresholds and timings are content
data with `verifiedOn`, not code.

**Item types.** Reuse `ExerciseKind` (multiple-choice; true/false as two-option MC;
matching; fill-in-the-blank). New: `listeningTask`, `writingTask` (prompt + rubric),
`speakingTask` (prompt + prep timer + optional recording + rubric).

**CCSE import.** `tools/import_ccse.py` reads a transcription of the official manual
(`content/exams/ccse/source/<edition>.md`) into one file per question with `source:
cervantes-ccse`, `edition`, the correct answer and a Russian explanation field.
`validate.py` checks ids, answer keys and that every item carries `source` and
`edition`. An owner task re-runs the import when Cervantes publishes a new edition;
removed questions are retired (kept for history, not scheduled).

**CCSE spaced repetition.** Each question is a review item `ccse:<id>` scheduled by
the existing engine. CCSE introductions draw from the foundation's combined daily
new-introduction budget, capped by a setting `ccseDailyNewLimit` (default 5, 0 =
off), so CCSE never takes more than its cap from the day's budget. "Exam mode" is
dropped: users who want more CCSE raise the cap. Due CCSE reviews appear in the
daily session like other due items.

**Preview is content-based.** Exam definitions mark a fixed preview set (one CCSE
mock form, one DELE A2 reading task) with `preview: true`. No counters; reinstalling
changes nothing.

**Timer and expiry.** Remaining time = section limit − (now − persisted section
start). Backgrounding does not pause. When time runs out the section is submitted
as is (unanswered = incorrect); if the app was not running, the attempt is closed
the same way on next launch. A user can abandon explicitly; abandoned attempts are
excluded from readiness.

**Readiness.** `ReadinessCalculator` (pure) blends the last three complete mocks per
part with mastery of mapped grammar cards (DELE) or of `ccse:` items (CCSE). Labels:
«Скорее сдадите», «На грани», «Пока рано». A DELE group with no productive-part
attempt is capped at «На грани». Copy never promises a pass.

**Speaking recordings.** Stored only in the app's local container, not synced, max
2 minutes per task and the latest 20 recordings kept; deleting a mock deletes its
recordings.

**Exam date.** Read from `study-goal` (`examKind`, `examDate`); this change only
displays the countdown.

## Risks / Trade-offs

- [Manual transcription errors] → validator checks answer keys; each item shows its
  manual reference so users can verify.
- [Self-assessed parts inflate readiness] → labelled self-assessed; cap rule above.
- [Exam rules change] → thresholds/timings are data with a visible `verifiedOn`.

## Migration Plan

Additive. New content, records per `cloudkit-schema-release`. Rollback: hide the
entry point; attempts remain stored and unused.
