#!/usr/bin/env python3
"""Validate repo content against the content-model. Exits non-zero on any error.

Checks: required fields, id format, known level/theme, unique ids,
unique order within a level, resolvable `related`, and theme contiguity
(themes group a contiguous run of cards by order).

Usage: python3 tools/validate.py
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import lib


def load_themes() -> dict[str, dict]:
    path = lib.content_dir() / "themes.json"
    if not path.exists():
        return {}
    data = json.loads(path.read_text(encoding="utf-8"))
    return {t["id"]: t for t in data.get("themes", [])}


def validate() -> list[str]:
    errors: list[str] = []
    themes = load_themes()
    files = lib.iter_card_files()
    cards = []
    for p in files:
        try:
            cards.append((p, lib.parse_card_file(p)))
        except Exception as e:  # noqa: BLE001
            errors.append(f"{p}: failed to parse ({e})")
    ids = [c.id for _, c in cards]
    id_set = set(ids)

    # duplicate ids
    seen = set()
    for cid in ids:
        if cid in seen:
            errors.append(f"duplicate id: {cid}")
        seen.add(cid)

    for p, c in cards:
        if not lib.ID_AT_START_RE.match(c.id or ""):
            errors.append(f"{p.name}: bad id format '{c.id}'")
        if c.level not in lib.LEVELS:
            errors.append(f"{c.id}: unknown level '{c.level}'")
        if not c.title:
            errors.append(f"{c.id}: missing title")
        if c.order < 1:
            errors.append(f"{c.id}: order must be >= 1")
        if c.theme not in themes:
            errors.append(f"{c.id}: unknown theme '{c.theme}'")
        elif themes[c.theme]["level"] != c.level:
            errors.append(f"{c.id}: theme '{c.theme}' belongs to {themes[c.theme]['level']}, not {c.level}")
        if p.parent.name != c.level:
            errors.append(f"{c.id}: file under {p.parent.name}/ but level is {c.level}")
        for r in c.related:
            if r not in id_set:
                errors.append(f"{c.id}: unresolved related '{r}'")

    # per-level: unique order + theme contiguity
    by_level: dict[str, list[lib.Card]] = {}
    for _, c in cards:
        by_level.setdefault(c.level, []).append(c)
    for level, cs in by_level.items():
        orders = [c.order for c in cs]
        dupes = {o for o in orders if orders.count(o) > 1}
        for o in sorted(dupes):
            errors.append(f"{level}: duplicate order {o}")
        ordered = sorted(cs, key=lambda c: c.order)
        # contiguity: the sequence of theme ids must not revisit a theme after leaving it
        seen_themes: list[str] = []
        for c in ordered:
            if not seen_themes or seen_themes[-1] != c.theme:
                if c.theme in seen_themes:
                    errors.append(f"{level}: theme '{c.theme}' is not contiguous (interleaved)")
                seen_themes.append(c.theme)

    return errors


def main() -> int:
    errors = validate()
    if errors:
        print(f"VALIDATION FAILED ({len(errors)} error(s)):", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1
    print(f"content valid: {len(lib.iter_card_files())} cards")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
