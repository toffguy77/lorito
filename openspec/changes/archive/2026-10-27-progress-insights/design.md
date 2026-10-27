## Context

`StatsCalculator` (Domain, pure) computes current/best streak and
today/week/all-time counts from study events with an injected "today".
`CardReview` stores `interval` and `status` per card. Mockups:
`design/mockups/Progress.dc.html`, `Today.dc.html` (week strip).

## Goals / Non-Goals

**Goals:** a consistency picture (heatmap, week strip) and a retention picture
(long-term memory per level), both pure and testable.

**Non-Goals:** streak freezes, goals/targets, charts beyond 12 weeks, exporting
stats, social comparison.

## Decisions

**Daily series as the single primitive.** `dailyActivity(days: 84, today:)`
returns 84 `(day, count)` pairs, oldest first, in the user's calendar (the same
day boundary the streak uses, so the strip and the streak never disagree). The
heatmap and the week strip both read from it.

**Buckets are relative to the user, not absolute.** 0 → `heat0`; otherwise
quartiles of the non-zero counts in the window (1–3), so a light learner still
sees variation. Ties and a single non-zero value fall into bucket 3. Pure and
tested.

**Long-term memory threshold = 21 days.** A card counts when its `CardReview`
status is `review` and `interval >= 21`. Suspended cards are excluded from both
numerator and denominator. Constant lives in Domain next to SRS constants.

**Grid layout.** Columns are weeks (oldest left), rows Mon–Sun; built with
`Grid` in SwiftUI. Because the 84-day window rarely starts on a Monday, the
grid shows 12–13 week columns with the slots outside the window left blank; each cell has an accessibility value "N повторений, дата",
and the whole grid is also summarised as one accessibility label.

## Risks / Trade-offs

- [84 days of events fetched on every open] → the existing fetch already loads
  events for streaks; reuse it and compute once per refresh.
- [Relative buckets hide absolute volume] → the total reviews in the window is
  printed above the grid.
