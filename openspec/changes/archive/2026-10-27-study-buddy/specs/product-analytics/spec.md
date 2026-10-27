## ADDED Requirements

### Requirement: Study buddy events
The app SHALL record the anonymous events `buddy_invite_sent`, `buddy_invite_accepted`, `buddy_nudge_sent` and `buddy_left`, without payload, and SHALL NOT record names, user record names or partner data.

#### Scenario: Nudge recorded without identity
- **WHEN** the user nudges their partner
- **THEN** `buddy_nudge_sent` is recorded with no parameters
