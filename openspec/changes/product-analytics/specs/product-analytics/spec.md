## ADDED Requirements

### Requirement: Closed anonymous event taxonomy
The app SHALL record product events only from a closed, enumerated set defined in the `Domain` layer, whose payloads contain only enumerated values, integers and booleans. Events SHALL NOT contain personal data, free text, card or exercise identifiers, or content text, and the app SHALL NOT require or create an account for analytics.

#### Scenario: Grade event carries no content
- **WHEN** the user grades a card
- **THEN** the recorded event contains the grade and whether the card was revealed, and no card identifier or card text

#### Scenario: No account needed
- **WHEN** a new user installs and studies without signing in anywhere
- **THEN** events are recorded without any account or login

### Requirement: Core funnel and engagement events
The app SHALL record at least: each onboarding step shown and onboarding completed, study session started and completed (with card count), card graded, exercise answered (with type and correctness), reminder notification opened, streak extended and streak lost.

#### Scenario: Session lifecycle recorded
- **WHEN** the user starts a study session and completes it
- **THEN** a session-started event and a session-completed event with the number of cards are recorded

#### Scenario: Reminder open recorded
- **WHEN** the user opens the app by tapping a reminder notification
- **THEN** a reminder-opened event is recorded

### Requirement: Provider abstraction
Events SHALL be delivered through a sink protocol defined in `Domain`; the concrete analytics provider SHALL be injected by the app target. Tests and previews SHALL use a no-op or recording sink, and no `Domain` or `Features` code SHALL import a provider SDK directly.

#### Scenario: Tests use a recording sink
- **WHEN** feature tests run with a recording sink injected
- **THEN** emitted events can be asserted without network access or provider SDK

### Requirement: Offline buffering never blocks the UI
Events SHALL be appended to a bounded on-device queue and sent in batches when the provider is reachable. Recording an event SHALL NOT block the main thread or delay any user action. When the queue exceeds its cap, the oldest events SHALL be dropped; events older than 30 days SHALL be discarded unsent.

#### Scenario: Offline study
- **WHEN** the user studies while the analytics endpoint is unreachable
- **THEN** studying is unaffected and events are kept in the queue for a later flush

#### Scenario: Queue cap
- **WHEN** the queue is full and a new event is recorded
- **THEN** the oldest event is dropped and the new event is kept

### Requirement: User opt-out
Settings SHALL offer a toggle "Помогать улучшать Lorito", enabled by default, with a short explanation and a link to the privacy policy. Turning it off SHALL stop recording immediately and purge the queued events; turning it on SHALL resume recording from that moment only.

#### Scenario: Opt-out purges queue
- **WHEN** the user turns the toggle off while events are queued
- **THEN** the queue is emptied and no further events are recorded or sent

#### Scenario: Opt-in resumes
- **WHEN** the user turns the toggle back on
- **THEN** new events are recorded, and nothing from the opted-out period exists

### Requirement: Retention metric definitions
Retention metrics SHALL be derivable from events alone: a user is active on a day with at least one card graded or exercise answered; D1, D7 and D30 retention SHALL be computed against the day of the user's first event; the north-star metric SHALL be the mean number of active days per calendar week among users active that week.

#### Scenario: Active day definition
- **WHEN** a user only opens the app and leaves without grading or answering
- **THEN** that day does not count as an active day

### Requirement: Privacy disclosures match collection
The privacy policy and the App Store privacy answers SHALL describe the collected usage data as product interaction data that is not linked to the user and not used for tracking, and SHALL be updated in the same release that first sends events.

#### Scenario: Release with analytics
- **WHEN** the first build that sends analytics events is submitted
- **THEN** the privacy policy page and App Store privacy answers describe that collection
