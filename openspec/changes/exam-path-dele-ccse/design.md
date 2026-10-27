## Context

Exam facts (re-checked 2026-10-27, [Jobbatical guide](https://www.jobbatical.com/es/blog/guide-passing-spain-ccse-dele-a2-exams);
fees and schedules change — confirm at cervantes.es before shipping copy):

| Exam | Format | Pass rule | Fee |
| --- | --- | --- | --- |
| DELE A2 | Reading 60 min · Listening 40 min · Writing & interaction 45 min · Speaking & interaction 12 min + 12 min prep | ≥ 30/50 in Group 1 (reading + writing) AND ≥ 30/50 in Group 2 (listening + speaking); no overall 60% threshold | ≈ €130, retake = full fee |
| CCSE | 25 multiple-choice / true-false questions, 45 min | ≥ 15 correct (60%) | €85, includes one free second attempt within 18 months |

Segment size: 116.8k Russian citizens with residence permits in Spain
([The Moscow Times, Eurostat migr_resvalid](https://ru.themoscowtimes.com/2026/10/06/v-evrosoyuz-posle-nachala-voini-uehali-bolee-100-000-rossiyan-a207888)).

Existing building blocks: cards + exercises (`practice-exercises`), SRS
(`srs-engine`), daily plan, Markdown rendering, content pipeline (Python stdlib).

## Goals / Non-Goals

**Goals:** realistic mock exams with correct timing and scoring; a CCSE bank
practiced with SRS; a readiness score users trust; content we are allowed to ship.

**Non-Goals:** automatic grading of free writing or speech (self-assessment only in
v1); DELE levels other than A2; official affiliation with Instituto Cervantes;
booking exams in-app (link-out to the official site is informational only).

## Decisions

**Two tracks, one engine.** `MockExam` = ordered sections with a time limit and a
list of `ExamItem`s. DELE groups sections into scoring groups; CCSE is one section.
`MockScorer.score(attempt) -> MockResult` is pure: per-section raw points scaled to
the section maximum, per-group totals, and `passed` = every group ≥ its threshold.
Thresholds live in the exam definition (data), not code, so a rule change is a
content edit.

**Item types.** Reuse `ExerciseKind` where it fits (multiple-choice, true/false as
two-option MC, matching, fill-in-the-blank). New: `listeningTask` (audio + MC),
`writingTask` (prompt + rubric), `speakingTask` (prompt + prep timer + record +
rubric). Rubric items are checkboxes mapped to points; the user ticks what they did.

**Authored bank, licence per item.** Every exam item carries `source` (`lorito` or a
named third party) and `licence`. `validate.py` fails a build that includes an item
whose source is not `lorito` unless its licence is in an allow-list file. This keeps
the open question (may we use Instituto Cervantes' published CCSE materials?)
from blocking development: we author our own items until it is answered.

**CCSE practice uses the SRS.** Each CCSE item is a schedulable unit with its own
`ReviewState`, isolated from grammar cards (separate daily quota) so exam prep never
crowds out the grammar plan unless the user chooses "exam mode".

**Readiness score.** `ReadinessCalculator` (pure): per DELE group, a weighted blend
of the last three mock group scores and the long-term mastery of the grammar cards
mapped to that group; for CCSE, share of bank items in review with interval ≥ 7
days plus last mock score. Output: 0–100 per part + "likely pass / borderline / not
yet". Weights are constants tested against fixtures; copy never promises a pass.

**Exam date.** Stored once and shared with `study-goal` (the goal type "exam" with a
date). Countdown and plan pacing come from `study-goal`; this change only reads it.

**Timer and interruption.** Mock timer is based on wall-clock start time persisted
in the attempt, so backgrounding the app does not pause the exam (like the real one);
the user may abandon a mock, which is stored as incomplete and excluded from
readiness.

## Risks / Trade-offs

- [Licensing of official materials] → authored bank + allow-list gate; legal check
  is an explicit owner task before any third-party item ships.
- [Self-assessed writing/speaking inflates readiness] → those parts are shown
  separately and labelled self-assessed; readiness never exceeds "borderline" for a
  group whose productive part has no mock attempt.
- [Exam rules change] → thresholds and timings are content data with a "verified on"
  date shown in the exam info screen.
- [Content volume] → v1 target: 3 full DELE A2 mocks and a CCSE bank sized to give
  at least 4 non-repeating 25-question mocks; exact counts set in content tasks.

## Migration Plan

Additive. New content folder and records; no schema change to existing records.
Rollback: hide the entry point; attempts remain in the store unused.
