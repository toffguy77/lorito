## Why

Onboarding asks the user to self-assess their level from six labels. People who
"know some Spanish" guess, and a wrong guess hurts on day one: too low and the
first cards are boring, too high and the first session is a wall of unknown rules.
After onboarding the user lands on Today and has to find "Начать" themselves —
the first study session, which is the activation moment, is one more decision
away. We already ship 892 exercises tagged by level and card, enough to measure
level in two minutes and to show the user their first personal mistakes.

## What Changes

- **Placement test option in onboarding:** next to the manual level list, a
  "Не знаю — проверить за 2 минуты" action starts a short adaptive test built
  from existing auto-checkable exercises.
- **Adaptive selection:** questions climb or drop a level based on answers;
  the test stops after a fixed question budget or when the level is settled,
  and proposes a target level the user can accept or change.
- **Result screen:** proposed level plus "ваши 3 ловушки" — up to three
  «Частые ошибки» items from cards whose exercises the user failed.
- **Diagnostic only:** test answers never touch `CardReview` or the study log.
- **First session right after onboarding:** finishing onboarding opens the
  first study session directly (when the queue is non-empty) instead of
  landing on Today.

## Capabilities

### New Capabilities
- `placement-test`: adaptive question selection, stopping rule, level
  proposal, trap extraction, isolation from SRS state.

### Modified Capabilities
- `onboarding-and-selection`: adds the placement-test path into level
  selection and the first-session hand-off after completion (ADDED requirements;
  the pending `streak-reminders` reminder step stays the last onboarding step).

## Impact

- **Domain**: `PlacementTest` (pure: next question, stopping rule, proposed
  level, traps) over `Exercise` + `ContentCatalog`; deterministic with an
  injected seed.
- **Features**: `OnboardingView` gains the test path and result screen;
  `RootView`/`MainTabView` gains a one-shot "start first session" hand-off.
- **Persistence**: none (test results are not stored; the proposed level is
  persisted only as `UserSettings.targetLevel` when accepted).
- **Analytics**: emits events defined by the sibling `product-analytics`
  change when present (test started / completed / level accepted).
- Depends on archived `plumaje-design-system` and `recall-first-study`;
  feeds `personal-traps` (traps found in the test seed the personal list if
  that change is applied).
