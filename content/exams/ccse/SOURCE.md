# CCSE question bank — source

The CCSE items are transcribed from the **official preparation manual of the
Instituto Cervantes**: «Manual de preparación de la prueba CCSE» (2026 edition,
NIPO 110-25-054-X), published free of charge at
https://examenes.cervantes.es/es/ccse/preparar-prueba. Owner decision
2026-10-27: Cervantes materials may be used, with attribution in content and in
the app.

**Imported:** edition 2026 («Manual de preparación de la prueba de conocimientos
constitucionales y socioculturales de España (CCSE)», © Instituto Cervantes 2025,
NIPO 110-25-054-X), downloaded 2026-10-29 from the Instituto Cervantes site:
https://cervantes.org/sites/public/produccion/files/2026-10/manual-preparacion-prueba-ccse-2026.pdf
(examenes.cervantes.es was under maintenance and linked there). 300 questions
(tareas 1–5: 120 / 36 / 24 / 36 / 84), answers from the manual's «Soluciones».
Transcription: `source/2026.md`. Mock forms: 12 × 25 questions, 10 / 3 / 2 / 3 / 7
per tarea; form 1 is the free preview. Russian explanations are generated and need
review.

## Owner steps

1. Download the current manual from examenes.cervantes.es.
2. Transcribe it to `content/exams/ccse/source/<edition>.md` in the format read by
   `tools/import_ccse.py` (`## Tarea N`, `N. question`, `a) … b) … c) …`,
   `Respuesta: <letter>`).
3. Run `python3 tools/import_ccse.py content/exams/ccse/source/<edition>.md --edition <edition>`,
   add Russian explanations to new questions (re-import keeps existing ones and
   the `preview` flags; forms are reassigned), then
   `python3 tools/validate.py && python3 tools/compile.py`.
4. Record here: edition, NIPO, download date.
5. Every January (new edition): repeat; questions removed from the manual are
   kept with `retired: true` and are no longer scheduled.
