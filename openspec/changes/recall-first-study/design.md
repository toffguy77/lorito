## Context

`StudySessionView` renders the whole card (chip, title, `CardContentView`) with
`GradeButtons` always visible. `SpacedRepetitionScheduler.schedule(state:grade:today:)`
is pure and day-granular (`relearnInterval = 0` → due today). `CardBodyParser`
already lifts "Частые ошибки" into a typed `.callout(.mistakes, …)` block.
`StatsCalculator` already yields current/best streak. Mockups:
`design/mockups/CardFront.dc.html`, `CardBack.dc.html`, `SessionDone.dc.html`,
`Today.dc.html`.

## Goals / Non-Goals

**Goals:**
- Force a recall attempt before the answer is shown.
- Show the real next interval per grade, derived from the existing scheduler.
- Close a session with a summary that rewards the streak and names weak themes.
- Surface one high-value mistake per day on Today using existing content.

**Non-Goals:**
- No change to SM-2 math, the daily plan, or exercise grading.
- No typed-answer checking on cards (exercises already cover production).
- No minute-level intervals; the scheduler stays day-granular ("сегодня" for 0).
- Authoring `recall` for all 159 cards is content work tracked separately; the
  fallback keeps the feature usable on day one.

## Decisions

**`recall` is an optional front-matter string (Markdown).** Example:
`recall: "**¿el или la?** *problema, mano, canción, agua*"`. Rendered with
Markdown emphasis → Spanish voice. Fallback when absent: "Вспомните главное:
{title}" plus, if present, the card's aliases as a hint line. Rationale: keeps
the content model flat; no per-card answer key needed because grading stays
self-assessed.

**Reveal is session state, not card state.** `StudySessionModel.isRevealed`
resets to `false` on advance. Grade buttons are not rendered until revealed,
which guarantees no accidental grade on the front. VoiceOver: "Показать ответ"
is the first focus target on the front.

**Interval captions are a pure Domain function.**
`IntervalPreview.captions(for state: ReviewState?, today: Date) -> [Grade: String]`
calls `schedule` for each grade on the current state (or a fresh `new` state)
and formats `interval` days: 0 → "сегодня", 1 → "1 день", 2–4 → "N дня",
else "N дней" (Russian plural rules, shared with the existing `dayWord`), and
≥ 30 → "≈ N мес." Deterministic for identical inputs; unit-tested against the
scheduler so captions can never drift from real behavior.

**Summary from the session's own events.** `SessionSummary` is computed from the
ordered list of `(cardID, grade)` written in this session plus the stats
calculator output after the last write: `studied` = distinct cards graded;
`firstTryShare` = cards whose first grade in the session was Хорошо/Легко ÷
studied; `revisitThemes` = themes of cards graded Опять or Трудно, ordered by
count, max 3; `isNewRecord` = currentStreak == bestStreak && currentStreak > 1.

**Trap of the day is deterministic.** `DailyTrap.pick(candidates:day:)` takes
cards in the user's included scope that have a mistakes callout, prefers cards
that already have a `CardReview` (studied), and selects index =
stableHash(yyyy-MM-dd) mod count — stable across launches and devices (no
`hashValue`, which is seeded per process). It shows the first bullet of the
section. Hidden when there are no candidates.

## Risks / Trade-offs

- [Extra tap per card slows sessions] → reveal button sits where the grade row
  appears, so thumb travel is zero; measure session duration before/after.
- [Generic fallback prompts are weak] → prioritise `recall` authoring for A1–A2
  first (most users); `enrich.py` drafts, human reviews.
- [First bullet of mistakes may be long] → line-limit 4 with "Открыть карточку".

## Migration Plan

Additive. Ship with fallback prompts; backfill `recall` content level by level
via `tools/compile.py`. Rollback: revert; content files with `recall` remain
valid because the field is optional.
