## Context

Onboarding (`onboarding-and-selection`) has a level step and a theme step; the
pending `streak-reminders` appends a reminder-time step. Exercises carry `level`,
`themeID`, `card` and a type; the pure `ExerciseChecker` decides correctness.
`daily-plan` introduces new cards in ascending `order` across included levels, so
a user choosing B1 starts with A1 card 1. `learning-platform-foundation` (sibling,
dependency) defines the local learning day, the new-introduction budget counted
by first `StudyEvent` per day, item kinds, and moves `CardBodyParser` to Domain.
Mockup: `design/mockups/Onboarding.dc.html`.

## Goals / Non-Goals

**Goals:** a test of a few minutes that is statistically sane, a result that
actually changes the plan, and a first session big enough to feel like learning.

**Non-Goals:** psychometric calibration; testing outside onboarding (Settings may
reuse it later); testing C1/C2 separately from B2 beyond the same block rule;
typed answers in the test.

## Decisions

**Pool.** Auto-checkable, fast types only: multiple-choice, picture-matching,
word-order. Within a level, exercises are drawn from distinct themes where
possible, using an injected seed for determinism.

**Blocks, not a staircase.** Each level is tested with a block of
`PlacementConstants.itemsPerLevel = 3` questions; a level passes with ≥ 2
correct (`passThreshold = 2`). Order: start with A2. If A2 passes, test B1, then
B2, … until a level fails or C2 passes. If A2 fails, test A1 once and stop. No
early stop inside a block. Maximum 5 blocks (A2…C2, 15 questions); a typical run is 2–3 blocks (6–9 questions, about two minutes).

**Proposal.** Highest passed level H (all levels below H are treated as passed
because the test only climbs after passes). Proposed `targetLevel` = the level
after H (C2 if H is C2); with no passed level, A1. Known levels = A1…H.
Example: A2 3/3, B1 1/3 → H = A2, proposed target B1, known A1–A2.

**Known levels change introduction order.** `UserSettings.placementKnownLevel = H`
is stored when the user accepts. The daily plan then introduces new cards of
levels above H first (in their `order`), and cards of levels ≤ H only after
those are exhausted. Cards stay in scope, so gaps in "known" levels still surface
later. Manual level choice leaves the field nil (plan unchanged).

**«Пропустить то, что я знаю» (opt-in).** Cards whose exercise was answered
correctly in the test, at a level ≤ H, are seeded by applying the scheduler to a
new state with grade Хорошо and the onboarding learning day as "today" (the
scheduler's normal first interval). Seeding writes `CardReview` only: no
`StudyEvent`, no streak, and it does not spend the new-introduction budget.
Failed cards are never seeded.

**Traps.** For failed exercises, the first «Частые ошибки» item of the card;
dedupe by card; up to 3, most recent first; cards without a mistakes section
skipped.

**First session.** On completing onboarding, a one-off flag gives the first
learning day a new allowance of `max(3, dailyNewCardCount)` within the
foundation's budget; failed-test cards (if in scope and not seeded) are
introduced first, then normal plan order. The session opens directly; on an
empty queue, Today. Not persisted beyond that day; relaunch never auto-starts.

**Onboarding order (owned here).** Level (manual or test) → themes →
reminders. Goal (`study-goal`) and regional variant (`regional-variants`) are
offered as dismissible prompts on Today after the first completed session, one
at a time.

## Risks / Trade-offs

- [3 items per level is noisy] → the threshold is forgiving (2/3) and the user
  can always override; known levels are deprioritised, not removed.
- [Seeding wrong cards] → opt-in, only correctly answered cards, modest interval;
  a later Опять corrects it through normal SRS.
- [Fewer than 3 exercises at a level] → use what exists; a level with < 2 usable
  exercises is treated as untestable and the test stops below it.

## Migration Plan

Additive; existing users never see onboarding again and have
`placementKnownLevel = nil`. Schema change follows `cloudkit-schema-release`.
Rollback: hide the test action; the plan ignores a nil known level.
