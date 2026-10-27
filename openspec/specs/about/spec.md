# about Specification

## Purpose
An in-app About / Licenses screen (reachable from Settings) that lists third-party materials bundled in the app with each item's license and source — satisfying the OpenMoji CC BY-SA 4.0 attribution required by the picture-matching image assets.
## Requirements
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

### Requirement: Vocabulary dataset attribution
The About / Licenses screen SHALL credit FrequencyWords (source repository link, content licence CC BY-SA 4.0) as the source of word frequency ranks, and SHALL state that Lorito's vocabulary dataset is an adaptation published under CC BY-SA 4.0.

#### Scenario: Attribution shown
- **WHEN** the About / Licenses screen is shown
- **THEN** it lists FrequencyWords with its CC BY-SA 4.0 licence and source, and the vocabulary dataset licence

