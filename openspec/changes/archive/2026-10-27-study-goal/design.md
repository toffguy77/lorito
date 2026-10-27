## Context

`daily-plan` composes the queue from review states, scope and the new-card limit
(`UserSettings.dailyNewCardCount`, default 1). `learning-platform-foundation`
(dependency) defines the local learning day, item kinds (only `.card` counts as a
card) and a combined daily new-introduction budget. `cloudkit-schema-release`
requires new synced fields to be optional scalars. `exam-path-dele-ccse`
(sibling) needs an exam date that is independent of card progress.

## Goals / Non-Goals

**Goals:** an optional level goal that can only speed the user up; an exam date
with its own lifecycle; an honest status; zero change for users without goals.

**Non-Goals:** several level goals at once; minutes-based goals; exam content
(→ `exam-path-dele-ccse`); goal-aware notifications; changing review scheduling.

## Decisions

**Two independent parts.** *Level goal*: `goalTargetLevel` + `goalTargetDate`
(+ `goalStartDate`, `goalStartIntroduced` captured at creation, `goalState`
active/achieved/expired). *Exam*: `examKind` (deleA2 / ccse) + `examDate` +
`examDone`. The "DELE A2" preset writes a level goal (A2, date = exam date) and an
exam (deleA2, same date). Either part can exist alone.

**Reached / achieved.** Level goal reached when every non-suspended `.card` item
up to the target level within selected themes is introduced; then pacing stops.
Exam achieved when `examDate` has passed (learning day after it) or `examDone`.

**Pace never lowers the user's setting.**
`pace = ceil(cardsLeft / max(learningDaysLeft, 1))`, learning days counted in the
device's local calendar from today through the target date inclusive.
`newPerDay = max(pace, dailyNewCardCount)`, then capped by the foundation's daily
new-introduction budget. Recomputed with the plan, so missed days raise it.

**Status.** Expected introduced count today = linear interpolation from
(`goalStartDate`, `goalStartIntroduced`) to (target date, total). On track when
actual ≥ expected; else behind by the difference. If the budget caps `newPerDay`
below `pace`, status is behind. Copy uses `RussianPlural`: «отстаёте на 1 карточку /
2 карточки / 5 карточек»; days left likewise.

**Lifecycle display.** Achieved / expired level goals and achieved exams show
their end state once on Today, then hide until a new goal is set.

**Prompt placement.** No onboarding step; after the first completed session,
Today shows «Есть дедлайн?» via the prompt slot owned by
`placement-test-and-first-session`; dismiss leaves no goal.

## Risks / Trade-offs

- [Pace above budget] → budget wins; status turns behind rather than flooding.
- [Introduced ≠ learned] → acceptable for pacing; long-term memory comes from
  `progress-insights`.
- [Concurrent edits on two devices] → last writer wins per field, like other
  `UserSettings` fields.

## Migration Plan

Additive optional fields, nil by default; dev schema exported and production
deployed per `cloudkit-schema-release`. Rollback: ignore the fields; the plan
falls back to `dailyNewCardCount`.
