## Why

The CCSE track has no questions yet: the official manual could not be downloaded
when exam-path shipped. The 2026 manual (NIPO 110-25-054-X) is now available. The
importer also puts every question into mock form 1, so a mock would show the whole
bank instead of 25 questions, and a yearly re-import would wipe the Russian
explanations.

## What Changes

- Import the 300 questions of the 2026 manual (tareas 1–5) with the manual's answer key.
- The importer splits the bank into mock forms of 25 questions with the official
  exam distribution per tarea (10 / 3 / 2 / 3 / 7), in question-number order.
- Re-import keeps an existing item's Russian explanation and `preview` flag.
- Form 1 is the free preview mock.
- Russian explanations for every question (generated — нужна вычитка).

## Capabilities

### Modified Capabilities
- `exam-path`: CCSE mock forms; re-import keeps explanations.

## Impact

- `tools/exams.py` (import), `tools/test_pipeline.py`.
- `content/exams/ccse/source/2026.md`, `content/exams/ccse/items/*.md`,
  `content/exams/ccse/SOURCE.md`; compiled `content.json`.
- No app code changes: mocks already read items by form.
