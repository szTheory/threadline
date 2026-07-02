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

## From 191-02 (2026-07-02)

- **Same `v1_23_charter_doc_contract_test.exs` failure still present.** Re-confirmed
  failing on clean `b8547d73` BEFORE the 191-02 Task 3 change, so it is not caused by
  the routing reshape (mix.exs `groups_for_extras`/alias, README `## Start here`, or
  the new `persona_routing_doc_contract_test.exs`). `mix verify.doc_contract` now runs
  114 tests with this single pre-existing failure; the new persona-routing test passes
  3/3. Still owned by the ADOPT-01 version-truth / charter work, not ADOPT-03 routing.
