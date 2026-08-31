---
phase: 198-green-bringup
plan: 12
subsystem: testing
tags: [ecto, storage-schema, test-hygiene, contract-test, ci-docs]

requires:
  - phase: 198-08
    provides: "the proven port recipe (repo_opts() as trailing opts on every Ecto call) for the remaining 14 defective files"
provides:
  - "mix test at 0 failures (1397 tests), the 79 unprefixed-audit-table test-side defects fully retired"
  - "CONTRIBUTING.md List 1 <-> ci.yml <-> phase06_nyquist_ci_contract_test.exs three-way parity restored"
affects: []

actuals:
  tokens: 22000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Threadline.StorageSchemaCase.repo_opts() as the trailing opts arg on every Ecto call against a Threadline-owned schema; import Threadline.StorageSchemaCase directly in plain ExUnit.Case modules, no-op for Threadline.DataCase modules (already imports it)"

key-files:
  created: []
  modified:
    - test/mix/tasks/threadline.evidence_show_test.exs
    - test/mix/tasks/threadline.incident_test.exs
    - test/mix/tasks/threadline/export_test.exs
    - test/threadline/capture/trigger_changed_from_test.exs
    - test/threadline/capture/trigger_context_test.exs
    - test/threadline/capture/trigger_redaction_test.exs
    - test/threadline/capture/trigger_test.exs
    - test/threadline/evidence/proof_test.exs
    - test/threadline/governance/evidence_record_test.exs
    - test/threadline/operator_surface/breadcrumb_test.exs
    - test/threadline/operator_surface/copy_contract_test.exs
    - test/threadline/operator_surface/exports_mix_parity_test.exs
    - test/threadline/operator_surface/live/row_history_live_test.exs
    - test/threadline/operator_surface/row_history_component_test.exs
    - CONTRIBUTING.md

key-decisions:
  - "Followed 198-08's port recipe mechanically for all 14 files: append repo_opts() as the trailing opts arg on every Ecto call naming a Threadline-owned schema; add import Threadline.StorageSchemaCase only to modules that use bare ExUnit.Case (DataCase already imports it)."
  - "Left all raw SQL in the trigger test files untouched except none needed changing -- the ~60 raw-SQL sites target public fixture tables or resolve storage schema internally via TriggerSQL, and trigger_test.exs:110's one audit-table raw SQL was already schema-qualified (threadline.audit_transactions) and stayed that way."
  - "mix ci.all's verify.example failure (examples/threadline_phoenix DemoContractTest, demo-seed data assertions) is documented as an out-of-scope pre-existing gap rather than fixed -- it is not an undefined_table/storage_schema defect, it is unrelated demo-seed content drift, and fixing it was never in this plan's files_modified list. Recorded in deferred-items.md and WINDOWS.md rather than silently claimed as green."

requirements-completed: [GREEN-04]

coverage:
  - id: D1
    description: "9 remaining use Threadline.DataCase files ported to repo_opts() (34 failing -> 0)"
    requirement: "GREEN-04"
    verification:
      - kind: unit
        ref: "mix test test/mix/tasks/ test/threadline/capture/ test/threadline/evidence/ test/threadline/governance/"
        status: pass
    human_judgment: false
  - id: D2
    description: "5 remaining non-DataCase files ported to repo_opts() with import Threadline.StorageSchemaCase added where needed (31 failing -> 0)"
    requirement: "GREEN-04"
    verification:
      - kind: unit
        ref: "mix test test/threadline/operator_surface/breadcrumb_test.exs test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/exports_mix_parity_test.exs test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/row_history_component_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "CONTRIBUTING.md List 1 gains verify-mechanical and verify-capture rows; three-way parity test green"
    requirement: "GREEN-04"
    verification:
      - kind: unit
        ref: "mix test test/threadline/phase06_nyquist_ci_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D4
    description: "Full mix test suite passes at 0 failures on two consecutive runs, anti-laundering caps stay green"
    requirement: "GREEN-04"
    verification:
      - kind: unit
        ref: "mix test (1397 tests, 0 failures, run twice) + mix test test/threadline/zero_skips_contract_test.exs test/threadline/storage_schema_prefix_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D5
    description: "mix ci.all's remaining verify.example failure is a documented, out-of-scope pre-existing gap, not silently ignored"
    verification: []
    human_judgment: true
    rationale: "This is a judgment call that the examples/threadline_phoenix demo-seed content-drift failure is genuinely unrelated to GREEN-04's storage_schema defect class and out of this plan's declared files_modified scope -- a human/future-plan should confirm that framing before closing the phase."

duration: ~65min
completed: 2026-08-28
status: complete
---

# Phase 198 Plan 12: Gap Closure to Zero Failures Summary

**Ported the remaining 14 defective test files to `Threadline.StorageSchemaCase.repo_opts()`, landed CONTRIBUTING.md's two missing List 1 rows, and drove `mix test` from 67 failures to 0 (1397 tests) across two consecutive runs — GREEN-04 met on its own terms.**

## Performance

- **Duration:** ~65 min
- **Started:** 2026-08-28 (approx, worktree base 6970cff7)
- **Completed:** 2026-08-28
- **Tasks:** 3
- **Files modified:** 15 (14 test files + CONTRIBUTING.md)

## Accomplishments

- Ported all 9 remaining `use Threadline.DataCase` files (mix-task tests, capture/trigger tests, evidence/governance tests) to append `repo_opts()` on every Ecto call naming a Threadline-owned schema. 34 failures → 0. Confirmed the two mix-task files' `@repo.insert!(...)` module-attribute call sites (the documented gotcha) were both caught. Confirmed the ~60 raw-SQL sites in the four trigger test files targeting `public` fixture tables and the one already-schema-qualified `trigger_test.exs:110` raw SQL against `threadline.audit_transactions` needed no change.
- Ported all 5 remaining non-`DataCase` files (`breadcrumb_test.exs`, `exports_mix_parity_test.exs`, both modules of `row_history_live_test.exs`, `row_history_component_test.exs`) — each got `import Threadline.StorageSchemaCase` added to its bare `use ExUnit.Case` module before porting call sites. `copy_contract_test.exs` confirmed as `use Threadline.DataCase` (no import needed) per the plan's explicit instruction to verify before adding one. 31 failures → 0.
- Added the two unowned rows (`verify-mechanical`, `verify-capture`) to CONTRIBUTING.md's List 1 `| Job key | Purpose |` table in `ci.yml` job order, and deleted the two dangling references to the GREEN-10-deleted `.github/workflows/hex-publish.yml` (the List 1 section intro and the release-runbook "Legacy fallback" sentence).
- `mix test` now passes 1397 tests, 0 failures (1 excluded — `pgbouncer_topology`), confirmed on two independent consecutive runs.
- `test/threadline/zero_skips_contract_test.exs`, `test/threadline/phase06_nyquist_ci_contract_test.exs`, and `test/threadline/storage_schema_prefix_contract_test.exs` all green throughout.

## Task Commits

Each task was committed atomically:

1. **Task 1: Port the 9 remaining `use Threadline.DataCase` files** - `19168428` (fix)
2. **Task 2: Port the 5 remaining files that need an added import** - `1393c69c` (fix)
3. **Task 3: Land the unowned CONTRIBUTING List 1 parity rows and drive the suite to zero** - `20528f87` (docs)

**Plan metadata:** commit pending (this SUMMARY + REQUIREMENTS.md)

## Files Created/Modified

- `test/mix/tasks/threadline.evidence_show_test.exs` — `repo_opts()` on `delete_all`/`insert!`
- `test/mix/tasks/threadline.incident_test.exs` — `repo_opts()` on both `@repo.insert!` module-attribute sites
- `test/mix/tasks/threadline/export_test.exs` — `repo_opts()` on both `@repo.insert!` sites
- `test/threadline/capture/trigger_changed_from_test.exs` — `repo_opts()` on all 14 `delete_all`/`all`/`one!` sites
- `test/threadline/capture/trigger_context_test.exs` — `repo_opts()` on both `Repo.all(AuditTransaction)` sites
- `test/threadline/capture/trigger_redaction_test.exs` — `repo_opts()` on all 8 `delete_all`/`all`/`one!` sites
- `test/threadline/capture/trigger_test.exs` — `repo_opts()` on all 10 `all`/`delete_all`/`aggregate` sites; line 110's schema-qualified raw SQL against `threadline.audit_transactions` left untouched
- `test/threadline/evidence/proof_test.exs` — `repo_opts()` on `delete_all`/`insert!`
- `test/threadline/governance/evidence_record_test.exs` — `repo_opts()` on `delete_all`/`insert!`/`aggregate`
- `test/threadline/operator_surface/breadcrumb_test.exs` — `import Threadline.StorageSchemaCase` added; `repo_opts()` on both `insert!` sites
- `test/threadline/operator_surface/copy_contract_test.exs` — `repo_opts()` on all 5 `delete_all`/`insert!` sites (already `use Threadline.DataCase`)
- `test/threadline/operator_surface/exports_mix_parity_test.exs` — `import Threadline.StorageSchemaCase` added; `repo_opts()` on all 5 `delete_all`/`insert!` sites
- `test/threadline/operator_surface/live/row_history_live_test.exs` — `import Threadline.StorageSchemaCase` added to both `RowHistoryLiveTest` and `RowHistoryLiveScopedTest` modules; `repo_opts()` on all 10 sites
- `test/threadline/operator_surface/row_history_component_test.exs` — `import Threadline.StorageSchemaCase` added; `repo_opts()` on all 5 sites
- `CONTRIBUTING.md` — added `verify-mechanical` and `verify-capture` rows to List 1; deleted two dangling `hex-publish.yml` references

## Decisions Made

See `key-decisions` in frontmatter. In short: applied the 198-08 port recipe mechanically and verbatim across all 14 files; verified each file's `use` line before deciding whether it needed the import; left the `mix ci.all` `verify.example` failure (unrelated example-app demo-seed content drift) as a documented gap rather than expanding scope to fix it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Ran `mix deps.get` in the root repo and in `examples/threadline_phoenix`**
- **Found during:** Task 1 setup and Task 3's full-suite run
- **Issue:** Neither the root worktree's `deps/` nor `examples/threadline_phoenix/deps/` were populated at plan start; `mix test` and the `verify.example` step of `mix ci.all` both failed with "the dependency is not available, run mix deps.get" for already-declared deps.
- **Fix:** Ran `mix deps.get` in both directories (already-declared deps only, no new packages added, per the Rule 3 package-manager-install exclusion — these are pre-existing `mix.lock`-pinned deps, not a new/unverified package name).
- **Files modified:** none tracked (`deps/` is gitignored in both projects; `mix.lock` unchanged)
- **Verification:** `mix test` and the example app's own test run both proceeded past the dependency error afterward.
- **Committed in:** N/A (no file changes to commit; environment setup only)

---

**Total deviations:** 1 auto-fixed (1 blocking — environment setup, package-manager install of already-declared deps)
**Impact on plan:** No scope creep. Required to run any test in this worktree.

## Known Stubs

None.

## Threat Flags

None — no new security-relevant surface introduced; all changes are test-side Ecto call-site opts and a documentation table edit.

## Issues Encountered

- `mix ci.all`'s `verify.example` step fails on `examples/threadline_phoenix`'s `ThreadlinePhoenix.DemoContractTest` (5-9 failures depending on run, e.g. `SEED-03 manifest heroes...`, `D-05 persona setup actor attribution org_memberships...`). This reproduces standalone in the example app (`cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix/demo_contract_test.exs`) and is unrelated to the `undefined_table` / storage_schema defect class this plan targets — these are `Ecto.NoResultsError` / assertion mismatches against `mix demo.seed`'s generated content, not missing-schema-prefix errors. It matches the recurring "example precommit demo-seed/walkthrough failures" pattern already acknowledged & deferred across Phases 177, 179, 180, and 182 in `.planning/STATE.md`. Documented in `.planning/phases/198-green-bringup/deferred-items.md` and appended to `.planning/WINDOWS.md` (kind: deviation, phase 198, status: open) rather than silently claimed as resolved. `mix test` (root, the GREEN-04 headline) is unaffected and passes cleanly.
- Also resolved (fixed, not just documented): `.planning/WINDOWS.md` entry #2, a pre-existing open entry from Plan 198-06 recording `test/threadline/phase06_nyquist_ci_contract_test.exs`'s red state due to the same CONTRIBUTING.md List 1 drift this plan's Task 3 closed — marked `fixed` via `gsd-tools windows fixed 2` since the test is now green.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- GREEN-04's headline claim — `mix test` passes with no deterministically-failing tests, each former failure fixed on its merits, no skip/exclude/delete/weaken — is met and verified twice.
- The one remaining `mix ci.all` gap (example-app demo-seed content drift) is explicitly out of this plan's scope and documented for a future plan/phase to pick up if the maintainer decides to prioritize it; it does not block GREEN-04 or the root-repo green-bringup goal.
- Anti-laundering caps (`zero_skips_contract_test.exs`, `storage_schema_prefix_contract_test.exs`) stay green; no `search_path`, `default_options/1`, or `prefix: "threadline"` literal was introduced anywhere in `config/`, `test/support/`, or `lib/`.

---
*Phase: 198-green-bringup*
*Completed: 2026-08-28*

## Self-Check: PASSED

- FOUND: test/mix/tasks/threadline.evidence_show_test.exs
- FOUND: test/mix/tasks/threadline.incident_test.exs
- FOUND: test/mix/tasks/threadline/export_test.exs
- FOUND: test/threadline/capture/trigger_changed_from_test.exs
- FOUND: test/threadline/capture/trigger_context_test.exs
- FOUND: test/threadline/capture/trigger_redaction_test.exs
- FOUND: test/threadline/capture/trigger_test.exs
- FOUND: test/threadline/evidence/proof_test.exs
- FOUND: test/threadline/governance/evidence_record_test.exs
- FOUND: test/threadline/operator_surface/breadcrumb_test.exs
- FOUND: test/threadline/operator_surface/copy_contract_test.exs
- FOUND: test/threadline/operator_surface/exports_mix_parity_test.exs
- FOUND: test/threadline/operator_surface/live/row_history_live_test.exs
- FOUND: test/threadline/operator_surface/row_history_component_test.exs
- FOUND: CONTRIBUTING.md
- FOUND: .planning/phases/198-green-bringup/deferred-items.md
- FOUND commits: 19168428, 1393c69c, 20528f87 (git log --oneline)
