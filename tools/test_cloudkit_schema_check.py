#!/usr/bin/env python3
"""Self-test for tools/cloudkit_schema_check.sh (fixture mode, no network).
Run: python3 tools/test_cloudkit_schema_check.py"""
import subprocess
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
SCRIPT = TOOLS / "cloudkit_schema_check.sh"
FIX = TOOLS / "fixtures" / "cloudkit"


def run(*args):
    return subprocess.run(["bash", str(SCRIPT), *args], capture_output=True, text=True)


class CloudKitSchemaCheckTests(unittest.TestCase):
    def test_missing_field_and_type_fail(self):
        r = run("--dev", str(FIX / "dev.ckdb"), "--prod", str(FIX / "prod_missing.ckdb"))
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)
        self.assertIn("CD_SettingsRecord.CD_studyGoalLevelRaw", r.stdout)
        self.assertIn("CD_StudyGoalRecord", r.stdout)

    def test_equal_schemas_pass(self):
        r = run("--dev", str(FIX / "dev.ckdb"), "--prod", str(FIX / "prod_equal.ckdb"))
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)

    def test_index_differences_are_not_missing_fields(self):
        # prod has QUERYABLE on a field dev lacks it on: not a missing field.
        r = run("--dev", str(FIX / "prod_missing.ckdb"), "--prod", str(FIX / "dev.ckdb"))
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)

    def test_warn_mode_never_fails(self):
        r = run("--warn", "--dev", str(FIX / "dev.ckdb"), "--prod", str(FIX / "prod_missing.ckdb"))
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertIn("WARNING", r.stdout)


if __name__ == "__main__":
    unittest.main(verbosity=2)
