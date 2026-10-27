#!/usr/bin/env bash
# CloudKit production-schema release gate (cloudkit-schema-release).
#
# Fails when the development schema has a record type or field that the
# production schema lacks, listing what is missing. Production is deployed by
# the owner in CloudKit Console («Deploy Schema Changes»); cktool can't do it.
#
# Usage:
#   tools/cloudkit_schema_check.sh                    # export both environments live
#   tools/cloudkit_schema_check.sh --warn             # report, never fail (TestFlight)
#   tools/cloudkit_schema_check.sh --dev A.ckdb --prod B.ckdb   # compare files (self-test)
#
# Live mode needs a CloudKit management token: CLOUDKIT_MANAGEMENT_TOKEN in the
# environment (CI secret), or one saved with `xcrun cktool save-token --type management`.
set -euo pipefail

TEAM_ID="${LORITO_TEAM_ID:-3GWRDGA8B7}"
CONTAINER_ID="iCloud.com.toffguy.lorito"
WARN=0
DEV=""
PROD=""
while [ $# -gt 0 ]; do
  case "$1" in
    --warn) WARN=1 ;;
    --dev) DEV="$2"; shift ;;
    --prod) PROD="$2"; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

if [ -z "$DEV" ] || [ -z "$PROD" ]; then
  TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
  TOKEN_ARGS=()
  if [ -n "${CLOUDKIT_MANAGEMENT_TOKEN:-}" ]; then TOKEN_ARGS=(--token "$CLOUDKIT_MANAGEMENT_TOKEN"); fi
  for env in development production; do
    if ! xcrun cktool export-schema ${TOKEN_ARGS[@]+"${TOKEN_ARGS[@]}"} --team-id "$TEAM_ID" \
        --container-id "$CONTAINER_ID" --environment "$env" --output-file "$TMP/$env.ckdb"; then
      echo "ERROR: could not export the $env schema (management token missing or invalid?)" >&2
      [ "$WARN" = 1 ] && exit 0 || exit 2
    fi
  done
  DEV="$TMP/development.ckdb"; PROD="$TMP/production.ckdb"
fi

python3 - "$DEV" "$PROD" "$WARN" <<'PY'
import re, sys
dev_path, prod_path, warn = sys.argv[1], sys.argv[2], sys.argv[3] == "1"

def parse(path):
    """{record type: {field names}} from a .ckdb export (GRANT lines ignored)."""
    text = open(path, encoding="utf-8").read()
    schema = {}
    for name, body in re.findall(r"RECORD TYPE\s+(\S+)\s*\((.*?)\);", text, re.S):
        fields = set()
        for line in body.splitlines():
            line = line.strip().rstrip(",")
            if not line or line.startswith("GRANT"):
                continue
            fields.add(line.split()[0].strip('"'))
        schema[name] = fields
    return schema

dev, prod = parse(dev_path), parse(prod_path)
missing = []
for rtype in sorted(dev):
    if rtype not in prod:
        missing.append(f"record type {rtype}")
        continue
    missing += [f"field {rtype}.{f}" for f in sorted(dev[rtype] - prod[rtype])]

if not missing:
    print("CloudKit schema OK: production has every development record type and field.")
    sys.exit(0)
label = "WARNING" if warn else "ERROR"
print(f"{label}: production CloudKit schema lacks {len(missing)} item(s) present in development:")
for m in missing:
    print(f"  - {m}")
print("Deploy them in CloudKit Console → iCloud.com.toffguy.lorito → Deploy Schema Changes.")
sys.exit(0 if warn else 1)
PY
