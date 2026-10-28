#!/usr/bin/env python3
"""Grammar Lens rules: reference tokenizer, matcher, validation, bundling (stdlib only).

Layout (content/lens/):
  rules/<id>.json   {id, title_ru, cards: [...], pattern: [step…], requires: [ctx…],
                     examples: {positive: [...], negative: [...]}}
  lemmas.tsv        form<TAB>lemma lines (# comments); the compiled table adds
                    every single-word form of the conjugation data
  sets.json         named surface sets: a list of forms; {"tense": <id>} (all
                    single-word forms of that conjugation tense); {"generate":
                    "infinitives" | "participles"} (from the conjugation data);
                    "extra" adds forms to a generated set

A pattern step tests one token with surface/lemma predicates only:
  {"surface": [...]} · {"lemma": [...]} · {"set": "<name>"} — combined = all hold;
  optional "gap": N lets up to N tokens precede the step (same sentence).
A context predicate: {"before"|"not_before"|"after"|"not_after": <step>, "within": N}.
Lexical-class predicates (part of speech…) are rejected: they can't be evaluated
here, and the app must give the same result as this reference.

Matching: every step and context predicate must hold; overlapping matches keep
the longest span, then the more specific rule (more predicates), then the lower
rule id. The app's Swift matcher mirrors this module (cross-checked on examples).
"""
from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path

import conjugate
import lib

STEP_KEYS = {"surface", "lemma", "set"}
CONTEXT_KEYS = {"before", "not_before", "after", "not_after"}
MIN_POSITIVE, MIN_NEGATIVE = 3, 2

_TOKEN = re.compile(r"[^\W\d_]+|[.!?…]+")


@dataclass(frozen=True)
class Token:
    surface: str
    lower: str
    sentence: int
    lemma: str | None = None


@dataclass(frozen=True)
class Match:
    rule: str
    start: int  # token indices, inclusive
    end: int


def tokenize(text: str) -> list[Token]:
    """Words are letter runs; `.` `!` `?` `…` end a sentence (¿ ¡ are ignored)."""
    out: list[Token] = []
    sentence, has_words = 0, False
    for m in _TOKEN.finditer(text):
        s = m.group(0)
        if s[0] in ".!?…":
            if has_words:
                sentence, has_words = sentence + 1, False
            continue
        out.append(Token(s, s.lower(), sentence))
        has_words = True
    return out


def tokens(text: str, table: dict[str, str]) -> list[Token]:
    return [Token(t.surface, t.lower, t.sentence, table.get(t.lower)) for t in tokenize(text)]


# --- matching -------------------------------------------------------------------

def _holds(step: dict, tok: Token, sets: dict[str, list[str]]) -> bool:
    if "surface" in step and tok.lower not in {s.lower() for s in step["surface"]}:
        return False
    if "lemma" in step and tok.lemma not in step["lemma"]:
        return False
    if "set" in step and tok.lower not in set(sets.get(step["set"], [])):
        return False
    return True


def specificity(rule: dict) -> int:
    steps = sum(len(STEP_KEYS & set(s)) for s in rule["pattern"])
    return steps + len(rule.get("requires") or [])


def _match_from(rule: dict, toks: list[Token], start: int, sets) -> int | None:
    """End index of the leftmost match of the pattern starting at `start`, or None."""
    pattern = rule["pattern"]

    def step(k: int, prev: int) -> int | None:
        if k == len(pattern):
            return prev
        gap = int(pattern[k].get("gap", 0))
        for j in range(prev + 1, min(prev + 2 + gap, len(toks))):
            if toks[j].sentence != toks[start].sentence:
                break
            if _holds(pattern[k], toks[j], sets):
                end = step(k + 1, j)
                if end is not None:
                    return end
        return None

    if not pattern or not _holds(pattern[0], toks[start], sets):
        return None
    return step(1, start)


def _context_ok(rule: dict, toks: list[Token], start: int, end: int, sets) -> bool:
    sentence = toks[start].sentence
    for req in rule.get("requires") or []:
        within = int(req.get("within", 1))
        for key in CONTEXT_KEYS & set(req):
            if key.endswith("before"):
                window = range(max(0, start - within), start)
            else:
                window = range(end + 1, min(len(toks), end + 1 + within))
            found = any(toks[k].sentence == sentence and _holds(req[key], toks[k], sets) for k in window)
            if found == key.startswith("not_"):
                return False
    return True


def match(toks: list[Token], rules: list[dict], sets: dict[str, list[str]]) -> list[Match]:
    candidates = []
    for rule in rules:
        for i in range(len(toks)):
            end = _match_from(rule, toks, i, sets)
            if end is not None and _context_ok(rule, toks, i, end, sets):
                candidates.append((-(end - i), -specificity(rule), rule["id"], i, end))
    taken: list[Match] = []
    for _, _, rid, i, end in sorted(candidates):
        if all(end < m.start or i > m.end for m in taken):
            taken.append(Match(rid, i, end))
    return sorted(taken, key=lambda m: m.start)


# --- content --------------------------------------------------------------------

def lens_dir() -> Path:
    return lib.content_dir() / "lens"


def load_rules() -> list[dict]:
    d = lens_dir() / "rules"
    return [json.loads(p.read_text(encoding="utf-8")) for p in sorted(d.glob("*.json"))] if d.exists() else []


def _conjugation():
    try:
        return conjugate.bundle()
    except Exception:  # noqa: BLE001 — conjugation errors are reported by its own validator
        return None


def lemma_table() -> dict[str, str]:
    """lemmas.tsv first (authored entries win), then conjugation forms by verb rank."""
    table: dict[str, str] = {}
    p = lens_dir() / "lemmas.tsv"
    if p.exists():
        for line in p.read_text(encoding="utf-8").splitlines():
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            form, _, lemma = line.partition("\t")
            table.setdefault(form.strip().lower(), lemma.strip())
    conj = _conjugation()
    for v in (conj or {}).get("verbs", []):
        lemma = conjugate.base_infinitive(v["infinitive"])
        forms = [f for six in v["paradigms"].values() for f in six] + list(v.get("vos", {}).values()) + [lemma]
        for f in forms:
            if " " not in f:
                table.setdefault(f.lower(), lemma)
    return table


def _tense_forms(verbs: list[dict], tense: str) -> set[str]:
    return {f.lower() for v in verbs
            for f in v["paradigms"].get(tense, []) + ([v["vos"][tense]] if tense in v.get("vos", {}) else [])
            if " " not in f}


def expand_set(spec, verbs: list[dict]) -> list[str]:
    """One sets.json entry → a sorted plain form list (what the app receives)."""
    if not isinstance(spec, dict):
        return sorted({f.lower() for f in spec})
    forms: set[str] = set()
    if spec.get("generate") == "infinitives":
        forms = {conjugate.base_infinitive(v["infinitive"]) for v in verbs}
    elif spec.get("generate") == "participles":
        # participle = the word after the auxiliary in the pretérito perfecto
        forms = {f.split()[-1] for v in verbs for f in v["paradigms"].get("preterito-perfecto", [])}
        if spec.get("inflect"):
            forms |= {p[:-1] + end for p in forms if p.endswith("o") for end in ("a", "os", "as")}
    tenses = ([spec["tense"]] if "tense" in spec else []) + list(spec.get("tenses", []))
    for tense in tenses:
        forms |= _tense_forms(verbs, tense)
    for tense in spec.get("exclude_tenses", []):
        forms -= _tense_forms(verbs, tense)
    forms = {f.lower() for f in forms | set(spec.get("extra", []))}
    forms -= {f.lower() for f in spec.get("exclude", [])}
    return sorted(forms)


def load_sets() -> dict[str, list[str]]:
    p = lens_dir() / "sets.json"
    raw = json.loads(p.read_text(encoding="utf-8")) if p.exists() else {}
    verbs = (_conjugation() or {}).get("verbs", [])
    return {name: expand_set(spec, verbs) for name, spec in raw.items()}


def validate_coverage(card_ids: set[str], rules: list[dict]) -> list[str]:
    """coverage.json: every card is linked by a rule or listed in `no_rule` with a reason."""
    p = lens_dir() / "coverage.json"
    if not p.exists():
        return []
    try:
        no_rule = json.loads(p.read_text(encoding="utf-8")).get("no_rule", {})
    except Exception as e:  # noqa: BLE001
        return [f"lens coverage: failed to parse coverage.json ({e})"]
    ruled = {c for r in rules for c in r.get("cards") or []}
    errors = [f"lens coverage: unknown card '{c}'" for c in sorted(set(no_rule) - card_ids)]
    errors += [f"lens coverage: '{c}' has a rule and a no_rule entry" for c in sorted(set(no_rule) & ruled)]
    errors += [f"lens coverage: '{c}' needs a reason" for c, why in sorted(no_rule.items()) if not str(why).strip()]
    errors += [f"lens coverage: '{c}' has no rule and no no_rule entry" for c in sorted(card_ids - ruled - set(no_rule))]
    return errors


def _check_step(rid: str, step, lemmas: set[str], sets: dict, where: str) -> list[str]:
    if not isinstance(step, dict):
        return [f"lens: {rid}: {where} must be an object"]
    errors = [f"lens: {rid}: {where} uses unsupported predicate '{k}' (surface/lemma/set only)"
              for k in sorted(set(step) - STEP_KEYS - {"gap"})]
    if not (STEP_KEYS & set(step)):
        errors.append(f"lens: {rid}: {where} needs a surface, lemma or set predicate")
    for lemma in step.get("lemma", []):
        if lemma not in lemmas:
            errors.append(f"lens: {rid}: lemma '{lemma}' missing from the lemma table")
    if "set" in step and step["set"] not in sets:
        errors.append(f"lens: {rid}: unknown set '{step['set']}'")
    return errors


def validate_lens(card_ids: set[str]) -> list[str]:
    if not lens_dir().exists():
        return []
    errors: list[str] = []
    try:
        rules, table, sets = load_rules(), lemma_table(), load_sets()
    except Exception as e:  # noqa: BLE001
        return [f"lens: failed to load ({e})"]
    lemmas = set(table.values())
    errors += validate_coverage(card_ids, rules)
    seen: set[str] = set()
    for r in rules:
        rid = r.get("id", "?")
        if rid in seen:
            errors.append(f"lens: duplicate rule id '{rid}'")
        seen.add(rid)
        if not r.get("title_ru"):
            errors.append(f"lens: {rid}: missing title_ru")
        cards = r.get("cards") or []
        if not cards:
            errors.append(f"lens: {rid}: needs at least one card")
        errors += [f"lens: {rid}: unknown card '{c}'" for c in cards if c not in card_ids]
        pattern = r.get("pattern") or []
        if not pattern:
            errors.append(f"lens: {rid}: empty pattern")
        rule_errors = [e for i, s in enumerate(pattern) for e in _check_step(rid, s, lemmas, sets, f"pattern step {i + 1}")]
        for i, req in enumerate(r.get("requires") or []):
            keys = CONTEXT_KEYS & set(req) if isinstance(req, dict) else set()
            if len(keys) != 1:
                rule_errors.append(f"lens: {rid}: requires {i + 1} needs exactly one of {sorted(CONTEXT_KEYS)}")
                continue
            rule_errors += [f"lens: {rid}: requires {i + 1} uses unsupported key '{k}'"
                            for k in sorted(set(req) - CONTEXT_KEYS - {"within"})]
            rule_errors += _check_step(rid, req[keys.pop()], lemmas, sets, f"requires {i + 1}")
        errors += rule_errors
        ex = r.get("examples") or {}
        pos, neg = ex.get("positive") or [], ex.get("negative") or []
        if len(pos) < MIN_POSITIVE or len(neg) < MIN_NEGATIVE:
            errors.append(f"lens: {rid}: examples need ≥ {MIN_POSITIVE} positive and ≥ {MIN_NEGATIVE} negative")
        if rule_errors:
            continue
        for text in pos:
            if not match(tokens(text, table), [r], sets):
                errors.append(f"lens: {rid}: positive example does not match: «{text}»")
        for text in neg:
            if match(tokens(text, table), [r], sets):
                errors.append(f"lens: {rid}: negative example matches: «{text}»")
    return errors


def bundle() -> dict | None:
    """lens.json: rules (by id), the lemma table and the expanded sets; None without content."""
    if not lens_dir().exists():
        return None
    rules, table, sets = sorted(load_rules(), key=lambda r: r["id"]), lemma_table(), load_sets()
    # Every example analysed with all rules: the app's matcher must reproduce these exactly.
    texts = sorted({t for r in rules for k in ("positive", "negative") for t in r["examples"][k]})
    crosscheck = [{"text": t, "tokens": [tok.lower for tok in tokenize(t)],
                   "sentences": [tok.sentence for tok in tokenize(t)],
                   "matches": [[m.rule, m.start, m.end] for m in match(tokens(t, table), rules, sets)]}
                  for t in texts]
    return {"rules": rules, "lemmas": dict(sorted(table.items())), "sets": sets, "crosscheck": crosscheck}
