## Context

The app is a single target with logic in `LoritoKit`; user data is SwiftData
with optional CloudKit. Widget extensions run in a separate process with tight
memory limits; sharing a CloudKit-backed SwiftData store with an extension is
fragile (concurrent containers, sync state). Mockup: `design/mockups/Widgets.dc.html`.

## Goals / Non-Goals

**Goals:** glanceable streak/plan, one in-place practice question, a session
Live Activity, a share card — all reading a tiny, versioned snapshot.

**Non-Goals:** grading SRS cards from a widget; push-driven widget updates;
watchOS complications; StandBy-specific layouts beyond system defaults.

## Decisions

**Snapshot file, not a shared database.** `WidgetSnapshot` (Codable, `version: 1`)
holds: `generatedAt`, `day`, `currentStreak`, `studiedToday`, `dueToday`,
`newToday`, `remainingToday`, `wordOfDay {spanish, note, cardID}`,
`questions [ {id, prompt, options, answer, cardID} ]` (up to 3, from
multiple-choice exercises in scope). Written atomically to
`<AppGroup>/widget-snapshot.json`. Unknown versions → widgets show a neutral
"Откройте Lorito" state. Rationale: zero coupling to SwiftData/CloudKit in the
extension; trivially testable.

**Refresh triggers mirror reminders.** Write the snapshot on launch, on
foreground/day rollover, and after a session completes — the same hooks
`MainTabView` already uses to reschedule reminders — then call
`WidgetCenter.shared.reloadAllTimelines()`. Timelines also schedule an entry at
next local midnight so "studied today" resets without the app.

**Interactive question is practice only.** Buttons are `Button(intent:)` with
`AnswerQuestionIntent(questionID, option)`, which stores the chosen option in
the App Group defaults and reloads the widget to show correct/incorrect and
"Дальше". It never writes `CardReview`/`StudyLog`, so the SRS stays consistent
with the in-app grading model. Tapping elsewhere deep-links to the card.

**Live Activity owned by the session.** `SessionActivityController.start` on
session open (if `ActivityAuthorizationInfo().areActivitiesEnabled`), `update`
after each grade (position, total, minutes-left estimate = remaining × median
seconds per card from this session, default 45 s), `end` with
`.after(now + 2 min)` on completion or exit. No push token.

**Share card rendered on device.** `StreakShareCard` (SwiftUI, 1080×1920
logical) rendered by `ImageRenderer` and shared via `ShareLink`. Contains only
the streak count and a static Spanish proverb — no personal data.

**Fonts in the extension.** The extension links `DesignSystem` and calls
`FontRegistry.registerAll()` in its `WidgetBundle` init; fallbacks apply if
registration fails.

## Risks / Trade-offs

- [Snapshot stale if the app is not opened] → midnight timeline entry resets
  "today"; streak-at-risk text is computed from `day` vs current date in the
  provider.
- [App Group adds signing work] → one-time; documented in tasks.
- [Live Activity budget] → one activity at a time, ended on exit.
- [App Group moves the SwiftData store] → with the group entitlement,
  SwiftData's default `ModelConfiguration` places the store in the group
  container, which would orphan existing users' data on update. The store is
  pinned to the app container (`groupContainer: .none`); only the snapshot file
  lives in the group.
- [Day boundary] → widgets use the app's existing day calendar (UTC, as the
  streak and daily plan do) so they never disagree with the app; timelines
  refresh at both the next local midnight and the next UTC day start.
