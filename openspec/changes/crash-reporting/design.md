## Context

The app target is thin; logic lives in LoritoKit, whose Domain layer must stay pure.
Analytics already follows a "protocol in the package, SDK sink in the app" pattern
(`AnalyticsSink` / `TelemetryDeckSink`). Build-time IDs come from the gitignored
`Config.local.xcconfig`, which CI writes from secrets.

## Decisions

- **SDK in the app target only.** `ErrorReporting` (protocol) and `ErrorReports`
  (a thread-safe holder of the shared reporter, no-op by default) live in Domain;
  `SentryErrorReporter` in the app target implements it. Persistence and Features
  call `ErrorReports.shared.report(_:area:)`.
- **Closed area enum.** `ErrorArea`: `contentLoad`, `persistenceFallback`,
  `purchase`, `buddy`. Adding an area is a spec change. The reporter sends a new
  `NSError(domain: original domain, code: original code)` tagged with the area —
  `userInfo` (messages, file paths, record names) is dropped before leaving the
  device.
- **Gating.** Start only if the DSN is non-empty, not UI testing, and (Release or
  `-crash-reporting` in Debug). `environment` = `production` / `debug`.
- **Options.** `sendDefaultPii = false`, `attachScreenshot = false`,
  `attachViewHierarchy = false`, `enableAppHangTracking = true`,
  `tracesSampleRate = 0`, `enableAutoPerformanceTracing = false`,
  `enableNetworkBreadcrumbs = false`, `enableCaptureFailedRequests = false`,
  session replay off; `beforeSend` clears `serverName` and `user` except the SDK's
  installation id (needed for crash-free users).
- **DSN in xcconfig.** `//` starts a comment in xcconfig, so `SENTRY_DSN` is stored
  without the scheme (`<key>@o<org>.ingest.de.sentry.io/<project>`) and the app
  prepends `https://`. The DSN is not a secret but stays out of git like the
  TelemetryDeck ID, so forks don't report into our project.
- **dSYMs.** `sentry-cli debug-files upload` (Homebrew `sentry-cli`, installed in
  the workflows) after `build_app`, not the fastlane plugin: CI runs Homebrew
  fastlane without Bundler, where plugins need extra setup. Skipped with a message
  when `SENTRY_AUTH_TOKEN`, `sentry-cli` or the dSYM archive is missing, so local
  builds and forks still work. An organization token carries the EU region URL.
  Org/project slugs via `SENTRY_ORG_SLUG` / `SENTRY_PROJECT_SLUG` (GitHub variables)
  with defaults.
- **Version.** `from: 9.29.0` (released 2026-09-17; ≥ 2 weeks old).

## Risks / Trade-offs

- Always-on diverges from the analytics consent model → disclosed in the privacy
  policy and App Privacy (Crash Data, Performance Data, Other Diagnostic Data — not
  linked, not tracking); no free text can be sent by construction.
- SDK size/start cost → static prebuilt framework, no tracing.
- Extensions not covered → follow-up change if crashes there show up in ASC.
