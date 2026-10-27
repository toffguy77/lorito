#!/usr/bin/env python3
"""Content enrichment step.

Expands a card's body using a consistent template (fuller explanations, more
examples, common-mistake notes) while preserving the card's identity
(`id`, `level`, `order`). Enrichment is incremental and reviewable: the LLM
integration points are `enrich_body` and `draft_recall`; by default they are
passthroughs so the pipeline stays deterministic and offline. Wire an LLM into
them to generate richer drafts, then review the diff before committing.

Usage:
    python3 tools/enrich.py <CARD_ID>                 # print the enriched body to stdout (review)
    python3 tools/enrich.py --template                # print the enrichment template/prompt
    python3 tools/enrich.py --recall <CARD_ID|LEVEL>  # print recall-prompt drafting context + draft
    python3 tools/enrich.py --set-recall <CARD_ID> "<text>"   # write a reviewed recall prompt
"""
from __future__ import annotations

import re
import sys

import lib
import validate

TEMPLATE = """\
You are enriching a Spanish-learning card for Russian speakers. Keep the
existing structure and the callout sections (Суть / Ключевые моменты / Ошибки /
Полезно). Expand explanations, add more examples with translations, and clarify
common mistakes. Do not change the card's meaning, level, or scope. Output
Markdown only.
"""

RECALL_TEMPLATE = """\
Write a recall prompt for the FRONT of a Spanish-learning card for Russian
speakers. The learner sees only the card title and this prompt, answers in
their head, then reveals the card. One line, at most 200 characters, Markdown.
Ask about the card's core idea (from Суть / Ключевые моменты) — a question,
not a statement of the answer. Russian for the question; Spanish words in
*italics*; bold the key question (e.g. **¿el или la?** *problema, mano, agua*).
Output the prompt only.
"""

SECTION_RE = re.compile(r"^(?:>\s*\*\*(?P<q>[^*]+)\*\*|#{1,6}\s+(?P<h>.+))\s*$")


def recall_context(card: lib.Card) -> str:
    """The parts of a card a recall prompt is drafted from: Суть + Ключевые моменты."""
    keep, out = False, []
    for line in card.body.splitlines():
        m = SECTION_RE.match(line.strip())
        if m:
            title = (m.group("q") or m.group("h") or "").lower()
            keep = "суть" in title or "ключев" in title
            continue
        if keep:
            out.append(line.lstrip("> ").rstrip())
    return "\n".join(l for l in out if l.strip())


def draft_recall(card: lib.Card) -> str | None:
    """Return a drafted recall prompt. Passthrough by default: the card's current
    `recall` (or None). Integration point: call an LLM with RECALL_TEMPLATE +
    the card title + `recall_context(card)` here."""
    return card.recall


def enrich_body(card: lib.Card) -> str:
    """Return an enriched Markdown body. Passthrough by default (identity-preserving)."""
    # Integration point: call an LLM with TEMPLATE + card.body here.
    return card.body


def enrich_card(card: lib.Card) -> lib.Card:
    """Enrich a card, preserving id/level/order (and its recall prompt)."""
    return lib.Card(
        id=card.id,
        level=card.level,
        theme=card.theme,
        order=card.order,
        title=card.title,
        aliases=card.aliases,
        related=card.related,
        tags=card.tags,
        body=enrich_body(card),
        recall=card.recall,
    )


def find_cards(selector: str) -> list[tuple]:
    """Cards matching a card id or a whole level, in level/order."""
    cards = [(p, lib.parse_card_file(p)) for p in lib.iter_card_files()]
    if selector in lib.LEVELS:
        return sorted([pc for pc in cards if pc[1].level == selector], key=lambda pc: pc[1].order)
    return [pc for pc in cards if pc[1].id == selector]


def set_recall(card_id: str, text: str) -> int:
    """Write a recall prompt into a card's front matter, validated first."""
    matches = find_cards(card_id)
    if not matches:
        print(f"card not found: {card_id}", file=sys.stderr)
        return 1
    path, card = matches[0]
    card.recall = text.strip()
    card.recall_raw = lib.quote_scalar(card.recall)
    errors = validate.validate_recall(card)
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    path.write_text(lib.render_card_file(card), encoding="utf-8")
    print(f"{card.id}: recall set")
    return 0


def main() -> int:
    args = sys.argv[1:]
    if args == ["--template"]:
        print(TEMPLATE)
        return 0
    if len(args) == 2 and args[0] == "--recall":
        matches = find_cards(args[1])
        if not matches:
            print(f"card not found: {args[1]}", file=sys.stderr)
            return 1
        print(RECALL_TEMPLATE)
        for _, c in matches:
            print(f"## {c.id} — {c.title}")
            print(recall_context(c) or "(no Суть / Ключевые моменты)")
            print(f"draft: {draft_recall(c) or '(none — fallback prompt in app)'}\n")
        return 0
    if len(args) == 3 and args[0] == "--set-recall":
        return set_recall(args[1], args[2])
    if len(args) != 1 or args[0].startswith("--"):
        print(__doc__)
        return 2
    matches = find_cards(args[0])
    if not matches:
        print(f"card not found: {args[0]}", file=sys.stderr)
        return 1
    print(enrich_card(matches[0][1]).body)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
