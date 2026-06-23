## ADDED Requirements

### Requirement: Semantic color tokens
The design system SHALL expose semantic color tokens (e.g., `accent`, `surface`, `surfaceSecondary`, `textPrimary`, `textSecondary`, `success`, `warning`, `danger`) rather than raw colors at call sites. The accent SHALL be indigo. Each token SHALL resolve to a defined value in both light and dark appearances.

#### Scenario: Token resolves per appearance
- **WHEN** the interface style switches between light and dark
- **THEN** every semantic token resolves to its appearance-specific value

#### Scenario: No raw colors at call sites
- **WHEN** a component needs a color
- **THEN** it references a semantic token, not a hard-coded literal

### Requirement: Light and dark themes
The design system SHALL support light and dark themes and SHALL follow the system appearance by default.

#### Scenario: Follows system appearance
- **WHEN** the device is in dark mode
- **THEN** the app renders the dark theme

### Requirement: Typography scale
The design system SHALL define a typography scale built on SF Pro / system fonts with named styles (e.g., title, heading, body, caption, label) including weight and tracking, and SHALL support Dynamic Type.

#### Scenario: Dynamic Type respected
- **WHEN** the user increases the system text size
- **THEN** text styled with the scale scales accordingly

### Requirement: Spacing, radius, and elevation tokens
The design system SHALL define reusable spacing, corner-radius, and elevation (shadow) tokens used by components.

#### Scenario: Components use tokens
- **WHEN** a component sets padding or corner radius
- **THEN** it uses a defined token value

### Requirement: Core components
The design system SHALL provide reusable SwiftUI components: a level/theme chip, a segmented day-progress indicator, callout blocks (Суть / Ключевые моменты / Ошибки / Полезно), SM-2 grade buttons (Опять / Трудно / Хорошо / Легко), and a study-card container. Components SHALL render correctly in both themes.

#### Scenario: Grade buttons present
- **WHEN** the grade-button component is rendered
- **THEN** it shows four actions labeled Опять, Трудно, Хорошо, Легко using semantic tokens

#### Scenario: Callout variants
- **WHEN** a callout is rendered with a given variant
- **THEN** it displays the corresponding heading and accent

### Requirement: Component gallery
The app SHALL include a developer-facing gallery screen that renders every design-system component in both light and dark themes for visual verification.

#### Scenario: Gallery renders all components
- **WHEN** the gallery screen is opened
- **THEN** it displays each core component in light and dark
