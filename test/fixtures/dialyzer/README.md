# Dialyzer warning fixtures

These five JSON fixtures are the source-owned audit record for the Phase 199 Dialyzer cleanup. Together they preserve the sealed partition of exactly **40 warnings** across **22 distinct warning origins**:

| Fixture | Warning IDs | Count |
| --- | --- | ---: |
| `critic-tooling.json` | W01, W02, W05 | 3 |
| `query-storage.json` | W03, W04, W33-W40 | 10 |
| `export-investigation.json` | W06-W20 | 15 |
| `operator-boundaries.json` | W21, W27-W32 | 7 |
| `operator-liveviews.json` | W22-W26 | 5 |

Every fixture records the slice name, original raw-output hash and warning count, its exact authorized source origins, the warning records assigned to that slice, and the post-fix analyzer command and output hash. Each warning record includes its stable ID, warning class, source path and line, original raw warning, disposition, and evidence.

## Ignore ratchet

The repository-wide ignore ceiling is zero because all 40 sealed warnings are fixed. The ceiling may only decrease after an approved exact filter is removed; it must never increase. A fixed warning must never receive an ignore entry.

If a warning is proven irreducible, its fixture record must first change to `irreducible` and include one exact `ignore_tuple`, a non-empty `rationale`, and a concrete `removal_trigger`. The matching tuple in `.dialyzer_ignore.exs` must have that rationale and removal trigger in the immediately preceding comment. Regexes, globs, message-only filters, duplicate tuples, helper-generated filters, unknown warnings, and unused filters all fail closed.

## Updating a slice

1. Capture the full raw analyzer baseline with `MIX_ENV=dev mix dialyzer --no-check --format raw --ignore-exit-status`.
2. Update only the fixture assigned to the source slice. Warning IDs and authorized origins are slice-disjoint; do not move or invent records to make a verifier pass.
3. Verify every fixture independently:

   ```sh
   bin/verify-dialyzer-slice --fixture test/fixtures/dialyzer/critic-tooling.json
   bin/verify-dialyzer-slice --fixture test/fixtures/dialyzer/query-storage.json
   bin/verify-dialyzer-slice --fixture test/fixtures/dialyzer/export-investigation.json
   bin/verify-dialyzer-slice --fixture test/fixtures/dialyzer/operator-boundaries.json
   bin/verify-dialyzer-slice --fixture test/fixtures/dialyzer/operator-liveviews.json
   ```

4. Run `mix test test/threadline/dialyzer_ignore_contract_test.exs` to prove the global 40-warning/22-origin partition and the exact ignore contract.
5. Run the strict analyzer with `mix dialyzer --list-unused-filters`. Any new warning or unused filter blocks the change.
