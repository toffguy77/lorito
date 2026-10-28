## Why

Crash reporting covers only the app process. The widget extension (Home and Lock
Screen widgets, the interactive practice widget, the Live Activity) and the Lens
Action extension run in their own processes: a crash there is invisible, and the
Lens extension closes silently when the bundled content fails to load.

## What Changes

- The widget and Lens Action extensions start Sentry with the same DSN, gating and
  privacy limits as the app.
- Extension events carry the app's release (`com.toffguy.lorito@<version>+<build>`)
  and a `component` tag (`app`, `widgets`, `lensAction`), so one release shows all
  three processes and the extensions' dSYMs (already in the archive) symbolicate.
- In extensions, app-hang tracking and release-health sessions are off: widget
  timelines and short-lived extension launches would distort crash-free rates.
- The Lens extension reports a content-load failure (area `contentLoad`) before
  closing.
- The start-up code moves to `Shared/CrashReporting.swift`, compiled into the app
  and both extensions.

## Capabilities

### Modified Capabilities
- `crash-reporting`: extensions covered; component tag; extension limits.

## Impact

- `project.yml` (Sentry dependency, config files and `SentryDSN` for both
  extensions; `Shared/` sources); `Shared/CrashReporting.swift`;
  `LoritoWidgets/LoritoWidgetsBundle.swift`; `LoritoLensAction/ActionViewController.swift`.
- Domain unchanged (`CrashReportingConfig` already decides the gating).
- `docs/privacy.html` unchanged: same data, same provider.
