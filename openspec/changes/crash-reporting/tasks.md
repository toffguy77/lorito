## 1. Domain (TDD)

- [x] 1.1 Failing tests: `ErrorReports.shared` is a no-op by default; a configured reporter receives `(area, domain, code)` only; `ErrorReport.sanitized` drops `userInfo`; areas are a closed enum
- [x] 1.2 `ErrorArea`, `ErrorReport`, `ErrorReporting`, `ErrorReports` (thread-safe holder) in `Domain/Diagnostics`

## 2. Call sites (TDD where testable)

- [x] 2.1 `RootView.load` reports `contentLoad`
- [x] 2.2 `PersistenceController.makeUserContainer` reports `persistenceFallback` when the CloudKit container fails (test with a failing factory)
- [x] 2.3 `PurchaseService`: purchase and restore errors report `purchase`; cancelled and pending outcomes don't; product loading isn't reported (offline is normal) (tests with the fake store)
- [x] 2.4 Study buddy: accepting a share (app scene delegate) and sending a nudge report `buddy` on failure (test with the fake backend)

## 3. App target

- [x] 3.1 `project.yml`: `Sentry` package (`from: 9.29.0`, product `Sentry`) for the app target; `SentryDSN: "$(SENTRY_DSN)"` in Info.plist; `SENTRY_DSN =` in `Config.xcconfig` with the no-scheme note
- [x] 3.2 `CrashReporting.swift`: gating (DSN, UI testing, Debug flag), options per design, `beforeSend` scrubbing, `SentryErrorReporter`; started first in `LoritoApp.init`
- [x] 3.3 Unit-testable gating: `CrashReportingConfig.resolve(rawDSN:uiTesting:debug:arguments:)` in Domain, covered by tests

## 4. Build and release

- [x] 4.1 `build` lane uploads dSYMs with `sentry-cli` when `SENTRY_AUTH_TOKEN` is set, else `UI.important` skip
- [x] 4.2 Workflows install `sentry-cli`, write `SENTRY_DSN` into `Config.local.xcconfig` and pass `SENTRY_AUTH_TOKEN`, `SENTRY_ORG_SLUG`, `SENTRY_PROJECT_SLUG` secrets to fastlane
- [x] 4.3 `docs/privacy.html`: crash-reporting section (Sentry, EU region, what is and isn't sent)
- [x] 4.4 `docs/sentry-setup.md`: owner steps in the browser (org in EU, project, DSN, auth token, IP/data-scrubbing settings, alerts, GitHub secrets, App Privacy answers) and a ready prompt for a browser agent

## 5. Verify

- [x] 5.1 `swift test`; `xcodegen generate` + `xcodebuild` build; full UI test suite (SDK must stay off)
- [ ] 5.2 (manual, owner) Debug run with `-crash-reporting` and a test DSN sends a test event (owner, after setup)
- [x] 5.3 `openspec validate crash-reporting --strict`
