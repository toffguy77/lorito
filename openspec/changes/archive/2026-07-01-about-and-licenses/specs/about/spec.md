## ADDED Requirements

### Requirement: About / Licenses screen
The app SHALL provide an About / Licenses screen, reachable from Settings, that lists the third-party materials bundled in the app together with each item's license and source. The list SHALL include the OpenMoji attribution (CC BY-SA 4.0) required by the picture-matching image assets.

#### Scenario: Reachable from Settings
- **WHEN** the user opens Settings and taps the «О приложении» entry
- **THEN** the About / Licenses screen is shown

#### Scenario: OpenMoji attribution present
- **WHEN** the About / Licenses screen is shown
- **THEN** it displays the OpenMoji credit and its CC BY-SA 4.0 license

#### Scenario: Third-party dependencies credited
- **WHEN** the About / Licenses screen is shown
- **THEN** each bundled third-party material lists its name, license, and source
