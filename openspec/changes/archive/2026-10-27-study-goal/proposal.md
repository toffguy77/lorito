## Why

Lorito asks "how many new cards per day?" but never "what for, and by when?".
Learners with a deadline — a move, a job, the DELE A2 or CCSE exam for Spanish
citizenship — have no way to see whether their pace gets them there, and learners
without one have nothing to pull them back on a lazy day. A goal with a date
turns the daily plan into a visible countdown and gives an honest "on track /
behind" signal, the strongest everyday motivator after the streak.

## What Changes

- **Level goal (optional):** a target level and a target date. While active it
  can only raise the daily new-card count: `newPerDay = max(pace, dailyNewCardCount)`,
  where pace = cards left ÷ learning days left, all within the daily
  new-introduction budget of `learning-platform-foundation`.
- **Exam date (optional, independent):** `examKind` (DELE A2 or CCSE) and
  `examDate`, for the countdown used by `exam-path-dele-ccse`. An exam goal is
  achieved when its date passes or the user marks it done — not when cards are
  introduced. The "DELE A2" preset sets both a level goal (A2) and the exam.
- **Countdown and status on Today:** learning days left, cards left, «в графике» /
  «отстаёте на N карточек» with Russian plurals.
- **Management** in Settings; first offered as a dismissible Today prompt after
  the first completed session (onboarding order is owned by
  `placement-test-and-first-session`).
- **Storage:** flattened optional scalar fields on `UserSettings`.

## Capabilities

### New Capabilities
- `study-goal`: level goal, exam date, pacing, status, lifecycle, Today
  countdown and prompt, Settings management.

### Modified Capabilities
- `daily-plan`: ADDED — goal-raised new-card limit.

## Impact

- **Domain**: `GoalPacing` (pace, status, lifecycle) and `ExamCountdown`, pure,
  using the local learning day; counts only `.card` items.
- **Persistence**: `UserSettings` optional scalars `goalTargetLevel`,
  `goalTargetDate`, `goalStartDate`, `goalStartIntroduced`, `goalState`,
  `examKind`, `examDate`, `examDone` — per `cloudkit-schema-release`.
- **Features**: Today goal card and post-first-session prompt; Settings → «Цель».
- Depends on `learning-platform-foundation` (learning day, item kinds, budget),
  `cloudkit-schema-release`, and the Today prompt slot from
  `placement-test-and-first-session`; consumed by `exam-path-dele-ccse`.
