## Context

Lorito is a greenfield iOS app for learning Spanish via spaced repetition. The source material is 165 Obsidian notes (levels A1–C2) holding summarized grammar/vocabulary rules in Russian. The product was agreed in brainstorming: iOS native (SwiftUI, iOS 17+), offline bundled content, per-user progress synced via the user's private CloudKit database (no custom backend), App Store distribution, SM-2 spaced repetition with self-grading, content owned in the app repo, "Modern Calm" design system (indigo accent, light + dark).

This change is the foundation only. It must produce stable contracts (content format, persistence model, design tokens/components, module boundaries) that later changes (`srs-engine`, `daily-plan`, `study-flow`, `reminders`) depend on, plus a buildable shell and a populated content bundle.

## Goals / Non-Goals

**Goals:**
- A buildable, launchable SwiftUI app shell with clear layer boundaries.
- A documented hybrid content format (frontmatter + Markdown) and a repeatable offline pipeline that migrates, validates, and bundles content.
- A persistence/sync foundation (SwiftData + CloudKit) with the user-data model defined.
- A reusable "Modern Calm" design system with a verification gallery.

**Non-Goals:**
- The SM-2 algorithm itself, daily-plan composition, study/Today/catalog screens, onboarding, and notifications (each is a later change).
- Practice exercises (later phase).
- Android (the Domain layer is kept portable, but no Android target now).
- Content enrichment of all 165 cards to final quality (the enrichment *step* exists; full enrichment is incremental).

## Decisions

- **SwiftUI + iOS 17 + SwiftData over UIKit/Core Data.** SwiftData gives a modern, declarative model layer with first-party CloudKit sync via its ModelConfiguration. Alternative (Core Data + NSPersistentCloudKitContainer) is more battle-tested but more boilerplate; acceptable to revisit if SwiftData+CloudKit limitations bite (see Risks).
- **CloudKit private database, no backend.** Each user's progress syncs in their own iCloud account. Content is identical for all users and ships in the bundle, so no server is needed. Trade-off: content updates require an app release (acceptable; content is curated and versioned with the app).
- **Hybrid content format (frontmatter + Markdown), content in-repo.** Frontmatter carries structured fields the app needs (id/level/theme/order/related); Markdown carries the rich body. This keeps authoring close to the existing vault notes while giving the app typed metadata. Alternatives rejected: fully-structured JSON (high authoring cost, rigid) and pure Markdown (weak metadata for scheduling/graph).
- **Compiled content bundle, not raw Markdown files in the app.** The pipeline validates and compiles all cards into one artifact embedded at build time, so the app loads content deterministically and validation gates releases. Bodies remain Markdown rendered at runtime.
- **Pipeline tooling separate from the app, in `tools/`.** Migration/enrichment/validation/compile are scripts (Node or Python). They read the vault once to seed, then the repo `content/` is the source of truth. The vault is not a runtime dependency.
- **Layered architecture with a pure `Domain`.** `Domain` (pure Swift) holds future SRS/scheduling logic and is unit-testable without a simulator and portable to other platforms. `Content`, `Persistence`, `DesignSystem`, `Features` depend inward. Enforced by import discipline.
- **Design tokens as a Swift token layer.** Semantic tokens (color/typography/spacing/radius/elevation) resolve per appearance; components consume tokens only. A gallery screen renders all components in both themes for visual QA, doubling as living documentation.
- **Markdown rendering**: render card bodies with a SwiftUI-compatible Markdown approach that supports tables and the callout convention; exact library chosen during implementation (a decision recorded in tasks/`CLAUDE.md`).

## Risks / Trade-offs

- **SwiftData + CloudKit constraints** (e.g., required optionals/defaults, no unique constraints synced, schema-migration friction) → Keep the user-data model small and additive; model review state and settings conservatively; isolate persistence behind a thin protocol so a Core Data fallback is possible without touching Domain/Features.
- **CloudKit container needs a paid Apple Developer account and entitlement** → Foundation works against the local store first; CloudKit sync is enabled behind configuration so the app is testable without an iCloud round-trip.
- **Lossy vault migration** (Obsidian-specific syntax, inconsistent note structure) → Migration is idempotent and re-runnable from the vault; validation fails loudly on malformed output; a human review step precedes committing migrated/enriched content.
- **Theme taxonomy is currently coarse** (mostly `gramática`) → Introduce a finer per-level theme registry derived from card ordering during theme assignment; encode it in the registry, not in tags.
- **Bundling content at build time means no over-the-air content updates** → Acceptable for v1; revisit a remote content channel only if update cadence demands it.

## Migration Plan

1. Initialize git and scaffold the Xcode project and module folders.
2. Build the design system + gallery (no data dependency).
3. Implement the content format/schema and the pipeline; seed-migrate from the vault; validate; compile the bundle.
4. Wire content loading and the SwiftData (local-first) persistence layer; enable CloudKit sync behind configuration.
5. Write `CLAUDE.md`. No production data exists yet, so there is no rollback concern beyond reverting the branch.

## Open Questions

- Exact Markdown-rendering library for SwiftUI (tables + callouts) — decide during implementation and record in `CLAUDE.md`.
- Pipeline language: Node vs Python — pick based on available tooling; either satisfies the specs.
- Bundle id (`com.toffguy.lorito`) and CloudKit container (`iCloud.com.toffguy.lorito`) are decided; only Apple Developer team enrollment is pending. Until enrolled, sync stays behind config and development uses the local store. If a custom domain is later acquired, the reverse-DNS prefix may be revisited before first release.
