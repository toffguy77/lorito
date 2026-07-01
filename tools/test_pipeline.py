#!/usr/bin/env python3
"""Tests for the content pipeline. Run: python3 tools/test_pipeline.py"""
from __future__ import annotations

import json
import os
import tempfile
import unittest
from pathlib import Path

import lib
import validate
import compile as compile_mod


def write_content(root: Path, cards: list[lib.Card], themes: list[dict]) -> None:
    for c in cards:
        d = root / c.level
        d.mkdir(parents=True, exist_ok=True)
        (d / f"{c.id}.md").write_text(lib.render_card_file(c), encoding="utf-8")
    (root / "themes.json").write_text(
        json.dumps({"themes": themes}, ensure_ascii=False), encoding="utf-8"
    )


def card(cid: str, order: int, theme: str = "a1-1", related=None) -> lib.Card:
    return lib.Card(
        id=cid, level="A1", theme=theme, order=order, title=f"Card {cid}",
        aliases=[], related=related or [], tags=["gramática"], body="Body\n",
    )


THEME = [{"id": "a1-1", "level": "A1", "title": "T1", "order": 1}]


class PipelineTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        os.environ["LORITO_CONTENT_DIR"] = self.tmp.name

    def tearDown(self) -> None:
        os.environ.pop("LORITO_CONTENT_DIR", None)
        os.environ.pop("LORITO_BUNDLE_PATH", None)
        self.tmp.cleanup()

    def test_clean_content_passes(self):
        write_content(Path(self.tmp.name), [card("A1-01", 1), card("A1-02", 2)], THEME)
        self.assertEqual(validate.validate(), [])

    def test_duplicate_ids_caught(self):
        root = Path(self.tmp.name)
        write_content(root, [card("A1-01", 1)], THEME)
        # second file with a different name but the same internal id
        (root / "A1" / "dup.md").write_text(
            lib.render_card_file(card("A1-01", 2)), encoding="utf-8"
        )
        errs = validate.validate()
        self.assertTrue(any("duplicate id" in e for e in errs), errs)

    def test_dangling_related_caught(self):
        write_content(Path(self.tmp.name), [card("A1-01", 1, related=["A1-99"])], THEME)
        errs = validate.validate()
        self.assertTrue(any("unresolved related" in e for e in errs), errs)

    def test_unknown_theme_caught(self):
        write_content(Path(self.tmp.name), [card("A1-01", 1, theme="zz-9")], THEME)
        errs = validate.validate()
        self.assertTrue(any("unknown theme" in e for e in errs), errs)

    def test_compile_produces_bundle(self):
        write_content(Path(self.tmp.name), [card("A1-01", 1), card("A1-02", 2)], THEME)
        out = Path(self.tmp.name) / "content.json"
        os.environ["LORITO_BUNDLE_PATH"] = str(out)
        self.assertEqual(compile_mod.main(), 0)
        self.assertTrue(out.exists())
        data = json.loads(out.read_text(encoding="utf-8"))
        self.assertEqual(len(data["cards"]), 2)
        self.assertEqual(data["cards"][0]["themeID"], "a1-1")

    def test_compile_blocked_by_invalid(self):
        write_content(Path(self.tmp.name), [card("A1-01", 1, related=["A1-99"])], THEME)
        out = Path(self.tmp.name) / "content.json"
        os.environ["LORITO_BUNDLE_PATH"] = str(out)
        self.assertEqual(compile_mod.main(), 1)
        self.assertFalse(out.exists())


def exercise(eid: str, etype: str, card_id: str = "A1-01", theme: str = "a1-1",
             level: str = "A1", **data) -> lib.Exercise:
    return lib.Exercise(
        id=eid, level=level, theme=theme, card=card_id, type=etype,
        prompt="Prompt?", explanation="Because.", data=data,
    )


def write_exercise(root: Path, ex: lib.Exercise) -> None:
    d = root / ex.level / "exercises"
    d.mkdir(parents=True, exist_ok=True)
    (d / f"{ex.id}.md").write_text(lib.render_exercise_file(ex), encoding="utf-8")


class ExerciseTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        os.environ["LORITO_CONTENT_DIR"] = self.tmp.name
        self.root = Path(self.tmp.name)
        # One real card the exercises can reference.
        write_content(self.root, [card("A1-01", 1)], THEME)

    def tearDown(self) -> None:
        os.environ.pop("LORITO_CONTENT_DIR", None)
        os.environ.pop("LORITO_BUNDLE_PATH", None)
        self.tmp.cleanup()

    def test_clean_exercises_pass(self):
        write_exercise(self.root, exercise("A1-EX-01", "multiple-choice",
                                           options=["el", "la"], answer="la"))
        write_exercise(self.root, exercise("A1-EX-02", "fill-in-the-blank",
                                           answer="la", accept=["LA"]))
        self.assertEqual(validate.validate(), [])

    def test_roundtrip_parse(self):
        write_exercise(self.root, exercise("A1-EX-01", "multiple-choice",
                                           options=["el", "la"], answer="la"))
        ex = lib.parse_exercise_file(self.root / "A1" / "exercises" / "A1-EX-01.md")
        self.assertEqual(ex.type, "multiple-choice")
        self.assertEqual(ex.data["options"], ["el", "la"])
        self.assertEqual(ex.data["answer"], "la")
        self.assertEqual(ex.explanation, "Because.")

    def test_missing_type_field_caught(self):
        write_exercise(self.root, exercise("A1-EX-01", "multiple-choice", options=["el", "la"]))
        errs = validate.validate()
        self.assertTrue(any("missing field 'answer'" in e for e in errs), errs)

    def test_unresolved_card_caught(self):
        write_exercise(self.root, exercise("A1-EX-01", "fill-in-the-blank",
                                           card_id="A1-99", answer="x"))
        errs = validate.validate()
        self.assertTrue(any("unresolved card 'A1-99'" in e for e in errs), errs)

    def test_card_level_mismatch_caught(self):
        ex = exercise("B1-EX-01", "fill-in-the-blank", card_id="A1-01",
                      theme="a1-1", level="B1", answer="x")
        write_exercise(self.root, ex)
        errs = validate.validate()
        self.assertTrue(any("is A1, not B1" in e for e in errs), errs)

    def test_unknown_type_caught(self):
        write_exercise(self.root, exercise("A1-EX-01", "crossword", answer="x"))
        errs = validate.validate()
        self.assertTrue(any("unknown type 'crossword'" in e for e in errs), errs)

    def test_mc_answer_not_in_options_caught(self):
        write_exercise(self.root, exercise("A1-EX-01", "multiple-choice",
                                           options=["el", "la"], answer="los"))
        errs = validate.validate()
        self.assertTrue(any("not among options" in e for e in errs), errs)

    def test_word_order_tokens_cannot_form_answer(self):
        write_exercise(self.root, exercise("A1-EX-01", "word-order",
                                           tokens=["yo", "como"], answer="yo no como"))
        errs = validate.validate()
        self.assertTrue(any("tokens cannot be arranged" in e for e in errs), errs)

    def test_word_order_valid(self):
        write_exercise(self.root, exercise("A1-EX-01", "word-order",
                                           tokens=["yo", "como", "pan"], answer="Yo como pan"))
        self.assertEqual(validate.validate(), [])

    def test_normalize_answer_folds_case_and_diacritics(self):
        self.assertEqual(lib.normalize_answer("  Está  "), lib.normalize_answer("esta"))
        self.assertEqual(lib.normalize_answer("Niño"), lib.normalize_answer("nino"))

    def test_duplicate_exercise_id_caught(self):
        write_exercise(self.root, exercise("A1-EX-01", "fill-in-the-blank", answer="a"))
        d = self.root / "A1" / "exercises"
        (d / "dup.md").write_text(
            lib.render_exercise_file(exercise("A1-EX-01", "fill-in-the-blank", answer="b")),
            encoding="utf-8",
        )
        errs = validate.validate()
        self.assertTrue(any("duplicate exercise id" in e for e in errs), errs)

    def test_compile_includes_exercises(self):
        write_exercise(self.root, exercise("A1-EX-01", "multiple-choice",
                                           options=["el", "la"], answer="la"))
        out = self.root / "content.json"
        os.environ["LORITO_BUNDLE_PATH"] = str(out)
        self.assertEqual(compile_mod.main(), 0)
        data = json.loads(out.read_text(encoding="utf-8"))
        self.assertEqual(len(data["exercises"]), 1)
        ex = data["exercises"][0]
        self.assertEqual(ex["type"], "multiple-choice")
        self.assertEqual(ex["card"], "A1-01")
        self.assertEqual(ex["options"], ["el", "la"])
        self.assertEqual(ex["prompt"], "Prompt?")
        self.assertEqual(ex["explanation"], "Because.")

    def test_compile_blocked_by_invalid_exercise(self):
        write_exercise(self.root, exercise("A1-EX-01", "multiple-choice",
                                           options=["el", "la"], answer="los"))
        out = self.root / "content.json"
        os.environ["LORITO_BUNDLE_PATH"] = str(out)
        self.assertEqual(compile_mod.main(), 1)
        self.assertFalse(out.exists())

    def test_coverage_lists_uncovered_cards_and_counts(self):
        # Two cards, one with an exercise, one without.
        write_content(self.root, [card("A1-01", 1), card("A1-02", 2)], THEME)
        write_exercise(self.root, exercise("A1-EX-01", "fill-in-the-blank",
                                           card_id="A1-01", answer="x"))
        rep = validate.coverage()
        self.assertEqual(rep["total"], 2)
        self.assertEqual(rep["covered"], 1)
        self.assertEqual(rep["uncovered"], ["A1-02"])
        self.assertIn("a1-1", rep["uncovered_by_theme"])

    def test_coverage_is_non_failing(self):
        # Cards exist with no exercises at all — coverage still exits zero.
        write_content(self.root, [card("A1-01", 1)], THEME)
        self.assertEqual(validate.print_coverage(), 0)
        self.assertEqual(validate.main(["--coverage"]), 0)
        # And it does not affect validation pass/fail.
        self.assertEqual(validate.validate(), [])


if __name__ == "__main__":
    unittest.main(verbosity=2)
