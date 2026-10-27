## Context

`stats-and-streak` computes "this week" counts, but its calculator uses
`Calendar(identifier: .gregorian)` whose default `firstWeekday` is 1 (Sunday), so
weeks currently start on Sunday. `learning-platform-foundation` (dependency)
switches day boundaries to the local learning day and introduces item kinds
(only `.card` counts as a card). Pending `progress-insights` defines long-term
memory per level. Pending `home-screen-widgets` renders a share card with
`ImageRenderer`. Sibling `personal-traps` ranks traps.

## Goals / Non-Goals

**Goals:** a weekly moment and level moments built from existing data; safe
share images; one week definition everywhere.

**Non-Goals:** recap notifications; leaderboards; certificates implying official
CEFR certification; un-celebrating levels.

## Decisions

**Week = Monday–Sunday everywhere.** The stats calculator sets
`firstWeekday = 2` (ISO-style weeks) on its calendar, in the local time zone of
the learning day. The recap covers the most recently completed week and appears
from Monday; `lastRecapWeek` (ISO week id, optional scalar) marks it seen.

**Recap facts (pure).** `daysStudied`, `newRules` (`.card` items whose first
study event is in the week), `longTerm` (current long-term `.card` count across
included levels; `CardReview` keeps no history, so no weekly delta is claimed),
`topTrap` (top in-scope personal trap by failures in the week; fallback: card
with most first-of-day Опять grades in the week; omitted if none).

**Milestones.** `LevelMilestones.newlyClosed(...)` returns included levels whose
non-suspended `.card` items are all long-term and that are not celebrated.

**Celebrated levels as a union set.** Stored as one optional scalar string of
sorted level codes (e.g. "A1,A2"), per `cloudkit-schema-release`. Before every
write the app unions the stored value with the new level; on receiving a synced
value the store unions it with the local value. Union is commutative and
idempotent, so concurrent devices converge and nothing is lost.

**Share images.** On-device, 9:16; brand mark, "A1 закрыт" or the week's
numbers, month and year; no name, account or device data; copy «уровень пройден
в Lorito», not an exam claim.

## Risks / Trade-offs

- [Changing week start shifts "this week" counts once] → documented in release
  notes; counts are display-only.
- [Union via settings sync] → requires a merge hook in the store, covered by a
  two-device store test.
- [No per-week long-term delta] → the recap shows the current count.

## Migration Plan

Additive optional fields (`lastRecapWeek`, `celebratedLevels`), schema per
`cloudkit-schema-release`. On first launch, already closed levels are celebrated
once. Rollback: hide the UI; revert `firstWeekday`.
