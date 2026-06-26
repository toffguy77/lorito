## 1. Universal packaging

- [x] 1.1 Set `TARGETED_DEVICE_FAMILY = "1,2"` in `project.yml`
- [x] 1.2 Declare iPad orientations (all four) via the `~ipad` orientation Info.plist key while keeping iPhone portrait-first; regenerate the project
- [x] 1.3 Build for an iPad simulator and confirm it launches and runs

## 2. Adaptive layout

- [x] 2.1 Constrain the study session card and catalog card reader to a comfortable max width and center them on large screens (existing `LoritoSpacing`), leaving iPhone unaffected
- [x] 2.2 Audit Today, onboarding, settings, reminders, and catalog lists at iPad sizes; fix any full-width controls or clipped content
- [x] 2.3 Verify portrait and landscape on iPad for every screen

## 3. Verification & store assets

- [x] 3.1 Capture iPad screenshots via the snapshot harness on an iPad simulator (portrait); confirm layouts visually
- [x] 3.2 Re-run iPhone snapshots to confirm no iPhone regressions
- [x] 3.3 Build, sign, and validate a universal Release IPA (no orientation rejection)
- [x] 3.4 Run `openspec validate ipad-support --strict` and fix until valid
