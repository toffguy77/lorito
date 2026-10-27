## Why

Studying alone is the main reason streaks die. Couples and friends who relocate
together often learn Spanish together, and a light social commitment ("we both
study today") is one of the strongest retention levers in the audit. Lorito has no
backend and should not get one; CloudKit sharing between two iCloud users gives a
shared space without accounts or servers. This is a P2 bet, built on top of the
existing optional CloudKit sync.

## What Changes

- **Study buddy (one partner):** invite a person via a system share link to one
  shared zone (read-write for the partner); once accepted, both see the partner's
  name, current streak, today's status and last seven days.
- **Shared streak:** a separate «Общая серия» counts consecutive days on which both
  partners studied.
- **Nudge:** «Напомнить» sends the partner a visible notification, at most once per
  day, delivered by a CloudKit database subscription (no server).
- **Privacy by design:** only daily aggregates are shared (studied yes/no, count of
  graded cards, current streak); never card content, grades, errors or settings.
- **Leave any time:** either partner can stop sharing; data disappears for both.
- Available only when iCloud sync is enabled; otherwise the feature explains why it
  is unavailable.

## Capabilities

### New Capabilities
- `study-buddy`: invite and accept, shared aggregates, shared streak, nudges,
  privacy boundary, leaving, availability rules.

### Modified Capabilities
<!-- None: cloudkit-sync stays as specified; sharing uses a separate shared zone. -->

## Impact

- **CloudKit**: one owner zone shared zone-wide via `CKShare` with read-write
  participant permission; record types `BuddyDay`, `BuddyNudge` per
  `cloudkit-schema-release`; `CKDatabaseSubscription`s for nudges.
- **App target**: Push Notifications capability (`aps-environment`); `CKSharingSupported`.
- **Domain**: `BuddyDay` value, `SharedStreakCalculator` (pure), nudge throttling
  rule (pure).
- **Features**: `BuddyService` (publish today's aggregate after each session, fetch
  partner records, accept share via `UICloudSharingController` / scene delegate
  `userDidAcceptCloudKitShareWith`), Buddy section on Progress and Today.
- **Depends on**: `cloudkit-sync`, `cloudkit-schema-release`,
  `learning-platform-foundation` (local learning day), `progress-insights` (week strip),
  `streak-protection` (sibling; freezes do not count as studied for the shared
  streak), `product-analytics`.
