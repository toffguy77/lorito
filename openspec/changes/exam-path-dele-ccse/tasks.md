## 0. Gates and dependencies

- [ ] 0.1 Owner: legal check — may Instituto Cervantes' published CCSE/DELE materials be reused? Record the answer in `content/exams/LICENSING.md`; until approved, only `source: lorito` items ship
- [ ] 0.2 Owner: re-verify exam timings, thresholds and fees at cervantes.es; set `verifiedOn` in the exam definitions
- [ ] 0.3 Dependencies available: `spanish-audio`, `study-goal`, `lorito-pro`; `listening-and-pronunciation` for speaking recording (fallback: speaking tasks without recording)

## 1. Content model and pipeline (TDD)

- [ ] 1.1 Document `content/exams/` in `content/schema.md`: exam definition (sections, time limits, groups, thresholds, `verifiedOn`), item front matter (`id`, `exam`, `section`, `type`, `source`, `licence`, `cards` mapping)
- [ ] 1.2 Failing tests in `tools/test_pipeline.py`: missing `source`/`licence` fails; third-party source without allow-listed licence fails; thresholds and timings parsed; compile writes exams into the bundle
- [ ] 1.3 Implement in `tools/validate.py` and `tools/compile.py`; add `content/exams/licence-allowlist.txt` (empty)

## 2. Domain (TDD)

- [ ] 2.1 `ExamDefinition`, `ExamItem` (incl. `listeningTask`, `writingTask`, `speakingTask`), decoding tests
- [ ] 2.2 `MockScorer.score` — tests: per-group scaling to 50, pass only if every group ≥ threshold, 38/28 fails on Group 2, 30/30 passes; CCSE 15/25 passes, 14/25 fails, unanswered = incorrect
- [ ] 2.3 `RubricScore` — tests: ticked items sum to points, self-assessed flag propagates to the result
- [ ] 2.4 `MockTimer` — remaining time from persisted start + injected now; tests for backgrounding and expiry
- [ ] 2.5 `ReadinessCalculator` — tests: deterministic, labels, cap at "borderline" without a productive attempt, abandoned mocks excluded
- [ ] 2.6 CCSE scheduling — tests that CCSE review states use the SRS and a separate quota; grammar plan unchanged unless exam mode

## 3. Persistence

- [ ] 3.1 `MockAttemptRecord` (exam, start time, answers, rubric ticks, status complete/abandoned) — CloudKit-friendly (optional/defaulted fields); store round-trip tests
- [ ] 3.2 CCSE review states stored alongside card reviews with a distinct id namespace (`CCSE-…`)

## 4. Content authoring

- [ ] 4.1 Author 3 full DELE A2 mocks (reading, listening scripts, writing prompts + rubrics, speaking prompts + rubrics), each item mapped to grammar cards
- [ ] 4.2 Author the CCSE bank in Russian-supported Spanish (questions in Spanish, explanations in Russian), enough for ≥ 4 non-repeating 25-question mocks
- [ ] 4.3 Listening audio via `spanish-audio` pre-rendering or recordings; store under the content bundle
- [ ] 4.4 `python3 tools/compile.py`

## 5. Features

- [ ] 5.1 «Путь к гражданству» entry on Today (when a goal of type exam exists) and in Catalog
- [ ] 5.2 Track screens: format, rules, verification date, readiness per part, countdown
- [ ] 5.3 Mock runner: section intro, timer, item views per type, speaking prep timer and recording, submit
- [ ] 5.4 Results screen: per-group scores vs thresholds, failing group, links to weakest grammar cards
- [ ] 5.5 Pro gating via `lorito-pro` entitlements; free preview counters
- [ ] 5.6 Analytics events (via `product-analytics`): mock started/completed/abandoned, result band (no answers content)

## 6. Validation

- [ ] 6.1 `swift test` green; `python3 tools/test_pipeline.py` green
- [ ] 6.2 `xcodebuild` build; UI test: start CCSE mock → answer 25 → result shows pass/fail correctly; background app during a section → timer continued
- [ ] 6.3 Manual: full DELE A2 mock on device with audio and recording
- [ ] 6.4 `openspec validate exam-path-dele-ccse --strict`
