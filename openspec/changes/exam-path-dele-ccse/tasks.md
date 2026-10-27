## 0. Dependencies and owner

- [ ] 0.1 Dependencies applied: `learning-platform-foundation`, `cloudkit-schema-release`, `study-goal` (`examKind`, `examDate`), `spanish-audio`, `lorito-pro`; `listening-and-pronunciation` for recording (fallback: speaking without recording)
- [ ] 0.2 Owner: provide the current edition of the Cervantes CCSE manual for transcription; record edition and date in `content/exams/ccse/SOURCE.md`
- [ ] 0.3 Owner: re-verify DELE A2/CCSE timings, thresholds and fees; set `verifiedOn`
- [ ] 0.4 Owner (recurring): when Cervantes publishes a new CCSE edition, re-run the import and review retired items

## 1. Content model and pipeline (TDD)

- [ ] 1.1 Document `content/exams/` in `content/schema.md`: exam definitions (sections, limits, groups, thresholds, `verifiedOn`, `preview`), item front matter (`id`, `exam`, `section`, `type`, `source`, `edition`, `cards`)
- [ ] 1.2 Failing tests in `tools/test_pipeline.py`: missing `source`/`edition` fails; invalid answer key fails; preview set present; compile writes exams
- [ ] 1.3 `tools/import_ccse.py` (stdlib) from the manual transcription → one file per question with `ccse:<id>`; retired items flagged
- [ ] 1.4 Implement validation and compile

## 2. Domain (TDD)

- [ ] 2.1 `ExamDefinition`, `ExamItem` (incl. `listeningTask`, `writingTask`, `speakingTask`) decoding tests
- [ ] 2.2 `MockScorer` — tests: group scaling, 38/28 fails on Group 2, 30/30 passes, CCSE 15/25 passes, 14/25 fails, unanswered = incorrect
- [ ] 2.3 `RubricScore` — ticked items → points, «Самооценка» flag
- [ ] 2.4 `MockTimer` — remaining time from persisted start + injected now; expiry closes the section; closing on next launch
- [ ] 2.5 `ReadinessCalculator` — deterministic, Russian labels, «На грани» cap, abandoned excluded
- [ ] 2.6 CCSE quota — tests: `ccse:` items introduced within the shared budget and never above `ccseDailyNewLimit`; 0 disables

## 3. Persistence

- [ ] 3.1 `MockAttemptRecord` and setting `ccseDailyNewLimit` per `cloudkit-schema-release` (optional/defaulted, mapped both ways, round-trip test, schema export)
- [ ] 3.2 Speaking audio in the local app container only, 2 min cap, latest 20 kept, deleted with the attempt

## 4. Content

- [ ] 4.1 Author 3 full DELE A2 mocks (reading, listening scripts, writing and speaking prompts + rubrics), items mapped to grammar cards; mark the preview reading task
- [ ] 4.2 Import the CCSE bank; add Russian explanations; mark one preview mock form
- [ ] 4.3 Listening audio via `spanish-audio` pre-rendering or recordings
- [ ] 4.4 `python3 tools/compile.py`

## 5. Features

- [ ] 5.1 «Экзамены DELE и CCSE» entry in Catalog and on Today when a goal with `examKind` exists; «Путь к гражданству» track
- [ ] 5.2 Track screens: format, rules, `verifiedOn`, readiness, countdown, Cervantes attribution
- [ ] 5.3 Mock runner (timer, item views, speaking prep and recording), results screen with failing group and weakest cards
- [ ] 5.4 Settings: «Новых вопросов CCSE в день» (`ccseDailyNewLimit`)
- [ ] 5.5 Pro gating via `lorito-pro`; preview by content flag
- [ ] 5.6 Analytics via `product-analytics`: mock started/completed/expired/abandoned, result band

## 6. Validation

- [ ] 6.1 `swift test`, `python3 tools/test_pipeline.py` green
- [ ] 6.2 `xcodebuild`; UI tests: CCSE mock → result; background during a section → timer continued; relaunch after expiry → attempt closed
- [ ] 6.3 Manual: full DELE A2 mock on device with audio and recording
- [ ] 6.4 `openspec validate exam-path-dele-ccse --strict`
