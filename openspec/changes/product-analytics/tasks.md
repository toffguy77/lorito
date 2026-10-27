## 0. Dependency

- [ ] 0.1 `learning-platform-foundation` applied (item kinds, local learning day)

## 1. Domain (TDD)

- [ ] 1.1 Write failing tests: `AnalyticsEvent` cases encode to name + parameters containing only enum raw values, ints and bools (no item ids, no free text); optional `experiment`/`variant` from the `Experiment` enum
- [ ] 1.2 Write failing tests: pure `EventQueue` — append, cap (2 000, oldest dropped), batch of N, discard events older than 30 days relative to injected "now"
- [ ] 1.3 Write failing tests: `StreakLossDetector` — positive → 0 emits once with previous length; freeze-kept streak emits nothing; repeated launches emit once
- [ ] 1.4 Implement `AnalyticsEvent`, `Experiment`, `AnalyticsSink`, `EventQueue`, `StreakLossDetector`

## 2. Features

- [ ] 2.1 `AnalyticsConsent` in `UserDefaults` (`analytics.consent`), written `granted` on first launch before any event; no-op sink until set; tests with an in-memory defaults suite
- [ ] 2.2 `AnalyticsService`: records via queue, flushes on foreground and after session completion with back-off; purge on opt-out. Tests with a recording sink and a failing sink
- [ ] 2.3 Emit events: onboarding steps/completed, session started/completed, item graded (kind only), exercise answered, reminder opened (via `RemindersRouter`), streak extended; run `StreakLossDetector` on launch
- [ ] 2.4 Settings: toggle "Помогать улучшать Lorito" + explanation + privacy link; UI test that toggling off purges and stops recording

## 3. App target & provider

- [ ] 3.1 Add TelemetryDeck SwiftSDK via SPM to the app target only; app ID from `Config.xcconfig` (gitignored value, documented key)
- [ ] 3.2 `TelemetryDeckSink` adapter; no-op sink in DEBUG unless `-analytics` launch argument
- [ ] 3.3 Verify the app launches and studies normally with network disabled

## 4. Disclosures & dashboards

- [ ] 4.1 Update `docs/privacy.html` (RU): what is collected, why, how to opt out
- [ ] 4.2 Prepare App Store Connect privacy answers: Usage Data → Product Interaction, not linked, not tracking
- [ ] 4.3 Define dashboard queries: onboarding funnel, D1/D7/D30, study days per week

## 5. Validation

- [ ] 5.1 `swift test` green
- [ ] 5.2 `xcodebuild` build; UI tests green
- [ ] 5.3 Manual: events visible in provider test mode; airplane-mode session then flush
- [ ] 5.4 `openspec validate product-analytics --strict`
