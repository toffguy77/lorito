## Context

`StatsCalculator` (Domain, pure) derives current streak, best streak and counts
from `StudyLog` events with an injected "today". Today is "savable": not studying
yet today does not break the streak. Pending `streak-reminders` makes reminders
streak-aware; pending `progress-insights` adds the daily activity series and
modifies the progress screen requirement.

## Goals / Non-Goals

**Goals:** forgiving streaks that stay deterministic and need no new storage;
clear UI for when protection kicked in.

**Non-Goals:** buying freezes (no IAP here; `lorito-pro` may decide later);
manual "equip freeze" actions; weekend modes; changing the day boundary.

## Decisions

**Everything is replayed from the log.** The calculator walks calendar days from
the first study day to yesterday, then applies the "today is savable" rule. A
day is *studied* if it has ≥ 1 grade event. Because freezes and revivals are a
pure function of the log, two devices with the same synced log always agree, and
no `UserSettings` field is needed.

**Freeze earning.** A counter of consecutive studied days in the current run
earns one freeze each time it reaches 7 (then restarts at 0). Stock is capped at
`StreakConstants.maxFreezes = 2`; earning at the cap is lost. Frozen days neither
advance nor reset the earning counter.

**Freeze use.** A missed day (not today) while the current streak is > 0 and
stock > 0 consumes one freeze; the day becomes *frozen*: the run continues, its
length does not grow. Several consecutive missed days consume one freeze each;
when stock runs out the next missed day breaks the run.

**Revival.** When a run with length ≥ 2 breaks on day L (the first missed,
unfrozen day), it becomes *revivable* until L + 7. If the user then studies on 3
consecutive days all within (L, L + 7], the gap days become *revived*: the run
continues from its pre-loss length and those 3 days are added. At most one
revival per `StreakConstants.revivalCooldownDays = 30` (measured between loss
days). Revival status is reported for UI: none / in progress (k of 3 days done,
deadline) / completed.

**Best streak** uses the same bridged runs, so a protected run counts as one.

**Constants** in Domain: `freezeEarnEvery = 7`, `maxFreezes = 2`,
`revivalDays = 3`, `revivalWindowDays = 7`, `revivalCooldownDays = 30`,
`minRevivableStreak = 2`.

**Reminder line.** The calculator exposes `frozenYesterday`; the reminder body
composition adds "Заморозка спасла вашу серию" for the first reminder after a
frozen day. Implemented as a separate composition step so it does not alter the
requirements modified by `streak-reminders`.

## Risks / Trade-offs

- [Protection inflates streak meaning] → frozen days don't add length; revival
  is rate-limited.
- [Replay cost over long histories] → linear in days; years of history is a few
  thousand iterations, computed on refresh only.
- [Users confused why streak survived] → explicit "серия спасена заморозкой" banner.

## Migration Plan

No data migration. On first launch after update, existing histories are
re-evaluated: some users' current streak may increase retroactively (gaps now
frozen). Accepted and noted in release notes. Rollback: revert the calculator.
