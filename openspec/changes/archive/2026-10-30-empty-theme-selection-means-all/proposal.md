## Why

The daily planner treats a stored empty theme selection as "all themes in scope", but
the scope model read it literally: Settings showed no theme selected and the setup
re-run blocked «Далее» on the themes step («Выберите хотя бы одну тему»). Found while
capturing App Store screenshots from the demo store, whose settings have no themes
stored; any user whose settings carry an empty list hits the same dead end.

Owner request (2026-10-30): fix bugs found along the way and ship new builds.

## What Changes

- Loading the scope (launch, Settings, setup re-run, reload) turns a stored empty theme
  selection into every theme of the included levels, matching the planner.

## Capabilities

### Modified Capabilities
- `onboarding-and-selection`: a stored empty theme selection means all in-scope themes.

## Impact

- `ScopeSelectionModel` init and `reload()`. No data or schema change; the next persist
  writes the explicit list.
