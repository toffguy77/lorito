## Why

Lorito v1.0.1 shipped **iPhone-only** (`TARGETED_DEVICE_FAMILY = 1`) — a deliberate v1 shortcut, because an iPad build that declares only portrait orientation fails App Store validation (iPad requires supporting all orientations or opting out of multitasking). Many learners use iPads, and the app's content (cards with tables, callouts, catalog lists) reads well on a larger screen. This change makes Lorito a proper universal app: installable and usable on iPad, with layouts that hold up at iPad sizes and orientations.

## What Changes

- **Make the app universal**: set `TARGETED_DEVICE_FAMILY = "1,2"` and declare the orientation support iPad requires (all orientations on iPad; iPhone may remain portrait).
- **Verify and adapt layouts at iPad sizes**: the Today, study session, catalog (levels → themes → cards + reader), onboarding, settings, and reminders screens render correctly on iPad in portrait and landscape — no clipped content, no awkwardly stretched full-width controls, readable measure for card bodies/tables.
- **Constrain content width** where full-bleed looks wrong on a large screen (e.g., cap the study card / reading column to a comfortable max width and center it) using design-system spacing, without introducing new tokens unless needed.
- **Keep behavior identical**: no feature differences between iPhone and iPad; same Domain logic, same flows. This is a presentation/packaging change.
- **App Store**: the universal binary uploads and validates with the iPad orientation requirement satisfied; iPad screenshots are added for the listing.

## Capabilities

### New Capabilities
- `ipad-support`: Universal (iPhone + iPad) packaging and adaptive layout — declaring iPad device family and required orientations, ensuring every existing screen renders correctly at iPad sizes in portrait and landscape, and constraining reading/card width on large screens, with no change to app behavior or Domain logic.

### Modified Capabilities
<!-- None at the requirement level. The existing study-flow, catalog, onboarding-and-selection, and reminders screens keep their behavioral requirements; this change only ensures they render correctly on a new device class and adjusts packaging. -->

## Impact

- **Code**: `project.yml` (`TARGETED_DEVICE_FAMILY` and orientation Info.plist keys); `Features` SwiftUI screens (max-width/centering tweaks where needed for large screens) using existing `DesignSystem` tokens; no `Domain`/`Persistence` changes.
- **App Store / signing**: a universal binary; iPad screenshots for the App Store listing (12.9"/13" class) generated via the existing fastlane snapshot path on an iPad simulator.
- **Foundation contracts consumed (not modified)**: all existing screens and `DesignSystem` components; no new dependencies.
