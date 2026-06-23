#!/usr/bin/env python3
"""Seed-migrate the Obsidian vault notes into repo content/<LEVEL>/<id>.md files,
and emit the per-level theme registry content/themes.json.

Usage:
    python3 tools/migrate.py [VAULT_DIR]

VAULT_DIR defaults to the known Español vault path. Idempotent: re-running
regenerates the same files from the vault.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import lib

DEFAULT_VAULT = Path(
    "/Users/thatguy/vault/20-Active/Personal/Learning/Español"
)


def main() -> int:
    vault = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_VAULT
    if not vault.is_dir():
        print(f"error: vault dir not found: {vault}", file=sys.stderr)
        return 1

    content = lib.content_dir()
    themes_registry: list[dict] = []
    total_cards = 0

    for level in lib.LEVELS:
        level_dir = vault / level
        if not level_dir.is_dir():
            print(f"warn: no {level} dir in vault, skipping", file=sys.stderr)
            continue

        moc = next(iter(level_dir.glob("*MOC*.md")), None)
        if moc is None:
            print(f"error: no MOC for {level}", file=sys.stderr)
            return 1
        sections = lib.parse_moc(moc)

        # card_id -> theme_id
        card_theme: dict[str, str] = {}
        for idx, (title, ids) in enumerate(sections, start=1):
            theme_id = f"{level.lower()}-{idx}"
            themes_registry.append(
                {"id": theme_id, "level": level, "title": title, "order": idx}
            )
            for cid in ids:
                card_theme[cid] = theme_id

        out_dir = content / level
        out_dir.mkdir(parents=True, exist_ok=True)

        for note in sorted(level_dir.glob("*.md")):
            if "MOC" in note.name:
                continue
            cid, title = lib.title_from_filename(note.name)
            raw = note.read_text(encoding="utf-8")
            fm, body = lib.split_frontmatter(raw)
            theme = card_theme.get(cid)
            if theme is None:
                print(f"error: {cid} not found in {level} MOC", file=sys.stderr)
                return 1
            card = lib.Card(
                id=cid,
                level=level,
                theme=theme,
                order=lib.order_from_id(cid),
                title=title,
                aliases=lib.parse_aliases(fm),
                related=lib.parse_related(fm),
                tags=lib.parse_category_tags(fm),
                body=lib.clean_body(body),
            )
            (out_dir / f"{cid}.md").write_text(lib.render_card_file(card), encoding="utf-8")
            total_cards += 1

    (content / "themes.json").write_text(
        json.dumps({"themes": themes_registry}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"migrated {total_cards} cards, {len(themes_registry)} themes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
