## Why

Spaced repetition only works if the learner comes back every day. Lorito has no backend and ships entirely offline, so the only way to pull a user back into the app is the device's own local notifications. The `bootstrap-foundation` change reserved `UserSettings.reminderConfig` but deliberately left its shape and behavior undefined; the `daily-plan` change can report how many cards are due/new for a given day. This change connects the two: it lets a user enable one or more daily reminders, requests notification permission with a clear flow, and schedules local notifications whose text reflects the day's due/new counts so the nudge is informative ("5 тем на повторение + 1 новая") rather than generic.

Scheduling decisions must be reproducible and testable without a simulator or real notification center. So the core decision — given the configured times, the day's counts, and an injected clock, produce the exact set of notification requests to schedule — is defined as pure logic behind a protocol, separate from the `UNUserNotificationCenter` system API. This mirrors the clock-injection and purity discipline already established by `srs-engine`.

## What Changes

- Define the concrete shape of `UserSettings.reminderConfig`: an `enabled` flag plus one or more daily reminder times (hour/minute, in the user's local calendar). The foundation `UserSettings` model is consumed, not redefined.
- Add a **notification authorization flow**: the app requests permission at the right moment and handles `notDetermined`, `denied`, and `authorized` (and provisional) states gracefully, including guiding the user to iOS Settings when permission was previously denied.
- Add a **pure scheduling-decision** component: given the reminder times, the due/new counts for the relevant day(s), and an injected "now"/clock, it returns the exact set of notification requests (identifier, trigger time, localized title/body) to be scheduled — with no system or clock side effects. When nothing is due, that day's reminder is **skipped** (no empty nudge); the rationale is specified in design.md.
- Add a **scheduler service** that applies those decisions through a `NotificationScheduling` protocol wrapping `UNUserNotificationCenter`, so production uses the system API and tests use a fake.
- Define **reschedule triggers**: reminders are recomputed and re-scheduled on settings change, after completing a study session, on app launch, and at day rollover.
- Define **notification content**: each scheduled notification's body reflects the day's due/new counts (in Russian), respecting the iOS limit of 64 pending notification requests via a bounded scheduling horizon.
- Define **deep-link behavior**: tapping a reminder opens the app to the Today/study entry point.

This change delivers no practice exercises and no server pushes. It produces a tested scheduling-decision contract plus a system-backed scheduler that the `study-flow`/Today surfaces invoke.

## Capabilities

### New Capabilities
- `reminders`: Configurable daily local notifications via `UNUserNotificationCenter` — the `reminderConfig` shape (enabled + one or more times), the authorization flow with graceful denied/undetermined handling, a pure clock-injected scheduling-decision that turns times + due/new counts into notification requests (skipping days with nothing due), a protocol-backed scheduler that respects the iOS pending-notification limit, the reschedule triggers (settings change, session completion, launch, day rollover), notification content reflecting the day's counts in Russian, and the deep link to the Today/study entry on tap.

### Modified Capabilities
<!-- None — the foundation specs (app-foundation, content-model, content-pipeline, design-system) are not archived yet, so this change introduces no MODIFIED deltas. It builds on the foundation's UserSettings.reminderConfig and consumes daily-plan's due/new counts without redefining either. -->

## Impact

- **Code (added, not in scope to author here)**: a pure reminder-scheduling-decision type in the `Domain` layer plus its unit tests; a `NotificationScheduling` protocol and a `UNUserNotificationCenter`-backed implementation; an authorization-state helper; a small Features surface to enable reminders and pick times; a deep-link route to Today.
- **Foundation contracts consumed (not modified)**: `UserSettings.reminderConfig` from `app-foundation` (this change fixes its concrete shape); the due/new counts exposed by `daily-plan`.
- **Platform**: requires the user-notifications capability; uses local notifications only — no push entitlement, no APNs, no backend.
- **Downstream / adjacent (not in scope here)**: `daily-plan` supplies the counts; `study-flow`/Today is the deep-link destination and triggers a reschedule on session completion.
