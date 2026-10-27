#!/usr/bin/env python3
"""Regional-variant markup in cards and exercises (stdlib only).

Codes: es (Spain), am (Latin America), rio (Rioplatense).

Card bodies:
  :::variant <codes>        a block (paragraphs, lists, tables) for the listed
  …                         variants; content outside blocks is for everyone
  :::
  {es: coche | am: carro}   inline alternatives: at least two distinct codes;
                            plain braces without a `code:` prefix stay text.
Neither form collides with Obsidian wiki-links ([[…]]) or callouts (> [!note]).

Exercises: optional `variants: {am: {answer, accept, options}, …}` overrides
answer data per variant; optional `only: [es]` restricts the exercise.
"""
from __future__ import annotations

import re

CODES = ("es", "am", "rio")
OVERRIDE_KEYS = {"answer", "accept", "options"}

_BLOCK_OPEN = re.compile(r"^:::variant\b(.*)$")
_BLOCK_CLOSE = re.compile(r"^:::\s*$")
# A brace group whose first entry starts with `word:` is variant markup.
_INLINE = re.compile(r"\{\s*([A-Za-z]+)\s*:[^{}]*\}")


def check_markup(body: str) -> list[str]:
    """Errors in a card body's variant markup (empty when valid)."""
    errors: list[str] = []
    open_line: int | None = None
    for n, raw in enumerate(body.splitlines(), 1):
        line = raw.strip()
        if m := _BLOCK_OPEN.match(line):
            if open_line is not None:
                errors.append(f"line {n}: nested variant block (opened on line {open_line})")
                continue
            open_line = n
            codes = m.group(1).split()
            if not codes:
                errors.append(f"line {n}: variant block without codes")
            for c in codes:
                if c not in CODES:
                    errors.append(f"line {n}: unknown variant code '{c}'")
            if len(set(codes)) != len(codes):
                errors.append(f"line {n}: repeated variant code in block")
        elif _BLOCK_CLOSE.match(line):
            if open_line is None:
                errors.append(f"line {n}: ':::' without an open variant block")
            open_line = None
        for im in _INLINE.finditer(raw):
            errors.extend(f"line {n}: {e}" for e in _check_inline(im.group(0)))
    if open_line is not None:
        errors.append(f"line {open_line}: unclosed variant block")
    return errors


def parse_inline(group: str) -> list[tuple[str, str]]:
    """`{es: coche | am: carro}` → [("es", "coche"), ("am", "carro")]."""
    out = []
    for part in group.strip()[1:-1].split("|"):
        code, _, text = part.partition(":")
        out.append((code.strip(), text.strip()))
    return out


def _check_inline(group: str) -> list[str]:
    pairs = parse_inline(group)
    errors = [f"unknown variant code '{c}' in {group}" for c, _ in pairs if c not in CODES]
    codes = [c for c, _ in pairs]
    if len(set(codes)) != len(codes):
        errors.append(f"repeated variant code in {group}")
    if len(set(codes)) < 2:
        errors.append(f"inline alternatives need at least two codes: {group}")
    if any(not t for _, t in pairs):
        errors.append(f"empty variant text in {group}")
    return errors


def check_exercise(ex_type: str, data: dict) -> list[str]:
    """Errors in an exercise's `variants` / `only` (each override is validated
    against the type schema after merging into the base data)."""
    from validate import validate_exercise_data  # local: validate imports this module

    errors: list[str] = []
    only = data.get("only")
    if only is not None:
        if not isinstance(only, list) or not only:
            errors.append("'only' must be a non-empty list of variant codes")
        else:
            errors += [f"'only' has unknown variant code '{c}'" for c in only if c not in CODES]
    overrides = data.get("variants")
    if overrides is None:
        return errors
    if not isinstance(overrides, dict):
        return errors + ["'variants' must map variant codes to overrides"]
    base = {k: v for k, v in data.items() if k not in ("variants", "only")}
    for code, ov in overrides.items():
        if code not in CODES:
            errors.append(f"'variants' has unknown variant code '{code}'")
            continue
        if not isinstance(ov, dict) or not ov:
            errors.append(f"variant '{code}': override must be a non-empty object")
            continue
        for k in sorted(set(ov) - OVERRIDE_KEYS):
            errors.append(f"variant '{code}': field '{k}' cannot be overridden")
        merged = {**base, **{k: v for k, v in ov.items() if k in OVERRIDE_KEYS}}
        errors += [f"variant '{code}': {e}" for e in validate_exercise_data(ex_type, merged)]
    return errors
