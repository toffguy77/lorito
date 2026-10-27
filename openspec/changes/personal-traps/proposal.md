## Why

Every Lorito card already lists the typical mistakes Russian speakers make
(«Частые ошибки»), and the app already knows which cards a user fails — cards
graded Опять and exercises answered incorrectly. But the two never meet: the
trap of the day is chosen from the whole scope, and a user who keeps writing
*la problema* never sees "this is your trap". Turning the content we have into a
personal list of the user's own mistakes is the most Lorito-specific retention
mechanic we can build: English-first competitors have no Russian-speaker
mistake data to copy.

## What Changes

- **Personal traps derived from failures:** a card becomes a personal trap when
  its first graded study event of a learning day is Опять (exercise failures
  count through the study event they write, once), provided the card has a
  «Частые ошибки» section. Only cards in the current scope are shown.
- **«Мои ловушки» list:** ranked by most recent failure, then by failure count;
  each entry shows the card's mistakes items and opens the card.
- **5-minute traps session:** up to 10 traps, each shown as the mistake item on
  the front and the card's explanation on the back, self-assessed «Ещё путаю» /
  «Ясно». It does not change `CardReview` scheduling.
- **Leaving the list:** a trap is resolved after two passing outcomes since its
  last failure (Хорошо/Легко grades in study or «Ясно» in the traps session).
- **Trap of the day prefers personal traps** when the user has any.
- Entry point on Today ("Мои ловушки · N") and from the session summary.

## Capabilities

### New Capabilities
- `personal-traps`: derivation, ranking, resolution, list screen, traps session.

### Modified Capabilities
- `study-flow`: "Trap of the day on the Today screen" prefers personal traps.

## Impact

- **Domain**: `PersonalTraps` pure function over study events, trap-practice
  events, scope and the content catalog (with injected today).
- **Persistence**: new `TrapPracticeEvent` record (card id, date, outcome) —
  additive, per `cloudkit-schema-release`.
- Depends on `learning-platform-foundation` (CardBodyParser in Domain, item
  kinds, learning day, first-grade-per-day rule).
- **Features**: Today entry card, traps list screen, traps session (focus-mode
  UI from `plumaje-design-system`), trap-of-the-day picker input.
- Related: `placement-test-and-first-session` shows "ваши 3 ловушки" from the
  test but does not write them here (the test is diagnostic only);
  `weekly-recap-and-milestones` reads the top trap of the week from this change.
