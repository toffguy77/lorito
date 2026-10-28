## 1. Domain (TDD)

- [x] 1.1 Failing tests: decode `variants`; `Word.resolved(for:)` per variant with fallback; noun gender from the form's article; checker accepts every form with its own article; lookup matches regional forms; example resolved for the variant
- [x] 1.2 Implement in `Domain/Vocabulary/Vocabulary.swift`

## 2. Features

- [x] 2.1 Word session reads the learner's variant: front, audio, expected answer, example; other forms listed after reveal / check
- [x] 2.2 Feature tests for the session model with a Latin American learner

## 3. Pipeline (TDD)

- [x] 3.1 Failing tests in `tools/test_pipeline.py` for the four new checks; example check resolves inline alternatives
- [x] 3.2 Implement in `tools/vocab.py`; document `variants` in `content/schema.md`

## 4. Content (generated — нужна вычитка)

- [x] 4.1 Regional forms for 43 A1–A2 entries where everyday usage differs; examples marked
- [ ] 4.2 (manual, owner) Review the regional forms

## 5. Verify

- [x] 5.1 `swift test`; `python3 tools/test_pipeline.py`; `validate.py`; `openspec validate vocabulary-regional-words --strict`
