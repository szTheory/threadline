---
phase: 247-ci-critical-path-and-suite-lanes
plan: 12
subsystem: ci
status: complete
tags: [ci, partitions, weights, d-11, ci-03]
requires:
  - phase: 247-08
    provides: "partition-timings-current-<run> artifacts from 3 main runs (247-OBSERVATION.md)"
provides:
  - "test/partition_weights.txt from CI current-lane per-file medians"
  - "ASYNC_FACTOR_PERMILLE=292 in bin/ci-test-partitions, fitted by least squares from the same TSVs"
affects: [247-13, 247-11]
tech-stack:
  added: []
  patterns:
    - "Weights come from CI TSVs via --ingest-weights --lane current; --write-weights stays the offline fallback"
    - "Async factor is a named, evidence-commented constant passed to awk with -v"
key-files:
  created: []
  modified:
    - test/partition_weights.txt
    - bin/ci-test-partitions
decisions:
  - "Async factor fitted at k=0.2918 (292 permille) over 12 points (3 runs x 4 current-lane partitions); residual RMS 13994 ms"
  - "stress_router_test.exs split NOT triggered: 74510 ms vs even share 321223 ms (23.2 %); no stress_router files changed"
  - "One weights file from current-lane timings; per-lane weights stay a 247-13 decision from data"
  - "bin/measure-main-ci gh >= 2.101 --allow-escape-sequences fix left for 247-13 (this plan did not touch measure-main-ci)"
metrics:
  duration: "~15 min"
  completed: 2026-10-26
  tasks: 3
  files: 2
actuals:
  tokens: 9000
  tasks: 3
  commits: 2
plan_head_before: 47cf0cde6495735b7be582f3c8419687c09e54f9
plan_head_after: c87eaecce244419e55f55394e328b32652815780
requirements: [CI-03]
---

# Phase 247 Plan 12: D-11 partition balance Summary

The partition weights now come from CI current-lane medians over 3 main runs. The guessed 1/4 async factor is replaced by a least-squares fit (k=0.292). The stress_router split was not needed: the file is 23 % of an even share. Both local suites are green on the new partition mix.

## Inputs

Artifacts `partition-timings-current-<run>` for main runs **40394247390**, **40396194471** and **40398138085**. They were downloaded read-only into the session scratch dir and never into `.planning/`. Each holds 4 TSVs whose header is `# threadline.partition-timings/1 partition=<i> lane=current boot_ms=… wall_ms=…`. None had expired, so no substitution was needed.

## Task 1: weights refresh (tracer)

`bin/ci-test-partitions --ingest-weights <scratch>/threadline-247-weights --lane current` printed:

```
ingest-weights: 269 files from 12 TSVs (0 skipped by --lane)
```

268 of the 269 rows changed. The header block and path order are unchanged. 178 rows moved by more than 2x. The full list is at the end of this file. The largest moves:

| File | Old ms | New ms |
|------|-------:|-------:|
| deps_audit_gate_test.exs | 2960 | 114759 |
| browser_full_projects_contract_test.exs | 17230 | 88492 |
| operator_surface/stress_router_prod_compile_test.exs | 26460 | 65567 (247-OBSERVATION predicted the 2.6x under-weight) |
| retry_network_contract_test.exs | 1300 | 35608 |
| ci_workflow_parity_contract_test.exs | 5378 | 38771 |
| deps_health_report_test.exs | 3270 | 31770 |
| repo_contract_scope_contract_test.exs | 39 | 25842 |

The old weights were Mac-warm and traced, so most small contract files were near 0 ms. On CI they are seconds each, because their walls overlap under async.

**Predicted assignment (N=4).** The script's own `assign_files` ran from a scratch copy of the function block.

| Async factor | P1 ms | P2 ms | P3 ms | P4 ms | max/min |
|--------------|------:|------:|------:|------:|--------:|
| 1/4 (Task 1, before the fit) | 161905 | 161905 | 161904 | 161904 | 1.000 |
| 292 permille (after Task 2) | 170822 | 170821 | 170821 | 170821 | 1.000 |

With the fitted factor, the four heaviest files each land in a different partition:

| File | Partition | Effective ms |
|------|----------:|-------------:|
| stress_router_test.exs | P1 | 74510 |
| stress_router_prod_compile_test.exs | P2 | 65567 |
| deps_audit_gate_test.exs | P3 | 33509 |
| browser_full_projects_contract_test.exs | P2 | 25839 |

Verify: `ci_topology_contract_test.exs` passed 26/0 on PG16, the header is present, and commit `5ba88242` touches only the weights file.

## Task 2: fitted async factor

Each point is one run r and one partition p, with:
- y = header `wall_ms` − `boot_ms`
- S = summed `wall_ms` of the sync files
- A = summed `wall_ms` of the async files

Files are classified by the script's own `use …, async: true` grep, and no rows went unclassified. The fit is k = Σ(y−S)·A / ΣA² over the 12 points. The awk program `fit.awk` was kept in the scratch dir and run as `awk -v flagsfile=<flags> -f fit.awk <flags> <12 TSVs>`:

```
40394247390/partition-timings-1.tsv y=169742 S=110739 A=290791 pred=195579 resid=-25837
40394247390/partition-timings-2.tsv y=146379 S=103616 A=223815 pred=168915 resid=-22536
40394247390/partition-timings-3.tsv y=218477 S=101331 A=365246 pred=207893 resid=10583
40394247390/partition-timings-4.tsv y=180008 S=148288 A=120908 pred=183563 resid=-3555
40396194471/partition-timings-1.tsv y=182866 S=118701 A=237153 pred=187891 resid=-5025
40396194471/partition-timings-2.tsv y=158138 S=114781 A=148945 pred=158236 resid=-98
40396194471/partition-timings-3.tsv y=230864 S=88699 A=401063 pred=205711 resid=25152
40396194471/partition-timings-4.tsv y=196153 S=163143 A=113777 pred=196338 resid=-185
40398138085/partition-timings-1.tsv y=111506 S=74507 A=175438 pred=125692 resid=-14186
40398138085/partition-timings-2.tsv y=100985 S=70700 A=118459 pred=105261 resid=-4276
40398138085/partition-timings-3.tsv y=151720 S=58601 A=275427 pred=138958 resid=12761
40398138085/partition-timings-4.tsv y=135824 S=114474 A=83739 pred=138905 resid=-3081
points=12 k=0.2918 permille=292 residualRMS=13994 ms missing_rows=0
```

k is within the [0.05, 1.0] clamp, so it was installed:
- `ASYNC_FACTOR_PERMILLE=292` sits beside an evidence comment (date, method, the 3 run ids, k, residual).
- awk now computes `int(raw * async_factor_permille / 1000)`, with the factor passed by `-v`.
- The `int(raw / 4)` literal is gone, and `ASYNC_FACTOR` appears 9 times.

The residuals are systematic: partition 3 is under-predicted (+10 to +25 s) and partitions 1 and 2 over-predicted. A single global factor cannot capture which async files overlap with which. This is the honest limit of the D-11 model, and 247-13 measures whether it reaches ≤ 1.15 on CI.

Self-test case **(x)** was added and listed in the header and the `ok (…)` line:
- At `ASYNC_FACTOR_PERMILLE=250` the sandbox assignment must equal the literal output of the pre-change script.
- At the default constant, the async file must weigh 40000 × factor / 1000.

A mutation check that swapped in `int(raw / 3)` made the self-test fail. `bin/ci-test-partitions --self-test` passes under the default bash and under `/bin/bash` 3.2. Shellcheck shows the same findings as HEAD; an SC2030/2031 note from a subshell assignment was avoided by using an env-prefix call. Commit `c87eaecc`.

## Task 3: conditional split and suites

**Split not triggered: 74510 ≤ 321223.** The even share is Σ refreshed raw weights 1284894 / 4, and `stress_router_test.exs` is 23.2 % of it. Measured against the effective share (async scaled, 170821), it is still under: 43.6 %. No stress_router files changed, and no support module was created. `test/partition_colocate.txt` is untouched.

Suites, run on an ephemeral `postgres:16` container labelled `dev.threadline.plan=247-12` (since removed):

- `mix verify.test_partitioned`: exit 0. Partitions took 72 / 64 / 106 / 115 s (786 / 813 / 913 / 859 tests, 0 failures). Total 117 s. **Local max/min 1.80.** The weights are CI-derived, so Mac-local balance does not follow them. The ≤ 1.15 target is a CI measurement (247-13).
- `mix verify.test`: 32 properties, 3371 tests, 0 failures, 3 excluded (285.1 s).
- `mix compile --warnings-as-errors`, `mix verify.format` and `mix verify.credo` are clean.

Task 3 changed no code, so it has no commit.

## Deviations from Plan

None. The plan ran as written. Two small choices:
- The predicted assignment was computed by sourcing the script's function block from a scratch copy, which is one of the two options the plan allows.
- The new self-test case is lettered (x), because (a)-(w) were already taken.

## Deferred

- The `bin/measure-main-ci --ratios` failure on gh ≥ 2.101 (`--allow-escape-sequences`) was not touched. This plan's scope does not include measure-main-ci, so the fix goes to 247-13, which runs it for D-12.

## Known Stubs

None.

## Moved >2x (178 rows, old -> new ms)

<details><summary>Full list</summary>

```
346 -> 135 test/mix/tasks/threadline/gen_row_history_index_test.exs
59 -> 270 test/mix/tasks/threadline/install_test.exs
1 -> 71 test/threadline/actor_reads_doc_contract_test.exs
0 -> 73 test/threadline/adoption_evidence_playbook_doc_contract_test.exs
1 -> 103 test/threadline/adoption_pilot_doc_contract_test.exs
0 -> 1 test/threadline/application_test.exs
0 -> 49 test/threadline/audit_doc_contract_test.exs
0 -> 24 test/threadline/audit_indexing_doc_contract_test.exs
1448 -> 11224 test/threadline/branch_protection_comparison_contract_test.exs
4 -> 287 test/threadline/brandbook_token_parity_test.exs
17230 -> 88492 test/threadline/browser_full_projects_contract_test.exs
800 -> 14472 test/threadline/browser_journey_evidence_contract_test.exs
328 -> 2608 test/threadline/capture/naming_property_test.exs
1 -> 8 test/threadline/capture/naming_test.exs
1842 -> 4163 test/threadline/capture/notice_guard_canary_test.exs
4 -> 18 test/threadline/capture/notice_guard_test.exs
312 -> 11114 test/threadline/capture/public_sql_contract_test.exs
11 -> 168 test/threadline/capture/redaction_policy_property_test.exs
4 -> 20 test/threadline/capture/trigger_body_invariants_test.exs
0 -> 56 test/threadline/capture/trigger_capture_config_test.exs
2989 -> 1418 test/threadline/capture/trigger_rerun_property_test.exs
0 -> 14 test/threadline/capture/trigger_sql_storage_schema_test.exs
8 -> 237 test/threadline/capture_semantics_boundary_test.exs
376 -> 2739 test/threadline/change_diff_property_test.exs
3 -> 444 test/threadline/changelog_contract_test.exs
101 -> 1077 test/threadline/ci_action_pin_contract_test.exs
8 -> 421 test/threadline/ci_action_runtime_contract_test.exs
7 -> 86 test/threadline/ci_all_dedup_contract_test.exs
77 -> 1374 test/threadline/ci_attestation_contract_test.exs
2169 -> 15263 test/threadline/ci_coverage_doc_contract_test.exs
542 -> 7886 test/threadline/ci_issue_upsert_contract_test.exs
955 -> 7253 test/threadline/ci_sha_gate_contract_test.exs
451 -> 10269 test/threadline/ci_token_permissions_contract_test.exs
124 -> 8392 test/threadline/ci_topology_contract_test.exs
5378 -> 38771 test/threadline/ci_workflow_parity_contract_test.exs
451 -> 9462 test/threadline/cloak_advisory_reachability_contract_test.exs
11 -> 213 test/threadline/code_walkthrough_doc_contract_test.exs
14 -> 417 test/threadline/community_health_contract_test.exs
33 -> 1116 test/threadline/community_health_render_contract_test.exs
69 -> 11220 test/threadline/credo_config_contract_test.exs
800 -> 10491 test/threadline/date_release_changelog_test.exs
15 -> 2199 test/threadline/dep_floor_guard_test.exs
439 -> 15613 test/threadline/dependabot_config_contract_test.exs
7 -> 344 test/threadline/deps_audit_contract_test.exs
2960 -> 114759 test/threadline/deps_audit_gate_test.exs
4 -> 1317 test/threadline/deps_health_doc_contract_test.exs
3270 -> 31770 test/threadline/deps_health_report_test.exs
15 -> 4898 test/threadline/dialyzer_ignore_contract_test.exs
1646 -> 6007 test/threadline/doc_rubric_contract_test.exs
99 -> 297 test/threadline/doc_spec_coverage_contract_test.exs
555 -> 7497 test/threadline/e2e_preflight_contract_test.exs
1 -> 159 test/threadline/evaluating_threadline_doc_contract_test.exs
2 -> 45 test/threadline/evidence/subject_test.exs
3 -> 41 test/threadline/evidence_cli_doc_contract_test.exs
380 -> 168 test/threadline/evidence_test.exs
7 -> 391 test/threadline/example_phoenix_readme_contract_test.exs
1 -> 89 test/threadline/example_phoenix_schemas_mount_contract_test.exs
1 -> 34 test/threadline/exploration_routing_doc_contract_test.exs
293 -> 2274 test/threadline/export_property_test.exs
15 -> 261 test/threadline/export_queue/oban_test.exs
7 -> 111 test/threadline/facade_naming_contract_test.exs
214 -> 11168 test/threadline/facade_only_references_contract_test.exs
508 -> 5545 test/threadline/flake_classifier_contract_test.exs
377 -> 22584 test/threadline/formatter_topology_contract_test.exs
4 -> 648 test/threadline/getting_started_fixtures_test.exs
4 -> 429 test/threadline/getting_started_saas_doc_contract_test.exs
71 -> 12491 test/threadline/guide_graph_contract_test.exs
3 -> 53 test/threadline/guides/redaction_contract_test.exs
1 -> 22 test/threadline/guides/stability_contract_test.exs
0 -> 54 test/threadline/guides/table_shapes_contract_test.exs
3 -> 56 test/threadline/health/policy_test.exs
6 -> 512 test/threadline/health_findings_doc_contract_test.exs
50 -> 1662 test/threadline/hex_pin_contract_test.exs
1 -> 125 test/threadline/how_threadline_works_doc_contract_test.exs
2 -> 26 test/threadline/ignore_advisories_contract_test.exs
1 -> 201 test/threadline/incident_playbook_doc_contract_test.exs
1 -> 287 test/threadline/integration_contracts_doc_contract_test.exs
0 -> 69 test/threadline/integrations/phx_gen_auth_doc_contract_test.exs
2 -> 303 test/threadline/integrations/phx_gen_auth_integration_test.exs
1 -> 119 test/threadline/integrations/sigra_doc_contract_test.exs
2 -> 297 test/threadline/integrations/sigra_test.exs
4 -> 154 test/threadline/job_test.exs
8 -> 7511 test/threadline/layer_boundary_contract_test.exs
10 -> 597 test/threadline/local_docker_dx_contract_test.exs
3 -> 305 test/threadline/lookup_return_shapes_contract_test.exs
633 -> 9652 test/threadline/main_ci_observer_contract_test.exs
1913 -> 16444 test/threadline/measure_main_ci_contract_test.exs
8 -> 1621 test/threadline/mix/migration_version_test.exs
1 -> 18 test/threadline/mix/migrations_path_test.exs
172 -> 1377 test/threadline/mix/trigger_migration_property_test.exs
27 -> 8392 test/threadline/mix/trigger_migration_test.exs
10 -> 2357 test/threadline/no_warn_undefined_contract_test.exs
3 -> 72 test/threadline/not_found_error_test.exs
1 -> 22 test/threadline/operator_surface/auth_test.exs
22 -> 5545 test/threadline/operator_surface/component_contract_test.exs
11 -> 593 test/threadline/operator_surface/coverage/on_mount_test.exs
0 -> 468 test/threadline/operator_surface/data_state_mapping_wave0_test.exs
0 -> 74 test/threadline/operator_surface/export_auth_plug_test.exs
2 -> 161 test/threadline/operator_surface/exports/filename_test.exs
6 -> 790 test/threadline/operator_surface/exports_doc_contract_test.exs
5 -> 110 test/threadline/operator_surface/gating_test.exs
169 -> 340 test/threadline/operator_surface/live/row_history_live_test.exs
200 -> 6558 test/threadline/operator_surface/operator_evidence_contract_test.exs
414 -> 14804 test/threadline/operator_surface/operator_surface_fixture_contract_test.exs
0 -> 625 test/threadline/operator_surface/page_header_test.exs
2 -> 402 test/threadline/operator_surface/pager_test.exs
5 -> 37 test/threadline/operator_surface/policy_show_doc_contract_test.exs
0 -> 561 test/threadline/operator_surface/presentation_test.exs
970 -> 15097 test/threadline/operator_surface/router_test.exs
0 -> 1 test/threadline/operator_surface/session_plug_test.exs
58 -> 11741 test/threadline/operator_surface/storybook_boundary_test.exs
130 -> 1040 test/threadline/operator_surface/stress_fixtures_test.exs
122 -> 401 test/threadline/operator_surface/stress_ledger_test.exs
26460 -> 65567 test/threadline/operator_surface/stress_router_prod_compile_test.exs
11 -> 1381 test/threadline/operator_surface/style_byte_lock_test.exs
75 -> 10513 test/threadline/operator_surface/style_contract_test.exs
0 -> 46 test/threadline/operator_surface/surface_header_csp_test.exs
545 -> 243 test/threadline/operator_surface/surface_header_test.exs
5 -> 1791 test/threadline/operator_surface/timeline_browse_doc_contract_test.exs
183 -> 657 test/threadline/operator_surface/transaction_live_test.exs
34 -> 1371 test/threadline/operator_surface/ui_form_policy_contract_test.exs
0 -> 685 test/threadline/operator_surface/ui_stress_test.exs
44 -> 1811 test/threadline/operator_surface/ui_test.exs
2 -> 64 test/threadline/operator_surface_doc_contract_test.exs
6 -> 340 test/threadline/option_allowlist_test.exs
75 -> 16187 test/threadline/optional_deps_contract_test.exs
5200 -> 17726 test/threadline/partition_monitor_test.exs
0 -> 42 test/threadline/performance_doc_contract_test.exs
0 -> 40 test/threadline/persona_routing_doc_contract_test.exs
114 -> 0 test/threadline/pgbouncer_topology_test.exs
34 -> 5835 test/threadline/planning_dependency_contract_test.exs
1 -> 36 test/threadline/plug_test.exs
8 -> 367 test/threadline/policy/redaction_presenter_test.exs
0 -> 18 test/threadline/production_checklist_doc_contract_test.exs
1153 -> 12447 test/threadline/property_generator_coverage_test.exs
69 -> 6892 test/threadline/property_scale_contract_test.exs
165 -> 1886 test/threadline/query/cursors_property_test.exs
3 -> 42 test/threadline/query/filter_params_test.exs
16 -> 431 test/threadline/query/row_key_validation_test.exs
3638 -> 1786 test/threadline/query_test.exs
0 -> 26 test/threadline/release_ci_gate_contract_test.exs
14 -> 1362 test/threadline/release_control_plane_contract_test.exs
1 -> 18 test/threadline/release_distribution_doc_contract_test.exs
785 -> 15438 test/threadline/removed_artifact_contract_test.exs
39 -> 25842 test/threadline/repo_contract_scope_contract_test.exs
227 -> 2211 test/threadline/repo_hygiene_contract_test.exs
10976 -> 24078 test/threadline/repo_hygiene_guard_test.exs
2 -> 82 test/threadline/retention/policy_test.exs
227 -> 747 test/threadline/retention/pruner_test.exs
1300 -> 35608 test/threadline/retry_network_contract_test.exs
52 -> 1710 test/threadline/row_history_focus_evidence_contract_test.exs
2 -> 203 test/threadline/schema_fields_contract_test.exs
0 -> 1 test/threadline/semantics/actor_ref_test.exs
9 -> 50 test/threadline/semver_adopter_doc_contract_test.exs
89 -> 5696 test/threadline/source_comment_location_contract_test.exs
8 -> 2074 test/threadline/source_family_test.exs
220 -> 13798 test/threadline/source_size_contract_test.exs
7 -> 2456 test/threadline/storage/local_test.exs
7 -> 195 test/threadline/storage/s3_test.exs
175 -> 20618 test/threadline/storage_schema_call_site_contract_test.exs
3 -> 33 test/threadline/storage_schema_migration_contract_test.exs
190 -> 483 test/threadline/storage_schema_prefix_contract_test.exs
14 -> 38 test/threadline/storage_schema_test.exs
0 -> 44 test/threadline/strict_rfc4180_test.exs
0 -> 15 test/threadline/support_playbook_doc_contract_test.exs
3 -> 164 test/threadline/telemetry_doc_contract_test.exs
0 -> 42 test/threadline/telemetry_helpers_test.exs
229 -> 2624 test/threadline/temp_leak_check_test.exs
76 -> 14911 test/threadline/test_structure_contract_test.exs
3 -> 1485 test/threadline/ui_critic_retirement_doc_contract_test.exs
1 -> 362 test/threadline/upgrade_path_doc_contract_test.exs
2 -> 87 test/threadline/upgrading_to_0_11_doc_contract_test.exs
4 -> 127 test/threadline/upgrading_to_1_0_doc_contract_test.exs
1777 -> 6625 test/threadline/verify_action_pins_test.exs
1 -> 41 test/threadline/verify_coverage_policy_test.exs
3363 -> 7840 test/threadline/verify_coverage_task_test.exs
13 -> 1241 test/threadline/version_truth_doc_contract_test.exs
1357 -> 4660 test/threadline/zero_skips_contract_test.exs
```

</details>

## Self-Check: PASSED

- FOUND: test/partition_weights.txt, bin/ci-test-partitions
- FOUND: commits 5ba88242, c87eaecc on HEAD
