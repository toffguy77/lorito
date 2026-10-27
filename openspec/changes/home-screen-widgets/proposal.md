## Why

Lorito only exists while it is open. Retention in habit apps is won outside the
app: on the Home Screen, the Lock Screen and in the Dynamic Island. iOS gives us
interactive widgets and Live Activities, and the app already computes exactly
what they need (streak, today's counts, exercises). A streak share card adds a
zero-cost acquisition loop. This is also the most visible "platform-native"
craft signal for App Store featuring and design juries.

## What Changes

- **Widget extension** (`LoritoWidgets`) with:
  - small "Серия" widget — streak + cards waiting today;
  - small "Слово дня" widget — the Spanish word from the trap of the day;
  - medium interactive "Вспомни" widget — a multiple-choice question answered
    in place (practice only, not graded into the SRS);
  - Lock Screen accessory widgets — circular (cards left today) and rectangular
    (streak at risk message).
- **Live Activity** for a running study session: progress "4 / 18" and an
  estimate of minutes left, in the Dynamic Island and on the Lock Screen.
- **Streak share card:** a 9:16 image rendered on-device from the completion
  state and shared via the system share sheet.
- **Shared snapshot:** the app writes a small JSON snapshot to an App Group
  container after launch, after each session and on day rollover; widgets read
  only the snapshot (no SwiftData/CloudKit in the extension).

## Capabilities

### New Capabilities
- `widgets`: widget kinds, the shared snapshot contract and refresh triggers,
  interactive practice question, Live Activity, share card.

### Modified Capabilities
<!-- None: study-flow and stats behavior is unchanged; they are inputs. -->

## Impact

- **project.yml**: new `app-extension` target `LoritoWidgets` (WidgetKit +
  ActivityKit), App Group `group.com.toffguy.lorito` on app and extension,
  `NSSupportsLiveActivities = YES` in the app Info.plist.
- **Domain**: `WidgetSnapshot` value type + pure builder.
- **Features**: `WidgetSnapshotWriter` (App Group file + `WidgetCenter.reloadAllTimelines`),
  `SessionActivityController` (ActivityKit), share-card view + `ImageRenderer`.
- **DesignSystem**: widget-sized variants of tokens/fonts (fonts must also be
  registered in the extension).
- Signing: App Group capability on the App ID; provisioning profiles updated
  in fastlane match/`asc.env` flow.
- Depends on `plumaje-design-system`; "Слово дня" depends on `recall-first-study`'s
  `DailyTrap`.
