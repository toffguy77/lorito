#!/usr/bin/env python3
"""Compile repo content into the app's bundled content artifact.

Runs validation first; refuses to write a bundle if validation fails.
Output: Packages/LoritoKit/Sources/Content/Resources/content.json
(shape matches Domain.ContentCatalog).

Usage: python3 tools/compile.py
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

import lib
import validate


def bundle_path() -> Path:
    env = os.environ.get("LORITO_BUNDLE_PATH")
    if env:
        return Path(env)
    return lib.repo_root() / "Packages/LoritoKit/Sources/Content/Resources/content.json"


def main() -> int:
    errors = validate.validate()
    if errors:
        print(f"refusing to compile: {len(errors)} validation error(s). Run tools/validate.py", file=sys.stderr)
        return 1

    themes_data = json.loads((lib.content_dir() / "themes.json").read_text(encoding="utf-8"))
    themes = themes_data.get("themes", [])

    cards_out = []
    for _, c in ((p, lib.parse_card_file(p)) for p in lib.iter_card_files()):
        cards_out.append({
            "id": c.id,
            "level": c.level,
            "themeID": c.theme,
            "order": c.order,
            "title": c.title,
            "aliases": c.aliases,
            "related": c.related,
            "tags": c.tags,
            "body": c.body,
        })

    catalog = {"themes": themes, "cards": cards_out}
    out = bundle_path()
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"compiled bundle: {len(cards_out)} cards, {len(themes)} themes -> {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
