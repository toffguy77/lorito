## 1. Assets (already in the repo with this change)

- [x] 1.1 Fonts (static TTF instances) + OFL licenses in `Packages/LoritoKit/Sources/DesignSystem/Resources/Fonts/`
- [x] 1.2 App icon PNGs (default / dark / tinted, 1024×1024, no alpha) + `Contents.json` with luminosity appearances
- [x] 1.3 `design/brand/tokens.json`, `design/brand/AppIcon*.svg`, `design/mockups/*.dc.html`, `design/README.md`

## 2. Tokens (DesignSystem, TDD)

- [ ] 2.1 Write failing tests: every token in `tokens.json` exists in `LoritoColor` with the documented light and dark hex values (parse `design/brand/tokens.json` in the test, or mirror it in a fixture)
- [ ] 2.2 Write failing test: contrast ≥ 4.5:1 for each documented text pairing in light and dark (pure luminance math on the token hexes)
- [ ] 2.3 Rewrite `LoritoColor` with the Plumaje set; keep `Color(hex:)` private to `Tokens/`
- [ ] 2.4 Update `LoritoSpacing` (add `screenGutter` 20), `LoritoRadius` (14/20/28/36/pill), `LoritoElevation` (`card`, `tabBar`), `LoritoLayout` (`minTouchTarget`, `primaryButtonHeight`, `tabBarHeight`)

## 3. Fonts (DesignSystem, TDD)

- [ ] 3.1 Declare `resources: [.process("Resources/Fonts")]` on the `DesignSystem` target in `Package.swift`
- [ ] 3.2 Write failing tests: after `FontRegistry.registerAll()` each PostScript name resolves (`UIFont(name:size:)` / `NSFont` on macOS host); calling twice is harmless
- [ ] 3.3 Implement `FontRegistry` (`CTFontManagerRegisterFontsForURL`, ignore `alreadyRegistered`), call it from `LoritoApp.init`
- [ ] 3.4 Rewrite `LoritoFont` with `display/title/number/heading/body/bodyStrong/caption/label/spanish/spanishInline`, each `Font.custom(_:size:relativeTo:)` with system-font fallback when the font is unavailable
- [ ] 3.5 Map Markdown emphasis in `CardBodyView`'s MarkdownUI theme to `spanishInline` + `accent`

## 4. Components

- [ ] 4.1 Restyle `LevelChip`, `DayProgressBar`, `CalloutBlock` (Суть on ink, others on `surfaceSunken`), `StudyCardContainer` (radius xl, `surfaceRaised`)
- [ ] 4.2 `GradeButtons`: new colors per design.md; optional `captions: [StudyGrade: String]`; 2-line layout; test caption/no-caption rendering via view model or snapshot
- [ ] 4.3 New `PrimaryButton` (pill, 56 pt, variants: highlight-on-ink, ink-on-light, outline)
- [ ] 4.4 New `FloatingTabBar` (capsule, 64 pt, selected = ink + Lima icon, a11y labels, ≥ 44 pt targets)
- [ ] 4.5 New `PlanHeroCard` (big number, three-segment bar, counts row, CTA slot) and `SessionProgressBar` (segmented, per-card outcome colors)
- [ ] 4.6 New `SpanishText` (spanish style, accent color, `.accessibilitySpeechLanguage("es-ES")`)
- [ ] 4.7 Replace emoji in empty/done states with typographic marks (¡ ¿) in `display` style
- [ ] 4.8 Update `ComponentGalleryView` to show every component in light and dark, including focus-mode samples

## 5. Screens (Features — styling only)

- [ ] 5.1 `MainTabView`: hide system tab bar, add `FloatingTabBar` via bottom safe-area inset; keep `selection` + reminder deep link
- [ ] 5.2 `TodayView`: greeting header in `display`, `PlanHeroCard` with existing counts and start action, existing empty/all-done states restyled (mockup `Today.dc.html`)
- [ ] 5.3 `StudySessionView` + `ExerciseSessionView`: focus mode on `ink`, close button, `SessionProgressBar`, card container (mockups `CardBack`, `Exercise`)
- [ ] 5.4 `CatalogView`: level pills + theme path with progress per theme (mockup `Catalog.dc.html`), same drill-down and card reader
- [ ] 5.5 `StatsView`: streak tile on `danger`, best streak and counts tiles (mockup `Progress.dc.html`, without the heatmap — see `progress-insights`)
- [ ] 5.6 `OnboardingView`: level rows with a Spanish sample phrase per level and "included" state for lower levels (mockup `Onboarding.dc.html`); themes and reminder steps restyled
- [ ] 5.7 `SettingsView`, `RemindersView`, `AboutView`: tokens only

## 6. Validation

- [ ] 6.1 `swift test` green; `rg 'Color\(hex' Sources --glob '!**/Tokens/**'` returns nothing
- [ ] 6.2 `xcodebuild` build + UI tests green; manual pass at Dynamic Type AX5 for Today and the study session
- [ ] 6.3 Check icon on device: Home Screen light/dark/tinted, Settings and Spotlight sizes
- [ ] 6.4 Regenerate fastlane screenshots
- [ ] 6.5 `openspec validate plumaje-design-system --strict`
