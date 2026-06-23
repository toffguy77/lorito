## ADDED Requirements

### Requirement: Browse levels and themes
The catalog SHALL let the user browse the included content hierarchically: the included levels, then the themes within a selected level, then the cards within a selected theme. It SHALL present only content that is included in the bundle and SHALL preserve each level's and theme's defined order.

#### Scenario: Drill from level to themes to cards
- **WHEN** the user selects a level and then a theme in the catalog
- **THEN** the cards belonging to that theme are listed in their defined order

#### Scenario: Only included content shown
- **WHEN** the catalog is browsed
- **THEN** it lists the levels, themes, and cards present in the content bundle and no others

### Requirement: Card rows show status
Each card row in the catalog SHALL display the card's status derived from its `CardReview`: new, learning, review, due, or suspended. A card whose review state is in `review` and whose due date has arrived SHALL be shown as due; a card with no review yet SHALL be shown as new.

#### Scenario: New card with no review
- **WHEN** a card has no `CardReview` yet
- **THEN** its row shows the new status

#### Scenario: Due card highlighted
- **WHEN** a card's `CardReview` status is review and its due date is reached
- **THEN** its row shows the due status

#### Scenario: Suspended card marked
- **WHEN** a card's `CardReview` status is suspended
- **THEN** its row shows the suspended status

### Requirement: Open and read a card
The catalog SHALL let the user open any listed card to read it, rendering its level/theme chip, title, and Markdown body (callouts and tables) using the same rendering as the study session.

#### Scenario: Read a card from the catalog
- **WHEN** the user opens a card from the catalog
- **THEN** the card's chip, title, and rendered Markdown body (callouts and tables) are shown

### Requirement: Suspend and unsuspend a card
From the card reader the catalog SHALL let the user suspend a card and unsuspend a suspended card, which SHALL set the card's `CardReview.status` to suspended or restore it to a non-suspended status. Suspending SHALL exclude the card from scheduling (per `srs-engine` / `daily-plan`); this change only sets the status and does not redefine the scheduling rules.

#### Scenario: Suspend a card
- **WHEN** the user suspends a card from the catalog reader
- **THEN** the card's `CardReview.status` is set to suspended and the change is persisted

#### Scenario: Unsuspend a card
- **WHEN** the user unsuspends a previously suspended card
- **THEN** the card's `CardReview.status` is restored to a non-suspended status and the change is persisted

#### Scenario: Suspended status reflected in listing
- **WHEN** the user suspends a card and returns to its theme listing
- **THEN** the card's row shows the suspended status
