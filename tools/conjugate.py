#!/usr/bin/env python3
"""Conjugation paradigms for the conjugation trainer (stdlib only).

Content lives in content/conjugation/:
  tenses.json          registry: [{id, es, ru, mood, level, card, order}]
  verbs/<inf>.json     {infinitive, rank, ru, model: ar|er|ir|irregular,
                        reflexive?, forms?: {<tense-id>: [6 forms]}}

Regular ar/er/ir paradigms are generated here for every registered tense; a
verb's `forms` replace the generated forms of that tense (stem changes,
orthographic changes, irregular verbs). Person order: yo, tú, él/ella/usted,
nosotros, vosotros, ellos/ustedes. Forms are stored without reflexive
pronouns; for `reflexive: true` the pronoun is prefixed here.
"""
from __future__ import annotations

import json
from pathlib import Path

import lib

PERSONS = ["yo", "tú", "él", "nosotros", "vosotros", "ellos"]
REFLEXIVE_PRONOUNS = ["me", "te", "se", "nos", "os", "se"]
MODELS = {"ar", "er", "ir", "irregular"}

# Simple tenses: endings appended to the stem (infinitive without -ar/-er/-ir).
_ENDINGS = {
    "presente": {
        "ar": ["o", "as", "a", "amos", "áis", "an"],
        "er": ["o", "es", "e", "emos", "éis", "en"],
        "ir": ["o", "es", "e", "imos", "ís", "en"],
    },
    "preterito-indefinido": {
        "ar": ["é", "aste", "ó", "amos", "asteis", "aron"],
        "er": ["í", "iste", "ió", "imos", "isteis", "ieron"],
        "ir": ["í", "iste", "ió", "imos", "isteis", "ieron"],
    },
    "preterito-imperfecto": {
        "ar": ["aba", "abas", "aba", "ábamos", "abais", "aban"],
        "er": ["ía", "ías", "ía", "íamos", "íais", "ían"],
        "ir": ["ía", "ías", "ía", "íamos", "íais", "ían"],
    },
    "presente-subjuntivo": {
        "ar": ["e", "es", "e", "emos", "éis", "en"],
        "er": ["a", "as", "a", "amos", "áis", "an"],
        "ir": ["a", "as", "a", "amos", "áis", "an"],
    },
    "imperfecto-subjuntivo": {
        "ar": ["ara", "aras", "ara", "áramos", "arais", "aran"],
        "er": ["iera", "ieras", "iera", "iéramos", "ierais", "ieran"],
        "ir": ["iera", "ieras", "iera", "iéramos", "ierais", "ieran"],
    },
    "futuro-subjuntivo": {
        "ar": ["are", "ares", "are", "áremos", "areis", "aren"],
        "er": ["iere", "ieres", "iere", "iéremos", "iereis", "ieren"],
        "ir": ["iere", "ieres", "iere", "iéremos", "iereis", "ieren"],
    },
}
# Future and conditional: endings appended to the whole infinitive.
_INFINITIVE_ENDINGS = {
    "futuro-simple": ["é", "ás", "á", "emos", "éis", "án"],
    "condicional-simple": ["ía", "ías", "ía", "íamos", "íais", "ían"],
}
# Compound tenses: haber + participle.
AUXILIARIES = {
    "preterito-perfecto": ["he", "has", "ha", "hemos", "habéis", "han"],
    "pluscuamperfecto": ["había", "habías", "había", "habíamos", "habíais", "habían"],
    "futuro-perfecto": ["habré", "habrás", "habrá", "habremos", "habréis", "habrán"],
    "condicional-perfecto": ["habría", "habrías", "habría", "habríamos", "habríais", "habrían"],
    "perfecto-subjuntivo": ["haya", "hayas", "haya", "hayamos", "hayáis", "hayan"],
    "pluscuamperfecto-subjuntivo": ["hubiera", "hubieras", "hubiera", "hubiéramos", "hubierais", "hubieran"],
}
GENERATED_TENSES = set(_ENDINGS) | set(_INFINITIVE_ENDINGS) | set(AUXILIARIES)


def base_infinitive(infinitive: str) -> str:
    """`levantarse` → `levantar`."""
    return infinitive[:-2] if infinitive.endswith("se") and infinitive[-4:-2] in ("ar", "er", "ir", "ír") else infinitive


def participle(infinitive: str, model: str) -> str:
    inf = base_infinitive(infinitive)
    return inf[:-2] + ("ado" if model == "ar" else "ido")


def regular_paradigm(infinitive: str, model: str, tense_id: str) -> list[str]:
    """Six regular forms of `infinitive` (model ar/er/ir) in `tense_id`."""
    if model not in ("ar", "er", "ir"):
        raise ValueError(f"no regular paradigm for model '{model}'")
    inf = base_infinitive(infinitive)
    if tense_id in _ENDINGS:
        return [inf[:-2] + e for e in _ENDINGS[tense_id][model]]
    if tense_id in _INFINITIVE_ENDINGS:
        return [inf + e for e in _INFINITIVE_ENDINGS[tense_id]]
    if tense_id in AUXILIARIES:
        p = participle(inf, model)
        return [f"{aux} {p}" for aux in AUXILIARIES[tense_id]]
    raise ValueError(f"unknown tense '{tense_id}'")


def paradigms(verb: dict, tense_ids: list[str]) -> dict[str, list[str]]:
    """Complete paradigms of a verb for the registered tenses: overrides win,
    then generated regular forms; reflexive pronouns prefixed."""
    out: dict[str, list[str]] = {}
    forms = verb.get("forms") or {}
    for tid in tense_ids:
        if tid in forms:
            six = list(forms[tid])
        else:
            six = regular_paradigm(verb["infinitive"], verb["model"], tid)
        if verb.get("reflexive"):
            six = [f"{pr} {f}" for pr, f in zip(REFLEXIVE_PRONOUNS, six)]
        out[tid] = six
    return out


# --- content loading & validation ------------------------------------------

def conjugation_dir() -> Path:
    return lib.content_dir() / "conjugation"


def load_tenses() -> list[dict]:
    p = conjugation_dir() / "tenses.json"
    return json.loads(p.read_text(encoding="utf-8")) if p.exists() else []


def iter_verb_files() -> list[Path]:
    d = conjugation_dir() / "verbs"
    return sorted(d.glob("*.json")) if d.exists() else []


def load_verbs() -> list[tuple[Path, dict]]:
    return [(p, json.loads(p.read_text(encoding="utf-8"))) for p in iter_verb_files()]


def validate_conjugation(card_level: dict[str, str]) -> list[str]:
    """Integrity errors for content/conjugation/ (empty when the dir is absent)."""
    if not conjugation_dir().exists():
        return []
    errors: list[str] = []
    try:
        tenses = load_tenses()
    except Exception as e:  # noqa: BLE001
        return [f"conjugation/tenses.json: failed to parse ({e})"]
    ids = [t.get("id") for t in tenses]
    for tid in sorted({i for i in ids if ids.count(i) > 1}):
        errors.append(f"conjugation: duplicate tense id '{tid}'")
    for t in tenses:
        tid, cid = t.get("id"), t.get("card")
        for key in ("id", "es", "ru", "mood", "level", "card", "order"):
            if key not in t:
                errors.append(f"conjugation: tense '{tid}' missing '{key}'")
        if tid not in GENERATED_TENSES:
            errors.append(f"conjugation: tense '{tid}' has no generator")
        if cid not in card_level:
            errors.append(f"conjugation: tense '{tid}' maps to missing card '{cid}'")
        elif card_level[cid] != t.get("level"):
            errors.append(f"conjugation: tense '{tid}' card '{cid}' has level {card_level[cid]}, not {t.get('level')}")
    registered = [t.get("id") for t in tenses]

    ranks: dict[int, str] = {}
    try:
        verbs = load_verbs()
    except Exception as e:  # noqa: BLE001
        return errors + [f"conjugation: verb file failed to parse ({e})"]
    for path, v in verbs:
        name = path.stem
        inf = v.get("infinitive")
        if inf != name:
            errors.append(f"conjugation: file '{name}.json' does not match infinitive '{inf}'")
        rank = v.get("rank")
        if not isinstance(rank, int) or isinstance(rank, bool) or rank < 1:
            errors.append(f"conjugation: {name}: rank must be a positive integer")
        elif rank in ranks:
            errors.append(f"conjugation: duplicate rank {rank} ({ranks[rank]}, {name})")
        else:
            ranks[rank] = name
        if not v.get("ru"):
            errors.append(f"conjugation: {name}: missing ru")
        model = v.get("model")
        if model not in MODELS:
            errors.append(f"conjugation: {name}: unknown model '{model}'")
        forms = v.get("forms") or {}
        for tid, six in forms.items():
            if tid not in registered:
                errors.append(f"conjugation: {name}: unknown tense '{tid}' in forms")
            if not (isinstance(six, list) and len(six) == 6 and all(isinstance(f, str) and f.strip() for f in six)):
                errors.append(f"conjugation: {name}: tense '{tid}' needs exactly six non-empty forms")
        if model == "irregular":
            for tid in registered:
                if tid not in forms:
                    errors.append(f"conjugation: {name}: irregular verb lacks tense '{tid}'")
    return errors


def bundle() -> dict | None:
    """The bundle section: tenses + every verb's complete paradigms (None without content)."""
    if not conjugation_dir().exists():
        return None
    tenses = sorted(load_tenses(), key=lambda t: t["order"])
    ids = [t["id"] for t in tenses]
    verbs = []
    for _, v in sorted(load_verbs(), key=lambda pv: pv[1]["rank"]):
        verbs.append({
            "infinitive": v["infinitive"],
            "rank": v["rank"],
            "ru": v["ru"],
            "reflexive": bool(v.get("reflexive", False)),
            "paradigms": paradigms(v, ids),
        })
    return {"tenses": tenses, "verbs": verbs}
