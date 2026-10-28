## 1. Shared start-up

- [x] 1.1 Move `CrashReporting` to `Shared/CrashReporting.swift` with a `Component` (app, widgets, lensAction): release name of the app, `component` tag, hang tracking and auto sessions off in extensions
- [x] 1.2 `project.yml`: `Shared/` in the three targets; Sentry dependency, `Config.xcconfig` and `SentryDSN` for both extensions

## 2. Call sites

- [x] 2.1 Widget bundle init starts reporting; Lens Action `viewDidLoad` starts reporting and reports a content-load failure before closing

## 3. Verify

- [x] 3.1 `xcodegen generate`; build; the extensions' Info.plist carry `SentryDSN`; the app still reports (Debug `-crash-reporting` run lands with `component: app`)
- [x] 3.2 `swift test`; UI suite on iPhone; `openspec validate crash-reporting-extensions --strict`
