## Why

Lorito has no visibility into crashes, hangs or failures in the field: App Store
Connect crash logs arrive late, unsymbolicated for extensions and only from users
who share diagnostics. The roadmap added CloudKit sharing, StoreKit, camera/Live
Text and an Action extension — exactly the code that fails on real devices and not
in the simulator. The owner chose Sentry (2026-10-28): crashes + errors only, EU
data region, always on (no separate switch).

## What Changes

- **Sentry SDK** (`sentry-cocoa`, SPM, prebuilt static `Sentry` product) in the
  app target only; the LoritoKit package stays SDK-free.
- **Crash and hang reporting** in Release builds when a DSN is configured; off in
  UI tests, in Debug unless launched with `-crash-reporting`, and when no DSN is set.
- **Privacy by configuration:** no default PII, no screenshots, no view hierarchy,
  no session replay, no performance tracing, no network breadcrumbs or failed-request
  capture; device name stripped. Release health sessions stay on (crash-free rate).
- **Non-fatal errors from a closed set of areas** (content load, persistence
  fallback, purchase, study buddy) through a pure `ErrorReporting` abstraction in
  `Domain`; only the area, error domain and code are sent — never messages,
  user data or text.
- **Always on** (owner decision): not tied to «Помогать улучшать Lorito»; the privacy
  policy and App Privacy answers disclose crash and diagnostic data, not linked, no
  tracking.
- **Build:** DSN via `SENTRY_DSN` in `Config.local.xcconfig` (CI secret), dSYM upload
  in the Fastlane `build` lane when `SENTRY_AUTH_TOKEN` is present.
- Owner setup in the browser (Sentry org in the EU region, project, DSN, auth
  token, data-scrubbing settings) documented as a step-by-step guide.

## Capabilities

### New Capabilities
- `crash-reporting`: crash, hang and non-fatal error reporting with privacy limits.

### Modified Capabilities
- `product-analytics`: privacy disclosures cover crash and diagnostic data.

## Impact

- `project.yml` (package, Info.plist key), `Lorito/Config.xcconfig`,
  `Lorito/Sources/CrashReporting.swift`, `LoritoApp.swift`.
- `Domain/Diagnostics/ErrorReporting.swift`; call sites in `RootView`,
  `PersistenceController`, `PurchaseService`, buddy.
- `fastlane/Fastfile`, `.github/workflows/*.yml`,
  `docs/privacy.html`, `docs/sentry-setup.md`.
- Widgets and the Lens Action extension are not instrumented (follow-up).
