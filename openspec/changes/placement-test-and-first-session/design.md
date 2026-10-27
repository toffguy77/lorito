## Context

Onboarding (`onboarding-and-selection`) has a level step, a theme step and, with
the pending `streak-reminders`, a reminder-time step. Exercises (`practice-exercises`)
carry `level`, `themeID`, `card` and a type; six types, five auto-checkable via
the pure `ExerciseChecker`. After onboarding `RootView` shows `MainTabView` on
Today. Mockup: `design/mockups/Onboarding.dc.html` ("Не знаю — проверить за 2 минуты").

## Goals / Non-Goals

**Goals:** a placement test that takes about two minutes, proposes a level the
user can override, surfaces personal mistakes, and leads straight into the first
session.

**Non-Goals:** marking cards as already known from test results (a later change
could seed `CardReview`); typed free-response in the test; a test outside
onboarding (Settings may reuse it later); psychometric calibration.

## Decisions

**Question pool.** Only auto-checkable types whose UI answers in one tap or a
short arrangement: multiple-choice, picture-matching, word-order. Fill-in-the-blank
and free-response are excluded to keep the test fast and unambiguous.

**Adaptive staircase.** Start at A2. Each step picks one unused exercise at the
current level, preferring a theme not yet asked at that level. Two correct
answers in a row at a level → step up; a wrong answer → step down. Stop when the
question budget (12) is spent, or once a level has been passed and the level
above it failed. Proposed level = highest level with ≥ 2 correct and no more
wrong than right; A1 if none. Constants live in Domain next to the algorithm.

**Deterministic.** `PlacementTest` takes the exercise pool, an injected seed and
the answer history, and returns the next exercise or a result. Same inputs →
same sequence; tests can replay a scripted session.

**Traps.** For each failed exercise, take the first «Частые ошибки» item of its
card via `CardBodyParser` (`.mistakes` callout); deduplicate by card; keep up to
three, most recent failure first. No mistakes section → card skipped.

**SRS isolation.** The test uses `ExerciseChecker` for correctness only; it never
calls the apply-and-persist operation and writes no `StudyLog`/`ExerciseAttempt`.

**First session hand-off.** Completing onboarding sets a transient
`startFirstSession` flag on the root navigation; MainTabView consumes it once
and presents the study session if today's queue is non-empty, else shows Today.
Not persisted: a relaunch never auto-starts a session.

## Risks / Trade-offs

- [Too few exercises at a level for unique themes] → fall back to any unused
  exercise at that level; if none, treat the level as untestable and stop.
- [Test misjudges level] → result screen always offers the manual list; the
  proposed level is pre-selected, not forced.
- [Auto-start feels abrupt] → session opens with its normal close button; the
  first card is the front side (recall-first), not a grade decision.

## Migration Plan

Additive. Existing users never see onboarding again, so nothing changes for
them. Rollback: hide the test action; manual selection path is unchanged.
