## ADDED Requirements

### Requirement: Widget snapshot contract
The app SHALL publish a versioned widget snapshot to a shared App Group container with the streak, studied-today flag, today's due/new/remaining counts, a word of the day, and up to three practice questions from multiple-choice exercises in scope. The snapshot SHALL be built by a pure `Domain` function and written atomically. Widgets SHALL read only this snapshot and SHALL NOT open the app's user-data store.

#### Scenario: Snapshot reflects stats
- **WHEN** the snapshot is built with a current streak of 13, 8 due and 4 new cards, and no study today
- **THEN** it contains streak 13, due 8, new 4, studied-today false

#### Scenario: Unknown version
- **WHEN** a widget reads a snapshot whose version it does not support, or no snapshot exists
- **THEN** it shows a neutral state inviting the user to open the app

### Requirement: Snapshot refresh triggers
The app SHALL rewrite the snapshot and request a reload of all widget timelines on launch, when it returns to the foreground or the day rolls over, and after a study or exercise session completes. Widget timelines SHALL include an entry at the next local midnight so that day-dependent content resets without the app running.

#### Scenario: After a session
- **WHEN** the user completes a study session
- **THEN** the snapshot is rewritten with studied-today true and widget timelines are reloaded

#### Scenario: Midnight reset
- **WHEN** local midnight passes without the app being opened
- **THEN** widgets treat the new day as not yet studied

### Requirement: Streak and plan widgets
The widget extension SHALL offer a small Home Screen widget showing the current streak and the number of cards remaining today, a small "Слово дня" widget showing the Spanish word of the day with a short Russian note, and Lock Screen accessory widgets: a circular one showing cards remaining today and a rectangular one that, when the streak is greater than zero and the user has not studied today, says the streak is at risk. Tapping any of them SHALL open the app on the Today screen.

#### Scenario: Streak at risk on Lock Screen
- **WHEN** the snapshot day is today, the streak is 13 and studied-today is false
- **THEN** the rectangular Lock Screen widget states that the 13-day streak is not yet extended today

#### Scenario: Tap opens Today
- **WHEN** the user taps the streak widget
- **THEN** the app opens on the Today screen

### Requirement: Interactive practice question widget
The extension SHALL offer a medium widget presenting one practice question from the snapshot with its options as buttons that can be answered without opening the app. Answering SHALL show whether the choice was correct and offer the next question. Answers given in the widget SHALL NOT modify any card's review state or write study events.

#### Scenario: Answer in place
- **WHEN** the user taps an option on the question widget
- **THEN** the widget shows whether the choice was correct without opening the app

#### Scenario: SRS untouched
- **WHEN** the user answers a question in the widget
- **THEN** no `CardReview` changes and no `StudyLog` or exercise attempt is written

### Requirement: Session Live Activity
When a study session starts and Live Activities are enabled, the app SHALL start a Live Activity showing the session position and total and an estimate of minutes left, update it after each grade, and end it when the session completes or the user exits. At most one Lorito Live Activity SHALL be active at a time.

#### Scenario: Progress updates
- **WHEN** the user grades the 4th of 18 cards
- **THEN** the Live Activity shows 4 / 18

#### Scenario: Ends on exit
- **WHEN** the user closes the session mid-way
- **THEN** the Live Activity ends

### Requirement: Streak share card
The session completion state SHALL offer sharing a 9:16 image, rendered on device, showing the brand mark, the current streak and a fixed Spanish proverb, through the system share sheet. The image SHALL NOT contain the user's name or any other personal data.

#### Scenario: Share from completion
- **WHEN** the user taps "Поделиться" on the completion state with a 13-day streak
- **THEN** the system share sheet opens with a 9:16 image showing 13
