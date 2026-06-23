## Context

Lorito is offline with no backend, so re-engagement depends entirely on local notifications via `UNUserNotificationCenter`. The `bootstrap-foundation` change reserved `UserSettings.reminderConfig` without specifying its shape; the `daily-plan` change can report the due-review count and the new-card count for a given day. This change defines `reminderConfig`'s shape and the behavior that turns it, plus the day's counts, into scheduled local notifications.

The project already established a discipline in `srs-engine`: put decision logic in the pure `Domain` layer with an injected clock, keep system frameworks behind protocols, and unit-test the logic without a simulator. Reminders follow the same pattern: a pure scheduling-decision function, and a thin `UNUserNotificationCenter`-backed service behind a protocol.

## Goals / Non-Goals

**Goals:**
- A concrete `reminderConfig` shape (enabled + one or more daily times) persisted in `UserSettings`.
- A clear authorization flow that handles `notDetermined` / `denied` / `authorized` gracefully, including a path to iOS Settings when denied.
- A pure, clock-injected decision function: (times + day counts + now) → set of notification requests, fully unit-testable.
- Notification bodies that reflect the day's due/new counts in Russian; skip days with nothing due.
- Rescheduling on settings change, session completion, launch, and day rollover; idempotent.
- Respect the 64 pending-notification limit; tapping a reminder routes to Today/study.

**Non-Goals:**
- Server/remote push notifications (no APNs, no push entitlement).
- Practice exercises and the study flow itself (separate changes).
- Defining how counts are computed — that is `daily-plan`'s contract; this change consumes it.
- Rich notification UI (attachments, actions, communication notifications) for v1.

## Decisions

- **`reminderConfig` = `enabled: Bool` + an ordered set of `(hour, minute)` local times.** Times are stored as local hour/minute, not absolute dates, so a "daily" reminder is naturally calendar-based and survives day rollover and time-zone moves. Alternative (store absolute `Date`s) was rejected: it drifts across days and time zones and complicates the daily-repeat semantics.

- **Pure decision function separate from the system API.** A `Domain`-layer function takes the times, the per-day due/new counts, and an injected "now", and returns notification requests (stable identifier, calendar trigger components, localized title/body). It performs no I/O. A separate scheduler service applies the result through the `NotificationScheduling` protocol. Rationale: the interesting logic (which days get reminders, what the body says, how many fit under the limit) is exhaustively testable with a fake clock and plain inputs, exactly as the SM-2 scheduler is. Alternative (compute trigger dates inline against `UNUserNotificationCenter`) was rejected as untestable and clock-coupled.

- **How counts are computed at schedule time.** The decision function does not call `daily-plan`; the caller resolves the due/new counts for each day in the horizon (using the same injected "now") and passes them in as data. For a daily-repeating `UNCalendarNotificationTrigger`, the counts shown are necessarily a *projection* made at schedule time. To keep them honest, the app reschedules frequently (see triggers) and uses **non-repeating, per-occurrence requests within a bounded horizon** rather than a single infinitely-repeating trigger, so each scheduled notification can carry that day's actual projected counts. The trade-off (more pending requests) is bounded by the horizon and the 64-request cap.

- **Skip days with nothing due (no empty nudge).** When both counts are zero for a day, no request is produced for that day. Rationale: a notification that opens to an empty queue trains users to ignore reminders. A "gentle nudge with nothing to do" was considered and rejected for v1; if retention data later argues for it, it can be added as a separate behavior. This keeps the contract simple and the notification always actionable.

- **Bounded scheduling horizon to respect the 64-request limit.** iOS keeps at most 64 pending requests per app. With up to a few times per day, the decision function produces requests only for a fixed forward horizon (e.g. the next several days), capped so the count never exceeds the limit, prioritizing the soonest reminders. Because non-empty days are the only ones scheduled and the app reschedules on launch/rollover/session-completion, the horizon is continually refreshed, so users keep getting accurate near-term reminders without ever exhausting the budget. Alternative (one repeating trigger per time, count-free body) was rejected because it cannot reflect that day's counts; alternative (schedule far into the future) was rejected because projected counts grow stale and the 64-cap is quickly hit.

- **Scoped removal before reschedule.** All reminder requests use identifiers under a reserved prefix/namespace. Rescheduling removes only requests with that prefix, never `removeAllPendingNotificationRequests()`, so the app coexists with any other (future) notification use and does not assume it owns the entire 64-request budget.

- **Authorization handled by a dedicated helper behind the protocol.** Requesting authorization, reading status, scheduling, and removing pending reminders are all expressed on the `NotificationScheduling` protocol. The Features layer reacts to status: `notDetermined` → request; `denied` → show Settings guidance and do not schedule; `authorized`/provisional → schedule. This isolates the only truly side-effecting parts and lets tests drive every branch with a fake.

- **Deep link via a notification identifier/userInfo route to Today.** Reminder requests carry a route marker so the notification delegate can navigate to the Today/study entry on tap, from terminated/background/foreground states. No custom URL scheme is required; an in-app route value suffices.

## Risks / Trade-offs

- **Projected counts can drift between schedule time and fire time** (e.g. the user studies on another device, or a card lapses) → mitigated by frequent rescheduling (launch, day rollover, session completion, settings change) and a short horizon; residual drift is acceptable because tapping always lands on the live Today screen showing real counts.
- **64-request cap with many configured times** → the horizon is capped and prioritizes the soonest reminders; the decision function enforces the bound so the system call can never be rejected for exceeding the limit.
- **Time-zone / DST changes** → storing local hour/minute and using calendar-based triggers keeps "20:00 daily" correct across DST; rescheduling on launch corrects any edge cases.
- **User denies permission after enabling in-app** → the in-app toggle can be on while system permission is denied; the app detects this on the authorization status and surfaces Settings guidance instead of silently failing to notify.
- **Background day-rollover while app is suspended** → reminders for the new day rely on already-scheduled per-occurrence requests plus the next launch's reschedule; the horizon ensures at least the next days are covered even if the app is not opened.

## Open Questions

- Exact scheduling-horizon length and the per-day time cap (must keep total ≤ 64) — pick a concrete value during implementation and encode it as a single constant.
- When to first prompt for authorization: immediately on toggling reminders on (chosen default) vs. a pre-permission priming screen — revisit if prompt-acceptance rates are low.
- Final Russian pluralization wording for the count strings (e.g. "тема/темы/тем", "новая/новые/новых") — to be finalized with the localized strings.
