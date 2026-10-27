## Why

Today a study card shows its full answer immediately; the user reads it and
grades it. Reading is recognition, not recall, so grades are inflated and
retention suffers — the core promise of a spaced-repetition app is undermined
at the exact moment it matters. The grade buttons also hide what they do: the
user cannot see that "Легко" pushes the card four days out. And the end of a
session is a dead end ("Готово!") that neither rewards the streak nor says what
comes back tomorrow. This change turns the session into an active-recall loop
and makes the scheduler visible.

## What Changes

- **Recall first:** a card opens on a front side — level chip, title and a
  recall prompt (e.g. "¿el или la? problema, mano, canción, agua"). The body
  and grade buttons appear only after "Показать ответ".
- **Optional `recall` field in card content:** a short Markdown prompt per card,
  authored in `content/` (enrichment step can draft it). Cards without it fall
  back to a generic prompt built from the title.
- **Interval preview on grade buttons:** each button shows when the card will
  return ("сегодня", "1 день", "4 дня"), computed by the existing pure SM-2
  scheduler for the current review state — no new scheduling rules.
- **Richer completion state:** cards studied, share remembered on the first
  grade, the current streak (with "new record" when it equals the best), and the
  themes to revisit (cards graded Опять/Трудно in the session).
- **Trap of the day on Today:** one "Частые ошибки" item from a card in the
  user's scope, picked deterministically per day, linking to the card.

## Capabilities

### New Capabilities
<!-- None. -->

### Modified Capabilities
- `study-flow`: session gains a front/reveal step and interval captions; the
  completion state gains a summary; the Today screen gains the trap of the day.
- `content-model`: cards gain an optional `recall` prompt field.
- `content-pipeline`: validation covers the `recall` field.

## Impact

- **Domain**: `IntervalPreview` (pure, uses `SpacedRepetitionScheduler`),
  `SessionSummary` (pure, from the session's grades + stats), `DailyTrap` (pure
  picker over cards' mistakes sections, injected date). `Card` gains
  `recall: String?`.
- **Content**: `content/schema.md`, `tools/validate.py`, `tools/compile.py`
  accept `recall`; `tools/enrich.py` can draft prompts for review.
- **Features**: `StudySessionModel` gains `isRevealed`; `StudySessionView`
  front/back; completion view; `TodayModel`/`TodayView` trap card.
- **DesignSystem**: uses `GradeButtons` captions and components from
  `plumaje-design-system` (depends on it).
- No SRS rule changes; no persistence schema changes.
