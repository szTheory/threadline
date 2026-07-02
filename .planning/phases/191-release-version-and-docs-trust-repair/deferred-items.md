# Deferred Items — Phase 191

Out-of-scope discoveries logged during execution. Not fixed (SCOPE BOUNDARY: only auto-fix issues directly caused by the current task's changes).

## From 191-01 (2026-07-02)

- **`v1_23_charter_doc_contract_test.exs` fails** — asserts PROJECT.md contains the
  v1.38 milestone strings ("Threadline is in milestone **v1.38 ...**" and
  "## Current Milestone: v1.38 ..."), but PROJECT.md was updated to v1.39 when the
  current milestone opened. Pre-existing drift, unrelated to the 191-01 files
  (`guides/upgrade-path.md`, `CONTRIBUTING.md`,
  `test/threadline/upgrade_path_doc_contract_test.exs`). The `mix verify.doc_contract`
  suite is otherwise green (110/111). Should be addressed by a later Phase 191 plan
  that owns PROJECT.md / milestone-charter truth, or by refreshing the charter test's
  expected milestone literal.
