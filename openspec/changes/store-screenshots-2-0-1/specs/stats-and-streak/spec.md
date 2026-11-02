## MODIFIED Requirements

### Requirement: Progress screen
The app SHALL present a progress screen that displays the current streak prominently, the best streak, the study counts, a 12-week activity heatmap built from the daily activity series together with the total number of grade events in that window, and the long-term memory breakdown for each included level, reachable as a top-level destination. The card counts and the heatmap total SHALL carry different labels: the card counts name cards, and the heatmap total names answers (every graded item: cards, conjugations, words, CCSE questions). At compact width with an accessibility text size the stat tiles SHALL stack one per row so no label breaks inside a word. With no study history it SHALL show an encouraging empty/zero state rather than an error.

#### Scenario: Stats are shown
- **WHEN** the user opens the progress screen with existing study history
- **THEN** it shows the current streak, best streak, and the today/this-week/all-time counts

#### Scenario: Heatmap and memory are shown
- **WHEN** the user opens the progress screen with existing study history
- **THEN** it shows an 84-day heatmap colored by intensity bucket and, for each included level, the long-term count out of the level total

#### Scenario: Card and answer totals are distinguishable
- **WHEN** the user graded 498 cards and 1 conjugation in the last 12 weeks
- **THEN** the all-time tile reads 498 with a label naming cards and the heatmap total reads 499 with a label naming answers

#### Scenario: Accessibility text size on iPhone
- **WHEN** the progress screen is shown at compact width with Dynamic Type AX5
- **THEN** the streak, best streak, card count, today and this-week tiles each take a full row and every label wraps between words

#### Scenario: Empty state
- **WHEN** the user opens the progress screen with no study history
- **THEN** it shows a zero/encouraging state (e.g., streak 0) and no error
