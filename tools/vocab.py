#!/usr/bin/env python3
"""Vocabulary decks (content/vocabulary/, CC BY-SA 4.0 — derived from FrequencyWords).

  decks.json           [{id, level, title_ru, order}]
  <deck-id>.json       [{id, es, pos, article?, gender?, plural?, forms?, ru,
                         example_es, example_ru, rank}]

Nouns need `article` (el / la) and `gender` (m / f / mf). `id` is the lemma slug,
unique across decks; `rank` is the FrequencyWords position of the lemma.
"""
from __future__ import annotations

import json
import re
import unicodedata
from pathlib import Path

import lib

POS = {"noun", "verb", "adj", "adv", "pron", "prep", "conj", "num", "phrase", "det", "interj"}
GENDERS = {"m", "f", "mf"}
ARTICLES = {"el", "la", "los", "las"}  # los / las for plural-only nouns (vacaciones)


def _fold(s: str) -> str:
    return "".join(c for c in unicodedata.normalize("NFD", s.lower()) if unicodedata.category(c) != "Mn")


def example_uses_word(w: dict) -> bool:
    """The example contains the lemma or a listed form. Verbs are exempt: their
    examples are conjugated and conjugated forms aren't all listed."""
    if w.get("pos") == "verb":
        return True
    example = _fold(w.get("example_es", ""))
    candidates = [w.get("es", "")] + list(w.get("forms") or [])
    if " " in w.get("es", ""):
        return any(_fold(c) in example for c in candidates if c)
    tokens = set(re.findall(r"[a-zñ]+", example))
    return any(_fold(c) in tokens for c in candidates if c)


def vocab_dir() -> Path:
    return lib.content_dir() / "vocabulary"


def load_decks() -> list[dict]:
    p = vocab_dir() / "decks.json"
    return json.loads(p.read_text(encoding="utf-8")) if p.exists() else []


def validate_vocabulary() -> list[str]:
    d = vocab_dir()
    if not d.exists():
        return []
    errors: list[str] = []
    if not (d / "LICENSE").exists():
        errors.append("vocabulary: missing LICENSE (CC BY-SA 4.0, FrequencyWords)")
    try:
        decks = load_decks()
    except Exception as e:  # noqa: BLE001
        return errors + [f"vocabulary/decks.json: failed to parse ({e})"]
    ids = [x.get("id") for x in decks]
    for i in sorted({i for i in ids if ids.count(i) > 1}):
        errors.append(f"vocabulary: duplicate deck id '{i}'")
    orders: dict[str, list[int]] = {}
    for x in decks:
        for key in ("id", "level", "title_ru", "order"):
            if key not in x:
                errors.append(f"vocabulary: deck '{x.get('id')}' missing '{key}'")
        if x.get("level") not in lib.LEVELS:
            errors.append(f"vocabulary: deck '{x.get('id')}' unknown level '{x.get('level')}'")
        orders.setdefault(x.get("level"), []).append(x.get("order"))
    for level, os_ in orders.items():
        for o in sorted({o for o in os_ if os_.count(o) > 1}, key=str):
            errors.append(f"vocabulary: {level} duplicate deck order {o}")
    known = set(ids)
    seen: set[str] = set()
    for f in sorted(d.glob("*.json")):
        if f.name == "decks.json":
            continue
        if f.stem not in known:
            errors.append(f"vocabulary: file '{f.name}' has no deck '{f.stem}' in decks.json")
            continue
        try:
            words = json.loads(f.read_text(encoding="utf-8"))
        except Exception as e:  # noqa: BLE001
            errors.append(f"vocabulary/{f.name}: failed to parse ({e})")
            continue
        for w in words:
            wid = w.get("id")
            if wid in seen:
                errors.append(f"vocabulary: duplicate word id '{wid}'")
            seen.add(wid)
            for key in ("id", "es", "pos", "ru", "example_es", "example_ru", "rank"):
                if not w.get(key):
                    errors.append(f"vocabulary: word '{wid}' missing '{key}'")
            if w.get("pos") not in POS:
                errors.append(f"vocabulary: word '{wid}' unknown pos '{w.get('pos')}'")
            if w.get("example_es") and not example_uses_word(w):
                errors.append(f"vocabulary: word '{wid}' example doesn't contain the word or a listed form")
            if w.get("pos") == "noun" and w.get("article") == "el" and w.get("gender") == "f" \
                    and not re.match(r"^h?[aá]", _fold(w.get("es", ""))):
                errors.append(f"vocabulary: noun '{wid}' with el must be masculine (el + feminine only before stressed a-)")
            if w.get("pos") == "noun":
                if w.get("article") not in ARTICLES:
                    errors.append(f"vocabulary: noun '{wid}' needs article el/la (los/las for plural-only)")
                if w.get("gender") not in GENDERS:
                    errors.append(f"vocabulary: noun '{wid}' needs gender m/f/mf")
            elif "gender" in w and w["gender"] not in GENDERS:
                errors.append(f"vocabulary: word '{wid}' bad gender '{w['gender']}'")
            r = w.get("rank")
            if not isinstance(r, int) or isinstance(r, bool) or r < 1:
                errors.append(f"vocabulary: word '{wid}' rank must be a positive integer")
            if "forms" in w and not (isinstance(w["forms"], list) and all(isinstance(x, str) for x in w["forms"])):
                errors.append(f"vocabulary: word '{wid}' forms must be a list of strings")
    return errors


def bundle() -> dict | None:
    d = vocab_dir()
    if not d.exists():
        return None
    out = []
    for x in sorted(load_decks(), key=lambda x: (lib.LEVELS.index(x["level"]), x["order"])):
        f = d / f"{x['id']}.json"
        words = json.loads(f.read_text(encoding="utf-8")) if f.exists() else []
        words = [{**w, "forms": w.get("forms", [])} for w in sorted(words, key=lambda w: w["rank"])]
        out.append({**x, "words": words})
    return {"decks": out}
