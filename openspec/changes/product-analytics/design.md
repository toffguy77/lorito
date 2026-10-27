## Context

The app is offline-first, local-first (SwiftData, optional CloudKit) and
advertises "без регистрации и рекламы". There is no backend. The App Store
page and privacy policy currently state that no data is collected. The audit
(doc "Lorito — продуктовый аудит") ranks analytics as P0: without it no
retention mechanic can be evaluated.

## Goals / Non-Goals

**Goals:**
- Answer: onboarding completion, D1/D7/D30, study days per week, session
  completion, reminder → session conversion, exercise accuracy by type.
- Zero personal data; one switch to turn it off.
- Never block or slow the UI; work when offline or when the endpoint is blocked.

**Non-Goals:**
- Per-user dashboards, cohorts by name, attribution/IDFA, ad networks.
- Crash reporting (Xcode Organizer already covers it).
- A/B testing framework (later; this change only lets experiments be measured
  by an `experiment` + `variant` signal parameter).

## Decisions

**Event taxonomy is a closed Swift enum.** `AnalyticsEvent` cases with
enum/int/bool associated values only, e.g. `onboardingStep(.level)`,
`sessionStarted(due: Int, new: Int)`, `cardGraded(grade, revealed: Bool)`,
`exerciseAnswered(type, correct: Bool)`, `sessionCompleted(cards: Int,
firstTryShare: Int /*percent*/)`, `reminderOpened`, `streakExtended(length)`,
`streakLost(previous)`. No strings from content or the user can enter the
payload; card IDs are excluded to avoid fingerprinting study history.
Rationale: a closed enum makes "no PII" reviewable in one file and testable.

**Provider behind `AnalyticsSink`.** `Domain` defines the protocol and the
event type; `Features` holds `AnalyticsService` (queue + sink); the app target
injects the concrete sink. Default candidate: TelemetryDeck, whose SDK salts and
hashes the user identifier on device and the server hashes it again with its
own salt (https://telemetrydeck.com/docs/articles/anonymization-how-it-works/);
Swift SDK: https://github.com/TelemetryDeck/SwiftSDK. Open question: what the
provider stores about IP addresses — check their privacy FAQ
(https://telemetrydeck.com/docs/guides/privacy-faq/) before shipping. Alternative if it is unreachable from
target regions: a self-hosted endpoint later; out of scope here.

**Offline queue.** Events append to a bounded on-disk queue (JSON lines in
Application Support, cap 2 000 events, oldest dropped) and flush in batches on
foreground and after sessions, with exponential back-off. The queue logic
(append, cap, batch, drop) is pure and unit-tested; I/O sits in Features.

**Opt-out semantics.** `UserSettings.analyticsEnabled` (default `true`,
synced). When false: sink becomes no-op, the queue is purged, nothing is
recorded until re-enabled. Toggle copy: "Помогать улучшать Lorito" with a
one-line explanation and link to the privacy policy.

**Metric definitions (computed in the provider dashboard):**
- Active learner on day *d*: ≥ 1 `cardGraded` or `exerciseAnswered` on *d*.
- D*N* retention: share of users whose first event was on day 0 and who are
  active on day *N*.
- North-star: mean number of active days in a calendar week per user active
  that week.
- Onboarding funnel: `onboardingStep` sequence → `onboardingCompleted` →
  first `sessionCompleted`.

**App Privacy label.** Declare "Usage Data → Product Interaction", not linked
to the user, not used for tracking, per Apple's App Privacy details categories
(https://developer.apple.com/app-store/app-privacy-details/).

## Risks / Trade-offs

- [Endpoint blocked or slow in some regions] → bounded offline queue; events
  older than 30 days are dropped rather than retried forever; analytics bias
  toward reachable users is noted in dashboards.
- [Users distrust any telemetry in a "no data" app] → explicit toggle,
  plain-language description, privacy policy diff in release notes.
- [Event sprawl] → new events require editing the closed enum and this spec.

## Migration Plan

Ship in a minor release with updated privacy policy and App Store privacy
answers in the same submission. Rollback: switch the injected sink to no-op
(one line in the app target); the queue is purged on next launch.
