#!/usr/bin/env python3
"""Tests for the content pipeline. Run: python3 tools/test_pipeline.py"""
from __future__ import annotations

import json
import os
import tempfile
import unittest
from pathlib import Path

import lib
import validate
import compile as compile_mod
import enrich


def write_content(root: Path, cards: list[lib.Card], themes: list[dict]) -> None:
    for c in cards:
        d = root / c.level
        d.mkdir(parents=True, exist_ok=True)
        (d / f"{c.id}.md").write_text(lib.render_card_file(c), encoding="utf-8")
    (root / "themes.json").write_text(
        json.dumps({"themes": themes}, ensure_ascii=False), encoding="utf-8"
    )


def card(cid: str, order: int, theme: str = "a1-1", related=None) -> lib.Card:
    return lib.Card(
        id=cid, level="A1", theme=theme, order=order, title=f"Card {cid}",
        aliases=[], related=related or [], tags=["gramática"], body="Body\n",
    )


THEME = [{"id": "a1-1", "level": "A1", "title": "T1", "order": 1}]


class PipelineTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        os.environ["LORITO_CONTENT_DIR"] = self.tmp.name

    def tearDown(self) -> None:
        os.environ.pop("LORITO_CONTENT_DIR", None)
        os.environ.pop("LORITO_BUNDLE_PATH", None)
        self.tmp.cleanup()

    def test_clean_content_passes(self):
        write_content(Path(self.tmp.name), [card("A1-01", 1), card("A1-02", 2)], THEME)
        self.assertEqual(validate.validate(), [])

    def test_duplicate_ids_caught(self):
        root = Path(self.tmp.name)
        write_content(root, [card("A1-01", 1)], THEME)
        # second file with a different name but the same internal id
        (root / "A1" / "dup.md").write_text(
            lib.render_card_file(card("A1-01", 2)), encoding="utf-8"
        )
        errs = validate.validate()
        self.assertTrue(any("duplicate id" in e for e in errs), errs)

    def test_dangling_related_caught(self):
        write_content(Path(self.tmp.name), [card("A1-01", 1, related=["A1-99"])], THEME)
        errs = validate.validate()
        self.assertTrue(any("unresolved related" in e for e in errs), errs)

    def test_unknown_theme_caught(self):
        write_content(Path(self.tmp.name), [card("A1-01", 1, theme="zz-9")], THEME)
        errs = validate.validate()
        self.assertTrue(any("unknown theme" in e for e in errs), errs)

    def test_compile_produces_bundle(self):
        write_content(Path(self.tmp.name), [card("A1-01", 1), card("A1-02", 2)], THEME)
        out = Path(self.tmp.name) / "content.json"
        os.environ["LORITO_BUNDLE_PATH"] = str(out)
        self.assertEqual(compile_mod.main(), 0)
        self.assertTrue(out.exists())
        data = json.loads(out.read_text(encoding="utf-8"))
        self.assertEqual(len(data["cards"]), 2)
        self.assertEqual(data["cards"][0]["themeID"], "a1-1")

    def test_compile_blocked_by_invalid(self):
        write_content(Path(self.tmp.name), [card("A1-01", 1, related=["A1-99"])], THEME)
        out = Path(self.tmp.name) / "content.json"
        os.environ["LORITO_BUNDLE_PATH"] = str(out)
        self.assertEqual(compile_mod.main(), 1)
        self.assertFalse(out.exists())


def exercise(eid: str, etype: str, card_id: str = "A1-01", theme: str = "a1-1",
             level: str = "A1", **data) -> lib.Exercise:
    return lib.Exercise(
        id=eid, level=level, theme=theme, card=card_id, type=etype,
        prompt="Prompt?", explanation="Because.", data=data,
    )


def write_exercise(root: Path, ex: lib.Exercise) -> None:
    d = root / ex.level / "exercises"
    d.mkdir(parents=True, exist_ok=True)
    (d / f"{ex.id}.md").write_text(lib.render_exercise_file(ex), encoding="utf-8")


class ExerciseTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        os.environ["LORITO_CONTENT_DIR"] = self.tmp.name
        self.root = Path(self.tmp.name)
        # One real card the exercises can reference.
        write_content(self.root, [card("A1-01", 1)], THEME)

    def tearDown(self) -> None:
        os.environ.pop("LORITO_CONTENT_DIR", None)
        os.environ.pop("LORITO_BUNDLE_PATH", None)
        self.tmp.cleanup()

    def test_clean_exercises_pass(self):
        write_exercise(self.root, exercise("A1-EX-01", "multiple-choice",
                                           options=["el", "la"], answer="la"))
        write_exercise(self.root, exercise("A1-EX-02", "fill-in-the-blank",
                                           answer="la", accept=["LA"]))
        self.assertEqual(validate.validate(), [])

    def test_roundtrip_parse(self):
        write_exercise(self.root, exercise("A1-EX-01", "multiple-choice",
                                           options=["el", "la"], answer="la"))
        ex = lib.parse_exercise_file(self.root / "A1" / "exercises" / "A1-EX-01.md")
        self.assertEqual(ex.type, "multiple-choice")
        self.assertEqual(ex.data["options"], ["el", "la"])
        self.assertEqual(ex.data["answer"], "la")
        self.assertEqual(ex.explanation, "Because.")

    def test_missing_type_field_caught(self):
        write_exercise(self.root, exercise("A1-EX-01", "multiple-choice", options=["el", "la"]))
        errs = validate.validate()
        self.assertTrue(any("missing field 'answer'" in e for e in errs), errs)

    def test_unresolved_card_caught(self):
        write_exercise(self.root, exercise("A1-EX-01", "fill-in-the-blank",
                                           card_id="A1-99", answer="x"))
        errs = validate.validate()
        self.assertTrue(any("unresolved card 'A1-99'" in e for e in errs), errs)

    def test_card_level_mismatch_caught(self):
        ex = exercise("B1-EX-01", "fill-in-the-blank", card_id="A1-01",
                      theme="a1-1", level="B1", answer="x")
        write_exercise(self.root, ex)
        errs = validate.validate()
        self.assertTrue(any("is A1, not B1" in e for e in errs), errs)

    def test_unknown_type_caught(self):
        write_exercise(self.root, exercise("A1-EX-01", "crossword", answer="x"))
        errs = validate.validate()
        self.assertTrue(any("unknown type 'crossword'" in e for e in errs), errs)

    def test_mc_answer_not_in_options_caught(self):
        write_exercise(self.root, exercise("A1-EX-01", "multiple-choice",
                                           options=["el", "la"], answer="los"))
        errs = validate.validate()
        self.assertTrue(any("not among options" in e for e in errs), errs)

    def test_word_order_tokens_cannot_form_answer(self):
        write_exercise(self.root, exercise("A1-EX-01", "word-order",
                                           tokens=["yo", "como"], answer="yo no como"))
        errs = validate.validate()
        self.assertTrue(any("tokens cannot be arranged" in e for e in errs), errs)

    def test_word_order_valid(self):
        write_exercise(self.root, exercise("A1-EX-01", "word-order",
                                           tokens=["yo", "como", "pan"], answer="Yo como pan"))
        self.assertEqual(validate.validate(), [])

    def test_normalize_answer_folds_case_and_diacritics(self):
        self.assertEqual(lib.normalize_answer("  Está  "), lib.normalize_answer("esta"))
        self.assertEqual(lib.normalize_answer("Niño"), lib.normalize_answer("nino"))

    def test_duplicate_exercise_id_caught(self):
        write_exercise(self.root, exercise("A1-EX-01", "fill-in-the-blank", answer="a"))
        d = self.root / "A1" / "exercises"
        (d / "dup.md").write_text(
            lib.render_exercise_file(exercise("A1-EX-01", "fill-in-the-blank", answer="b")),
            encoding="utf-8",
        )
        errs = validate.validate()
        self.assertTrue(any("duplicate exercise id" in e for e in errs), errs)

    def test_compile_includes_exercises(self):
        write_exercise(self.root, exercise("A1-EX-01", "multiple-choice",
                                           options=["el", "la"], answer="la"))
        out = self.root / "content.json"
        os.environ["LORITO_BUNDLE_PATH"] = str(out)
        self.assertEqual(compile_mod.main(), 0)
        data = json.loads(out.read_text(encoding="utf-8"))
        self.assertEqual(len(data["exercises"]), 1)
        ex = data["exercises"][0]
        self.assertEqual(ex["type"], "multiple-choice")
        self.assertEqual(ex["card"], "A1-01")
        self.assertEqual(ex["options"], ["el", "la"])
        self.assertEqual(ex["prompt"], "Prompt?")
        self.assertEqual(ex["explanation"], "Because.")

    def test_compile_blocked_by_invalid_exercise(self):
        write_exercise(self.root, exercise("A1-EX-01", "multiple-choice",
                                           options=["el", "la"], answer="los"))
        out = self.root / "content.json"
        os.environ["LORITO_BUNDLE_PATH"] = str(out)
        self.assertEqual(compile_mod.main(), 1)
        self.assertFalse(out.exists())

    def test_coverage_lists_uncovered_cards_and_counts(self):
        # Two cards, one with an exercise, one without.
        write_content(self.root, [card("A1-01", 1), card("A1-02", 2)], THEME)
        write_exercise(self.root, exercise("A1-EX-01", "fill-in-the-blank",
                                           card_id="A1-01", answer="x"))
        rep = validate.coverage()
        self.assertEqual(rep["total"], 2)
        self.assertEqual(rep["covered"], 1)
        self.assertEqual(rep["uncovered"], ["A1-02"])
        self.assertIn("a1-1", rep["uncovered_by_theme"])

    def test_coverage_is_non_failing(self):
        # Cards exist with no exercises at all — coverage still exits zero.
        write_content(self.root, [card("A1-01", 1)], THEME)
        self.assertEqual(validate.print_coverage(), 0)
        self.assertEqual(validate.main(["--coverage"]), 0)
        # And it does not affect validation pass/fail.
        self.assertEqual(validate.validate(), [])

    def test_picture_matching_missing_asset_caught(self):
        ex = exercise("A1-EX-01", "picture-matching",
                      options=[{"image": "casa.png", "label": "casa"},
                               {"image": "perro.png", "label": "perro"}])
        write_exercise(self.root, ex)
        errs = validate.validate()
        self.assertTrue(any("missing image asset 'casa.png'" in e for e in errs), errs)

    def test_picture_matching_with_assets_passes_and_compiles(self):
        assets = self.root / "exercise-assets"
        assets.mkdir(parents=True, exist_ok=True)
        (assets / "casa.png").write_bytes(b"\x89PNG\r\n")   # fixture bytes
        (assets / "perro.png").write_bytes(b"\x89PNG\r\n")
        ex = exercise("A1-EX-01", "picture-matching",
                      options=[{"image": "casa.png", "label": "casa"},
                               {"image": "perro.png", "label": "perro"}])
        write_exercise(self.root, ex)
        self.assertEqual(validate.validate(), [])
        out = self.root / "content.json"
        os.environ["LORITO_BUNDLE_PATH"] = str(out)
        self.assertEqual(compile_mod.main(), 0)
        # Assets copied next to the bundle.
        self.assertTrue((out.parent / "exercise-assets" / "casa.png").exists())
        self.assertTrue((out.parent / "exercise-assets" / "perro.png").exists())


class RecallTests(unittest.TestCase):
    """Optional `recall` front-matter field (recall-first-study)."""

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        os.environ["LORITO_CONTENT_DIR"] = self.tmp.name
        self.root = Path(self.tmp.name)

    def tearDown(self) -> None:
        os.environ.pop("LORITO_CONTENT_DIR", None)
        os.environ.pop("LORITO_BUNDLE_PATH", None)
        self.tmp.cleanup()

    def write_raw_recall(self, raw_line: str) -> None:
        """Write A1-01 with a hand-written `recall` front-matter line."""
        write_content(self.root, [card("A1-01", 1)], THEME)
        path = self.root / "A1" / "A1-01.md"
        text = path.read_text(encoding="utf-8")
        path.write_text(text.replace("tags:", raw_line + "\ntags:", 1), encoding="utf-8")

    def compile_cards(self) -> list[dict]:
        out = self.root / "content.json"
        os.environ["LORITO_BUNDLE_PATH"] = str(out)
        self.assertEqual(compile_mod.main(), 0)
        return json.loads(out.read_text(encoding="utf-8"))["cards"]

    def test_valid_recall_passes_and_compiles(self):
        c = card("A1-01", 1)
        c.recall = "**¿el или la?** *problema, mano, canción, agua*"
        write_content(self.root, [c, card("A1-02", 2)], THEME)
        self.assertEqual(validate.validate(), [])
        cards = {x["id"]: x for x in self.compile_cards()}
        self.assertEqual(cards["A1-01"]["recall"], c.recall)
        self.assertNotIn("recall", cards["A1-02"])

    def test_recall_with_quotes_round_trips(self):
        c = card("A1-01", 1)
        c.recall = 'Что значит "ser"?'
        write_content(self.root, [c], THEME)
        self.assertEqual(lib.parse_card_file(self.root / "A1" / "A1-01.md").recall, c.recall)
        self.assertEqual(validate.validate(), [])

    def test_missing_recall_is_fine(self):
        write_content(self.root, [card("A1-01", 1)], THEME)
        self.assertEqual(validate.validate(), [])
        self.assertTrue(all("recall" not in x for x in self.compile_cards()))

    def test_empty_recall_fails(self):
        self.write_raw_recall('recall: "   "')
        errs = validate.validate()
        self.assertTrue(any("A1-01" in e and "recall" in e and "empty" in e for e in errs), errs)

    def test_multiline_recall_fails(self):
        self.write_raw_recall('recall: |')
        errs = validate.validate()
        self.assertTrue(any("A1-01" in e and "recall" in e for e in errs), errs)

    def test_unterminated_recall_fails(self):
        self.write_raw_recall('recall: "first line')
        errs = validate.validate()
        self.assertTrue(any("A1-01" in e and "recall" in e for e in errs), errs)

    def test_overlong_recall_fails(self):
        c = card("A1-01", 1)
        c.recall = "x" * 201
        write_content(self.root, [c], THEME)
        errs = validate.validate()
        self.assertTrue(any("A1-01" in e and "200" in e for e in errs), errs)

    def test_non_string_recall_fails(self):
        for raw in ['recall: ["a", "b"]', "recall: 42", "recall: true"]:
            self.write_raw_recall(raw)
            errs = validate.validate()
            self.assertTrue(any("A1-01" in e and "recall" in e and "string" in e for e in errs), (raw, errs))


    def test_set_recall_writes_valid_prompt(self):
        write_content(self.root, [card("A1-01", 1)], THEME)
        self.assertEqual(enrich.set_recall("A1-01", "  **¿Какой род?** *mano*  "), 0)
        c = lib.parse_card_file(self.root / "A1" / "A1-01.md")
        self.assertEqual(c.recall, "**¿Какой род?** *mano*")
        self.assertEqual(c.body, "Body\n")
        self.assertEqual(validate.validate(), [])

    def test_set_recall_rejects_overlong(self):
        write_content(self.root, [card("A1-01", 1)], THEME)
        self.assertEqual(enrich.set_recall("A1-01", "x" * 201), 1)
        self.assertIsNone(lib.parse_card_file(self.root / "A1" / "A1-01.md").recall)

    def test_recall_context_uses_essence_and_key_points(self):
        c = card("A1-01", 1)
        c.body = "> **Суть**\n> Два рода.\n\n## 🔑 Ключевые моменты\n- el / la\n\n## ⚠️ Частые ошибки\n- нет\n"
        ctx = enrich.recall_context(c)
        self.assertIn("Два рода.", ctx)
        self.assertIn("el / la", ctx)
        self.assertNotIn("нет", ctx)




# --- conjugation-trainer -----------------------------------------------------

import conjugate  # noqa: E402

AUX = {
    "preterito-perfecto": ["he", "has", "ha", "hemos", "habéis", "han"],
    "pluscuamperfecto": ["había", "habías", "había", "habíamos", "habíais", "habían"],
    "futuro-perfecto": ["habré", "habrás", "habrá", "habremos", "habréis", "habrán"],
    "condicional-perfecto": ["habría", "habrías", "habría", "habríamos", "habríais", "habrían"],
    "perfecto-subjuntivo": ["haya", "hayas", "haya", "hayamos", "hayáis", "hayan"],
    "pluscuamperfecto-subjuntivo": ["hubiera", "hubieras", "hubiera", "hubiéramos", "hubierais", "hubieran"],
}

HAND = {
    "hablar": {
        "presente": "hablo hablas habla hablamos habláis hablan",
        "preterito-indefinido": "hablé hablaste habló hablamos hablasteis hablaron",
        "preterito-imperfecto": "hablaba hablabas hablaba hablábamos hablabais hablaban",
        "futuro-simple": "hablaré hablarás hablará hablaremos hablaréis hablarán",
        "condicional-simple": "hablaría hablarías hablaría hablaríamos hablaríais hablarían",
        "presente-subjuntivo": "hable hables hable hablemos habléis hablen",
        "imperfecto-subjuntivo": "hablara hablaras hablara habláramos hablarais hablaran",
        "futuro-subjuntivo": "hablare hablares hablare habláremos hablareis hablaren",
        "participle": "hablado",
    },
    "comer": {
        "presente": "como comes come comemos coméis comen",
        "preterito-indefinido": "comí comiste comió comimos comisteis comieron",
        "preterito-imperfecto": "comía comías comía comíamos comíais comían",
        "futuro-simple": "comeré comerás comerá comeremos comeréis comerán",
        "condicional-simple": "comería comerías comería comeríamos comeríais comerían",
        "presente-subjuntivo": "coma comas coma comamos comáis coman",
        "imperfecto-subjuntivo": "comiera comieras comiera comiéramos comierais comieran",
        "futuro-subjuntivo": "comiere comieres comiere comiéremos comiereis comieren",
        "participle": "comido",
    },
    "vivir": {
        "presente": "vivo vives vive vivimos vivís viven",
        "preterito-indefinido": "viví viviste vivió vivimos vivisteis vivieron",
        "preterito-imperfecto": "vivía vivías vivía vivíamos vivíais vivían",
        "futuro-simple": "viviré vivirás vivirá viviremos viviréis vivirán",
        "condicional-simple": "viviría vivirías viviría viviríamos viviríais vivirían",
        "presente-subjuntivo": "viva vivas viva vivamos viváis vivan",
        "imperfecto-subjuntivo": "viviera vivieras viviera viviéramos vivierais vivieran",
        "futuro-subjuntivo": "viviere vivieres viviere viviéremos viviereis vivieren",
        "participle": "vivido",
    },
}

TENSE_IDS = list(HAND["hablar"].keys())[:-1] + list(AUX.keys())


def tense(tid: str, card_id: str = "A1-01", level: str = "A1", order: int = 1) -> dict:
    return {"id": tid, "es": tid, "ru": tid, "mood": "indicativo", "level": level, "card": card_id, "order": order}


def write_conjugation(root: Path, tenses: list[dict], verbs: dict[str, dict]) -> None:
    d = root / "conjugation"
    (d / "verbs").mkdir(parents=True, exist_ok=True)
    (d / "tenses.json").write_text(json.dumps(tenses, ensure_ascii=False), encoding="utf-8")
    for name, verb in verbs.items():
        (d / "verbs" / f"{name}.json").write_text(json.dumps(verb, ensure_ascii=False), encoding="utf-8")


class ConjugationGenerationTests(unittest.TestCase):
    def test_regular_paradigms_match_hand_checked_tables(self):
        for inf, model in [("hablar", "ar"), ("comer", "er"), ("vivir", "ir")]:
            for tid in TENSE_IDS:
                got = conjugate.regular_paradigm(inf, model, tid)
                if tid in AUX:
                    want = [f"{a} {HAND[inf]['participle']}" for a in AUX[tid]]
                else:
                    want = HAND[inf][tid].split()
                self.assertEqual(got, want, f"{inf} {tid}")

    def test_override_replaces_generated_tense(self):
        buscar = {"infinitive": "buscar", "rank": 1, "ru": "искать", "model": "ar",
                  "forms": {"preterito-indefinido": ["busqué", "buscaste", "buscó", "buscamos", "buscasteis", "buscaron"]}}
        p = conjugate.paradigms(buscar, TENSE_IDS)
        self.assertEqual(p["preterito-indefinido"][0], "busqué")
        self.assertEqual(p["presente"][0], "busco")

    def test_reflexive_forms_carry_the_pronoun(self):
        verb = {"infinitive": "levantarse", "rank": 1, "ru": "вставать", "model": "ar", "reflexive": True}
        p = conjugate.paradigms(verb, TENSE_IDS)
        self.assertEqual(p["presente"], ["me levanto", "te levantas", "se levanta", "nos levantamos",
                                         "os levantáis", "se levantan"])
        self.assertEqual(p["preterito-perfecto"][0], "me he levantado")


class ConjugationValidationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        os.environ["LORITO_CONTENT_DIR"] = self.tmp.name
        self.root = Path(self.tmp.name)
        write_content(self.root, [card("A1-01", 1), card("A1-02", 2)], THEME)
        self.tenses = [tense("presente")]
        self.hablar = {"infinitive": "hablar", "rank": 1, "ru": "говорить", "model": "ar"}

    def tearDown(self) -> None:
        os.environ.pop("LORITO_CONTENT_DIR", None)
        os.environ.pop("LORITO_BUNDLE_PATH", None)
        self.tmp.cleanup()

    def errors(self, tenses, verbs) -> list[str]:
        write_conjugation(self.root, tenses, verbs)
        return validate.validate()

    def test_clean_conjugation_passes(self):
        self.assertEqual(self.errors(self.tenses, {"hablar": self.hablar}), [])

    def test_no_conjugation_dir_is_fine(self):
        self.assertEqual(validate.validate(), [])

    def test_duplicate_tense_id(self):
        errs = self.errors([tense("presente"), tense("presente", order=2)], {"hablar": self.hablar})
        self.assertTrue(any("duplicate tense" in e for e in errs), errs)

    def test_missing_or_wrong_level_card(self):
        errs = self.errors([tense("presente", card_id="A1-99")], {"hablar": self.hablar})
        self.assertTrue(any("presente" in e and "A1-99" in e for e in errs), errs)
        errs = self.errors([tense("presente", level="B1")], {"hablar": self.hablar})
        self.assertTrue(any("presente" in e and "level" in e for e in errs), errs)

    def test_file_name_must_match_infinitive(self):
        errs = self.errors(self.tenses, {"hablarr": self.hablar})
        self.assertTrue(any("hablarr" in e and "infinitive" in e for e in errs), errs)

    def test_duplicate_or_bad_rank(self):
        comer = {"infinitive": "comer", "rank": 1, "ru": "есть", "model": "er"}
        errs = self.errors(self.tenses, {"hablar": self.hablar, "comer": comer})
        self.assertTrue(any("duplicate rank" in e for e in errs), errs)
        errs = self.errors(self.tenses, {"hablar": {**self.hablar, "rank": 0}})
        self.assertTrue(any("rank" in e for e in errs), errs)

    def test_unknown_model(self):
        errs = self.errors(self.tenses, {"hablar": {**self.hablar, "model": "xr"}})
        self.assertTrue(any("model" in e for e in errs), errs)

    def test_unknown_tense_in_forms(self):
        errs = self.errors(self.tenses, {"hablar": {**self.hablar, "forms": {"aoristo": ["a"] * 6}}})
        self.assertTrue(any("aoristo" in e for e in errs), errs)

    def test_wrong_form_count(self):
        errs = self.errors(self.tenses, {"hablar": {**self.hablar, "forms": {"presente": ["a"] * 5}}})
        self.assertTrue(any("hablar" in e and "presente" in e for e in errs), errs)

    def test_incomplete_irregular(self):
        ser = {"infinitive": "ser", "rank": 2, "ru": "быть", "model": "irregular", "forms": {}}
        errs = self.errors(self.tenses, {"hablar": self.hablar, "ser": ser})
        self.assertTrue(any("ser" in e and "presente" in e for e in errs), errs)

    def test_compile_bundles_paradigms_and_is_blocked_when_invalid(self):
        write_conjugation(self.root, self.tenses, {"hablar": self.hablar})
        out = self.root / "content.json"
        os.environ["LORITO_BUNDLE_PATH"] = str(out)
        self.assertEqual(compile_mod.main(), 0)
        data = json.loads(out.read_text(encoding="utf-8"))
        self.assertEqual(data["conjugation"]["tenses"][0]["id"], "presente")
        self.assertEqual(data["conjugation"]["verbs"][0]["paradigms"]["presente"][0], "hablo")
        out.unlink()
        write_conjugation(self.root, self.tenses, {"hablar": {**self.hablar, "model": "xr"}})
        self.assertEqual(compile_mod.main(), 1)
        self.assertFalse(out.exists())


# --- listening-and-pronunciation ---------------------------------------------

class ListeningExerciseTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        os.environ["LORITO_CONTENT_DIR"] = self.tmp.name
        self.root = Path(self.tmp.name)
        write_content(self.root, [card("A1-01", 1)], THEME)

    def tearDown(self) -> None:
        os.environ.pop("LORITO_CONTENT_DIR", None)
        os.environ.pop("LORITO_BUNDLE_PATH", None)
        self.tmp.cleanup()

    def errors(self, *exercises) -> list[str]:
        for ex in exercises:
            write_exercise(self.root, ex)
        return validate.validate()

    def test_clean_listening_types_pass(self):
        errs = self.errors(
            exercise("A1-EX-10", "listen-choose", audio="¿Dónde está el baño?", options=["туалет", "кухня"], answer="туалет"),
            exercise("A1-EX-11", "dictation", audio="Me llamo Ana.", accept=["me llamo ana"]),
            exercise("A1-EX-12", "speak", answer="Buenos días", accept=["buen día"]),
        )
        self.assertEqual(errs, [])

    def test_required_fields(self):
        errs = self.errors(exercise("A1-EX-10", "listen-choose", options=["a", "b"], answer="a"),
                           exercise("A1-EX-11", "dictation"),
                           exercise("A1-EX-12", "speak"))
        self.assertTrue(any("A1-EX-10" in e and "audio" in e for e in errs), errs)
        self.assertTrue(any("A1-EX-11" in e and "audio" in e for e in errs), errs)
        self.assertTrue(any("A1-EX-12" in e and "answer" in e for e in errs), errs)

    def test_listen_choose_answer_among_options(self):
        errs = self.errors(exercise("A1-EX-10", "listen-choose", audio="Hola.", options=["a", "b"], answer="c"))
        self.assertTrue(any("A1-EX-10" in e and "not among options" in e for e in errs), errs)

    def test_one_line_and_length_limits(self):
        d = self.root / "A1" / "exercises"
        d.mkdir(parents=True, exist_ok=True)
        # A quoted scalar with an escaped line break (frontmatter values are one line).
        (d / "A1-EX-13.md").write_text(
            '---\nid: A1-EX-13\nlevel: A1\ntheme: a1-1\ncard: A1-01\ntype: listen-choose\n'
            'audio: "uno\\ndos"\noptions: ["a", "b"]\nanswer: a\n---\nPrompt?\n', encoding="utf-8")
        errs = self.errors(exercise("A1-EX-11", "dictation", audio="a" * 121),
                           exercise("A1-EX-12", "speak", answer="b" * 81))
        self.assertTrue(any("A1-EX-11" in e and "120" in e for e in errs), errs)
        self.assertTrue(any("A1-EX-12" in e and "80" in e for e in errs), errs)
        self.assertTrue(any("A1-EX-13" in e and "one line" in e for e in errs), errs)

    def test_unknown_type_still_rejected(self):
        errs = self.errors(exercise("A1-EX-14", "karaoke", audio="x"))
        self.assertTrue(any("unknown type" in e for e in errs), errs)

    def test_bundle_carries_audio_fields(self):
        write_exercise(self.root, exercise("A1-EX-11", "dictation", audio="Me llamo Ana.", accept=["me llamo ana"]))
        out = self.root / "content.json"
        os.environ["LORITO_BUNDLE_PATH"] = str(out)
        self.assertEqual(compile_mod.main(), 0)
        ex = json.loads(out.read_text(encoding="utf-8"))["exercises"][0]
        self.assertEqual((ex["type"], ex["audio"], ex["accept"]), ("dictation", "Me llamo Ana.", ["me llamo ana"]))


# --- exam-path-dele-ccse -----------------------------------------------------

import exams  # noqa: E402

DEFS = [
    {"id": "ccse", "title": "CCSE", "verifiedOn": "2026-10-27",
     "sections": [{"id": "ccse", "title": "CCSE", "minutes": 45, "maxPoints": 25, "productive": False}],
     "groups": [{"id": "all", "title": "Итог", "sections": ["ccse"], "passPoints": 15}]},
]


def exam_item(root: Path, iid: str, **fields) -> None:
    d = root / "exams" / fields.get("exam", "ccse") / "items"
    d.mkdir(parents=True, exist_ok=True)
    fm = {"id": iid, "exam": "ccse", "section": "ccse", "type": "choice", "form": 1,
          "options": ["sí", "no"], "answer": "sí", "source": "cervantes-ccse", "edition": "2026", **fields}
    lines = ["---"]
    for k, v in fm.items():
        if v is None:
            continue
        lines.append(f"{k}: {json.dumps(v, ensure_ascii=False) if isinstance(v, (list, dict, bool, int, float)) else lib.quote_scalar(str(v))}")
    lines += ["---", "¿Pregunta?", "", "> **Объяснение**", "> Пояснение."]
    (d / f"{iid}.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


class ExamPipelineTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        os.environ["LORITO_CONTENT_DIR"] = self.tmp.name
        self.root = Path(self.tmp.name)
        write_content(self.root, [card("A1-01", 1)], THEME)
        (self.root / "exams").mkdir()
        (self.root / "exams" / "definitions.json").write_text(json.dumps(DEFS, ensure_ascii=False), encoding="utf-8")

    def tearDown(self) -> None:
        os.environ.pop("LORITO_CONTENT_DIR", None)
        os.environ.pop("LORITO_BUNDLE_PATH", None)
        self.tmp.cleanup()

    def test_clean_bank_passes_and_compiles(self):
        exam_item(self.root, "ccse-1", preview=True)
        exam_item(self.root, "ccse-2")
        self.assertEqual(validate.validate(), [])
        out = self.root / "content.json"
        os.environ["LORITO_BUNDLE_PATH"] = str(out)
        self.assertEqual(compile_mod.main(), 0)
        data = json.loads(out.read_text(encoding="utf-8"))["exams"]
        self.assertEqual(data["definitions"][0]["id"], "ccse")
        item = data["items"][0]
        self.assertEqual((item["id"], item["text"], item["explanation"]), ("ccse-1", "¿Pregunta?", "Пояснение."))
        self.assertEqual(item["kind"], {"choice": {"options": ["sí", "no"], "answer": "sí"}})

    def test_missing_source_or_edition_fails(self):
        exam_item(self.root, "ccse-1", preview=True, edition=None)
        errs = validate.validate()
        self.assertTrue(any("ccse-1" in e and "edition" in e for e in errs), errs)
        exam_item(self.root, "ccse-1", preview=True, source=None)
        self.assertTrue(any("ccse-1" in e and "source" in e for e in validate.validate()))

    def test_invalid_answer_key_fails(self):
        exam_item(self.root, "ccse-1", preview=True, answer="quizá")
        self.assertTrue(any("ccse-1" in e and "answer" in e for e in validate.validate()))

    def test_preview_set_required(self):
        exam_item(self.root, "ccse-1")
        self.assertTrue(any("preview" in e for e in validate.validate()))

    def test_productive_tasks_need_rubric(self):
        exam_item(self.root, "ccse-1", preview=True)
        exam_item(self.root, "dele-w1", exam="dele-a2", section="writing", type="writing", options=None, answer=None,
                  source=None, edition=None, rubric=[], preview=True)
        defs = DEFS + [{"id": "dele-a2", "title": "DELE A2", "verifiedOn": "2026-10-27",
                        "sections": [{"id": "writing", "title": "Письмо", "minutes": 45, "maxPoints": 25, "productive": True}],
                        "groups": [{"id": "g1", "title": "G1", "sections": ["writing"], "passPoints": 15}]}]
        (self.root / "exams" / "definitions.json").write_text(json.dumps(defs, ensure_ascii=False), encoding="utf-8")
        self.assertTrue(any("dele-w1" in e and "rubric" in e for e in validate.validate()))

    def test_import_ccse_writes_items_and_retires_missing(self):
        src = self.root / "exams" / "ccse" / "source"
        src.mkdir(parents=True)
        (src / "2026.md").write_text(
            "## Tarea 1\n\n1. ¿Pregunta uno?\na) sí\nb) no\nc) quizá\nRespuesta: a\n\n"
            "2. ¿Pregunta dos?\na) uno\nb) dos\nRespuesta: b\n", encoding="utf-8")
        old = self.root / "exams" / "ccse" / "items"
        old.mkdir(parents=True)
        exam_item(self.root, "ccse-1099", edition="2025")
        written = exams.import_ccse(src / "2026.md", edition="2026")
        self.assertEqual(written, ["ccse-1", "ccse-2"])
        items = {p.stem: lib.parse_exercise_fm(lib.split_frontmatter(p.read_text(encoding="utf-8"))[0]) for p in old.glob("*.md")}
        self.assertEqual(items["ccse-1"]["answer"], "sí")
        self.assertEqual(items["ccse-2"]["options"], ["uno", "dos"])
        self.assertEqual(items["ccse-1"]["edition"], "2026")
        self.assertTrue(items["ccse-1099"]["retired"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
