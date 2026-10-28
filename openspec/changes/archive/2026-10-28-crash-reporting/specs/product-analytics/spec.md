## MODIFIED Requirements

### Requirement: Privacy disclosures match collection
The privacy policy and the App Store privacy answers SHALL describe the collected usage data as product interaction data that is not linked to the user and not used for tracking, and SHALL be updated in the same release that first sends events. They SHALL also disclose crash data, performance (hang) data and other diagnostic data sent by crash reporting, not linked to the user and not used for tracking, in the release that first enables it.

#### Scenario: Crash reporting disclosed
- **WHEN** the first release with crash reporting ships
- **THEN** the privacy policy names the crash-reporting service and what it receives, and the App Privacy answers list Crash Data, Performance Data and Other Diagnostic Data as not linked and not tracking
