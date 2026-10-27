#!/usr/bin/env python3
"""Import a transcription of the Cervantes CCSE manual into content/exams/ccse/items.

Usage: python3 tools/import_ccse.py content/exams/ccse/source/<edition>.md --edition <edition>
Transcription format: "## Tarea N" headings; questions "N. text"; options "a) …"
"b) …" ["c) …"]; then "Respuesta: <letter>". Questions missing from the new
edition are kept and flagged `retired: true`.
"""
import sys

import exams

if __name__ == "__main__":
    sys.exit(exams.main(["import", *sys.argv[1:]]))
