## ADDED Requirements

### Requirement: Availability requires iCloud sync
Study Buddy SHALL be available only when an iCloud account is available and progress sync is enabled; otherwise it SHALL show a state explaining that iCloud is required, and studying SHALL be unaffected.

#### Scenario: No iCloud account
- **WHEN** the user opens Study Buddy without an iCloud account
- **THEN** an explanation is shown and no invite can be created

### Requirement: Invite and accept one partner
A user SHALL be able to invite exactly one partner through a system share link, and the partner SHALL become connected after accepting it; while connected, a second invitation SHALL NOT be offered.

#### Scenario: Partner accepts
- **WHEN** the partner opens the invite link and accepts
- **THEN** both users see each other as their study buddy

### Requirement: Only daily aggregates are shared
The app SHALL share only per-day aggregates — whether the user studied, the number of cards graded, the current streak — plus a display name, and SHALL keep at most the last 14 days. Card content, grades, mistakes, settings and exercise answers SHALL NOT be shared.

#### Scenario: What the partner sees
- **WHEN** the partner views the buddy section
- **THEN** they see the user's name, current streak, today's status and the last seven days, and nothing about specific cards

### Requirement: Shared streak
The shared streak SHALL be computed by a pure function as the number of consecutive days, ending today or, if today is not yet complete for both, yesterday, on which both partners studied; streak freezes SHALL NOT count as studied.

#### Scenario: One partner missed a day
- **WHEN** both studied on the last three days except the user missed the day before yesterday
- **THEN** the shared streak is at most 2

#### Scenario: Freeze used
- **WHEN** a partner's personal streak was kept by a freeze on a day without study
- **THEN** that day breaks the shared streak

### Requirement: Throttled nudge
A user SHALL be able to send «Напомнить» to the partner at most once per day, and not after the partner has studied that day; the partner SHALL receive it as a notification when their app next fetches buddy data.

#### Scenario: Second nudge same day
- **WHEN** the user has already nudged the partner today
- **THEN** the nudge action is disabled until the next day

#### Scenario: Partner already studied
- **WHEN** the partner studied today
- **THEN** no nudge can be sent

### Requirement: Leaving the pair
Either partner SHALL be able to stop studying together at any time; afterwards neither SHALL see the other's data once their app next refreshes.

#### Scenario: Partner leaves
- **WHEN** the partner chooses «Перестать учиться вместе»
- **THEN** after the next refresh the user's buddy section returns to the invite state
