"""Shared helpers for the Lorito content pipeline.

Parses the source Obsidian vault notes and the per-level MOC files, and the
repo's own content/<LEVEL>/<id>.md card files. Pure standard library.
"""
from __future__ import annotations

import os
import re
from dataclasses import dataclass, field
from pathlib import Path

LEVELS = ["A1", "A2", "B1", "B2", "C1", "C2"]
ID_RE = re.compile(r"\b([A-C][12]-\d{2})\b")
ID_AT_START_RE = re.compile(r"^([A-C][12]-\d{2})\b")
CATEGORY_TAGS = ["gramática", "vocabulario", "ortografía", "fonética"]

# Sections in a MOC that are NOT themes (navigation only).
NON_THEME_HEADINGS = ("Дети", "Бэклинки", "Исходящие")


@dataclass
class Card:
    id: str
    level: str
    theme: str
    order: int
    title: str
    aliases: list[str] = field(default_factory=list)
    related: list[str] = field(default_factory=list)
    tags: list[str] = field(default_factory=list)
    body: str = ""


def split_frontmatter(text: str) -> tuple[str, str]:
    """Return (frontmatter_text, body_text). Frontmatter is between leading '---' fences."""
    if text.startswith("---"):
        end = text.find("\n---", 3)
        if end != -1:
            fm = text[3:end].strip("\n")
            body = text[end + 4:].lstrip("\n")
            return fm, body
    return "", text


def _fm_line(fm: str, key: str) -> str | None:
    for line in fm.splitlines():
        if line.startswith(key + ":"):
            return line[len(key) + 1:].strip()
    return None


def parse_aliases(fm: str) -> list[str]:
    line = _fm_line(fm, "aliases") or ""
    return re.findall(r'"([^"]+)"', line)


def parse_related(fm: str) -> list[str]:
    line = _fm_line(fm, "related") or ""
    return ID_RE.findall(line)


def parse_category_tags(fm: str) -> list[str]:
    line = _fm_line(fm, "tags") or ""
    out = []
    for cat in CATEGORY_TAGS:
        if f"español/{cat}" in line:
            out.append(cat)
    return out


DATAVIEW_RE = re.compile(r"```dataview.*?```", re.DOTALL)
CALLOUT_RE = re.compile(r"^>\s*\[!\w+\]\s*(.*)$", re.MULTILINE)
WIKILINK_PIPE_RE = re.compile(r"\[\[[^\]|]+\|([^\]]+)\]\]")
WIKILINK_RE = re.compile(r"\[\[([^\]]+)\]\]")
NAV_CUT_RE = re.compile(r"^#{1,3}\s.*(Навигаци|Бэклинки|Исходящие)", re.MULTILINE)


def clean_body(body: str) -> str:
    """Strip Obsidian-specific syntax, keeping the instructional content."""
    # Cut navigation / backlink / outlink sections off the tail.
    m = NAV_CUT_RE.search(body)
    if m:
        body = body[:m.start()]
    # Remove dataview fenced blocks.
    body = DATAVIEW_RE.sub("", body)
    # Drop the leading H1 (title lives in metadata).
    lines = body.splitlines()
    while lines and not lines[0].strip():
        lines.pop(0)
    if lines and lines[0].startswith("# "):
        lines.pop(0)
    body = "\n".join(lines)
    # Obsidian callouts "> [!info] Суть" -> "> **Суть**".
    body = CALLOUT_RE.sub(lambda mo: f"> **{mo.group(1).strip()}**" if mo.group(1).strip() else ">", body)
    # Wikilinks -> display text / target text.
    body = WIKILINK_PIPE_RE.sub(lambda mo: mo.group(1), body)
    body = WIKILINK_RE.sub(lambda mo: mo.group(1).split("—")[-1].strip(), body)
    return body.strip() + "\n"


def title_from_filename(name: str) -> tuple[str, str]:
    """'A1-01 — Алфавит ....md' -> ('A1-01', 'Алфавит ...')."""
    stem = name[:-3] if name.endswith(".md") else name
    m = ID_AT_START_RE.match(stem)
    cid = m.group(1) if m else stem
    title = stem.split("—", 1)[1].strip() if "—" in stem else stem
    return cid, title


def order_from_id(card_id: str) -> int:
    return int(card_id.split("-")[1])


def parse_moc(path: Path) -> list[tuple[str, list[str]]]:
    """Return ordered [(theme_title, [card_ids])] for the numbered sections of a MOC."""
    text = path.read_text(encoding="utf-8")
    sections: list[tuple[str, list[str]]] = []
    current_title: str | None = None
    current_ids: list[str] = []
    for line in text.splitlines():
        if line.startswith("### "):
            # flush previous
            if current_title is not None:
                sections.append((current_title, current_ids))
            heading = line[4:].strip()
            # strip leading emoji/number keycap and spaces
            heading = re.sub(r"^[\W\d_]+", "", heading).strip()
            if any(heading.startswith(h) for h in NON_THEME_HEADINGS):
                current_title = None
                current_ids = []
            else:
                current_title = heading
                current_ids = []
        elif current_title is not None:
            ids = ID_RE.findall(line)
            current_ids.extend(ids)
    if current_title is not None:
        sections.append((current_title, current_ids))
    return [(t, ids) for t, ids in sections if ids]


# ---- repo content/ card files ----

def render_card_file(card: Card) -> str:
    """Serialize a Card back to frontmatter + body for content/<LEVEL>/<id>.md."""
    def yaml_list(xs: list[str]) -> str:
        return "[" + ", ".join(f'"{x}"' for x in xs) + "]"

    fm = [
        "---",
        f"id: {card.id}",
        f"level: {card.level}",
        f"theme: {card.theme}",
        f"order: {card.order}",
        f'title: "{card.title}"',
        f"aliases: {yaml_list(card.aliases)}",
        f"related: {yaml_list(card.related)}",
        f"tags: {yaml_list(card.tags)}",
        "---",
        "",
    ]
    return "\n".join(fm) + card.body


def parse_card_file(path: Path) -> Card:
    text = path.read_text(encoding="utf-8")
    fm, body = split_frontmatter(text)

    def scalar(key: str, default: str = "") -> str:
        v = _fm_line(fm, key)
        if v is None:
            return default
        return v.strip().strip('"')

    return Card(
        id=scalar("id"),
        level=scalar("level"),
        theme=scalar("theme"),
        order=int(scalar("order", "0") or 0),
        title=scalar("title"),
        aliases=re.findall(r'"([^"]+)"', _fm_line(fm, "aliases") or ""),
        related=ID_RE.findall(_fm_line(fm, "related") or ""),
        tags=re.findall(r'"([^"]+)"', _fm_line(fm, "tags") or ""),
        body=body,
    )


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def content_dir() -> Path:
    env = os.environ.get("LORITO_CONTENT_DIR")
    return Path(env) if env else repo_root() / "content"


def iter_card_files() -> list[Path]:
    base = content_dir()
    return sorted(base.glob("*/*.md"), key=lambda p: (p.parent.name, p.name))
