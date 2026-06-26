## Context

v1.0.1 is iPhone-only because an iPad build declaring only `UIInterfaceOrientationPortrait` fails App Store validation ("must support all orientations for iPad multitasking"). The codebase is plain SwiftUI in the `Features` layer over design-system tokens, so it already adapts reasonably; the work is enabling the iPad device family, satisfying the orientation rule, and tightening a few layouts for large screens. No `Domain`/`Persistence` changes.

## Goals / Non-Goals

**Goals:**
- Ship a universal binary (iPhone + iPad) that passes App Store validation.
- Every existing screen renders correctly on iPad in portrait and landscape.
- Reading/card columns stay a comfortable width on large screens (not edge-to-edge).

**Non-Goals:**
- iPad-specific features, multi-column/split-view navigation, or Stage Manager-specific work.
- Any change to study logic, sync, or behavior.
- New design tokens unless a gap is found.

## Decisions

- **Universal family + all orientations on iPad.** Set `TARGETED_DEVICE_FAMILY = "1,2"`; declare all four orientations for iPad while keeping iPhone portrait-first via the size-class/`UISupportedInterfaceOrientations~ipad` key. Rationale: satisfies Apple's iPad requirement without forcing iPhone landscape. *Alternative — opt out of multitasking* (`UIRequiresFullScreen`) is discouraged and still needs orientations.
- **Constrain reading width, don't redesign.** Wrap the study card and card reader (and other long-form content) in a centered container with a sensible `maxWidth` (e.g., ~640pt) using existing `LoritoSpacing`. Rationale: full-bleed text/tables on a 13" iPad are hard to read; centering keeps line length comfortable with minimal change. Tab/list screens keep native adaptive behavior.
- **Verify via the existing snapshot harness on an iPad simulator.** Reuse the `LoritoUITests`/snapshot flow to capture iPad screenshots and visually confirm layouts. Rationale: same tooling already proven for iPhone screenshots.

## Risks / Trade-offs

- **Layout regressions on iPhone from width caps** → apply `maxWidth` with `frame(maxWidth:)` + centering so iPhone (narrower than the cap) is unaffected; verify iPhone snapshots still look right.
- **Orientation key mistakes re-trigger the validation error** → validate a signed build before tagging; the original failure is the canary.
- **Larger QA surface (2 device classes × orientations)** → rely on snapshot captures for the key screens; behavior is identical so logic tests are unchanged.
