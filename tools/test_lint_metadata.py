#!/usr/bin/env python3
"""Tests for tools/lint_metadata.py (temporary metadata trees, no network).
Run: python3 tools/test_lint_metadata.py"""
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
SCRIPT = TOOLS / "lint_metadata.py"

GOOD = {
    "name.txt": "Lorito: испанский язык",
    "subtitle.txt": "Грамматика по-русски, A1–C2",
    "promotional_text.txt": "Испанская грамматика по-русски от A1 до C2.",
    "description.txt": "Испанская грамматика по-русски.",
    "keywords.txt": "испанская,учить,правила,глаголы,спряжение,времена,субхунтив,subjuntivo,карточки,упражнения",
    "release_notes.txt": "Исправления.",
}


def tree(root: Path, locales):
    for locale, overrides in locales.items():
        d = root / locale
        d.mkdir(parents=True)
        for name, text in {**GOOD, **overrides}.items():
            if text is not None:
                (d / name).write_text(text, encoding="utf-8")


def lint(root: Path, *extra):
    return subprocess.run([sys.executable, str(SCRIPT), "--metadata", str(root), *extra],
                          capture_output=True, text=True)


class LintMetadataTests(unittest.TestCase):
    def check(self, locales, *extra):
        with tempfile.TemporaryDirectory() as tmp:
            tree(Path(tmp), locales)
            return lint(Path(tmp), *extra)

    def test_good_metadata_passes(self):
        r = self.check({"ru": {}})
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)

    def test_stage1_keywords_are_counted_in_characters(self):
        # 90 characters but 161 UTF-8 bytes: within the character limit.
        self.assertEqual(len(GOOD["keywords.txt"]), 90)
        self.assertGreater(len(GOOD["keywords.txt"].encode()), 100)
        self.assertEqual(self.check({"ru": {}}).returncode, 0)

    def test_over_limit_name(self):
        r = self.check({"ru": {"name.txt": "Л" * 31}})
        self.assertEqual(r.returncode, 1)
        self.assertIn("ru/name.txt", r.stdout)

    def test_too_short_name(self):
        self.assertEqual(self.check({"ru": {"name.txt": "L"}}).returncode, 1)

    def test_over_limit_subtitle(self):
        r = self.check({"ru": {"subtitle.txt": "а" * 31}})
        self.assertEqual(r.returncode, 1)
        self.assertIn("ru/subtitle.txt", r.stdout)
        self.assertIn("31", r.stdout)

    def test_subtitle_at_limit_passes(self):
        self.assertEqual(self.check({"ru": {"subtitle.txt": "а" * 30}}).returncode, 0)

    def test_over_limit_promo(self):
        r = self.check({"ru": {"promotional_text.txt": "а" * 171}})
        self.assertEqual(r.returncode, 1)
        self.assertIn("promotional_text", r.stdout)

    def test_over_limit_description(self):
        r = self.check({"ru": {"description.txt": "а" * 4001}})
        self.assertEqual(r.returncode, 1)
        self.assertIn("description", r.stdout)

    def test_keywords_over_100_characters(self):
        kw = ",".join(["слово" + str(i) for i in range(20)])  # > 100 chars
        self.assertGreater(len(kw), 100)
        r = self.check({"ru": {"keywords.txt": kw}})
        self.assertEqual(r.returncode, 1)
        self.assertIn("keywords", r.stdout)

    def test_short_keyword_named(self):
        r = self.check({"ru": {"keywords.txt": "испанская,B1,глаголы"}})
        self.assertEqual(r.returncode, 1)
        self.assertIn("«B1»", r.stdout)

    def test_duplicate_keyword_named(self):
        r = self.check({"ru": {"keywords.txt": "глаголы,испанская,Глаголы"}})
        self.assertEqual(r.returncode, 1)
        self.assertIn("«глаголы»", r.stdout)

    def test_keyword_repeating_name_or_subtitle_word(self):
        r = self.check({"ru": {"keywords.txt": "испанская,язык"}})
        self.assertEqual(r.returncode, 1)
        self.assertIn("«язык»", r.stdout)
        r = self.check({"ru": {"keywords.txt": "испанская,грамматика"}})
        self.assertEqual(r.returncode, 1)
        self.assertIn("«грамматика»", r.stdout)

    def test_all_localizations_scanned(self):
        r = self.check({"ru": {}, "es-ES": {}, "es-MX": {"subtitle.txt": "а" * 40}})
        self.assertEqual(r.returncode, 1)
        self.assertIn("es-MX/subtitle.txt", r.stdout)
        self.assertNotIn("ru/subtitle.txt", r.stdout)

    def test_missing_optional_files_are_fine(self):
        self.assertEqual(self.check({"ru": {"promotional_text.txt": None, "release_notes.txt": None}}).returncode, 0)

    def test_non_locale_directories_ignored(self):
        with tempfile.TemporaryDirectory() as tmp:
            tree(Path(tmp), {"ru": {}})
            (Path(tmp) / "review_information").mkdir()
            (Path(tmp) / "review_information" / "notes.txt").write_text("x" * 5000)
            (Path(tmp) / "copyright.txt").write_text("2026")
            self.assertEqual(lint(Path(tmp)).returncode, 0)

    def test_forbidden_terms(self):
        r = self.check({"ru": {"description.txt": "Подготовка к DELE."}}, "--forbid-terms", "DELE,CCSE,экзамен,гражданство")
        self.assertEqual(r.returncode, 1)
        self.assertIn("DELE", r.stdout)
        r = self.check({"ru": {"keywords.txt": "испанская,экзамены"}}, "--forbid-terms", "экзамен")
        self.assertEqual(r.returncode, 1)
        self.assertEqual(self.check({"ru": {}}, "--forbid-terms", "DELE").returncode, 0)


if __name__ == "__main__":
    unittest.main()
