## Why

A review of the roadmap changes against the code found defects and gaps that
every later change would inherit:

- **Unlimited new cards (shipped bug).** `DailyPlanner.selectNew` treats a card
  as "new" only while it has no `ReviewState`. After a new card is graded,
  `TodayModel.refresh()` recomputes the plan, the next card becomes "new", and it
  is not in "graded today" — pressing «Начать» again introduces another card, with
  no daily limit. Every planned quota (goal pace, conjugations, words, CCSE) would
  inherit this.
- **Non-card review items** (`conj:`, `word:`, `ccse:`) are about to share
  `ReviewState` / `StudyEvent` with grammar cards; Today progress, stats, session
  summaries and catalog statuses would silently count drills as cards.
- **No combined daily load.** Several changes add their own quotas; together they
  would turn a 5-minute habit into a 30-minute chore, switched on silently for
  existing users.
- **UTC day boundary.** `StatsCalculator`, `DueSelection`, the scheduler and the
  trap of the day use a UTC calendar: in Buenos Aires the "day" flips at 21:00.
  Streak freezes, goals and shared streaks would lock this in.
- **Exercises inflate memory.** Each exercise answer grades the card through
  `GradingService`; five correct exercises on one day push the interval five times.
- **«Опять · сегодня» is not true.** Today drops every card graded today, so a card
  graded Опять never returns that day although its caption says «сегодня».
- **Gesture collisions.** Tap-to-speak, long-press «В мои слова» and variant notes
  all target Spanish spans inside MarkdownUI, which has no per-span hit testing.
- **Layering.** `CardBodyParser` lives in DesignSystem (imports SwiftUI), yet Domain
  logic (trap of the day, placement, traps) needs it.

## What Changes

- New capability `review-items`: item kinds, first-introduction accounting, a
  combined daily budget, the local learning day, and the first-grade-per-day rule.
- **Bug fix:** the new-card limit counts cards first introduced on the current
  learning day (MODIFIED `daily-plan` "New-card count limit").
- `study-flow`: cards graded Опять come back once at the end of the session.
- New capability `spanish-text-interactions`: Spanish spans become links with a
  custom scheme handled by `OpenURLAction`; tap = speak, long-press = context menu.
- Refactor: `CardBodyParser` moves into Domain (no behavior change).

## Capabilities

### New Capabilities
- `review-items`: kinds of reviewable items, quota accounting, daily budget,
  learning day, memory-update rule.
- `spanish-text-interactions`: the one gesture contract for Spanish text.

### Modified Capabilities
- `daily-plan`: the new-card limit is spent against first introductions today.
- `study-flow`: in-session relearn of cards graded Опять.

## Impact

- **Domain**: `ItemKind`, `LearningDay` (local calendar, replaces the UTC helpers
  in `StatsCalculator`, `DueSelection`, `SpacedRepetitionScheduler`,
  `StudyGrade+Domain`, `DailyTrap`), `IntroductionLedger` (first event per item),
  `DailyBudget`; `CardBodyParser` moved here.
- **Features**: `TodayModel`, `StudySessionModel` (relearn queue, budget),
  `ExerciseSessionModel` (memory update only on first grade per day), stats and
  catalog consumers filter `.card`.
- **DesignSystem**: `CardBodyView` emits `lorito-es://` links for Spanish spans;
  `SpanishText` uses the same contract.
- **Data**: no schema change. Historical events are re-bucketed by local day on
  read (no migration).
- Prerequisite for: fsrs-scheduler, study-goal, streak-protection, personal-traps,
  weekly-recap-and-milestones, conjugation-trainer, vocabulary-decks,
  exam-path-dele-ccse, grammar-lens, study-buddy, spanish-audio.
