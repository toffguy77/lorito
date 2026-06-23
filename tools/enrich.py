#!/usr/bin/env python3
"""Content enrichment step.

Expands a card's body using a consistent template (fuller explanations, more
examples, common-mistake notes) while preserving the card's identity
(`id`, `level`, `order`). Enrichment is incremental and reviewable: the LLM
integration point is `enrich_body`; by default it is a passthrough so the
pipeline stays deterministic and offline. Wire an LLM into `enrich_body` to
generate richer drafts, then review the diff before committing.

Usage:
    python3 tools/enrich.py <CARD_ID>     # print the enriched body to stdout (review)
    python3 tools/enrich.py --template    # print the enrichment template/prompt
"""
from __future__ import annotations

import sys

import lib

TEMPLATE = """\
You are enriching a Spanish-learning card for Russian speakers. Keep the
existing structure and the callout sections (Суть / Ключевые моменты / Ошибки /
Полезно). Expand explanations, add more examples with translations, and clarify
common mistakes. Do not change the card's meaning, level, or scope. Output
Markdown only.
"""


def enrich_body(card: lib.Card) -> str:
    """Return an enriched Markdown body. Passthrough by default (identity-preserving)."""
    # Integration point: call an LLM with TEMPLATE + card.body here.
    return card.body


def enrich_card(card: lib.Card) -> lib.Card:
    """Enrich a card, preserving id/level/order."""
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
    )


def main() -> int:
    if len(sys.argv) == 2 and sys.argv[1] == "--template":
        print(TEMPLATE)
        return 0
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    card_id = sys.argv[1]
    for p in lib.iter_card_files():
        c = lib.parse_card_file(p)
        if c.id == card_id:
            print(enrich_card(c).body)
            return 0
    print(f"card not found: {card_id}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
