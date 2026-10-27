## 1. Metadata lint (TDD)

- [ ] 1.1 Write failing tests (`tools/test_lint_metadata.py`): over-limit name/subtitle/promo/description/keywords, keyword ≤ 2 chars, duplicate keyword, keyword repeating a name word, byte-length warning only
- [ ] 1.2 Implement `tools/lint_metadata.py` (stdlib); add to CI before `fastlane deliver`
- [ ] 1.3 Run against current metadata and record findings

## 2. Copy (stage 1)

- [ ] 2.1 Decide name: «Lorito: испанская грамматика» vs keep «Lorito Español» + grammar subtitle; record decision in design.md
- [ ] 2.2 Write subtitle, promotional text, description per design structure; counts taken from `content.json` of the release build
- [ ] 2.3 Write stage-1 keywords (no DELE/CCSE); lint green
- [ ] 2.4 Update `release_notes.txt` for the release

## 3. Screenshots

- [ ] 3.1 Add six scenes to `ScreenshotUITests` (seeded demo data, light theme)
- [ ] 3.2 Frame with Russian headlines (fastlane frameit or a SwiftUI renderer) for iPhone 6.9" and iPad 13"
- [ ] 3.3 Review on a phone screen at actual size

## 4. Stage 2 (with exam-path release)

- [ ] 4.1 Swap in DELE/CCSE keywords and the exam paragraph in the description; lint green

## 5. Validation

- [ ] 5.1 `python3 tools/test_lint_metadata.py` and `python3 tools/lint_metadata.py` green
- [ ] 5.2 `fastlane deliver --skip_binary_upload` dry run / preview in App Store Connect
- [ ] 5.3 After 4 weeks: compare impressions and product page conversion in App Store Connect analytics
- [ ] 5.4 `openspec validate aso-grammar-positioning --strict`
