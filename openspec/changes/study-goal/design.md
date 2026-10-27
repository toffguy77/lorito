## Context

`daily-plan` composes the day's queue purely from review states, the user's
scope and `UserSettings.dailyNewCardCount` (default 1). Cards are ordered by
level and `order`; a card is "introduced" once it has a `CardReview`. Today shows
counts and the start action. There is no notion of a deadline.

## Goals / Non-Goals

**Goals:** one optional goal with a date; a pace that is derived, not guessed;
an honest status; zero change for users without a goal.

**Non-Goals:** multiple concurrent goals; goals measured in minutes or streak
days; exam content (→ `exam-path-dele-ccse`); goal-aware notifications; changing
review scheduling.

## Decisions

**Goal = target level + target date.** `StudyGoal { kind: .level | .deleA2,
targetLevel, targetDate, createdAt }`. "Reached" means every non-suspended card
of all levels up to `targetLevel` within the user's selected themes has been
introduced. DELE A2 is a labelled `.level` goal with `targetLevel = A2`; its date
is entered by the user (we do not ship exam calendars).

**Pace.** `pace = ceil(cardsLeft / max(daysLeft, 1))`, clamped to
`[GoalConstants.minDailyNew = 1, GoalConstants.maxDailyNew = 10]`. `daysLeft`
counts today through the target date inclusive. Pure, injected "today".
Recomputed whenever the plan is recomputed, so missed days raise the pace
automatically. When the clamp binds at the maximum, status is "behind" even on
day one: the goal is not reachable at a sane pace, and the UI says so.

**Status.** Expected introduced count at today = linear interpolation from
`createdAt` (introduced count then) to the target date (total). `onTrack` when
actual ≥ expected; otherwise `behind(by: expected − actual)`.

**Lifecycle.** `active` → `achieved` when reached (first check after the last
card is introduced); → `expired` when the date passes unreached. Achieved and
expired goals stop pacing; Today shows the end state once, then the goal card
disappears until the user sets a new goal.

**Daily-plan integration without touching its rules.** The plan's existing
new-card limit input is fed `GoalPacing.pace(...)` when a goal is active, else
`UserSettings.dailyNewCardCount`. The composer itself is unchanged.

**Persistence.** `UserSettings.goal: StudyGoal?` encoded with defaults so older
synced records decode as `nil`.

## Risks / Trade-offs

- [Pace spikes after a missed week] → the max clamp caps it; status turns
  "behind" instead of flooding the queue.
- [Introduced ≠ learned] → acceptable for pacing; long-term memory is shown by
  `progress-insights` and level milestones in `weekly-recap-and-milestones`.
- [Two devices edit the goal] → last-writer-wins like other `UserSettings`
  fields per `cloudkit-sync`.

## Migration Plan

Additive; `goal` defaults to nil. Rollback: ignore the field; the plan falls
back to `dailyNewCardCount`.
