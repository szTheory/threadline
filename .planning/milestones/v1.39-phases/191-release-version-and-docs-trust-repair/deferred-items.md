# Deferred Items — Phase 191

Out-of-scope discoveries logged during execution. Not fixed (SCOPE BOUNDARY: only auto-fix issues directly caused by the current task's changes).

## From 191-01 (2026-07-02)

- **Status:** acknowledged
- **Acknowledged at:** v1.40 milestone close, 2026-08-27

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

- **Status:** acknowledged
- **Acknowledged at:** v1.40 milestone close, 2026-08-27

- **Same `v1_23_charter_doc_contract_test.exs` failure still present.** Re-confirmed
  failing on clean `b8547d73` BEFORE the 191-02 Task 3 change, so it is not caused by
  the routing reshape (mix.exs `groups_for_extras`/alias, README `## Start here`, or
  the new `persona_routing_doc_contract_test.exs`). `mix verify.doc_contract` now runs
  114 tests with this single pre-existing failure; the new persona-routing test passes
  3/3. Still owned by the ADOPT-01 version-truth / charter work, not ADOPT-03 routing.

## From 191-03 (2026-07-02)

- **Status:** acknowledged
- **Acknowledged at:** v1.40 milestone close, 2026-08-27

- **Same `v1_23_charter_doc_contract_test.exs` failure remains — out of THIS plan's
  declared task scope.** 191-03's declared scope (frontmatter `files_modified` +
  Tasks 1-3) is install-pin / SSOT-prose / upgrade-coverage reconciliation (ROADMAP
  criteria 1 & 4): the seven `~> 0.9.0` pin flips, the evaluating-threadline.md SSOT
  correction, and the new `version_truth_doc_contract_test.exs`. It does **not** include
  `PROJECT.md` or `v1_23_charter_doc_contract_test.exs`, and none of the three tasks
  touch milestone-charter truth. The `version_truth` guard covers install pins,
  `x-release-please-version` current-version prose, and current-minor upgrade coverage —
  a distinct axis from the milestone-charter literal the charter test asserts. Per the
  SCOPE BOUNDARY rule, left as logged. `mix verify.doc_contract` now runs 117 tests with
  this single pre-existing failure; the new `version_truth_doc_contract_test.exs` passes
  3/3. Fix belongs to a plan that owns `PROJECT.md` / charter-test milestone truth
  (refresh the expected `v1.38` literal to the active milestone, or bind it to a SSOT).
