## Why

We are building **Lorito**, an iOS app that teaches Spanish through spaced-repetition study cards. Before any learning flow can exist, the project needs a foundation: an iOS app skeleton, a defined content format with a pipeline that turns the existing 165 Obsidian notes into shippable data, a persistence layer that syncs user progress via iCloud, and a reusable design system. This change establishes that foundation so subsequent changes (SRS engine, daily plan, study screens, notifications) build on stable contracts instead of redefining them.

## What Changes

- Create the iOS app skeleton (SwiftUI, iOS 17+) with a layered architecture: `Domain` (pure Swift), `Content`, `Persistence`, `Features`, plus a shared design-system module.
- Define the **content format**: one file per card = YAML frontmatter (id, level, theme, order, title, aliases, related, tags) + Markdown body, organized as `content/<LEVEL>/<id>.md`, with a documented schema.
- Build the **content pipeline** (offline tooling): seed-migrate the 165 vault cards into the repo format (stripping Obsidian-specific syntax), assign each card a theme, support an LLM enrichment step, validate integrity (unique ids, resolvable `related`, valid levels/themes), and compile a bundled content artifact for the app.
- Establish the **persistence foundation**: local store via SwiftData with CloudKit private-database sync for user data; define the user-data entities (settings, per-card review state, study log) at the storage level, modeled so practice results can later feed the SRS.
- Implement the **design system** "Modern Calm": semantic color tokens (light + dark), typography scale (SF Pro), spacing/radius/elevation tokens, and core components (level/theme chip, segmented day-progress indicator, callout blocks, SM-2 grade buttons, study-card container).
- Add project docs: `CLAUDE.md` and a `content/schema.md`.

This change delivers no end-user study flow yet — it produces a buildable app shell, a populated content bundle, and a component gallery.

## Capabilities

### New Capabilities
- `content-model`: The on-disk content format and schema for levels, themes, and cards (frontmatter + Markdown body), including validation rules and the level/theme taxonomy.
- `content-pipeline`: Offline tooling to seed-migrate vault notes, enrich content, validate integrity, and compile the bundled content artifact consumed by the app.
- `design-system`: The "Modern Calm" visual language — semantic tokens, light/dark theming, typography, and the reusable SwiftUI components — with accessibility and Dynamic Type support.
- `app-foundation`: The app skeleton, module/layer boundaries, and the SwiftData + CloudKit persistence/sync foundation for user data.

### Modified Capabilities
<!-- None — this is the first change; no existing specs. -->

## Impact

- **New project structure**: `Lorito/` (Xcode project), `content/`, `tools/`, `CLAUDE.md`.
- **Identity**: brand/wordmark **Lorito**; App Store name **"Lorito Español"** (differentiated from the existing unrelated "Loro"/"Lorito" apps); bundle id `com.toffguy.lorito`; CloudKit container `iCloud.com.toffguy.lorito`. Trademark clearance and domain are the owner's due diligence before registration.
- **Dependencies**: Xcode 16 / Swift 6, iOS 17 SDK; CloudKit entitlement and the iCloud container `iCloud.com.toffguy.lorito`; a Markdown-rendering approach for SwiftUI; Node or Python for the content pipeline tooling.
- **No backend**: user data lives in the user's private CloudKit database; content ships in-app.
- **Roadmap (subsequent OpenSpec changes, not in scope here)**:
  1. `srs-engine` — SM-2 algorithm (again/hard/good/easy) over review state.
  2. `daily-plan` — compose each day's queue (1 new card + due reviews), respecting `related` prerequisites and selected themes.
  3. `onboarding-and-selection` — pick target level (auto-includes lower levels) and optionally narrow themes.
  4. `study-flow` — the study-card screen, Today screen, and catalog browsing.
  5. `reminders` — configurable daily local notifications reflecting due counts.
  6. `practice-exercises` — later phase; results feed the SRS.
