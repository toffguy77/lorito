## ADDED Requirements

### Requirement: First-run onboarding is shown once
On the very first launch the app SHALL present the onboarding flow before the main flow. Once onboarding completes, the app SHALL record that it completed and SHALL NOT present onboarding again on subsequent launches; those launches SHALL open directly to the main flow.

#### Scenario: First launch shows onboarding
- **WHEN** the app launches and onboarding has never been completed
- **THEN** the onboarding flow is presented before the main flow

#### Scenario: Later launches skip onboarding
- **WHEN** the app launches and onboarding was previously completed
- **THEN** the main flow is shown directly and onboarding is not presented

### Requirement: Target level selection auto-includes lower levels
During onboarding the user SHALL choose exactly one target level from A1, A2, B1, B2, C1, C2. Choosing a target level SHALL include that level and all lower levels per `content-model`, and SHALL persist the chosen target to `UserSettings.targetLevel`.

#### Scenario: Choosing B1 includes A1 through B1
- **WHEN** the user selects target level `B1`
- **THEN** the included levels are `A1`, `A2`, and `B1`
- **THEN** `UserSettings.targetLevel` is persisted as `B1`

#### Scenario: Choosing A1 includes only A1
- **WHEN** the user selects target level `A1`
- **THEN** the only included level is `A1`
- **THEN** `UserSettings.targetLevel` is persisted as `A1`

### Requirement: Target level is required to finish onboarding
The user SHALL be unable to complete onboarding until a target level has been chosen. The control that finishes onboarding SHALL remain unavailable while no target level is selected.

#### Scenario: Cannot finish without a target level
- **WHEN** no target level has been selected
- **THEN** the action that completes onboarding is unavailable

#### Scenario: Can finish once a target level is chosen
- **WHEN** a target level has been selected and the resulting scope is studyable
- **THEN** the action that completes onboarding becomes available

### Requirement: Optional theme narrowing within included levels
The user MAY narrow which themes to study from the themes belonging to the included levels. The default selection SHALL be all in-scope themes selected. The selection SHALL persist to `UserSettings.selectedThemes`. Only themes belonging to the included levels SHALL be selectable.

#### Scenario: Default selects all in-scope themes
- **WHEN** the user reaches theme selection without changing anything
- **THEN** every theme belonging to the included levels is selected by default

#### Scenario: Narrowing persists the chosen subset
- **WHEN** the user deselects some themes and confirms a still-studyable selection
- **THEN** `UserSettings.selectedThemes` is persisted as exactly the remaining selected themes

#### Scenario: Only included-level themes are offered
- **WHEN** the target level is `A2` and theme selection is shown
- **THEN** only themes belonging to levels `A1` and `A2` are offered for selection

### Requirement: Settings can change scope after onboarding
After onboarding, a settings screen SHALL let the user change the target level and the theme selection. Changing the target level SHALL re-scope the included content and the set of selectable themes; raising the level SHALL widen scope and lowering it SHALL narrow scope. Any persisted change to target level or theme selection SHALL trigger a `daily-plan` recompute (referenced capability).

#### Scenario: Raising the level widens scope
- **WHEN** the current target level is `A2` and the user changes it to `B1` in settings
- **THEN** the included levels become `A1`, `A2`, `B1`
- **THEN** the themes selectable in settings now include `B1` themes
- **THEN** a `daily-plan` recompute is triggered

#### Scenario: Lowering the level narrows scope
- **WHEN** the current target level is `B1` and the user changes it to `A1` in settings
- **THEN** the included levels become only `A1`
- **THEN** themes that belonged solely to `A2` or `B1` are no longer in scope
- **THEN** a `daily-plan` recompute is triggered

#### Scenario: Changing theme selection triggers recompute
- **WHEN** the user changes the selected themes in settings to a different studyable set
- **THEN** `UserSettings.selectedThemes` is updated and a `daily-plan` recompute is triggered

### Requirement: Non-empty studyable scope guard
The system SHALL prevent persisting any selection that yields zero studyable cards. A selection is studyable only when the set of in-scope cards — cards whose level is included by the target level and whose theme is among the selected themes — is non-empty. The guard SHALL apply in both onboarding and settings; a non-studyable selection SHALL NOT be persisted and SHALL NOT trigger a recompute.

#### Scenario: Deselecting all themes is blocked
- **WHEN** the user deselects every theme so that no in-scope cards remain
- **THEN** the selection is rejected and not persisted
- **THEN** the user is prevented from proceeding until at least one theme yielding in-scope cards is selected

#### Scenario: At least one studyable theme is accepted
- **WHEN** the user's selection leaves at least one theme that contributes in-scope cards
- **THEN** the selection is accepted and persisted

### Requirement: Pure scope helpers in Domain
The `Domain` layer SHALL expose pure, deterministic helpers, with no UI or persistence dependencies, that derive: the included levels for a given target level; the in-scope themes for those included levels; the in-scope cards for a given target level and selected-theme set; and whether such a selection is studyable (its in-scope card set is non-empty). These helpers SHALL be the single source of selection logic used by onboarding, settings, and `daily-plan`.

#### Scenario: Included levels are pure
- **WHEN** the included-levels helper is given target level `B2`
- **THEN** it returns `A1`, `A2`, `B1`, `B2` and performs no I/O

#### Scenario: In-scope cards filter by level and theme
- **WHEN** the in-scope-cards helper is given target level `A2` and a selected-theme set
- **THEN** it returns exactly the cards whose level is `A1` or `A2` and whose theme is in the selected set

#### Scenario: Studyability reflects the in-scope set
- **WHEN** the studyability helper is given a selection whose in-scope card set is empty
- **THEN** it returns false, and otherwise it returns true
