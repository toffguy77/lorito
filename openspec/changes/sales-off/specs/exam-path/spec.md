## MODIFIED Requirements

### Requirement: Content-based free preview
While sales are on, exam content marked as preview (one CCSE mock and one DELE A2 reading task) SHALL be available without Pro; all other exam content SHALL present the Pro offer when opened without Pro. Preview availability SHALL NOT depend on usage counters. While sales are off, all exam content SHALL be available in full.

#### Scenario: Non-Pro user opens non-preview content
- **WHEN** sales are on and a non-Pro user opens a second CCSE mock
- **THEN** the Pro offer is shown and no attempt is created

#### Scenario: Preview after reinstall
- **WHEN** sales are on and a non-Pro user reinstalls the app
- **THEN** the same preview content is available

#### Scenario: Everything open while sales are off
- **WHEN** sales are off and a user opens any DELE A2 or CCSE mock
- **THEN** the full mock starts
