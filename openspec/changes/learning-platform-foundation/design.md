## Context

Code facts (LoritoKit at `456f19a`):
- `DailyPlanner.selectNew` seeds `introduced` with every id that has a review state
  and introduces up to `dailyNewCardCount` more; it has no notion of "introduced
  today". `TodayModel.refresh()` subtracts ids graded today from the recomputed
  queue, so each refresh after grading a new card offers a fresh one.
- Day math uses `Calendar(identifier: .gregorian)` with `TimeZone(identifier: "UTC")`
  in `StatsCalculator`, `DueSelection`, `SpacedRepetitionScheduler`,
  `StudyGrade+Domain` and `DailyTrap`.
- `ExercisePracticeService` → `GradingService.grade` applies the scheduler on every
  auto-checked answer.
- `CardBodyParser` is declared in `DesignSystem/Components/CardContentView.swift`.
- `StudyEvent` / `ReviewState` key items by a plain `cardID` string.

## Goals / Non-Goals

**Goals:** fix the unlimited-new-cards bug; give every later change one shared
contract for item kinds, quotas, the day boundary, memory updates and Spanish-text
gestures; keep Domain pure.

**Non-Goals:** changing the scheduler math (fsrs-scheduler); new quotas themselves
(owned by conjugation-trainer, vocabulary-decks, exam-path-dele-ccse, study-goal);
the audio engine (spanish-audio).

## Decisions

**Item ids carry their kind.** `ItemKind.parse(_ id: String)`:
`^[A-C][12]-\d{2}$` → `.card`; `conj:<verb>:<tense>` → `.conjugation`;
`word:<lemma>` → `.word`; `ccse:<id>` → `.ccse`; anything else → `.unknown`
(ignored by planners, kept in storage). No new field: the prefix is the contract,
so old data needs no migration.

**Introduction ledger.** An item is "introduced on day D" when its earliest graded
`StudyEvent` falls on D. `IntroductionLedger(events:day:)` is pure. Every new-item
quota (cards, conjugations, words, CCSE) subtracts the items introduced today from
its limit. The planner passes the remaining allowance to `selectNew`; Today stops
offering new items once it is spent.

**Combined budget.** `DailyBudget` caps the sum of new introductions across kinds
per day (default 10). Card new-limit = `dailyNewCardCount` (existing setting).
Conjugation and word quotas default to 0 for every user and only switch on when
the user enables them; defaults when enabled are owned by their changes. When the
sum would exceed the budget, cards are served first, then conjugations, words,
CCSE.

**Local learning day.** `LearningDay` = the device's current time zone, local
midnight boundary. Rationale: users think in local days; the audience lives from
UTC−3 to UTC+3. Historical events are re-bucketed on read; a user who changes time
zone may see one day merge or split — accepted and documented. Anki's 4 a.m.
rollover was considered and rejected for now: reminders and streak copy talk
about "сегодня" in plain local terms.

**First grade per day updates memory.** `GradingService` applies the scheduler
only when the item has no graded event earlier on the same learning day; later
grades that day (exercises, in-session relearn) are recorded as `StudyEvent`s but
leave `ReviewState` unchanged. This also gives FSRS a clean "one review per day"
input.

**In-session relearn.** A card graded Опять is appended once to the end of the
current session queue (not persisted). Its second grade is logged only (rule
above), which makes the «сегодня» caption true without changing scheduling.

**Spanish spans as links.** `CardBodyView`'s MarkdownUI theme renders emphasis
whose text contains a Latin letter as a link `lorito-es://span?text=<urlencoded>`;
`SpanishText` does the same. A view-level `OpenURLAction` handles the scheme:
tap → speak (no-op until spanish-audio ships); long-press → context menu whose
items are registered by features («Произнести», «В мои слова», «Варианты»). Spike
first: confirm MarkdownUI link styling keeps the Spanish font and that long-press
works on links inside `Text` (fallback: a sheet listing the spans of the block).

**Parser move.** `CardBodyParser` and `CardBlock`/`CalloutKind` move to Domain;
DesignSystem keeps the views and re-exports nothing (call sites import Domain).

## Risks / Trade-offs

- [Local day re-bucketing changes past streaks for users far from UTC] → computed,
  not stored; a one-time shift is accepted; mention in release notes.
- [Budget default too low/high] → setting is a constant now; product-analytics
  measures session length before exposing it.
- [Link-based spans look like links] → theme removes underline and uses the Spanish
  style; VoiceOver reads them as text with a "Произнести" custom action.

## Migration Plan

No data migration. Ship before any change that adds a quota or a new item kind.
Rollback: revert; data is untouched.
