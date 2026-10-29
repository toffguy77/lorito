## Why

Closing «Пройти настройку заново» after picking another level, before the themes step
saved it, left Settings showing the unsaved level while the stored one stayed in use.
The re-run and Settings share one scope model, and its working state was never reset.

Owner request (2026-10-29): fix the bugs found.

## What Changes

- When the re-run is dismissed (closed or completed), Settings reloads the scope from
  the stored settings, so it shows exactly what was saved.

## Capabilities

### Modified Capabilities
- `onboarding-and-selection`: the re-run discards unsaved scope choices on close.

## Impact

- `ScopeSelectionModel.reload()`, `SettingsView` dismissal. No data or schema change.
