## Why

The picture-matching exercises use **OpenMoji** images under **CC BY-SA 4.0**, which *requires* visible attribution wherever the app is distributed. The app has no place to show credits today, so it can't ship the OpenMoji assets compliantly. This change adds an **About / Licenses** screen (reachable from Settings) that surfaces third-party attributions, and — since we're making the OpenMoji-based type release-ready — expands the A1 picture-matching vocabulary set to its practical maximum.

## What Changes

- Add an **About / Licenses screen** (`about` capability): a Settings entry «О приложении» opening a screen that lists third-party credits — OpenMoji (CC BY-SA 4.0), MarkdownUI (MIT) — with name, license, and source. Data is a static in-app list; no network.
- **Expand A1 picture-matching**: add ~25 more OpenMoji everyday-vocabulary emojis (family, body, more animals, more food) and 6 more `picture-matching` exercises on A1-30 (14 total; bundle → 892 exercises, 57 assets).
- Wire the About entry into `SettingsView`; recompile the bundle; keep all tests green and verify the screen on the simulator.

## Capabilities

### New Capabilities
- `about`: An in-app About / Licenses screen that lists third-party attributions (name, license, source), satisfying the OpenMoji CC BY-SA attribution requirement, reachable from Settings.

### Modified Capabilities
<!-- content-model "Exercise-type variety" already records picture-matching as enabled; this change only adds more of that content, no requirement change. -->

## Impact

- **Features (added)**: an About/Licenses screen + a Settings navigation entry.
- **Content (added)**: ~25 more `content/exercise-assets/*.png` (OpenMoji) + 6 more A1-30 `picture-matching` exercises.
- **Bundle (regenerated)**: `content.json` + `Resources/exercise-assets/`.
- **Tests (added)**: the licenses list is non-empty and includes OpenMoji; a UI test opens the screen.
- **Licensing**: this is precisely the mechanism that makes the OpenMoji assets compliant to ship.
- **No new third-party dependencies.**
