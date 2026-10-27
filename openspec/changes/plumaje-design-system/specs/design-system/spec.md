## MODIFIED Requirements

### Requirement: Semantic color tokens
The design system SHALL expose semantic color tokens rather than raw colors at call sites. The token set SHALL include at least: `surface`, `surfaceRaised`, `surfaceSunken`, `separator`, `textPrimary`, `textSecondary`, `textTertiary`, `accent`, `onAccent`, `accentSoft`, `onAccentSoft`, `highlight`, `onHighlight`, `ink`, `onInk`, `onInkSecondary`, `inkRaised`, `inkTrack`, `danger`, `dangerText`, `dangerSoft`, and the activity scale `heat0`–`heat3`. The accent SHALL be parrot green (Loro, `#0E7C47` in light), the highlight SHALL be Lima (`#CBEF6B`), and the ink SHALL be Tinta (`#0F1A14`), with all values as defined in `design/brand/tokens.json`. Each token SHALL resolve to a defined value in both light and dark appearances.

#### Scenario: Token resolves per appearance
- **WHEN** the interface style switches between light and dark
- **THEN** every semantic token resolves to its appearance-specific value from the token source

#### Scenario: No raw colors at call sites
- **WHEN** a component or screen needs a color
- **THEN** it references a semantic token, not a hard-coded literal

#### Scenario: Accent is parrot green
- **WHEN** the `accent` token is resolved in the light appearance
- **THEN** it equals `#0E7C47`

### Requirement: Light and dark themes
The design system SHALL support light and dark themes and SHALL follow the system appearance by default. Focus surfaces (`ink`, `onInk`, `onInkSecondary`, `inkRaised`, `inkTrack`) SHALL resolve to the same values in both appearances so that focus-mode screens look identical in light and dark.

#### Scenario: Follows system appearance
- **WHEN** the device is in dark mode
- **THEN** the app renders the dark theme

#### Scenario: Focus surfaces are appearance-independent
- **WHEN** the `ink` token is resolved in light and in dark
- **THEN** both resolve to `#0F1A14`

### Requirement: Typography scale
The design system SHALL define a typography scale built on three bundled font families with named styles: `display`, `title`, `number`, and `heading` in Unbounded; `body`, `bodyStrong`, `caption`, and `label` in Onest; and `spanish` and `spanishInline` in Instrument Serif Italic. Every style SHALL scale with Dynamic Type relative to a system text style. The `spanish` styles SHALL be used only for Spanish-language text (words, examples, answers) and SHALL NOT be used for Russian text, as that family has no Cyrillic glyphs.

#### Scenario: Dynamic Type respected
- **WHEN** the user increases the system text size
- **THEN** text styled with any style of the scale scales accordingly

#### Scenario: Spanish text uses the Spanish voice
- **WHEN** a Spanish word or example from a card or exercise is rendered (including Markdown emphasis inside a card body)
- **THEN** it is rendered in the `spanish` or `spanishInline` style in the `accent` color

#### Scenario: Russian text never uses the Spanish family
- **WHEN** Russian UI copy or explanation text is rendered
- **THEN** it uses an Onest or Unbounded style

### Requirement: Core components
The design system SHALL provide reusable SwiftUI components: a level/theme chip, a segmented day-progress indicator, a segmented session-progress bar, callout blocks (Суть / Ключевые моменты / Ошибки / Полезно), SM-2 grade buttons (Опять / Трудно / Хорошо / Легко) with an optional per-grade caption line, a study-card container, a primary pill button, a floating tab bar, a plan hero card, and a `SpanishText` view. Components SHALL render correctly in both themes, SHALL offer touch targets of at least 44×44 pt, and SHALL NOT use emoji as iconography.

#### Scenario: Grade buttons present
- **WHEN** the grade-button component is rendered
- **THEN** it shows four actions labeled Опять, Трудно, Хорошо, Легко using semantic tokens

#### Scenario: Grade buttons show captions when supplied
- **WHEN** the grade-button component is rendered with a caption for each grade
- **THEN** each button shows its caption on a second line beneath the grade label, and without captions it shows the label only

#### Scenario: Grades distinguishable without color
- **WHEN** the four grade buttons are rendered
- **THEN** adjacent buttons differ in background lightness, not hue alone

#### Scenario: Callout variants
- **WHEN** a callout is rendered with a given variant
- **THEN** it displays the corresponding heading and accent

#### Scenario: Floating tab bar is accessible
- **WHEN** the floating tab bar is rendered
- **THEN** each destination is a button of at least 44×44 pt with an accessibility label, and the selected destination is visually distinct

## ADDED Requirements

### Requirement: Bundled brand fonts
The `DesignSystem` module SHALL bundle the font files for Unbounded (Bold, ExtraBold), Onest (Regular, Medium, SemiBold, Bold) and Instrument Serif (Regular, Italic) together with their SIL Open Font License texts, and SHALL register them with the system from the module bundle at app start. Registration SHALL be idempotent. If a font fails to register, the corresponding styles SHALL fall back to the system font of the same text style instead of failing.

#### Scenario: Fonts available after launch
- **WHEN** the app has launched
- **THEN** each bundled PostScript name (e.g. `Unbounded-ExtraBold`, `Onest-Regular`, `InstrumentSerif-Italic`) resolves to an installed font

#### Scenario: Repeated registration is harmless
- **WHEN** font registration runs a second time in the same process
- **THEN** no error is surfaced and fonts remain available

#### Scenario: Missing font falls back
- **WHEN** a bundled font cannot be registered
- **THEN** text in the affected styles renders in the system font at the same text style and remains visible

### Requirement: Brand app icon
The app SHALL ship the Plumaje app icon — the glyph "¡" whose dot is a red circle (the parrot's eye) — in three appearances: light (Lima glyph on Loro green), dark (Lima glyph on Tinta), and tinted (grayscale on black). Each appearance SHALL be a 1024×1024 image without an alpha channel, generated from the vector sources in `design/brand/`.

#### Scenario: Icon variants present
- **WHEN** the app icon set is inspected
- **THEN** it contains a default, a dark-luminosity, and a tinted-luminosity 1024×1024 image

#### Scenario: Main icon has no transparency
- **WHEN** the default app icon image is inspected
- **THEN** it has no alpha channel

### Requirement: Accessible text contrast
Every documented foreground/background token pairing used for text SHALL meet a contrast ratio of at least 4.5:1 in both light and dark appearances. Colors used only for large glyphs or decoration (e.g. `danger` on light surfaces) SHALL NOT be used for body-size text.

#### Scenario: Text pairs meet contrast
- **WHEN** the contrast of each text pairing (e.g. `textSecondary` on `surface`, `onAccent` on `accent`, `dangerText` on `dangerSoft`, `onHighlight` on `highlight`) is computed for light and dark
- **THEN** every ratio is at least 4.5:1

### Requirement: Screens adopt the Plumaje visual language
The Today, study session, exercise session, catalog, progress, onboarding and settings screens SHALL be styled exclusively with the Plumaje tokens and components, with the study and exercise sessions rendered on focus surfaces. The restyle SHALL NOT change any screen's data, navigation, or behavior as specified by other capabilities.

#### Scenario: Sessions render in focus mode
- **WHEN** a study or exercise session is presented in either appearance
- **THEN** its background is the `ink` token and its primary action uses `highlight`

#### Scenario: Behavior unchanged
- **WHEN** the existing study-flow, catalog, stats-and-streak, onboarding-and-selection and practice-exercises scenarios are executed after the restyle
- **THEN** they pass without modification
