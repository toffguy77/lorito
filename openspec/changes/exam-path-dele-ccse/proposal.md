## Why

The audit identified Russian speakers living in Spain as the segment where Lorito's
value is highest and who can pay (116.8k Russian citizens with residence permits in
Spain per Eurostat via The Moscow Times). Spanish nationality by residence requires
two exams for most applicants: DELE A2 and CCSE. Both have a date, a fee and a
failure cost (a DELE A2 retake costs the full fee, ≈ €130). Nothing in the App
Store prepares Russian speakers for both exams with explanations in Russian. Our
159 grammar cards and 892 exercises already cover most of what DELE A2 tests; what
is missing is the exam format, the CCSE civics content, and a readiness signal.

## What Changes

- New «Путь к гражданству» section with two tracks: **DELE A2** and **CCSE**.
- **DELE A2 track:** practice and timed mock exams in the real four-part format
  (reading 60 min, listening 40 min, writing and interaction 45 min, speaking and
  interaction 12 min + 12 min preparation), scored per group with the pass rule
  "≥ 30/50 in Group 1 (reading + writing) and ≥ 30/50 in Group 2 (listening +
  speaking)". Writing and speaking are self-assessed against published-style rubrics.
- **CCSE track:** a question bank of civics and culture questions, practice with
  spaced repetition, and 25-question mock tests in 45 minutes, pass at ≥ 15 correct.
- **Our own authored question bank.** Whether Instituto Cervantes materials may be
  reused is an open question; the content model supports authored items with a
  per-item source/licence field, and shipping any third-party item is gated on a
  licensing check.
- **Exam date and readiness:** the user sets an exam date (shared with
  `study-goal`), sees a countdown, and a readiness score per part computed by a
  pure function from mock results and the mastery of mapped grammar cards.
- The section is a Pro feature (`lorito-pro`); a free preview (one CCSE mock and
  one DELE reading task) stays available.

## Capabilities

### New Capabilities
- `exam-path`: exam tracks, item types, mock exam timing and scoring, CCSE bank
  practice, exam date countdown, readiness score, content and licensing rules.

### Modified Capabilities
<!-- None: the daily plan, SRS and exercises are reused, not changed. -->

## Impact

- **Content**: new `content/exams/` (DELE A2 tasks, CCSE items) with front matter
  incl. `source` and `licence`; `tools/validate.py` / `compile.py` extended; audio
  for listening tasks (recorded or synthesized via `spanish-audio`).
- **Domain**: `ExamItem`, `MockExam`, `MockScorer` (pure), `ReadinessCalculator`
  (pure), CCSE items scheduled by the existing SRS.
- **Persistence**: `MockAttemptRecord` (CloudKit-friendly, optional fields only).
- **Features**: «Путь к гражданству» entry on Today and in Catalog; mock runner with
  timer; results screen; rubric self-assessment.
- **Depends on**: `spanish-audio` (listening), `listening-and-pronunciation`
  (speaking practice), `study-goal` (exam date), `lorito-pro` (gating),
  `product-analytics` (funnel events). Archived base: `plumaje-design-system`,
  `recall-first-study`.
