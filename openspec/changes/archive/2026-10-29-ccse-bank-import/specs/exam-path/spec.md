## ADDED Requirements

### Requirement: CCSE mock forms
The CCSE bank SHALL be split into mock forms of 25 questions with the official exam distribution per tarea — 10 from tarea 1, 3 from tarea 2, 2 from tarea 3, 3 from tarea 4 and 7 from tarea 5 — taking each tarea's questions in number order. Form 1 SHALL be the free preview mock.

#### Scenario: Form composition
- **WHEN** the 2026 manual (120 / 36 / 24 / 36 / 84 questions per tarea) is imported
- **THEN** there are 12 forms of 25 questions, each with 10 / 3 / 2 / 3 / 7 questions from tareas 1–5

### Requirement: CCSE re-import keeps explanations
Importing a new manual edition SHALL keep the Russian explanation and the `preview` flag of every question that is still in the manual, and SHALL update its text, options, answer, form and edition.

#### Scenario: Yearly re-import
- **WHEN** a question with a Russian explanation is imported again from a new edition
- **THEN** its explanation is unchanged and its edition is the new one
