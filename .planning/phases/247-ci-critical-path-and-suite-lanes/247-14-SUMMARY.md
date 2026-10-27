---
phase: 247-ci-critical-path-and-suite-lanes
plan: 14
subsystem: ci
status: complete
tags: [ci, lane-weights, partitions, gap-closure]
requires:
  - phase: 247-13
    provides: "B2 main timing artifacts and CI-03 numeric miss"
provides:
  - "Per-lane measured weights, strict three-run ingestion, explicit routing and adversarial guards"
affects: [247-15, 247-verification]
tech-stack:
  added: []
  patterns: [strict-explicit-output, atomic-weight-replacement]
key-files:
  created: [test/partition_weights_min.txt, test/partition_weights_latest.txt]
  modified: [bin/ci-test-partitions, test/partition_weights.txt, test/threadline/ci_topology_contract_test.exs]
key-decisions:
  - "Keep async factor 292; new current-only fit reduces residual RMS by only 2.1 percent"
  - "Preserve valid zero-ms observations and floor generated median weights to 1 ms"
requirements-completed: []
requirements-implemented: [CI-03]
coverage:
  - id: lane-weights
    description: "Measured lane weights are selected and every file is assigned exactly once"
    requirement: CI-03
    verification:
      - kind: integration
        ref: "bin/ci-test-partitions --self-test (Bash 5 and /bin/bash 3.2)"
        status: pass
      - kind: integration
        ref: "mix verify.test_partitioned, full and min/toolchain"
        status: pass
    human_judgment: false
actuals:
  tokens: 19736
  tasks: 3
  commits: 6
duration: 14min
completed: 2026-10-27
---

# Phase 247 Plan 14 Summary

**Each CI lane selects weights derived from its own three B2 main runs, with strict artifact inventory checks and atomic replacement.**

Completed: 2026-10-27T00:46:35.633460+00:00. Three tasks executed. CI-03 remains unmet until Plan 15 measures main; no numeric gate is inferred from local predictions.

## Artifact provenance

Read-only API checks reconfirmed successful attempt 1, main branch and head `29abf5653a0e1c31b70d73d71a3f6c552d9b9712` for `40413601357`, `40414924903`, `40416330436`. All nine exact `partition-timings-<lane>-<run>` artifacts remain unexpired (14-day retention, expires November 9); downloaded separately under scratch `threadline-247-lane-weights/<lane>/<run>/<lane>/`. No substitution or B1 data. Each lane ingestion used 12 TSVs from three distinct four-partition runs; min/latest 206 files each, current 269 files. Task 1 left current weights byte-identical until Task 2 refreshed them. Files retain the same six-line header and path-sorted format.

## Predictions and factor decision

| Lane | Predicted loads p1/p2/p3/p4 (ms) | max/min | Raw even share / heaviest file (ms) |
|---|---|---|---|
| min | 102060 / 102059 / 102059 / 102059 | 1.000010 | 149441.75 / 79489 |
| latest | 103290 / 103289 / 103289 / 103289 | 1.000010 | 153151.50 / 88678 |
| current | 183268 / 183268 / 183268 / 183267 | 1.000005 | 352570 / 101008 |

The D-11 single-file split condition remains false on all actual inputs. Fresh current-only least-squares fit using the same formula yields k=0.310265 and residual RMS 21327.78 ms, versus 21791.77 ms at 0.292 (2.1% reduction). Retained 292 because the improvement is not material. No monitor, watchdog, N=4, colocation, test-helper exclusions, or workflow changes.

## Verification

- Both Bash 5 and macOS `/bin/bash` 3.2 self-tests exit 0 with `lane-min-routing`, `lane-all-routing`, `lane-assignment-mutation`, and `lane-ingest-integrity` markers. Existing failure propagation, hang/TERM/KILL, summary and warning-only ratio cases remain green.
- Focused topology and scope contracts: **44 tests, 0 failures**. Formatting and Credo pass (`5691 mods/funs, found no issues`). `git diff --check` clean.
- Full local `mix verify.test_partitioned`: **269 files exactly once; 32 properties, 3381 tests, 0 failures**, four rows 963/776/905/737 tests. Partition seconds 68/70/65/97, whole step 98 s, local ratio **1.49** (warning, no numeric pass claim).
- Min/toolchain `mix verify.test_partitioned`: **206 files exactly once; 32 properties, 2561 tests, 0 failures**, four rows 504/691/534/832 tests; 63 repo contracts filtered, current/local inventory unchanged. Seconds 56/37/77/121, whole step 122 s, local ratio **3.27** (warning). Local timing is not main-run acceptance evidence.
- Ephemeral `postgres:16`, label `dev.threadline.plan=247-14`, published loopback port discovered with `docker port`. No assumption of port 5432.
- Independent review: `247-14-REVIEW.md`, one coverage warning resolved and no open findings after follow-up. Added sentinel-weight assignment equality and a runtime current-for-latest mutation, beyond checking printed paths.

## Task commits

```
0848c2f1 test(247-14): prove min lane weight selection fails before routing
c847368d ci(247-14): ingest complete min timing runs and route measured lane weights
86a29fc6 test(247-14): require latest lane measured weights before generation
4ebe553b ci(247-14): refresh all lane weights from post-B2 main timings
b50e9536 test(247-14): reject corrupt lane weights and interrupted refreshes
5c3d60cc ci(247-14): harden positive weights and prove atomic lane routing
```

## Deviations and issues

1. Real artifacts contain zero-ms walls for very fast/excluded modules. Accept nonnegative numeric observations, floor final medians to 1 ms (the runner already uses that minimum); committed zero/negative weights are rejected. This preserves the three-run observed inventory rather than deleting legitimate files.
2. Legacy ingestion without `--output` retains its permissive lane-filter/absent-weight semantics. Explicit output validates exactly three complete four-partition runs and exact lane inventory, disallows other output paths, and replaces in the target directory atomically.
3. A sandboxed scoped run failed only because CleanCheckoutContractTest deliberately registers a temporary Git worktree and metadata writes were denied. Re-ran the complete scoped path with metadata access enabled; green results above. No code change for that failure. Process-aware self-tests likewise need unrestricted process inspection.
4. Resolved a BSD awk ternary formatting issue in the new sentinel fixture before both final Bash reruns. No production assignment change was involved.

## Current weight moves

No prior min/latest file existed, so no prior-target move lines for them. Current refresh reported:

```
ingest-weights: 269 files from 12 TSVs (0 skipped by --lane)
moved >2x: 270 -> 98 test/mix/tasks/threadline/install_test.exs
moved >2x: 24 -> 116 test/threadline/audit_indexing_doc_contract_test.exs
moved >2x: 687 -> 275 test/threadline/capture/legacy_trigger_pk_fallback_test.exs
moved >2x: 8 -> 29 test/threadline/capture/naming_test.exs
moved >2x: 1418 -> 3052 test/threadline/capture/trigger_rerun_property_test.exs
moved >2x: 14 -> 36 test/threadline/capture/trigger_sql_storage_schema_test.exs
moved >2x: 322 -> 61 test/threadline/change_diff_test.exs
moved >2x: 8392 -> 3986 test/threadline/ci_topology_contract_test.exs
moved >2x: 213 -> 716 test/threadline/code_walkthrough_doc_contract_test.exs
moved >2x: 2199 -> 706 test/threadline/dep_floor_guard_test.exs
moved >2x: 4898 -> 11389 test/threadline/dialyzer_ignore_contract_test.exs
moved >2x: 297 -> 147 test/threadline/doc_spec_coverage_contract_test.exs
moved >2x: 41 -> 103 test/threadline/evidence_cli_doc_contract_test.exs
moved >2x: 89 -> 19 test/threadline/example_phoenix_schemas_mount_contract_test.exs
moved >2x: 34 -> 115 test/threadline/exploration_routing_doc_contract_test.exs
moved >2x: 111 -> 522 test/threadline/facade_naming_contract_test.exs
moved >2x: 11168 -> 26929 test/threadline/facade_only_references_contract_test.exs
moved >2x: 56 -> 279 test/threadline/health/policy_test.exs
moved >2x: 3425 -> 1419 test/threadline/health/trigger_findings_test.exs
moved >2x: 287 -> 56 test/threadline/integration_contracts_doc_contract_test.exs
moved >2x: 69 -> 21 test/threadline/integrations/phx_gen_auth_doc_contract_test.exs
moved >2x: 119 -> 42 test/threadline/integrations/sigra_doc_contract_test.exs
moved >2x: 297 -> 47 test/threadline/integrations/sigra_test.exs
moved >2x: 2357 -> 8593 test/threadline/no_warn_undefined_contract_test.exs
moved >2x: 72 -> 24 test/threadline/not_found_error_test.exs
moved >2x: 326 -> 122 test/threadline/operator_surface/card_nesting_regression_test.exs
moved >2x: 593 -> 206 test/threadline/operator_surface/coverage/on_mount_test.exs
moved >2x: 74 -> 154 test/threadline/operator_surface/export_auth_plug_test.exs
moved >2x: 14804 -> 32162 test/threadline/operator_surface/operator_surface_fixture_contract_test.exs
moved >2x: 561 -> 238 test/threadline/operator_surface/presentation_test.exs
moved >2x: 1 -> 92 test/threadline/operator_surface/session_plug_test.exs
moved >2x: 11741 -> 32931 test/threadline/operator_surface/storybook_boundary_test.exs
moved >2x: 243 -> 1130 test/threadline/operator_surface/surface_header_test.exs
moved >2x: 332 -> 133 test/threadline/operator_surface/theme_auth_plug_test.exs
moved >2x: 685 -> 137 test/threadline/operator_surface/ui_stress_test.exs
moved >2x: 340 -> 61 test/threadline/option_allowlist_test.exs
moved >2x: 42 -> 118 test/threadline/performance_doc_contract_test.exs
moved >2x: 0 -> 1 test/threadline/pgbouncer_topology_test.exs
moved >2x: 5835 -> 2215 test/threadline/planning_dependency_contract_test.exs
moved >2x: 36 -> 3 test/threadline/plug_test.exs
moved >2x: 833 -> 1673 test/threadline/query/row_history_index_explain_test.exs
moved >2x: 846 -> 285 test/threadline/query/row_key_composite_test.exs
moved >2x: 26 -> 10 test/threadline/release_ci_gate_contract_test.exs
moved >2x: 1710 -> 615 test/threadline/row_history_focus_evidence_contract_test.exs
moved >2x: 203 -> 100 test/threadline/schema_fields_contract_test.exs
moved >2x: 50 -> 129 test/threadline/semver_adopter_doc_contract_test.exs
moved >2x: 195 -> 56 test/threadline/storage/s3_test.exs
moved >2x: 33 -> 6 test/threadline/storage_schema_migration_contract_test.exs
moved >2x: 38 -> 8 test/threadline/storage_schema_test.exs
moved >2x: 15 -> 75 test/threadline/support_playbook_doc_contract_test.exs
moved >2x: 42 -> 119 test/threadline/telemetry_helpers_test.exs
moved >2x: 362 -> 147 test/threadline/upgrade_path_doc_contract_test.exs
moved >2x: 87 -> 271 test/threadline/upgrading_to_0_11_doc_contract_test.exs
moved >2x: 6625 -> 14413 test/threadline/verify_action_pins_test.exs
moved >2x: 1241 -> 4437 test/threadline/version_truth_doc_contract_test.exs
```

## Next plan

247-15: isolated exact-head local CI gate, standing-grant PR landing and five main attempt-1 measurements. Both local ratios exceed the fixed numeric limit; only real main evidence can close CI-03. Requirements remain pending.

## Self-Check: PASSED

All three planned implementation tasks, files, ingestion counts, exact inventories, both scope executions, adversarial tests and independent review verified. This checks Plan 14 implementation only, not Phase 247 numeric acceptance.
