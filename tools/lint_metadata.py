#!/usr/bin/env python3
"""Lint App Store metadata (fastlane/metadata/<locale>/*.txt) against Apple's
field limits and our keyword rules. Lengths are counted in characters
(the keyword limit too — see app-store-presence spec). Exits 1 on any
violation, naming the file and the offending value.

Usage: python3 tools/lint_metadata.py [--metadata DIR] [--forbid-terms A,B,...]
"""
import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_METADATA = ROOT / "fastlane" / "metadata"

# field file -> (min, max) characters
LIMITS = {
    "name.txt": (2, 30),
    "subtitle.txt": (0, 30),
    "promotional_text.txt": (0, 170),
    "description.txt": (0, 4000),
    "keywords.txt": (0, 100),
    "release_notes.txt": (0, 4000),
}
LOCALE = re.compile(r"^[a-z]{2,3}(-[A-Za-z]{2,4})?$")


def read(path: Path):
    return path.read_text(encoding="utf-8").strip() if path.exists() else None


def words(text: str):
    """Lower-cased words of a name/subtitle; hyphenated words stay whole."""
    return {w for w in re.split(r"[^\w\-–]+", text.lower()) if w}


def lint_locale(d: Path, forbidden):
    errors = []
    rel = lambda f: f"{d.name}/{f}"
    fields = {f: read(d / f) for f in LIMITS}
    for f, (lo, hi) in LIMITS.items():
        text = fields[f]
        if text is None:
            continue
        n = len(text)
        if n > hi or n < lo:
            errors.append(f"{rel(f)}: {n} characters (allowed {lo}–{hi})")

    keywords = fields["keywords.txt"]
    if keywords:
        taken = words(fields["name.txt"] or "") | words(fields["subtitle.txt"] or "")
        seen = set()
        for raw in keywords.split(","):
            kw = raw.strip()
            key = kw.lower()
            if len(kw) <= 2:
                errors.append(f"{rel('keywords.txt')}: keyword «{kw}» is too short (needs more than 2 characters)")
            if key in seen:
                errors.append(f"{rel('keywords.txt')}: duplicate keyword «{key}»")
            seen.add(key)
            for w in words(kw):
                if w in taken:
                    errors.append(f"{rel('keywords.txt')}: keyword word «{w}» repeats the name or subtitle")

    for term in forbidden:
        for f, text in fields.items():
            if text and term.lower() in text.lower():
                errors.append(f"{rel(f)}: contains «{term}», not allowed in this release")
    return errors


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--metadata", type=Path, default=DEFAULT_METADATA)
    p.add_argument("--forbid-terms", default="", help="comma-separated terms that must not appear")
    args = p.parse_args(argv)
    forbidden = [t.strip() for t in args.forbid_terms.split(",") if t.strip()]

    locales = sorted(d for d in args.metadata.iterdir() if d.is_dir() and LOCALE.match(d.name))
    if not locales:
        print(f"no localizations under {args.metadata}")
        return 1
    errors = [e for d in locales for e in lint_locale(d, forbidden)]
    for e in errors:
        print(e)
    print(f"{'FAIL' if errors else 'OK'}: {len(locales)} localization(s), {len(errors)} problem(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
