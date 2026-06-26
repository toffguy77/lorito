# ipad-support Specification

## Purpose
TBD - created by archiving change ipad-support. Update Purpose after archive.
## Requirements
### Requirement: Universal app installable on iPad
The app SHALL be a universal binary that installs and runs on iPad as well as iPhone, declaring the device families and the orientations iPad requires so the build passes App Store validation.

#### Scenario: Installs on iPad
- **WHEN** the app is installed on an iPad
- **THEN** it launches and runs as a native iPad app

#### Scenario: Passes orientation validation
- **WHEN** a universal Release build is submitted
- **THEN** it satisfies the iPad orientation requirement and is accepted (no "must support all orientations" rejection)

### Requirement: Screens render correctly at iPad sizes
Every existing screen — Today, study session, catalog (levels, themes, cards, reader), onboarding, settings, reminders — SHALL render correctly on iPad in both portrait and landscape, with no clipped or overflowing content.

#### Scenario: Portrait and landscape both usable
- **WHEN** the user rotates an iPad between portrait and landscape on any screen
- **THEN** the screen remains usable with no clipped, overlapping, or cut-off content

#### Scenario: Catalog and Today usable on large screen
- **WHEN** the user browses the catalog and opens the Today screen on iPad
- **THEN** lists, counts, the day-progress indicator, and navigation work as on iPhone

### Requirement: Comfortable reading width on large screens
On large screens the study card and card reader SHALL constrain their content to a comfortable maximum width and center it, rather than stretching text and tables edge-to-edge.

#### Scenario: Card content is not full-bleed on iPad
- **WHEN** a card is shown in the study session or catalog reader on a 13" iPad
- **THEN** its title, Markdown body, callouts, and tables are constrained to a readable width and centered

#### Scenario: iPhone layout unchanged
- **WHEN** the same screens are shown on iPhone
- **THEN** their layout is unchanged from the current iPhone presentation

### Requirement: Behavior identical across device classes
The app SHALL behave identically on iPhone and iPad — same flows, scheduling, daily plan, and sync — with no feature differences between device classes.

#### Scenario: Same study behavior on iPad
- **WHEN** the user studies and grades cards on iPad
- **THEN** the scheduling, daily-plan composition, and persistence behave exactly as on iPhone

