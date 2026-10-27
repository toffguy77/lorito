## Context

`cloudkit-sync` stores `CardReview`, `UserSettings` and `StudyLog` in the user's
private database via SwiftData, local-first, with no custom backend, and is enabled
only in builds with the iCloud entitlement (`LORITO_CLOUDKIT`). This change does not rely on
SwiftData for sharing; it uses CloudKit directly. Apple's model for sharing between
iCloud users is `CKShare`: created either for a root record or for a whole custom
record zone in the owner's private database (`init(recordZoneID:)`), distributed by
URL (e.g. via `UICloudSharingController`), requiring `CKSharingSupported` in
Info.plist; a participant who deletes the share is removed from it
([CKShare](https://developer.apple.com/documentation/cloudkit/ckshare)).

## Goals / Non-Goals

**Goals:** one partner, daily aggregates only, a shared streak, a throttled nudge, no
server, leaving is instant and complete.

**Non-Goals:** groups larger than two, leaderboards, chat, sharing grades or
mistakes, Android or web partners, push infrastructure of our own.

## Decisions

**Zone-wide share of aggregates.** Each user who enables Study Buddy creates a
`BuddyZone` in their private database containing only `BuddyDay` records
(`day: String yyyy-MM-dd`, `studied: Bool`, `gradedCount: Int`, `currentStreak: Int`,
`displayName: String`) and at most one `BuddyNudge` record per day. A zone-wide
`CKShare` is sent to the partner; both partners share their own zones with each
other, so each reads the other's zone from the shared database. This keeps the
private SwiftData store untouched.

**Publishing.** After each completed session and on day rollover, `BuddyService`
upserts today's `BuddyDay` from the existing stats calculator. Only the last 14 days
are kept; older records are deleted.

**Shared streak is pure.** `SharedStreakCalculator.streak(mine:theirs:today:)`
counts consecutive days ending today (or yesterday if today is not yet complete for
both) where both `studied` are true. Freezes from `streak-protection` do not count
as studied here, so the shared streak always reflects real study.

**Nudge.** «Напомнить» writes a `BuddyNudge` in the sender's zone; the partner's app
creates a local notification when it fetches a new nudge (on foreground, background
refresh, or a CloudKit zone subscription's silent push). Pure rule: at most one nudge
per sender per partner day, and never after the partner has studied that day.

**Availability.** Feature visible only when the iCloud account is available and sync
is enabled; otherwise an explanatory empty state. Display name defaults to the
iCloud participant name and can be edited.

**Leaving.** Either partner can «Перестать учиться вместе»: the owner deletes the
share and their `BuddyZone`; the participant removes themselves from the partner's
share. Partner data disappears on next fetch.

## Risks / Trade-offs

- [CloudKit sharing complexity and edge cases (account changes, revoked shares)] →
  P2 scope, one partner only, defensive refetch; feature flagged until stable.
- [Silent pushes are not guaranteed] → nudges also delivered on next foreground.
- [Privacy expectations] → the invite screen states exactly what is shared.

## Migration Plan

Additive. Deploy the new record types to the production CloudKit schema before
release (owner task). Rollback: hide the feature; existing zones can be deleted on
next launch by a cleanup task.
