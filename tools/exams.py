#!/usr/bin/env python3
"""Exam path content (DELE A2, CCSE) — stdlib only.

Layout:
  content/exams/definitions.json         exam definitions (sections, timings,
                                         groups, thresholds, verifiedOn)
  content/exams/<exam>/items/<id>.md     one item per file: front matter + text
                                         + optional "> **Объяснение**" block
  content/exams/ccse/source/<edition>.md transcription of the Cervantes manual,
                                         imported with `import` (below)

Item front matter: id, exam, section, type (choice | listening | writing |
speaking), form (mock number), points, options + answer (choice/listening),
script (listening), rubric [{text, points}] and prep (seconds, speaking),
cards [...], preview (true), source + edition (required for CCSE), retired.

Usage:
  python3 tools/exams.py import content/exams/ccse/source/2026.md --edition 2026
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

import lib

TYPES = {"choice", "listening", "writing", "speaking"}


def exams_dir() -> Path:
    return lib.content_dir() / "exams"


def load_definitions() -> list[dict]:
    p = exams_dir() / "definitions.json"
    return json.loads(p.read_text(encoding="utf-8")) if p.exists() else []


def iter_item_files() -> list[Path]:
    return sorted(exams_dir().glob("*/items/*.md")) if exams_dir().exists() else []


def _bool(v) -> bool:
    return v is True or str(v).strip().lower() == "true"


def parse_item(path: Path) -> dict:
    fm, body = lib.split_frontmatter(path.read_text(encoding="utf-8"))
    d = lib.parse_exercise_fm(fm)
    text, explanation = lib.split_prompt_explanation(body)
    d["text"], d["explanation"] = text.strip(), explanation.strip()
    return d


def bundle_item(d: dict) -> dict:
    t = d.get("type")
    if t == "choice":
        kind = {"choice": {"options": d["options"], "answer": d["answer"]}}
    elif t == "listening":
        kind = {"listeningTask": {"script": d["script"], "options": d["options"], "answer": d["answer"]}}
    elif t == "writing":
        kind = {"writingTask": {"prompt": d.get("text", ""), "rubric": d["rubric"]}}
    else:
        kind = {"speakingTask": {"prompt": d.get("text", ""), "prepSeconds": int(d.get("prep", 0)), "rubric": d["rubric"]}}
    out = {
        "id": d["id"], "exam": d["exam"], "section": d["section"], "points": float(d.get("points", 1)),
        "kind": kind, "text": d.get("text", ""), "explanation": d.get("explanation", ""),
        "form": int(d.get("form", 1)), "preview": _bool(d.get("preview")), "cards": d.get("cards") or [],
        "retired": _bool(d.get("retired")),
    }
    for k in ("source", "edition"):
        if d.get(k):
            out[k] = d[k]
    return out


def validate_exams(card_ids: set[str]) -> list[str]:
    if not exams_dir().exists():
        return []
    errors: list[str] = []
    try:
        defs = {x["id"]: x for x in load_definitions()}
    except Exception as e:  # noqa: BLE001
        return [f"exams/definitions.json: failed to parse ({e})"]
    for x in defs.values():
        for key in ("title", "verifiedOn", "sections", "groups"):
            if key not in x:
                errors.append(f"exams: definition '{x.get('id')}' missing '{key}'")
        sections = {s["id"] for s in x.get("sections", [])}
        for g in x.get("groups", []):
            for sid in g.get("sections", []):
                if sid not in sections:
                    errors.append(f"exams: {x['id']} group '{g.get('id')}' names unknown section '{sid}'")
    seen: set[str] = set()
    has_preview: dict[str, bool] = {}
    for p in iter_item_files():
        try:
            d = parse_item(p)
        except Exception as e:  # noqa: BLE001
            errors.append(f"{p}: failed to parse ({e})")
            continue
        iid = d.get("id") or p.stem
        if iid in seen:
            errors.append(f"exams: duplicate item id '{iid}'")
        seen.add(iid)
        exam = d.get("exam")
        if exam not in defs:
            errors.append(f"{iid}: unknown exam '{exam}'")
            continue
        sections = {s["id"]: s for s in defs[exam]["sections"]}
        if d.get("section") not in sections:
            errors.append(f"{iid}: unknown section '{d.get('section')}'")
        t = d.get("type")
        if t not in TYPES:
            errors.append(f"{iid}: unknown type '{t}'")
            continue
        if t in ("choice", "listening"):
            opts = d.get("options")
            if not isinstance(opts, list) or len(opts) < 2:
                errors.append(f"{iid}: 'options' needs at least 2 entries")
            elif d.get("answer") not in opts:
                errors.append(f"{iid}: answer '{d.get('answer')}' is not among options")
        if t == "listening" and not d.get("script"):
            errors.append(f"{iid}: listening item needs 'script'")
        if t in ("writing", "speaking"):
            rubric = d.get("rubric")
            if not isinstance(rubric, list) or not rubric or any(
                    not isinstance(r, dict) or "text" not in r or "points" not in r for r in rubric):
                errors.append(f"{iid}: productive task needs a non-empty rubric of {{text, points}}")
        if exam == "ccse":
            for key in ("source", "edition"):
                if not d.get(key):
                    errors.append(f"{iid}: CCSE item missing '{key}'")
        for c in d.get("cards") or []:
            if c not in card_ids:
                errors.append(f"{iid}: unresolved card '{c}'")
        has_preview[exam] = has_preview.get(exam, False) or (_bool(d.get("preview")) and not _bool(d.get("retired")))
    for exam, ok in has_preview.items():
        if not ok:
            errors.append(f"exams: '{exam}' has no preview item (content-based free preview)")
    return errors


def bundle() -> dict | None:
    if not exams_dir().exists():
        return None
    return {"definitions": load_definitions(),
            "items": [bundle_item(parse_item(p)) for p in iter_item_files()]}


# --- CCSE import --------------------------------------------------------------

_Q = re.compile(r"^(\d+)\.\s+(.*)$")
_OPT = re.compile(r"^([a-c])\)\s+(.*)$")
_ANS = re.compile(r"^Respuesta:\s*([a-c])\s*$", re.IGNORECASE)
_TASK = re.compile(r"^##\s*Tarea\s+(\d+)", re.IGNORECASE)
# Questions per tarea in one CCSE exam (25 in all).
CCSE_PER_FORM = {1: 10, 2: 3, 3: 2, 4: 3, 5: 7}


def import_ccse(source: Path, edition: str) -> list[str]:
    """Write one item per question of a manual transcription; flag items that
    disappeared from the new edition as retired (kept for history)."""
    out_dir = exams_dir() / "ccse" / "items"
    out_dir.mkdir(parents=True, exist_ok=True)
    questions: list[dict] = []
    task, cur = 1, None
    for line in source.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if m := _TASK.match(line):
            task = int(m.group(1))
        elif m := _Q.match(line):
            cur = {"n": int(m.group(1)), "text": m.group(2), "options": [], "task": task}
            questions.append(cur)
        elif cur is not None and (m := _OPT.match(line)):
            cur["options"].append(m.group(2))
        elif cur is not None and (m := _ANS.match(line)):
            cur["answer"] = cur["options"]["abc".index(m.group(1).lower())]
    written = []
    seen_in_task: dict[int, int] = {}
    for q in questions:
        iid = f"ccse-{q['n']}"
        # Mock forms of 25 with the official distribution per tarea, in number order.
        idx = seen_in_task.get(q["task"], 0)
        seen_in_task[q["task"]] = idx + 1
        form = idx // CCSE_PER_FORM.get(q["task"], 25) + 1
        path = out_dir / f"{iid}.md"
        old = parse_item(path) if path.exists() else {}
        fm = [("id", iid), ("exam", "ccse"), ("section", "ccse"), ("type", "choice"), ("form", form),
              ("task", q["task"]), ("options", q["options"]), ("answer", q.get("answer", "")),
              ("source", "cervantes-ccse"), ("edition", edition)]
        if _bool(old.get("preview")):
            fm.append(("preview", True))
        explanation = [f"> {x}" for x in (old.get("explanation") or "").splitlines()] or ["> "]
        lines = ["---"] + [f"{k}: {json.dumps(v, ensure_ascii=False) if isinstance(v, (list, int, bool)) else lib.quote_scalar(str(v))}"
                           for k, v in fm] + ["---", q["text"], "", "> **Объяснение**", *explanation]
        path.write_text("\n".join(lines) + "\n", encoding="utf-8")
        written.append(iid)
    for p in out_dir.glob("*.md"):
        if p.stem not in written:
            text = p.read_text(encoding="utf-8")
            if "\nretired:" not in text:
                p.write_text(text.replace("\n---\n", "\nretired: true\n---\n", 1), encoding="utf-8")
    return written


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Exam content tools")
    sub = ap.add_subparsers(dest="cmd", required=True)
    imp = sub.add_parser("import", help="import a CCSE manual transcription")
    imp.add_argument("source", type=Path)
    imp.add_argument("--edition", required=True)
    args = ap.parse_args(argv)
    written = import_ccse(args.source, args.edition)
    print(f"imported {len(written)} CCSE questions (edition {args.edition})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
