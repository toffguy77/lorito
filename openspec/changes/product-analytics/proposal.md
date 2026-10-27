## Why

Lorito has no product analytics. We cannot tell how many people finish
onboarding, come back the next day, or keep a streak, so every retention idea
in the roadmap (recall-first, streak protection, widgets, placement test) would
ship blind. We need the smallest possible measurement layer that keeps the
app's promise — no account, no ads, no personal data — and still answers
D1/D7/D30 and "how many days a week do people study".

## What Changes

- **Anonymous event layer:** a fixed event taxonomy (onboarding steps, session
  start/complete, grade, exercise result, reminder opened, streak extended/lost,
  paywall later) recorded through an `AnalyticsSink` protocol. No account, only the
  provider's salted and hashed anonymous user identifier, no free text, no
  card content.
- **Provider behind a protocol:** TelemetryDeck as the default candidate; a
  no-op sink for tests, previews and opted-out users.
- **Offline buffering:** events are queued on device and flushed when the
  provider is reachable, so the app never waits on the network (relevant for
  users in Russia, where third-party endpoints may be unreachable).
- **Opt-out:** a "Помогать улучшать Lorito" toggle in Settings, on by default,
  honoured immediately (queue purged on opt-out).
- **Metrics definitions:** D1/D7/D30 retention and the north-star "study days
  per week per active learner" defined from events, plus the onboarding funnel.
- **App Privacy label** and privacy policy (`docs/privacy.html`) updated.

## Capabilities

### New Capabilities
- `product-analytics`: event taxonomy, privacy constraints, opt-out, provider
  abstraction with offline buffering, metric definitions.

### Modified Capabilities
<!-- None: existing flows emit events but their behavior is unchanged. -->

## Impact

- **Domain**: `AnalyticsEvent` (enum, no payload beyond enums/ints/bools),
  `AnalyticsSink` protocol, pure `EventQueue` logic.
- **Features**: emit points in onboarding, Today, study/exercise sessions,
  reminder routing, streak updates; Settings toggle.
- **App target**: provider SDK via SPM (TelemetryDeck SwiftSDK) wired in
  `LoritoApp`; app ID in an `xcconfig`, not in source.
- **Docs/metadata**: `docs/privacy.html`, App Store Connect privacy answers.
- `UserSettings` gains `analyticsEnabled: Bool` (default `true`); additive,
  CloudKit-safe.
- Prerequisite for measuring `streak-reminders`, `progress-insights`,
  `home-screen-widgets` and later roadmap changes.
