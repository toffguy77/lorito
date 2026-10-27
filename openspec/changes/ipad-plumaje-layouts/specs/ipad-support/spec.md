## MODIFIED Requirements

### Requirement: Screens render correctly at iPad sizes
Every existing screen — Today, study session, catalog (levels, themes, cards, reader), progress, onboarding, settings, reminders — SHALL render correctly on iPad in both portrait and landscape, with no clipped or overflowing content. At regular horizontal size class the Today, study session, catalog and progress screens SHALL use their regular-width layouts; at compact horizontal size class (including Slide Over and narrow Split View) every screen SHALL use its iPhone layout.

#### Scenario: Portrait and landscape both usable
- **WHEN** the user rotates an iPad between portrait and landscape on any screen
- **THEN** the screen remains usable with no clipped, overlapping, or cut-off content

#### Scenario: Catalog and Today usable on large screen
- **WHEN** the user browses the catalog and opens the Today screen on iPad
- **THEN** lists, counts, the day-progress indicator, and navigation work as on iPhone

#### Scenario: Compact width uses iPhone layout
- **WHEN** Lorito runs on iPad in Slide Over or a narrow Split View
- **THEN** it shows the iPhone layouts, including the bottom tab bar

### Requirement: Behavior identical across device classes
The app SHALL behave identically on iPhone and iPad — same flows, scheduling, daily plan, sync, and the same set of features and data shown — with no feature differences between device classes. Device classes MAY differ only in layout, navigation chrome, and supported input methods (keyboard, pointer).

#### Scenario: Same study behavior on iPad
- **WHEN** the user studies and grades cards on iPad
- **THEN** the scheduling, daily-plan composition, and persistence behave exactly as on iPhone

#### Scenario: Same information on both devices
- **WHEN** a piece of information (e.g. trap of the day, week strip, related cards) is shown on iPad
- **THEN** the same information is reachable on iPhone

## ADDED Requirements

### Requirement: Adaptive navigation at regular width
At regular horizontal size class the app SHALL present its four destinations (Сегодня, Каталог, Прогресс, Настройки) as a sidebar in landscape and as a top tab bar in portrait, with the same destination identifiers as on iPhone. The selected destination and any reminder deep link to Today SHALL work identically in every navigation form.

#### Scenario: Sidebar in landscape
- **WHEN** the app is shown full screen on iPad in landscape
- **THEN** the destinations are listed in a sidebar with the current one highlighted

#### Scenario: Reminder opens Today
- **WHEN** the user taps a reminder notification on iPad
- **THEN** the app shows the Today destination

### Requirement: Today dashboard at regular width
At regular width the Today screen SHALL show two columns: the plan hero with counts and the start action on the leading side, and the week strip, trap of the day and long-term memory summary on the trailing side.

#### Scenario: Two columns in landscape
- **WHEN** the Today screen is shown at regular width with a non-empty queue
- **THEN** the plan hero and start action are in the leading column and the week strip, trap of the day and memory summary in the trailing column

### Requirement: Study session layout at regular width
At regular width the study session SHALL show, after reveal, the card body split across two columns within the reading-width constraint, a side panel with the card's related cards and keyboard hints, and the four grade buttons in one row with their key caps. Before reveal the front side SHALL be shown in a single centered column.

#### Scenario: Revealed card in two columns
- **WHEN** a revealed card whose body exceeds one column's height is shown at regular width
- **THEN** its blocks are distributed across two columns without splitting a callout or table

#### Scenario: Short card stays single column
- **WHEN** a revealed card's body fits in one column
- **THEN** it is shown in a single centered column

### Requirement: Three-column catalog at regular width
At regular width the catalog SHALL show three columns: levels and themes, the selected theme's cards with their status, and the selected card's reader. The selected level, theme and card SHALL be preserved across rotation, size-class changes and relaunch.

#### Scenario: Select a card
- **WHEN** the user selects a theme and then a card at regular width
- **THEN** the card list and the reader for that card are visible at the same time

#### Scenario: Selection survives rotation
- **WHEN** the user rotates the iPad with a card open in the reader
- **THEN** the same theme and card remain selected

### Requirement: Progress dashboard at regular width
At regular width the progress screen SHALL arrange the streak, best streak and totals in one row and show the activity heatmap at full content width, followed by the long-term memory bars and the today/week counts.

#### Scenario: Dashboard arrangement
- **WHEN** the progress screen is shown at regular width with study history
- **THEN** the streak tiles share one row and the heatmap spans the content width

### Requirement: Hardware keyboard shortcuts
With a hardware keyboard the app SHALL support: Return to start the session from Today, Space to reveal the answer, 1–4 to choose Опять, Трудно, Хорошо and Легко, Esc to close the session, and arrow keys to move through catalog lists. Each shortcut SHALL be active only while its on-screen action is visible and enabled, and SHALL be listed in the system keyboard-shortcut overlay.

#### Scenario: Keyboard-only study
- **WHEN** the user presses Return on Today, then Space, then 3 on the first card
- **THEN** the session starts, the answer is revealed, and the card is graded Хорошо

#### Scenario: No grading before reveal
- **WHEN** the user presses 3 while the card's front side is shown
- **THEN** nothing is graded

### Requirement: Pointer and resize behavior
Interactive elements SHALL show the system pointer hover effect when used with a trackpad or mouse. Resizing the app window (rotation, Split View, Stage Manager) SHALL NOT reset the selected destination, catalog selection, or an open study session.

#### Scenario: Resize during a session
- **WHEN** the user resizes Lorito from full screen to a narrow Split View in the middle of a session
- **THEN** the session continues on the same card and reveal state in the compact layout
