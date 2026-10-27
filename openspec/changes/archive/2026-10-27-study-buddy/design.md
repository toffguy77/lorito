## Context

`cloudkit-sync` stores `CardReview`, `UserSettings` and `StudyLog` in the user's
private database via SwiftData, local-first, no custom backend, enabled only in
builds with the iCloud entitlement (`LORITO_CLOUDKIT`). This change does not rely on
SwiftData for sharing; it uses CloudKit directly. Apple's model for sharing between
iCloud users is `CKShare`: created for a root record or for a whole custom record
zone in the owner's private database (`init(recordZoneID:)`), distributed by URL
(e.g. via `UICloudSharingController`), requiring `CKSharingSupported` in Info.plist;
participants with write permission can modify records in the share; a participant
who deletes the share is removed from it
([CKShare](https://developer.apple.com/documentation/cloudkit/ckshare)).

Contract from `learning-platform-foundation`: the learning day is the LOCAL calendar
day. New record types follow `cloudkit-schema-release`.

## Goals / Non-Goals

**Goals:** one partner, daily aggregates only, a shared streak, a throttled nudge with
a visible notification, no server, instant and complete leaving.

**Non-Goals:** groups larger than two, leaderboards, chat, sharing grades or
mistakes, Android or web partners, push infrastructure of our own.

## Decisions

**One owner zone, read-write for the participant.** The inviter creates `BuddyZone`
in their private database and a zone-wide `CKShare` with participant permission
read-write. The partner accepts once; both write their own records into that single
zone (the partner through their shared database). No second invite.

**Records.** `BuddyDay` — record name `<userRecordName>:<day>`, fields `owner`
(participant user record name), `day` (`yyyy-MM-dd` of the writer's local learning
day), `studied`, `gradedCount`, `currentStreak`, `displayName`. `BuddyNudge` — record
name `<senderRecordName>:<day>` (one per sender per day by construction), fields
`from`, `day`. Each user prunes their own `BuddyDay` records older than 14 days.
Record types follow `cloudkit-schema-release`.

**Publishing.** After each completed session and on learning-day rollover,
`BuddyService` upserts the user's `BuddyDay` for today's local learning day from the
existing stats calculator.

**Shared streak is pure.** `SharedStreakCalculator.streak(mine:theirs:today:)` counts
consecutive local learning days ending today (or yesterday if today is not yet
complete for both) on which both `studied` are true. Each partner's days are compared
by their own local day keys; freezes from `streak-protection` do not count as studied.

**Nudge delivery without a server.** Each device registers a `CKDatabaseSubscription`
— the owner on its private database (zone changes), the participant on its shared
database — with `CKSubscription.NotificationInfo` carrying an alert body, so iOS shows
a visible notification when a `BuddyNudge` record is created. The app filters nudges
it sent itself on fetch. This needs the Push Notifications capability
(`aps-environment`) and the `remote-notification` background mode (already present for
sync). Throttle (pure): at most one nudge per sender per partner learning day, none
after the partner studied that day.

**Availability.** Visible only when the iCloud account is available and sync is
enabled; otherwise an explanatory state.

**Leaving.** The owner deletes the share and `BuddyZone`; the participant deletes
the share from their shared database, which removes them. Partner data disappears on
next fetch.

## Risks / Trade-offs

- [CloudKit sharing edge cases (account change, revoked share)] → P2, one partner,
  defensive refetch, feature flag until stable.
- [Subscription notifications are best effort] → nudges also shown on next foreground.
- [Different time zones] → each partner's day key is their own local day; the shared
  streak compares "today" per partner, documented in UI copy.

## Migration Plan

Additive. Record types deployed to production per `cloudkit-schema-release` before
release. Rollback: hide the feature; zones deleted by a cleanup task on next launch.
