# CloudKit schema

`schema.ckdb` is the **development** schema of `iCloud.com.toffguy.lorito`,
exported with `cktool`. Every change that adds synced data updates it in the
same change, so schema changes show up in review (`cloudkit-sync` spec:
"Committed development schema").

## Export (needs a CloudKit management token)

```bash
# once per Mac: paste the management token when prompted
xcrun cktool save-token --type management

# after a Debug run with -LoritoInitCloudKitSchema (creates new types/fields in development)
xcrun cktool export-schema --team-id 3GWRDGA8B7 \
  --container-id iCloud.com.toffguy.lorito \
  --environment development --output-file cloudkit/schema.ckdb
```

## Release gate

`tools/cloudkit_schema_check.sh` exports development and production and fails
when production lacks a record type or field. `fastlane ci_release` and `submit`
run it (fail), `ci_beta` warns. In CI it reads `CLOUDKIT_MANAGEMENT_TOKEN`
(GitHub secret). Fix a failure in CloudKit Console → the container →
**Deploy Schema Changes**, then re-run the gate.

Self-test (no network): `python3 tools/test_cloudkit_schema_check.py`.
