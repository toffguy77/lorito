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


def validate_exercises(themes: dict[str, dict], card_level: dict[str, str]) -> list[str]:
    """Validate practice exercises against the content-model. `card_level` maps
    every card id to its level (for resolving each exercise's `card` reference)."""
    errors: list[str] = []
    seen: set[str] = set()
    for p in lib.iter_exercise_files():
        try:
            ex = lib.parse_exercise_file(p)
        except Exception as e:  # noqa: BLE001
            errors.append(f"{p}: failed to parse exercise ({e})")
            continue
        eid = ex.id or p.name
        if not ex.id:
            errors.append(f"{p.name}: exercise missing id")
        if ex.id in seen:
            errors.append(f"duplicate exercise id: {ex.id}")
        seen.add(ex.id)
        if ex.level not in lib.LEVELS:
            errors.append(f"{eid}: unknown level '{ex.level}'")
        if p.parent.parent.name != ex.level:
            errors.append(f"{eid}: file under {p.parent.parent.name}/exercises but level is {ex.level}")
        if ex.theme not in themes:
            errors.append(f"{eid}: unknown theme '{ex.theme}'")
        elif themes[ex.theme]["level"] != ex.level:
            errors.append(f"{eid}: theme '{ex.theme}' belongs to {themes[ex.theme]['level']}, not {ex.level}")
        if not ex.card:
            errors.append(f"{eid}: missing card reference")
        elif ex.card not in card_level:
            errors.append(f"{eid}: unresolved card '{ex.card}'")
        elif card_level[ex.card] != ex.level:
            errors.append(f"{eid}: card '{ex.card}' is {card_level[ex.card]}, not {ex.level}")
        if ex.type not in lib.EXERCISE_TYPES:
            errors.append(f"{eid}: unknown type '{ex.type}'")
            continue
        errors.extend(f"{eid}: {e}" for e in _validate_exercise_type(ex))
        # picture-matching: every referenced image asset must exist in the sources.
        for img in lib.exercise_image_names(ex):
            if not (lib.exercise_assets_dir() / img).exists():
                errors.append(f"{eid}: missing image asset '{img}'")
    return errors


def _missing(data: dict, *keys: str) -> list[str]:
    return [f"missing field '{k}' for type" for k in keys if k not in data or data[k] in (None, "", [])]


def _validate_exercise_type(ex: lib.Exercise) -> list[str]:
    d, errs = ex.data, []
    if ex.type == "multiple-choice":
        errs += _missing(d, "options", "answer")
        opts = d.get("options")
        if isinstance(opts, list) and len(opts) < 2:
            errs.append("'options' needs at least 2 entries")
        if isinstance(opts, list) and "answer" in d and d["answer"] not in opts:
            errs.append(f"answer '{d.get('answer')}' is not among options")
    elif ex.type == "fill-in-the-blank":
        errs += _missing(d, "answer")
    elif ex.type == "matching":
        pairs = d.get("pairs")
        if not isinstance(pairs, list) or len(pairs) < 2:
            errs.append("'pairs' needs at least 2 {left,right} entries")
        elif any(not isinstance(pr, dict) or "left" not in pr or "right" not in pr for pr in pairs):
            errs.append("each pair needs 'left' and 'right'")
    elif ex.type == "word-order":
        errs += _missing(d, "tokens", "answer")
        toks, ans = d.get("tokens"), d.get("answer")
        if isinstance(toks, list) and isinstance(ans, str):
            tok_norm = sorted(lib.normalize_answer(t) for t in toks)
            ans_norm = sorted(lib.normalize_answer(w) for w in ans.split())
            if tok_norm != ans_norm:
                errs.append("tokens cannot be arranged into answer")
    elif ex.type == "picture-matching":
        opts = d.get("options")
        if not isinstance(opts, list) or len(opts) < 2:
            errs.append("'options' needs at least 2 {image,label} entries")
        elif any(not isinstance(o, dict) or "image" not in o or "label" not in o for o in opts):
            errs.append("each option needs 'image' and 'label'")
        # Asset-file existence is checked in validate_exercises (needs the filesystem).
    elif ex.type == "free-response":
        errs += _missing(d, "answer")
    return errs


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

    # Practice exercises (content/<LEVEL>/exercises/<id>.md).
    card_level = {c.id: c.level for _, c in cards}
    errors.extend(validate_exercises(themes, card_level))

    return errors


def coverage(level: str | None = None) -> dict:
    """Informational exercise-coverage report. Returns, per card, whether it has
    any practice exercise. Does NOT validate or fail — purely a progress signal.

    `level` optionally restricts the report to a single CEFR level."""
    cards = [lib.parse_card_file(p) for p in lib.iter_card_files()]
    if level:
        cards = [c for c in cards if c.level == level]
    covered_ids = {ex.card for ex in (lib.parse_exercise_file(p) for p in lib.iter_exercise_files())}
    uncovered = [c.id for c in cards if c.id not in covered_ids]
    by_theme: dict[str, list[str]] = {}
    for c in cards:
        if c.id not in covered_ids:
            by_theme.setdefault(c.theme, []).append(c.id)
    return {
        "total": len(cards),
        "covered": len(cards) - len(uncovered),
        "uncovered": uncovered,
        "uncovered_by_theme": by_theme,
    }


def print_coverage(level: str | None = None) -> int:
    rep = coverage(level)
    scope = level or "all levels"
    print(f"exercise coverage ({scope}): {rep['covered']}/{rep['total']} cards have exercises")
    for theme in sorted(rep["uncovered_by_theme"]):
        ids = ", ".join(rep["uncovered_by_theme"][theme])
        print(f"  {theme}: missing {ids}")
    if not rep["uncovered"]:
        print("  all cards covered ✓")
    return 0  # informational — never fails


def main(argv: list[str] | None = None) -> int:
    args = argv if argv is not None else sys.argv[1:]
    if "--coverage" in args:
        rest = [a for a in args if a != "--coverage"]
        level = rest[0] if rest else None
        return print_coverage(level)

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
