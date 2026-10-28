## ADDED Requirements

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
