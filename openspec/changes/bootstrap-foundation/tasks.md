## 1. Repo & Project Scaffold

- [ ] 1.1 Initialize git, add `.gitignore` (Xcode, Swift, `.superpowers/`, build artifacts, content bundle output)
- [ ] 1.2 Create the Xcode iOS app project `Lorito` targeting iOS 17+ (Swift 6) with bundle id `com.toffguy.lorito` and App Store name "Lorito Español"; app launches to a placeholder root screen
- [ ] 1.3 Create layer folders/groups: `Domain`, `Content`, `Persistence`, `DesignSystem`, `Features`; document the dependency direction
- [ ] 1.4 Add a unit test target and a smoke test that the app module imports

## 2. Design System (no data dependency)

- [ ] 2.1 Define semantic color tokens (accent/indigo, surface, surfaceSecondary, textPrimary, textSecondary, success, warning, danger) with light + dark values
- [ ] 2.2 Define typography scale (title/heading/body/caption/label with weight + tracking) on SF Pro, with Dynamic Type support
- [ ] 2.3 Define spacing, corner-radius, and elevation tokens
- [ ] 2.4 Build component: level/theme chip
- [ ] 2.5 Build component: segmented day-progress indicator
- [ ] 2.6 Build component: callout blocks (Суть / Ключевые моменты / Ошибки / Полезно) with variants
- [ ] 2.7 Build component: SM-2 grade buttons (Опять / Трудно / Хорошо / Легко)
- [ ] 2.8 Build component: study-card container
- [ ] 2.9 Build the component gallery screen rendering all components in light + dark; verify visually
- [ ] 2.10 Verify no raw color literals at component call sites (tokens only)

## 3. Content Model & Schema

- [ ] 3.1 Write `content/schema.md` (frontmatter fields, id pattern, level/theme taxonomy, body callout conventions)
- [ ] 3.2 Define the per-level theme registry file (themes per level, contiguous by `order`)
- [ ] 3.3 Define Swift content types (Level, Theme, Card) in the `Content`/`Domain` layer matching the schema

## 4. Content Pipeline (tools/)

- [ ] 4.1 Choose pipeline language (Node or Python); record the decision in `CLAUDE.md`
- [ ] 4.2 Implement seed migration: read vault notes, strip Obsidian syntax (Dataview, `up:`, backlink blocks), emit `content/<LEVEL>/<id>.md` with valid frontmatter
- [ ] 4.3 Normalize ids to the `A1-07` two-digit pattern during migration
- [ ] 4.4 Implement theme assignment writing `theme` per card and maintaining the registry (contiguous by order)
- [ ] 4.5 Implement the enrichment step (consistent template; preserves id/level/order; output reviewable)
- [ ] 4.6 Implement integrity validation (duplicate ids, duplicate order-in-level, unknown level/theme, unresolved `related`, missing required fields); non-zero exit on failure
- [ ] 4.7 Implement bundle compilation (runs validation first; writes the bundled content artifact to app resources; fails if validation fails)
- [ ] 4.8 Run migration on the 165 vault cards, then validate; review output and commit the migrated content
- [ ] 4.9 Add pipeline tests: validation catches duplicates/dangling refs; clean content passes; compile produces a bundle

## 5. Content Loading (app)

- [ ] 5.1 Embed the compiled content bundle in app resources
- [ ] 5.2 Implement content loading at startup; expose levels/themes/cards queryable in memory
- [ ] 5.3 Add a test that all bundled cards load and `related`/theme references resolve in-app
- [ ] 5.4 Choose and integrate a SwiftUI Markdown renderer (tables + callouts); render a sample card body in the gallery; record the choice in `CLAUDE.md`

## 6. Persistence & iCloud Sync Foundation

- [ ] 6.1 Define SwiftData user-data models: UserSettings (target level, selected themes, reminder config, daily new-card count), CardReview (easeFactor, interval, repetitions, dueDate, lastGrade, status), StudyLog
- [ ] 6.2 Set up the SwiftData ModelContainer (local-first), behind a thin persistence protocol to keep Domain/Features decoupled
- [ ] 6.3 Add CloudKit sync via ModelConfiguration behind a configuration flag; add the CloudKit entitlement with container `iCloud.com.toffguy.lorito` and document setup in `CLAUDE.md`
- [ ] 6.4 Add tests: write/read round-trip across a simulated relaunch; settings and review state persist
- [ ] 6.5 Confirm the Domain layer imports no SwiftUI/SwiftData/CloudKit (lint/check or test)

## 7. Documentation & Wrap-up

- [ ] 7.1 Write `CLAUDE.md` (build/run/test commands, pipeline commands, architecture layers, Markdown-renderer and pipeline-language decisions, CloudKit setup notes)
- [ ] 7.2 Run `openspec validate bootstrap-foundation --strict` and fix any issues
- [ ] 7.3 Verify acceptance: app builds and launches, gallery renders both themes, pipeline validates+bundles, persistence round-trips
