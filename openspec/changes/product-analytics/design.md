## Context

The app is offline-first, local-first (SwiftData, optional CloudKit) and
advertises "без регистрации и рекламы". There is no backend. The App Store
page and privacy policy currently state that no data is collected. The audit
(doc "Lorito — продуктовый аудит") ranks analytics as P0: without it no
retention mechanic can be evaluated. `learning-platform-foundation`
introduces item kinds (`card`, `conj`, `word`, `ccse`) and the local
learning day; this change reuses both.

## Goals / Non-Goals

**Goals:**
- Answer: onboarding completion, D1/D7/D30, study days per week, session
  completion, reminder → session conversion, exercise accuracy by type.
- Zero personal data; one per-device switch to turn it off.
- Never block or slow the UI; work when offline or when the endpoint is blocked.
- Let later changes add events without editing this change.

**Non-Goals:**
- Per-user dashboards, attribution/IDFA, ad networks.
- Crash reporting (Xcode Organizer already covers it).
- An A/B assignment engine (later); this change only defines the
  `experiment` / `variant` properties experiments will use.

## Decisions

**Event taxonomy is a closed Swift enum, extended by spec.** `AnalyticsEvent`
cases carry enum/int/bool values only: `onboardingStep(step)`,
`onboardingCompleted`, `sessionStarted(due:new:)`, `sessionCompleted(items:
firstTryPercent:)`, `itemGraded(kind, grade, revealed)`,
`exerciseAnswered(type, correct)`, `reminderOpened`, `streakExtended(length)`,
`streakLost(previous)`. No item ids or text enter the payload. Other changes
add cases (e.g. `paywallShown`, `placementCompleted`, `lensUsed`,
`buddyInvited`) by an ADDED requirement in `product-analytics` and a new enum
case; nothing else may emit events.

**Experiment properties.** Any event may carry two optional string-enum
properties, `experiment` and `variant`, taken from a closed
`Experiment` enum defined in `Domain`, so experiment arms never contain free
text.

**streakLost is computed, not observed.** A streak is lost when the user does
nothing, so there is no moment to record it. On each launch, a pure
`StreakLossDetector` compares the stored "last reported streak" (device-local)
with the streak computed by `stats-and-streak` for the local learning day; if
the previous streak was > 0 and the current is 0, it emits
`streakLost(previous)` once. Days covered by a streak freeze (from the
streak-protection change, when it exists) are not breaks, because the streak
calculator already treats them as kept; the detector only reads its result.

**Provider behind `AnalyticsSink`.** `Domain` defines the protocol and the
event type; `Features` holds `AnalyticsService` (queue + sink); the app target
injects the concrete sink. Default candidate: TelemetryDeck, whose SDK salts and
hashes the user identifier on device and the server hashes it again with its
own salt (https://telemetrydeck.com/docs/articles/anonymization-how-it-works/);
Swift SDK: https://github.com/TelemetryDeck/SwiftSDK. Open question: what the
provider stores about IP addresses — check its privacy FAQ
(https://telemetrydeck.com/docs/guides/privacy-faq/) before shipping.
Alternative if unreachable from target regions: a self-hosted endpoint later.

**Offline queue.** Events append to a bounded on-disk queue (JSON lines in
Application Support, cap 2 000 events, oldest dropped) and flush in batches on
foreground and after sessions, with exponential back-off. The queue logic
(append, cap, batch, age-out) is pure and unit-tested; I/O sits in Features.

**Consent is device-local.** Stored in `UserDefaults` (key
`analytics.consent`: `granted` / `denied`), never synced through CloudKit, so
a choice on one device does not silently enable collection on another. On
first launch the value is written as `granted` (default on) before any event
is recorded; until that write happens the sink is no-op. Turning it off
purges the queue immediately. Toggle copy: "Помогать улучшать Lorito" with a
one-line explanation and a link to the privacy policy.

**Metric definitions (computed in the provider dashboard):**
- Active on day *d* (local learning day): ≥ 1 `itemGraded` or
  `exerciseAnswered` on *d*.
- D*N* retention: share of users whose first event was on day 0 and who are
  active on day *N*.
- North-star: mean number of active days in a calendar week per user active
  that week.
- Onboarding funnel: `onboardingStep` sequence → `onboardingCompleted` →
  first `sessionCompleted`.

**App Privacy label.** Declare "Usage Data → Product Interaction", not linked
to the user, not used for tracking, per Apple's App Privacy categories
(https://developer.apple.com/app-store/app-privacy-details/).

## Risks / Trade-offs

- [Endpoint blocked or slow in some regions] → bounded offline queue; events
  older than 30 days are dropped; dashboards note bias toward reachable users.
- [Users distrust telemetry in a "no data" app] → explicit toggle,
  plain-language description, privacy policy diff in release notes.
- [Event sprawl] → new events only via ADDED requirements + enum cases.
- [streakLost reported late] → it is attributed to the launch day; dashboards
  treat it as "lost since last launch".

## Migration Plan

Ship in a minor release with updated privacy policy and App Store privacy
answers in the same submission. Rollback: switch the injected sink to no-op
(one line in the app target); the queue is purged on next launch.
