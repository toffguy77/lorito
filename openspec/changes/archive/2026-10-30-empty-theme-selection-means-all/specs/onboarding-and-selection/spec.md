## MODIFIED Requirements

### Requirement: Optional theme narrowing within included levels
The user MAY narrow which themes to study from the themes belonging to the included levels. The default selection SHALL be all in-scope themes selected. The selection SHALL persist to `UserSettings.selectedThemes`. Only themes belonging to the included levels SHALL be selectable. A stored empty selection SHALL be shown and treated as all in-scope themes selected, as the daily plan treats it.

#### Scenario: Default selects all in-scope themes
- **WHEN** the user reaches theme selection without changing anything
- **THEN** every theme belonging to the included levels is selected by default

#### Scenario: Narrowing persists the chosen subset
- **WHEN** the user deselects some themes and confirms a still-studyable selection
- **THEN** `UserSettings.selectedThemes` is persisted as exactly the remaining selected themes

#### Scenario: Only included-level themes are offered
- **WHEN** the target level is `A2` and theme selection is shown
- **THEN** only themes belonging to levels `A1` and `A2` are offered for selection

#### Scenario: Stored empty selection
- **WHEN** the stored settings have target level B1 and no selected themes, and Settings or the setup re-run opens
- **THEN** every A1, A2 and B1 theme shows as selected and the themes step can continue
