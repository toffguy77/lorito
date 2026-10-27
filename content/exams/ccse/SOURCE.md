# CCSE question bank — source

The CCSE items are transcribed from the **official preparation manual of the
Instituto Cervantes**: «Manual de preparación de la prueba CCSE» (2026 edition,
NIPO 110-25-054-X), published free of charge at
https://examenes.cervantes.es/es/ccse/preparar-prueba. Owner decision
2026-10-27: Cervantes materials may be used, with attribution in content and in
the app.

**Status:** not imported yet — examenes.cervantes.es could not be reached when
this change was implemented (2026-10-27), and copies on other sites were not
used.

## Owner steps

1. Download the current manual from examenes.cervantes.es.
2. Transcribe it to `content/exams/ccse/source/<edition>.md` in the format read by
   `tools/import_ccse.py` (`## Tarea N`, `N. question`, `a) … b) … c) …`,
   `Respuesta: <letter>`).
3. Run `python3 tools/import_ccse.py content/exams/ccse/source/<edition>.md --edition <edition>`,
   add Russian explanations, mark one mock form `preview: true`, then
   `python3 tools/validate.py && python3 tools/compile.py`.
4. Record here: edition, NIPO, download date.
5. Every January (new edition): repeat; questions removed from the manual are
   kept with `retired: true` and are no longer scheduled.
