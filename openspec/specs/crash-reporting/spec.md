# crash-reporting Specification

## Purpose
TBD - created by archiving change crash-reporting. Update Purpose after archive.
## Requirements
### Requirement: Crash and hang reporting
Release builds SHALL report crashes and app hangs to Sentry when a DSN is configured. Reporting SHALL be off in UI-testing launches, in Debug builds unless launched with `-crash-reporting`, and whenever the DSN is empty. Reporting SHALL NOT depend on the analytics consent setting.

#### Scenario: Release build with a DSN
- **WHEN** a Release build with a configured DSN crashes
- **THEN** the crash is reported on the next launch, tagged with the app version and build

#### Scenario: No DSN
- **WHEN** the build has no DSN configured
- **THEN** the SDK is not started and nothing is sent

#### Scenario: UI tests
- **WHEN** the app is launched with `-lorito-ui-testing`
- **THEN** the SDK is not started

### Requirement: Privacy limits on reports
Reports SHALL NOT include default PII, IP-derived user data, screenshots, view hierarchies, session replays, performance traces, network breadcrumbs, failed-request captures or the device name, and SHALL NOT include card, answer, analysed or personal-word text.

#### Scenario: Device name stripped
- **WHEN** any event is about to be sent
- **THEN** its server name and user fields other than the SDK installation id are empty

### Requirement: Non-fatal errors from a closed set of areas
The package SHALL report non-fatal errors only through a pure `ErrorReporting` abstraction in `Domain` with a closed area set — content load, persistence fallback, purchase, study buddy — and SHALL send only the area, the error domain and the error code, never the error's message or user info.

#### Scenario: Content fails to load
- **WHEN** the bundled content cannot be loaded at launch
- **THEN** an error with area `contentLoad` and the original domain and code is reported, without its message

#### Scenario: Cancelled purchase not reported
- **WHEN** the user cancels a purchase
- **THEN** no error is reported

#### Scenario: Synced store falls back to local
- **WHEN** the CloudKit-backed container cannot be created and the app falls back to the local store
- **THEN** an error with area `persistenceFallback` is reported

### Requirement: Symbolicated builds
The release build lane SHALL upload the build's dSYMs to Sentry when an auth token is available, and SHALL skip the upload with a message otherwise without failing the build.

#### Scenario: Local build without token
- **WHEN** the build lane runs without `SENTRY_AUTH_TOKEN`
- **THEN** the build succeeds and the log says the dSYM upload was skipped

### Requirement: Extensions report crashes
The widget extension and the Lens Action extension SHALL start crash reporting with the app's DSN, gating and privacy limits. Their events SHALL use the app's release name and carry a `component` tag (`app`, `widgets`, `lensAction`); the app's events SHALL carry `component: app`. Extensions SHALL NOT track app hangs or release-health sessions. The Lens Action extension SHALL report a content-load failure with area `contentLoad` before it closes.

#### Scenario: Widget crash
- **WHEN** the widget extension of a Release build with a DSN crashes
- **THEN** the crash is reported under the app's release with `component: widgets`

#### Scenario: Lens content fails to load
- **WHEN** the Lens Action extension cannot load the bundled content
- **THEN** an error with area `contentLoad` is reported and the extension closes

#### Scenario: No sessions from extensions
- **WHEN** a widget timeline is refreshed
- **THEN** no release-health session is started

