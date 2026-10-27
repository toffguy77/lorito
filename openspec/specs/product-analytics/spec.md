# product-analytics Specification

## Purpose
TBD - created by archiving change product-analytics. Update Purpose after archive.
## Requirements
### Requirement: Closed anonymous event taxonomy
The app SHALL record product events only from a closed, enumerated set defined in the `Domain` layer, whose payloads contain only enumerated values, integers and booleans. Events SHALL NOT contain personal data, free text, item identifiers or content text, and the app SHALL NOT require or create an account for analytics.

#### Scenario: Grade event carries no content
- **WHEN** the user grades a card
- **THEN** the recorded event contains the item kind, the grade and whether the card was revealed, and no item identifier or card text

#### Scenario: No account needed
- **WHEN** a new user installs and studies without signing in anywhere
- **THEN** events are recorded without any account or login

### Requirement: Taxonomy extended only through this capability
New events SHALL be introduced only by an ADDED requirement in the `product-analytics` capability together with a new case of the event enum. Code SHALL NOT send events that are not cases of that enum.

#### Scenario: Paywall events from another change
- **WHEN** the Pro change needs a paywall-shown event
- **THEN** it adds a `product-analytics` requirement and an enum case, and no ad-hoc event name is sent

### Requirement: Core funnel and engagement events
The app SHALL record at least: each onboarding step shown and onboarding completed, study session started and completed (with item count), item graded, exercise answered (with type and correctness), reminder notification opened, and streak extended.

#### Scenario: Session lifecycle recorded
- **WHEN** the user starts a study session and completes it
- **THEN** a session-started event and a session-completed event with the number of items are recorded

#### Scenario: Reminder open recorded
- **WHEN** the user opens the app by tapping a reminder notification
- **THEN** a reminder-opened event is recorded

### Requirement: Streak loss detected on launch
A streak-lost event SHALL be emitted at most once per loss, on the first launch after the streak computed by `stats-and-streak` drops from a positive value to zero, carrying the previous length. Days the streak calculator treats as kept (e.g. by a streak freeze) SHALL NOT count as a loss.

#### Scenario: Missed day
- **WHEN** the last reported streak was 6 and on launch the computed streak is 0
- **THEN** one streak-lost event with previous length 6 is recorded

#### Scenario: Freeze keeps the streak
- **WHEN** a missed day is covered by a streak freeze and the computed streak stays positive
- **THEN** no streak-lost event is recorded

### Requirement: Experiment properties
Any event SHALL be able to carry optional `experiment` and `variant` properties whose values come from a closed enum in `Domain`, so that experiment arms can be compared without free text.

#### Scenario: Event in an experiment arm
- **WHEN** a session completes for a user in arm `b` of experiment `firstSessionImmediately`
- **THEN** the session-completed event carries `experiment` and `variant` with those enum values

### Requirement: Provider abstraction
Events SHALL be delivered through a sink protocol defined in `Domain`; the concrete provider SHALL be injected by the app target. Tests and previews SHALL use a no-op or recording sink, and no `Domain` or `Features` code SHALL import a provider SDK.

#### Scenario: Tests use a recording sink
- **WHEN** feature tests run with a recording sink injected
- **THEN** emitted events can be asserted without network access or provider SDK

### Requirement: Offline buffering never blocks the UI
Events SHALL be appended to a bounded on-device queue and sent in batches when the provider is reachable. Recording SHALL NOT block the main thread or delay any user action. When the queue exceeds its cap, the oldest events SHALL be dropped; events older than 30 days SHALL be discarded unsent.

#### Scenario: Offline study
- **WHEN** the user studies while the analytics endpoint is unreachable
- **THEN** studying is unaffected and events stay queued for a later flush

#### Scenario: Queue cap
- **WHEN** the queue is full and a new event is recorded
- **THEN** the oldest event is dropped and the new event is kept

### Requirement: Device-local consent
Consent SHALL be stored only on the device and SHALL NOT sync between devices. Settings SHALL offer "Помогать улучшать Lorito", on by default, with an explanation and privacy-policy link. Nothing SHALL be recorded until the device's consent value is set; turning it off SHALL stop recording and purge the queue at once.

#### Scenario: Opt-out purges queue
- **WHEN** the user turns the toggle off while events are queued
- **THEN** the queue is emptied and no further events are recorded or sent

#### Scenario: Choice does not travel
- **WHEN** the user opts out on iPhone and then opens Lorito on an iPad with the same iCloud account
- **THEN** the iPad uses its own consent value

### Requirement: Retention metric definitions
Retention metrics SHALL be derivable from events alone: a user is active on a local learning day with at least one item graded or exercise answered; D1, D7 and D30 SHALL be computed against the day of the user's first event; the north-star metric SHALL be the mean number of active days per calendar week among users active that week.

#### Scenario: Active day definition
- **WHEN** a user only opens the app and leaves without grading or answering
- **THEN** that day does not count as an active day

### Requirement: Privacy disclosures match collection
The privacy policy and the App Store privacy answers SHALL describe the collected usage data as product interaction data that is not linked to the user and not used for tracking, and SHALL be updated in the same release that first sends events.

#### Scenario: Release with analytics
- **WHEN** the first build that sends analytics events is submitted
- **THEN** the privacy policy page and App Store privacy answers describe that collection

### Requirement: Placement and first-session events
The event taxonomy SHALL include `placementStarted`, `placementCompleted` with the proposed level, the highest known level (or none) and the number of questions, `placementSkipKnownApplied` with the number of seeded cards, and `firstSessionStarted` with the number of new cards; all payloads SHALL be enumerated values, integers or booleans.

#### Scenario: Test completed
- **WHEN** the user completes the placement test with proposal B1 after 6 questions
- **THEN** a `placementCompleted` event with level B1, known level A2 and 6 questions is recorded

#### Scenario: First session
- **WHEN** the first session opens after onboarding with 3 new cards
- **THEN** a `firstSessionStarted` event with 3 new cards is recorded

### Requirement: Purchase funnel events
The app SHALL record the anonymous events `paywall_shown` (with the entry point), `purchase_started`, `purchase_completed` and `purchase_failed` (with product id and a coarse reason: cancelled, pending, error, unavailable) and `restore` (with outcome), and SHALL NOT include prices paid, Apple IDs or any personal data.

#### Scenario: Purchase completed
- **WHEN** a user buys the lifetime product
- **THEN** `purchase_started` and `purchase_completed` are recorded with the product id and no personal data

#### Scenario: Unavailable storefront
- **WHEN** the paywall cannot load products
- **THEN** `paywall_shown` is recorded and a `purchase_failed` event is not recorded unless a purchase was attempted

### Requirement: Grammar Lens events
The app SHALL record anonymous events `lens_opened` (with input source: paste, share, camera, photo), `lens_analyzed` (with a bucketed match count) and `lens_card_requested` (with card id), and SHALL NOT record the analysed text.

#### Scenario: Analysis recorded without text
- **WHEN** the user analyses a pasted paragraph with three matches
- **THEN** `lens_analyzed` is recorded with source paste and the match bucket, and no text

