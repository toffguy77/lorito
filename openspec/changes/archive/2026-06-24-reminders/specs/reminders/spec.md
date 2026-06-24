## ADDED Requirements

### Requirement: Reminder configuration shape
The `UserSettings.reminderConfig` defined by `app-foundation` SHALL have a concrete shape consisting of an `enabled` flag and an ordered set of one or more daily reminder times, each a local hour and minute (0–23, 0–59). When `enabled` is false the app SHALL schedule no reminders. The app SHALL allow the user to add, edit, and remove reminder times, and SHALL keep at least one time whenever reminders are enabled. This change SHALL consume the foundation `UserSettings` model and SHALL NOT redefine it.

#### Scenario: Enabling reminders persists a configuration
- **WHEN** the user enables reminders and sets a time of 20:00
- **THEN** `reminderConfig.enabled` is true and `reminderConfig` contains a daily time of 20:00, persisted in `UserSettings`

#### Scenario: Multiple times per day are supported
- **WHEN** the user adds reminder times 09:00 and 20:00
- **THEN** `reminderConfig` contains both 09:00 and 20:00 as distinct daily times

#### Scenario: Disabling clears scheduling intent
- **WHEN** the user disables reminders
- **THEN** `reminderConfig.enabled` is false and the app schedules no notification requests

### Requirement: Notification authorization flow
The app SHALL request notification authorization through a clear flow before scheduling reminders, and SHALL handle the `notDetermined`, `denied`, and `authorized` (including provisional) states gracefully. When authorization is `notDetermined`, enabling reminders SHALL trigger the system authorization prompt. When authorization is `denied`, the app SHALL NOT attempt to schedule and SHALL present guidance directing the user to iOS Settings to enable notifications. When authorization is `authorized` (or provisional), the app SHALL proceed to schedule reminders per the configuration.

#### Scenario: First enable requests authorization
- **WHEN** the user enables reminders while authorization status is `notDetermined`
- **THEN** the app requests notification authorization from the system

#### Scenario: Denied authorization guides to Settings
- **WHEN** the user enables reminders while authorization status is `denied`
- **THEN** the app does not schedule notifications and shows guidance to enable notifications in iOS Settings

#### Scenario: Authorized proceeds to schedule
- **WHEN** authorization status is `authorized` and reminders are enabled
- **THEN** the app proceeds to schedule notification requests per `reminderConfig`

### Requirement: Pure scheduling decision
The set of notification requests to schedule SHALL be produced by a pure decision function in the `Domain` layer that takes the reminder times, the due/new counts for the relevant day(s), and an injected "now"/clock, and returns the exact set of notification requests (each with a stable identifier, a calendar trigger date, and a localized title and body). The decision function SHALL NOT perform I/O, SHALL NOT call any system notification API, and SHALL NOT read any ambient clock (e.g. `Date.now`); for identical inputs it SHALL return identical output.

#### Scenario: Same inputs produce same requests
- **WHEN** the decision function is called twice with the same times, the same counts, and the same injected "now"
- **THEN** both calls return identical sets of notification requests (identifiers, trigger dates, titles, bodies)

#### Scenario: No hidden clock or I/O
- **WHEN** the decision function computes trigger dates
- **THEN** the result depends only on the injected "now" and the inputs, and the function performs no notification-API or persistence access

#### Scenario: A request per future configured time
- **WHEN** reminders are enabled with times 09:00 and 20:00 and at least one count is non-zero for those days
- **THEN** the returned requests include one request per configured time within the scheduling horizon, each triggering at that local time

### Requirement: Content reflects the day's counts
Each scheduled notification's body SHALL reflect the due/new counts for the day it fires, expressed in Russian (e.g. "5 тем на повторение + 1 новая"). The wording SHALL distinguish the review (due) count from the new-card count, and SHALL use grammatically appropriate Russian for the counts.

#### Scenario: Body shows due and new counts
- **WHEN** a reminder is scheduled for a day with 5 due reviews and 1 new card
- **THEN** the notification body conveys both 5 reviews and 1 new card in Russian

#### Scenario: Only reviews due
- **WHEN** a reminder is scheduled for a day with due reviews and no new cards
- **THEN** the notification body conveys the review count and does not assert a new card is available

### Requirement: Skip reminders when nothing is due
When the due count and the new-card count for a given day are both zero, the decision function SHALL produce no notification request for that day (the reminder for that day is skipped rather than firing an empty or misleading nudge).

#### Scenario: Nothing due means no notification
- **WHEN** a day has 0 due reviews and 0 new cards
- **THEN** the decision function returns no notification request for that day

#### Scenario: Other days unaffected by a skipped day
- **WHEN** one day in the horizon has nothing due but a later day has cards due
- **THEN** the skipped day yields no request while the later day still yields its request(s)

### Requirement: Rescheduling triggers
The app SHALL recompute and re-schedule reminders — clearing previously scheduled reminder requests and applying the current decision — on each of: a change to `reminderConfig`, completion of a study session, app launch, and day rollover (the local calendar day changing while the app is running). Re-scheduling SHALL be idempotent: repeated triggers with unchanged inputs SHALL leave the same set of pending reminder requests.

#### Scenario: Settings change reschedules
- **WHEN** the user changes a reminder time
- **THEN** the app clears its previously scheduled reminder requests and schedules the requests for the new configuration

#### Scenario: Completing a session reschedules
- **WHEN** the user completes a study session
- **THEN** the app reschedules reminders so upcoming notifications reflect the updated due/new counts

#### Scenario: Launch reschedules
- **WHEN** the app launches with reminders enabled and authorization granted
- **THEN** the app reschedules reminders for the current configuration and counts

#### Scenario: Day rollover reschedules
- **WHEN** the local calendar day changes while the app is running
- **THEN** the app reschedules reminders for the new day

#### Scenario: Repeated reschedule is idempotent
- **WHEN** rescheduling runs twice with unchanged configuration and counts
- **THEN** the resulting set of pending reminder requests is the same after both runs

### Requirement: Scheduler behind a protocol
System notification access SHALL be hidden behind a `NotificationScheduling` protocol that abstracts requesting authorization, querying authorization status, scheduling notification requests, and removing pending reminder requests. Production code SHALL use a `UNUserNotificationCenter`-backed implementation; tests SHALL be able to substitute a fake conforming to the same protocol. The pure decision function SHALL NOT depend on this protocol or on `UNUserNotificationCenter`.

#### Scenario: Production uses the system center
- **WHEN** the app schedules reminders at runtime
- **THEN** it does so through the `NotificationScheduling` protocol backed by `UNUserNotificationCenter`

#### Scenario: Tests use a fake scheduler
- **WHEN** the scheduling service is exercised in a unit test
- **THEN** a fake conforming to `NotificationScheduling` is injected and records the scheduled and removed requests without touching the system

### Requirement: Respect the pending-notification limit
The app SHALL respect the iOS limit on pending notification requests (64). The decision function SHALL bound the number of reminder requests it produces to a fixed scheduling horizon such that the total never exceeds the limit, and SHALL prioritize the soonest reminders. When the app removes its own reminder requests before rescheduling, it SHALL remove only its reminder requests and SHALL NOT assume it owns the entire pending-request budget.

#### Scenario: Output stays within the limit
- **WHEN** the configuration has many times across a multi-day horizon
- **THEN** the decision function returns at most the limit's worth of reminder requests, keeping the soonest ones

#### Scenario: Removal is scoped to reminder requests
- **WHEN** the app clears its scheduled reminders before rescheduling
- **THEN** it removes only the reminder requests it created and leaves any unrelated pending requests intact

### Requirement: Tapping a reminder opens Today/study
A reminder notification SHALL carry the information needed to route the app to the Today/study entry point, and tapping it SHALL open the app to that entry point. The routing SHALL work whether the app was launched from terminated, backgrounded, or foreground states.

#### Scenario: Tap routes to Today
- **WHEN** the user taps a reminder notification
- **THEN** the app opens to the Today/study entry point

#### Scenario: Tap from terminated state routes correctly
- **WHEN** the app is not running and the user taps a reminder notification
- **THEN** the app launches and navigates to the Today/study entry point
