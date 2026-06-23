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


if __name__ == "__main__":
    unittest.main(verbosity=2)
