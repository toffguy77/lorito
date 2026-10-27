## 0. Owner

- [ ] 0.1 Dependencies applied: `learning-platform-foundation` (local learning day), `cloudkit-schema-release`
- [ ] 0.2 `BuddyDay`/`BuddyNudge` per `cloudkit-schema-release`: optional fields, schema exported to `cloudkit/schema.ckdb`, deployed to production in CloudKit Console before release
- [ ] 0.3 Enable the Push Notifications capability on the App ID; add `aps-environment` to `Lorito.entitlements` (development/production per configuration); keep `remote-notification` background mode
- [ ] 0.4 Declare `CKSharingSupported` in Info.plist (`project.yml`) and accept shares in the app/scene delegate

## 1. Domain (TDD)

- [ ] 1.1 `BuddyDay`, `BuddyNudge` values; day keys = local learning day from the foundation
- [ ] 1.2 Failing tests for `SharedStreakCalculator.streak(mine:theirs:today:)`: both studied N days; gap breaks; today incomplete → counts to yesterday; freeze day breaks; deterministic
- [ ] 1.3 Failing tests for the nudge rule: once per partner day; not after partner studied
- [ ] 1.4 Aggregate builder from existing stats (studied, graded count, current streak), last 14 days only

## 2. CloudKit service (Features)

- [ ] 2.1 `BuddyService`: owner creates `BuddyZone` + zone-wide `CKShare` with read-write participant permission; present `UICloudSharingController`; accept via `userDidAcceptCloudKitShareWith`; no second invite
- [ ] 2.2 Publish today's `BuddyDay` after session completion and on day rollover; prune > 14 days
- [ ] 2.3 Fetch partner records on foreground and background refresh (owner: private DB zone; participant: shared DB)
- [ ] 2.4 Nudge: write `BuddyNudge` (`<sender>:<day>` record name); register `CKDatabaseSubscription` (owner → private DB, participant → shared DB) with alert `NotificationInfo` «Ваш напарник напоминает: пора повторить испанский»; ignore own nudges on fetch
- [ ] 2.5 Leave: owner deletes share + zone; participant leaves the share; local cache cleared
- [ ] 2.6 Availability check (account status + sync enabled) and error states

## 3. UI

- [ ] 3.1 Invite screen stating exactly what is shared
- [ ] 3.2 Buddy card on Progress (partner name, streak, today, 7-day strip, «Общая серия») and a compact line on Today
- [ ] 3.3 «Напомнить» button with disabled states; «Перестать учиться вместе»
- [ ] 3.4 Analytics via `product-analytics`: invite sent/accepted, nudge sent, left (no names)

## 4. Validation

- [ ] 4.1 `swift test` green
- [ ] 4.2 `xcodebuild` build; UI test for the unavailable state without iCloud
- [ ] 4.3 Manual with two Apple IDs on two devices: invite, accept, study on one → partner sees today studied; shared streak; nudge delivery; leave from each side
- [ ] 4.4 `openspec validate study-buddy --strict`
