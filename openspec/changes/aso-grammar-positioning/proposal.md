## Why

The App Store page sells Lorito as «Испанский по карточкам» — a crowded,
generic promise that hides what makes the app different: a complete A1–C2
Spanish grammar explained in Russian through the mistakes Russian speakers
actually make. The audit names this as the most valuable advantage; the store
page is where it has to land first. Search terms that express it (грамматика,
subjuntivo, ser/estar, спряжение, later DELE/CCSE) are missing from the
metadata today.

## What Changes

- **New positioning** across name, subtitle, promotional text and description:
  «Испанская грамматика, объяснённая по-русски — A1–C2».
- **Keywords** rebuilt around grammar intents; DELE/CCSE terms are added only
  in a second stage, once the exam path feature ships (metadata must describe
  what the app does).
- **Description** rewritten: problem → what is inside (159 rules, 892
  exercises, recall-first, interval preview, offline, no account, no ads) →
  who it is for, in plain Russian.
- **Screenshot plan** built from the Plumaje mockups (iPhone 6.9" and iPad
  13"), each with one benefit headline.
- **Metadata lint**: a script checks field limits before `fastlane deliver`.

## Capabilities

### New Capabilities
- `app-store-presence`: positioning statement, metadata fields and limits,
  staged keyword policy, screenshot set, metadata validation.

### Modified Capabilities
<!-- None. -->

## Impact

- `fastlane/metadata/ru/*.txt` (name, subtitle, keywords, promotional_text,
  description, release_notes).
- `fastlane/Snapfile` / `ScreenshotUITests`: new screenshot scenes and
  framing with headlines.
- New `tools/lint_metadata.py` (stdlib), run in CI before upload.
- No app code changes. Depends on `plumaje-design-system` and
  `recall-first-study` (archived) for screenshots; stage 2 depends on the
  exam-path change.
