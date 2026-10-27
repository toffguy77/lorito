## Context

`stats-and-streak` defines day and week boundaries for counts. Pending
`progress-insights` adds the daily activity series and "long-term memory by
level" (status `review`, interval ≥ 21, suspended excluded). Pending
`home-screen-widgets` renders a streak share card with `ImageRenderer`. Sibling
`personal-traps` ranks the user's traps.

## Goals / Non-Goals

**Goals:** a weekly moment and level moments built from data we already have;
share images that are safe to post.

**Non-Goals:** push notifications for the recap; leaderboards; certificates
claiming official CEFR certification; un-celebrating a level if cards later lapse.

## Decisions

**Week = the stats calculator's week.** The recap covers the 7 days ending on
the most recent Sunday (inclusive), identified by an ISO week id. It appears on
the first Today visit from Sunday onward and is dismissed per week by storing
`lastRecapWeek`. A user who skips a week sees only the latest week.

**Recap facts (pure).** `daysStudied` (days with ≥ 1 grade event), `newRules`
(cards whose first study event falls in the week), `longTerm` (current
long-term memory count across included levels; `CardReview` keeps no history, so
no weekly delta is claimed), `topTrap` (top personal trap
by failures within the week; fallback: card with most Опять grades in the week;
omitted if none). A week with zero study days shows an encouraging empty recap
rather than zeros only.

**Milestones.** `LevelMilestones.newlyClosed(reviews:catalog:includedLevels:
celebrated:)` returns levels where every non-suspended card is in long-term
memory and the level is not in `celebratedLevels`. Celebration is shown once,
then the level is appended to `celebratedLevels`. Certificate stays valid even if
cards later fall below 21 days.

**Share images.** Rendered on device, 9:16; content: brand mark, "A1 закрыт" or
the week's numbers, month and year. No name, no account, no device info. Copy
avoids implying an official exam result ("уровень пройден в Lorito").

## Risks / Trade-offs

- [Closing a level takes months] → milestones are rare by design; the weekly
  recap covers the in-between.
- [Recap feels like noise] → once a week, dismissible, never a notification.
- [No per-week long-term delta] → the recap shows the current count; a weekly
  delta would need review history, which `CardReview` does not keep.

## Migration Plan

Additive; new `UserSettings` fields default to nil / empty. On first launch after
update, levels already closed are celebrated once. Rollback: hide the UI.
