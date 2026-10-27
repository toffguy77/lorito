## Context

`DesignSystem` is a thin token layer (`LoritoColor`, `LoritoFont`, spacing /
radius / elevation) plus components (chip, day-progress, callout, grade buttons,
study-card container, Markdown body) and a gallery. Features consume tokens only
(convention: no raw colors outside `Tokens/`). That convention makes a full
re-skin a token-and-component change with mechanical call-site updates.

Reference mockups: `design/mockups/*.dc.html` (canvas
https://claude.ai/artifact/C7pCNDDHPe4doaViBKqT6T). Token values:
`design/brand/tokens.json`.

## Goals / Non-Goals

**Goals:**
- Ship the Plumaje identity end to end: tokens, fonts, icon, components, screens.
- Keep the token-only convention; no raw colors or font names at call sites.
- Preserve Dynamic Type and light/dark support; guarantee text contrast.
- Zero behavior change: every existing spec scenario outside `design-system`
  still passes unchanged.

**Non-Goals:**
- Recall-first cards, interval preview, trap of the day, richer completion
  (→ `recall-first-study`).
- Activity heatmap and long-term memory stats (→ `progress-insights`).
- Widgets, Live Activity, share card (→ `home-screen-widgets`).
- Placement test from onboarding (future change).
- iOS 26 Liquid Glass `.icon` (Icon Composer) package — PNG variants are enough
  for iOS 17–18; revisit when raising the deployment target.

## Decisions

**Static font instances, not variable fonts.** The repo ships static TTFs
instanced from the Google Fonts variable sources (Unbounded 700/800, Onest
400/500/600/700, Instrument Serif Regular/Italic). `Font.custom(_:size:relativeTo:)`
addresses them by PostScript name; static files avoid `.weight()` quirks with
variable axes on iOS 17. Alternative (variable TTF + `UIFontDescriptor` axes) is
more compact but harder to test and to snapshot.

**Register fonts from the package bundle.** SPM resources live in
`Bundle.module`, which `UIAppFonts` in Info.plist cannot see. `FontRegistry.registerAll()`
calls `CTFontManagerRegisterFontsForURL` for each bundled TTF once at app start
(idempotent; "already registered" is not an error). If registration fails the
font tokens fall back to the system font of the same text style — the app never
crashes or renders invisible text.

**Spanish voice is a token, not a convention.** `LoritoFont.spanish` /
`.spanishInline` plus a `SpanishText` view (font + `accent` color + `lang` = es
for VoiceOver pronunciation via `.accessibilitySpeechLanguage("es-ES")`). Markdown
emphasis inside card bodies (`*el libro*`) maps to the Spanish style in
`CardBodyView`'s MarkdownUI theme, so content needs no edits.

**Focus surfaces are fixed ink.** Sessions use `ink`/`onInk`/`inkRaised`/`inkTrack`,
whose values are identical in light and dark. This is deliberate: the session is
a mode, not a page; it reads the same at night and in daylight.

**Floating tab bar.** A custom capsule bar replaces the system `TabView` chrome
(`.toolbar(.hidden, for: .tabBar)` with a `safeAreaInset(edge: .bottom)` bar),
keeping `TabView` for state and deep links (reminder routing to Today stays as
is). Each item is a 44×44+ button with an accessibility label; the selected item
is ink with a Lima icon.

**Grade buttons gain a secondary line.** `GradeButtons` accepts an optional
per-grade caption (`[StudyGrade: String]`). This change renders without
captions; `recall-first-study` supplies interval text. Colors: Опять =
dangerSoft/dangerText, Трудно = inkRaised/onInk, Хорошо = accent/onAccent,
Легко = highlight/onHighlight — distinguishable by lightness, not only hue.

**Icon from vector source.** `design/brand/AppIcon*.svg` are the masters; the
committed PNGs are 1024×1024 RGB without alpha. Asset catalog uses
`appearances: luminosity = dark | tinted` entries (Xcode 16+).

## Risks / Trade-offs

- [Custom fonts break Dynamic Type at extreme sizes] → every style uses
  `relativeTo:`; UI test at AX5 for Today and the session.
- [Unbounded is wide; long Russian titles may wrap] → titles use
  `minimumScaleFactor(0.8)` and two-line limit; catalog rows use Onest.
- [Fonts add ~1.4 MB] → acceptable; optional subsetting to Latin+Cyrillic later.
- [Re-skin touches every screen; regressions in UI tests that match on
  colors/labels] → labels and accessibility identifiers are kept; only styling
  changes.
- [Icon reads as "i" at 29 pt] → the red circle is ≥ 22% of glyph height to keep
  the eye legible; verify on device at Settings/Spotlight sizes.

## Migration Plan

1. Land tokens + fonts + components behind no flag (pure visual change).
2. Update screens one by one; gallery shows old and new until the last screen
   is converted, then the old tokens are removed.
3. Regenerate fastlane screenshots; update App Store promotional text if needed.
Rollback: revert the change; data and schemas are untouched.
