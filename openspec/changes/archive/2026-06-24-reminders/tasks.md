## 1. Configuration shape

- [x] 1.1 Define the concrete `reminderConfig` shape consumed by the foundation `UserSettings`: `enabled: Bool` plus an ordered set of one or more daily `(hour, minute)` local times; do not redefine the `UserSettings` model
- [x] 1.2 Add helpers to add/edit/remove reminder times, enforcing at least one time whenever `enabled` is true
- [x] 1.3 Add a test: enabling with a time persists `enabled=true` and the time; multiple distinct times are retained; disabling clears scheduling intent

## 2. Pure scheduling decision (TDD)

- [x] 2.1 Write failing tests: identical (times, counts, injected "now") inputs produce identical request sets (identifiers, trigger dates, titles, bodies)
- [x] 2.2 Write failing tests: one request per configured future time within the horizon when counts are non-zero; trigger date matches the local time
- [x] 2.3 Write failing tests: a day with 0 due and 0 new yields no request; other days in the horizon are unaffected
- [x] 2.4 Write failing tests: bodies reflect due/new counts in Russian (both counts; reviews-only case); no I/O and no ambient clock access
- [x] 2.5 Write failing tests: output is bounded to the scheduling horizon and never exceeds the 64-request limit, keeping the soonest reminders
- [x] 2.6 Implement the pure `Domain` decision function (times + per-day counts + injected "now" → notification requests) to make tests pass; no `UNUserNotificationCenter`, no `Date.now`, no persistence
- [x] 2.7 Encode the scheduling-horizon length and per-day time cap as a single constant keeping total ≤ 64

## 3. Notification scheduling protocol

- [x] 3.1 Define the `NotificationScheduling` protocol: request authorization, query authorization status, schedule requests, remove pending reminder requests (scoped by reserved identifier prefix)
- [x] 3.2 Implement the `UNUserNotificationCenter`-backed conformance for production
- [x] 3.3 Implement a fake conformance for tests that records scheduled and removed requests
- [x] 3.4 Add a test: scheduling service applies the decision through the protocol; removal is scoped to reminder-prefixed identifiers and leaves unrelated pending requests intact

## 4. Authorization flow

- [x] 4.1 Implement an authorization helper over the protocol mapping `notDetermined` → request, `denied` → Settings guidance + no scheduling, `authorized`/provisional → schedule
- [x] 4.2 Add the Features surface to enable reminders and pick one or more times (DesignSystem components, Russian UI)
- [x] 4.3 Add Settings-guidance UI shown when status is `denied`
- [x] 4.4 Add tests driving each authorization branch with the fake scheduler

## 5. Scheduler service & reschedule triggers

- [x] 5.1 Implement the scheduler service: resolve per-day due/new counts (from `daily-plan`, using the injected "now"), run the decision function, clear prior reminder requests, schedule the new set — idempotently
- [x] 5.2 Wire reschedule on `reminderConfig` change
- [x] 5.3 Wire reschedule on study-session completion
- [x] 5.4 Wire reschedule on app launch
- [x] 5.5 Wire reschedule on day rollover (local calendar day change while running)
- [x] 5.6 Add tests: each trigger reschedules; repeated reschedule with unchanged inputs is idempotent (same pending set)

## 6. Deep link to Today/study

- [x] 6.1 Tag reminder requests with a route marker (identifier/userInfo) for the Today/study entry
- [x] 6.2 Implement the notification delegate handling tap → navigate to Today/study from terminated, background, and foreground states
- [x] 6.3 Add a test/verification that a tapped reminder routes to the Today/study entry point

## 7. Platform & wrap-up

- [x] 7.1 Add the user-notifications capability/configuration (local notifications only; no push entitlement) and document setup
- [x] 7.2 Verify acceptance: enable flow requests authorization; denied path guides to Settings; bodies reflect counts; empty days skipped; limit respected; tap opens Today
- [x] 7.3 Run `openspec validate reminders --strict` and fix until valid
