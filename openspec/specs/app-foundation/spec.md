# app-foundation Specification

## Purpose
TBD - created by archiving change bootstrap-foundation. Update Purpose after archive.
## Requirements
### Requirement: App skeleton builds and launches
The repository SHALL contain a SwiftUI iOS app project targeting iOS 17+ that builds and launches to a root screen.

#### Scenario: App launches
- **WHEN** the app is built and run on an iOS 17+ simulator
- **THEN** it launches to a root screen without crashing

### Requirement: Layered module boundaries
The codebase SHALL be organized into separated layers — `Domain` (pure Swift, no UI or persistence imports), `Content` (loads the bundled content artifact), `Persistence` (SwiftData + CloudKit), `DesignSystem`, and `Features` (SwiftUI screens). The `Domain` layer SHALL NOT import SwiftUI, SwiftData, or CloudKit.

#### Scenario: Domain stays pure
- **WHEN** the project compiles
- **THEN** the Domain layer has no dependency on SwiftUI, SwiftData, or CloudKit

### Requirement: Content loading
The app SHALL load the bundled content artifact at startup and expose levels, themes, and cards to the rest of the app.

#### Scenario: Content available after load
- **WHEN** the app finishes loading content
- **THEN** the full set of levels, themes, and cards is queryable in memory

### Requirement: User-data persistence with iCloud sync
The app SHALL persist user data locally via SwiftData and sync it through the user's private CloudKit database, with no custom backend. The user-data model SHALL include settings (target level, selected themes, reminder configuration, daily new-card count), per-card review state (fields sufficient for SM-2: ease factor, interval, repetitions, due date, last grade, status), and a study log. Review state SHALL be modeled so that later practice results can update it.

#### Scenario: Progress persists across launches
- **WHEN** user data is written and the app is relaunched
- **THEN** the previously written data is read back

#### Scenario: Syncs via CloudKit
- **WHEN** the device is signed into iCloud and connected
- **THEN** user-data changes propagate to the user's private CloudKit database

### Requirement: Project documentation
The repository SHALL contain a `CLAUDE.md` describing build/run/test commands, the content-pipeline commands, and the architecture layers.

#### Scenario: CLAUDE.md present
- **WHEN** a contributor opens `CLAUDE.md`
- **THEN** they find build/test/run and pipeline commands and the layer overview

