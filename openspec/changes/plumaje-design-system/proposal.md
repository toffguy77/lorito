## Why

The current "Modern Calm" system (indigo accent, SF Pro, emoji in empty states)
is clean but generic: nothing on screen says "Spanish", nothing is recognizable
in a screenshot, and the App Store presence is indistinguishable from dozens of
flash-card apps. Lorito is heading for a public launch, design awards and
investor demos, so the visual identity has to carry the product. The redesign
"Plumaje" gives Lorito an ownable language — the inverted marks ¡ ¿ as a brand
glyph, a parrot palette, and a typographic rule that makes the target language
visible at a glance — without changing any study behavior.

## What Changes

- **BREAKING (visual):** replace the "Modern Calm" tokens with "Plumaje":
  accent becomes parrot green (Loro `#0E7C47`), plus Lima highlight, Chile
  danger, and Tinta ink surfaces; every token keeps a light and dark value.
  Source of truth: `design/brand/tokens.json`.
- **Typography with two voices:** bundle three OFL font families —
  Unbounded (titles, numbers), Onest (Russian UI), Instrument Serif Italic
  (Spanish text only) — registered at launch, Dynamic Type preserved via
  `relativeTo`.
- **New app icon:** "¡" whose dot is the parrot's eye; light, dark and tinted
  variants (iOS 18+) from vector sources in `design/brand/`.
- **Components:** restyle chip, day-progress, callouts, grade buttons,
  study-card container; add a primary pill button, a floating tab bar, a plan
  hero card, a `SpanishText` view and a segmented session progress bar. Emoji
  in empty/complete states are replaced by typographic marks.
- **Focus mode:** the study and exercise sessions render on ink in both
  themes.
- **Screen restyle (no behavior change):** Today, study session, exercises,
  catalog, progress, onboarding and settings adopt the new tokens and
  components. Data, navigation and flows stay as specified today.

## Capabilities

### New Capabilities
<!-- None — this extends design-system. -->

### Modified Capabilities
- `design-system`: new semantic token set and accent; typography scale built on
  bundled fonts with a dedicated Spanish style; extended core components; focus
  surfaces; bundled-font registration; app icon variants; contrast guarantee.

## Impact

- **DesignSystem**: `LoritoColor`, `LoritoFont`, `LoritoSpacing`,
  `LoritoRadius`, `LoritoElevation` rewritten from `tokens.json`; new
  `FontRegistry`; new/updated components; gallery updated. `Package.swift`
  declares `Resources/Fonts` as processed resources of `DesignSystem`.
- **Features**: call sites switch to the new tokens/components (no logic
  changes). `MainTabView` uses the floating tab bar.
- **App target**: `AppIcon.appiconset` gains dark and tinted variants
  (already added under this change's assets).
- **Assets added in this change**: fonts + OFL licenses under
  `Packages/LoritoKit/Sources/DesignSystem/Resources/Fonts/`, icon PNGs, and
  `design/` (tokens, SVG sources, mockup sources).
- **Screenshots/metadata**: fastlane snapshots must be regenerated.
- Binary size: ≈1.4 MB of fonts (Unbounded ≈0.85 MB; may be subset later).
