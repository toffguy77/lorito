## Why

Spaced repetition progress is invisible day to day: a good week feels the same
as a bad one, and finishing a whole level passes without a moment. Learners need
a rhythm above the daily session — a short weekly look back and real milestones
— both to stay motivated and to have something worth sharing. `progress-insights`
already defines long-term memory per level; this change turns it into moments.

## What Changes

- **Weekly recap:** from Monday, once per completed Monday–Sunday week, a recap
  card shows days studied out of 7, new rules introduced this
  week, the current long-term memory count, and the top trap of the
  week; it can be shared as an image.
- **Level milestones:** when every non-suspended card of an included level is in
  long-term memory (as defined by `progress-insights`), the app celebrates once
  with «A1 закрыт» and offers a shareable certificate image.
- **Share images carry no personal data:** numbers, level, month and the brand
  mark only.
- All facts come from pure `Domain` functions over existing data; only "seen"
  markers are persisted.

## Capabilities

### New Capabilities
- `weekly-recap-and-milestones`: weekly recap computation and display, level
  milestone detection and celebration, share images.

### Modified Capabilities
- `stats-and-streak`: ADDED — weeks start on Monday (the calculator's calendar
  currently defaults to Sunday).

## Impact

- **Domain**: `WeeklyRecap.make(...)` and `LevelMilestones.newlyClosed(...)`,
  pure with injected today; reuse the week boundary of the stats calculator and
  the long-term memory rule of `progress-insights`.
- **Persistence**: optional scalars `lastRecapWeek` (ISO week id) and
  `celebratedLevels` (sorted level codes, merged by union) per
  `cloudkit-schema-release`.
- Counts only `.card` items (`learning-platform-foundation`).
- **Features**: Today recap card, milestone celebration sheet, `ImageRenderer`
  share images (pattern shared with `home-screen-widgets`' streak share card).
- Depends on `progress-insights` (long-term memory by level). Uses
  `personal-traps` for the top trap when applied; otherwise falls back to the
  card graded Опять most often this week.
