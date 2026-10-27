## Why

Onboarding asks the user to self-assess their level from six labels. People who
"know some Spanish" guess, and a wrong guess hurts on day one: too low and the
first cards are boring, too high and the first session is a wall of unknown rules.
After onboarding the user lands on Today and has to find "Начать" themselves, and
with the default of 1 new card per day the first session is a single card — the
activation moment is both delayed and tiny. We already ship 892 exercises tagged
by level and card, enough to measure level in a few minutes, change what gets
studied, and show the user their first personal mistakes.

## What Changes

- **Placement test option in onboarding:** next to the manual level list,
  "Не знаю — проверить за 2 минуты" starts a block-based test built from existing
  auto-checkable exercises: 3 questions per level, a level passes at ≥ 2 of 3.
- **Result changes what is studied:** the proposed target level is one above the
  highest passed level (A1 if none) and becomes `targetLevel` when accepted;
  passed levels are remembered as "known" so their new cards are introduced after
  the higher levels' cards; an optional «Пропустить то, что я знаю» seeds the
  cards answered correctly in the test as already reviewed via the scheduler.
- **Result screen** shows "ваши 3 ловушки" — «Частые ошибки» items of cards the
  user failed.
- **One onboarding order:** level (manual or test) → themes → reminders (the
  pending `streak-reminders` step stays last). Goal and regional-variant prompts
  move out of onboarding to Today after the first session.
- **First session right after onboarding** with a one-off allowance of 3 new
  cards, failed-test cards first, instead of landing on Today.
- **Analytics:** placement and first-session events added to `product-analytics`.

## Capabilities

### New Capabilities
- `placement-test`: block selection, pass/stop rules, level proposal, known
  levels, optional seeding, trap extraction.

### Modified Capabilities
- `onboarding-and-selection`: ADDED — test path in level selection, the single
  onboarding order, first-session hand-off with its one-off allowance,
  post-session prompts on Today.
- `daily-plan`: ADDED — new cards of placement-known levels are introduced after
  the cards of higher included levels.
- `product-analytics` (from sibling change): ADDED placement events.

## Impact

- **Domain**: `PlacementTest` (pure: next question, block scoring, stop rule,
  proposal, known levels, traps, seeding plan); traps use `CardBodyParser`
  (moved to Domain by `learning-platform-foundation`).
- **Persistence**: `UserSettings.placementKnownLevel: CEFRLevel?` (optional
  scalar, per `cloudkit-schema-release`); optional seeded `CardReview` records.
- **Features**: onboarding test path and result screen; one-shot first-session
  hand-off; Today prompt slots for goal (`study-goal`) and variant
  (`regional-variants`).
- Depends on `learning-platform-foundation` (learning day, new-item budget,
  item kinds), `cloudkit-schema-release`, `product-analytics`; pending
  `streak-reminders` keeps the reminder step last.
