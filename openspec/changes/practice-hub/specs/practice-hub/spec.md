# Spec Delta

## Purpose
Free exercise practice outside the card reader: mixed, weak-spot, per-theme and per-level sessions drawn only from cards the user has already studied, with entry points on Today and in the Catalog.

## ADDED Requirements

### Requirement: Only studied cards feed free practice
Free practice SHALL select only exercises whose associated card has a review status other than new (learning, review or suspended), within the selected scope. Exercises of cards the user has not started SHALL never be selected, and starting free practice SHALL NOT introduce a new card. Listening and speaking exercises SHALL follow the existing audio rules of `practice-exercises` (no voice, turned off, temporarily skipped).

#### Scenario: Unstudied card excluded
- **WHEN** theme `a1-2` has cards A1-05 (studied) and A1-06 (new), each with exercises, and the user starts «Практика по теме» for `a1-2`
- **THEN** the session contains only exercises of A1-05 and A1-06 remains new

#### Scenario: Suspended card still practicable
- **WHEN** the user suspended a card they had studied
- **THEN** its exercises are eligible for free practice

### Requirement: Practice modes
Free practice SHALL offer four modes:
- «Смешанная»: up to 20 exercises drawn from all eligible exercises across levels, preferring exercises never attempted or attempted least recently, and not placing two exercises of the same card next to each other when another choice exists;
- «Слабые места»: up to 20 eligible exercises whose most recent attempt was incorrect, most recent miss first;
- «Практика по теме»: every eligible exercise of one theme, in card order;
- «Практика по уровню»: up to 20 eligible exercises of one level, chosen as in «Смешанная».

#### Scenario: Weak spot leaves after a correct answer
- **WHEN** an exercise's last attempt was incorrect and the user answers it correctly in free practice
- **THEN** it is no longer selected by «Слабые места»

#### Scenario: Mixed prefers unseen exercises
- **WHEN** 30 eligible exercises exist and 10 of them have never been attempted
- **THEN** a «Смешанная» session contains those 10

#### Scenario: Level cap
- **WHEN** level A2 has 60 eligible exercises and the user starts «Практика по уровню» for A2
- **THEN** the session has 20 exercises, all of level A2

### Requirement: Expectations are stated before practice
The app SHALL tell the user that exercises unlock as cards are studied. Every free-practice entry SHALL show how many exercises are available in its scope as «доступно X из Y», where Y counts all exercises of that scope and X the eligible ones. When a mode has no eligible exercises, choosing it SHALL show an empty state that explains why instead of starting a session: for scopes with no studied cards — «Упражнения открываются, когда вы изучаете карточки. Начните с плана на сегодня»; for «Слабые места» with no misses — «Ошибок пока нет — слабые места появятся здесь, когда они будут».

#### Scenario: Partial availability shown
- **WHEN** the user studied 3 of 6 cards of a theme that has 36 exercises, 18 of them on studied cards
- **THEN** the theme practice entry reads «доступно 18 из 36»

#### Scenario: Nothing studied yet
- **WHEN** a user who has studied no cards opens «Практика» on Today and chooses «Смешанная»
- **THEN** the empty state explaining that exercises unlock with studied cards is shown and no session starts

#### Scenario: No weak spots
- **WHEN** the user has no exercise whose last attempt was incorrect
- **THEN** «Слабые места» shows the no-misses message and no session starts

### Requirement: Practice entry on Today
The Today screen SHALL show a «Практика» row beside the other training rows («Слова», «Спряжения», «Мои ловушки») once onboarding is complete, with the caption «Упражнения по изученным карточкам». Opening it SHALL present «Смешанная» and «Слабые места» with their counts and a note that theme and level practice live in the Catalog.

#### Scenario: Row opens the modes
- **WHEN** the user taps «Практика» on Today
- **THEN** «Смешанная» and «Слабые места» are offered with their available counts

### Requirement: Practice entries in the Catalog
A theme's card list SHALL offer «Практика по теме» and the Catalog level view SHALL offer «Практика по уровню» for the selected level, each with its «доступно X из Y» count, on iPhone and iPad.

#### Scenario: Theme practice from the Catalog
- **WHEN** the user opens a theme in the Catalog and taps «Практика по теме»
- **THEN** a free-practice session of that theme's eligible exercises starts

#### Scenario: Level practice on iPad
- **WHEN** on iPad the user selects level B1 in the Catalog sidebar and taps «Практика по уровню»
- **THEN** a free-practice session of B1 eligible exercises starts

### Requirement: Free practice session
A free-practice session SHALL use the existing interactive exercise screen in focus mode, and its completion state SHALL report how many exercises were answered correctly. Closing the session early SHALL keep the attempts already recorded.

#### Scenario: Completion summary
- **WHEN** the user finishes a 20-exercise mixed session with 17 correct answers
- **THEN** the completion state reports 17 of 20 correct

### Requirement: Free practice is a Pro feature
Free practice SHALL be available to Lorito Pro users and to everyone while sales are off (`monetization`). Without entitlement the entries SHALL remain visible with a lock, and choosing one SHALL present the paywall instead of a session. Practice from a card's reader SHALL stay free.

#### Scenario: Sales off
- **WHEN** sales are off and a user without a purchase taps «Смешанная»
- **THEN** the session starts and no paywall or lock is shown

#### Scenario: Locked with sales on
- **WHEN** sales are on and a non-Pro user taps «Практика по теме»
- **THEN** the paywall is presented and no session starts

#### Scenario: Card reader stays free
- **WHEN** sales are on and a non-Pro user taps «Практика · 6» in a card's reader
- **THEN** the card's practice session starts without a paywall
