---
phase: 247-ci-critical-path-and-suite-lanes
verified: 2026-10-27T02:37:43Z
status: gaps_found
score: 3/4
covered_files:
    - ".github/workflows/ci.yml"
    - ".planning/ARCHIVE-REGISTER.md"
    - ".planning/REQUIREMENTS.md"
    - ".planning/ROADMAP.md"
    - ".planning/STATE.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-01-PLAN.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-01-SUMMARY.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-02-PLAN.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-02-SUMMARY.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-03-PLAN.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-03-SUMMARY.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-04-PLAN.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-04-SUMMARY.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-05-PLAN.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-05-SUMMARY.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-06-PLAN.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-06-SUMMARY.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-07-PLAN.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-07-SUMMARY.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-08-PLAN.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-08-SUMMARY.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-09-PLAN.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-09-SUMMARY.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-10-PLAN.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-10-SUMMARY.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-11-PLAN.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-11-SUMMARY.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-12-PLAN.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-12-SUMMARY.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-13-PLAN.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-13-SUMMARY.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-14-PLAN.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-14-SUMMARY.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-15-PLAN.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-15-SUMMARY.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-B3-MEASUREMENT.json"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-CONTEXT.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-LANDING.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-MEASUREMENT.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-OBSERVATION.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-REGRESSION.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-RESEARCH.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-REVIEW-DISPOSITION.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-REVIEW.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-SECURITY.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-UI-REVIEW.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/247-VALIDATION.md"
    - ".planning/phases/247-ci-critical-path-and-suite-lanes/deferred-items.md"
    - "CONTRIBUTING.md"
    - "bin/browser-full-projects"
    - "bin/ci-test-partitions"
    - "bin/measure-main-ci"
    - "examples/threadline_phoenix/e2e/package.json"
    - "examples/threadline_phoenix/e2e/playwright.config.ts"
    - "examples/threadline_phoenix/e2e/support/operator-ci-evidence.test.ts"
    - "examples/threadline_phoenix/e2e/support/operator-ci-evidence.ts"
    - "examples/threadline_phoenix/e2e/support/slow-specs.test.ts"
    - "examples/threadline_phoenix/e2e/support/slow-specs.ts"
    - "examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts"
    - "test/partition_weights.txt"
    - "test/partition_weights_latest.txt"
    - "test/partition_weights_min.txt"
    - "test/support/partition_monitor.ex"
    - "test/test_helper.exs"
    - "test/threadline/adoption_evidence_playbook_doc_contract_test.exs"
    - "test/threadline/audit_doc_contract_test.exs"
    - "test/threadline/branch_protection_comparison_contract_test.exs"
    - "test/threadline/browser_full_projects_contract_test.exs"
    - "test/threadline/browser_journey_evidence_contract_test.exs"
    - "test/threadline/changelog_contract_test.exs"
    - "test/threadline/ci_action_pin_contract_test.exs"
    - "test/threadline/ci_action_runtime_contract_test.exs"
    - "test/threadline/ci_attestation_contract_test.exs"
    - "test/threadline/ci_coverage_doc_contract_test.exs"
    - "test/threadline/ci_issue_upsert_contract_test.exs"
    - "test/threadline/ci_sha_gate_contract_test.exs"
    - "test/threadline/ci_token_permissions_contract_test.exs"
    - "test/threadline/ci_topology_contract_test.exs"
    - "test/threadline/ci_workflow_parity_contract_test.exs"
    - "test/threadline/community_health_contract_test.exs"
    - "test/threadline/community_health_render_contract_test.exs"
    - "test/threadline/date_release_changelog_test.exs"
    - "test/threadline/dependabot_config_contract_test.exs"
    - "test/threadline/deps_audit_contract_test.exs"
    - "test/threadline/deps_audit_gate_test.exs"
    - "test/threadline/deps_health_doc_contract_test.exs"
    - "test/threadline/deps_health_report_test.exs"
    - "test/threadline/e2e_preflight_contract_test.exs"
    - "test/threadline/evaluating_threadline_doc_contract_test.exs"
    - "test/threadline/evidence_cli_doc_contract_test.exs"
    - "test/threadline/example_phoenix_schemas_mount_contract_test.exs"
    - "test/threadline/exploration_routing_doc_contract_test.exs"
    - "test/threadline/flake_classifier_contract_test.exs"
    - "test/threadline/guide_graph_contract_test.exs"
    - "test/threadline/guides/redaction_contract_test.exs"
    - "test/threadline/guides/stability_contract_test.exs"
    - "test/threadline/guides/table_shapes_contract_test.exs"
    - "test/threadline/guides/upgrade_path_contract_test.exs"
    - "test/threadline/hex_pin_contract_test.exs"
    - "test/threadline/incident_playbook_doc_contract_test.exs"
    - "test/threadline/local_docker_dx_contract_test.exs"
    - "test/threadline/main_ci_observer_contract_test.exs"
    - "test/threadline/measure_main_ci_contract_test.exs"
    - "test/threadline/operator_surface/operator_evidence_contract_test.exs"
    - "test/threadline/operator_surface/operator_surface_fixture_contract_test.exs"
    - "test/threadline/operator_surface/style_contract_test.exs"
    - "test/threadline/partition_monitor_test.exs"
    - "test/threadline/performance_doc_contract_test.exs"
    - "test/threadline/persona_routing_doc_contract_test.exs"
    - "test/threadline/planning_dependency_contract_test.exs"
    - "test/threadline/planning_independence_contract_test.exs"
    - "test/threadline/playwright_fail_fast_contract_test.exs"
    - "test/threadline/production_checklist_doc_contract_test.exs"
    - "test/threadline/public_options_contract_test.exs"
    - "test/threadline/release_ci_gate_contract_test.exs"
    - "test/threadline/release_control_plane_contract_test.exs"
    - "test/threadline/release_distribution_doc_contract_test.exs"
    - "test/threadline/removed_artifact_contract_test.exs"
    - "test/threadline/repo_contract_scope_contract_test.exs"
    - "test/threadline/repo_hygiene_contract_test.exs"
    - "test/threadline/repo_hygiene_guard_test.exs"
    - "test/threadline/row_history_focus_evidence_contract_test.exs"
    - "test/threadline/semver_adopter_doc_contract_test.exs"
    - "test/threadline/support_playbook_doc_contract_test.exs"
    - "test/threadline/temp_leak_check_test.exs"
    - "test/threadline/ui_critic_retirement_doc_contract_test.exs"
    - "test/threadline/upgrading_to_0_11_doc_contract_test.exs"
    - "test/threadline/upgrading_to_1_0_doc_contract_test.exs"
    - "test/threadline/verify_action_pins_test.exs"
    - "test/threadline/version_truth_doc_contract_test.exs"
covered_digest: "v3:sha256:85015277efd4c1f57371d79c0cbc2f86ed5e0c8f9662852380f91d7c97d98900"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/4
  gaps_closed:
    - "CI-03 lane-specific weight generation, strict ingestion, and selected lane routing are implemented and covered by adversarial contracts."
  gaps_remaining:
    - "CI-03 measured max/min ratio remains above 1.15 in seven of the fixed first-three lane/run observations."
  regressions: []
gaps:
  - truth: "With partition weights refreshed from CI timings, the slowest/fastest partition ratio is <= 1.15 over 3 runs on each lane."
    status: failed
    reason: "After the per-lane weights landed at main squash 89add23ede29b7840e6cfa29cd70eb3c8ea59ae2, the canonical attempt-1 reader and its committed receipt show current 1.13/1.24/1.15, min 1.36/1.35/1.28, and latest 1.36/1.30/1.30 for the first three qualifying successes. Seven of nine exceed 1.15; the threshold is unchanged."
    artifacts:
      - path: test/partition_weights.txt
        issue: "The refreshed current-lane weights are selected, but current still exceeds the measured threshold in one of the first three main runs (1.24)."
      - path: test/partition_weights_min.txt
        issue: "Min-lane weights are generated from min-lane artifacts and selected correctly, but all three first-sample ratios exceed 1.15."
      - path: test/partition_weights_latest.txt
        issue: "Latest-lane weights are generated from latest-lane artifacts and selected correctly, but all three first-sample ratios exceed 1.15."
      - path: .planning/phases/247-ci-critical-path-and-suite-lanes/247-MEASUREMENT.md
        issue: "The fixed main sample records the numeric CI-03 miss and the nine actual ratios."
    missing:
      - "Further improve assignment balance or obtain a maintainer scope decision, then measure a new fixed first-three consecutive successful attempt-1 main sample with every lane at <= 1.15. Keep the threshold unchanged."
---

# Phase 247: CI Critical Path and Suite Lanes — Verification

**Phase Goal:** Required CI finishes in <= 9 minutes median on main without dropping coverage, partitions are balanced, and a hung test fails fast and names itself.
**Verified:** 2026-10-27T02:37:43Z
**Status:** gaps_found
**Re-verification:** Yes — after gap plans 247-14 and 247-15.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Every main CI run publishes the slowest 20 browser specs with durations, and timing visibility landed before the browser split. | VERIFIED | `slow-specs.ts` consumes the Playwright JSON report, writes a top-20 summary and artifact, and is wired from each browser leg under `if: always()`. Its Node unit tests and the prior main-run timing receipts pass; the exact-head PR #96 run and each of the five B3 main runs include the timing artifact family. |
| 2 | Browser E2E runs once per Playwright project, the journey receipt reconciles every journey, and the five-run main median is <= 540 s. | VERIFIED | `ci.yml` has desktop/mobile matrix legs, a receipt job in unconditional `ci-required` needs, and tests pin the project inventory and receipt requirements. PR #96 attempt 1 (run 40432374330) passed all 17 jobs and reconciled 31 journeys. The live canonical reader selected five successful attempt-1 runs on main SHA `89add23e`; walls were 423/471/451/442/444 s, median 444 s. Its five selected run records each include 17 successful jobs and a green receipt. |
| 3 | Repo-file contract tests run only on the current lane while local `mix test` and docs retain full scope, and CI-refreshed weights yield max/min <= 1.15 across three runs on each lane. | FAILED | Scope selection, full local inventory, docs, lane-specific weight ingestion and assignment all exist and are exercised. The independent numeric acceptance still fails: current 1.13/1.24/1.15, min 1.36/1.35/1.28, latest 1.36/1.30/1.30. Seven of the nine fixed first-three values exceed 1.15. Evidence: live `bin/measure-main-ci --since 89add23ede29b7840e6cfa29cd70eb3c8ea59ae2 --count 5 --ratios --format json`, `247-B3-MEASUREMENT.json`, and the measurement table. |
| 4 | A hung test fails within its partition timeout and names itself, reproduced against the PR #89 hang shape. | VERIFIED | `PartitionMonitor` reports in-flight test or `setup_all` identity and the runner watchdog kills the partition process group after its 480 s budget, before the CI step/job limits. Existing named monitor tests exercise both hang shapes. The throwaway PR #89-shape run 40387548421 terminated in 525 s and named `Threadline.ZzHangReproTest (setup_all)`; the live CI min lane has the formatter attached. |

**Score:** 3/4 roadmap truths verified (0 present, behavior-unverified).

### Gap-plan must-haves

The added plan truths are checked separately from the roadmap score. Plan 247-14's three truths pass: min/latest/current weights use their own three distinct successful attempt-1 B2 runs (12 TSVs per lane), exact inventories are 206/206/269 files, the runner routes unset/current/min/latest correctly, and its strict ingestion/routing mutations fail closed. Plan 247-15's three evidence truths pass: the lane weights landed on main, CI-02 passed its fixed five-run gate, and CI-03's measured MISS remains explicit and unaltered alongside the preserved CI-01/02/04 topology.

## Required Artifacts

All 39 artifacts declared across the 15 plans pass the GSD artifact checker (present and required patterns found). The main runtime artifacts were also read and traced directly:

| Artifact | Expected | Status | Evidence |
|---|---|---|---|
| `.github/workflows/ci.yml` | Browser timings, matrix receipt, lane scope, partition watchdog | VERIFIED | Substantive workflow; live PR and main runs show all 17 jobs including both browser legs, receipt, and `CI required`. |
| `examples/threadline_phoenix/e2e/support/slow-specs.ts` + unit test | Top-20 per-spec timing summary and artifact | VERIFIED | Playwright JSON input, output summary/artifact wiring, and Node unit coverage. |
| `bin/measure-main-ci` | Read-only attempt-1 wall and ratio measurement | VERIFIED | Re-executed against main; returned five qualifying runs, median 444 s and the same ratio vectors as the committed JSON. |
| `bin/ci-test-partitions` + `test/support/partition_monitor.ex` | Lane weights, exact assignment, named hangs and timing TSVs | VERIFIED | Runner selects the lane file, filters only toolchain scope, calls assignment verification, retains N=4/colocation/watchdog; formatter writes per-file timing rows and hang diagnostics. |
| `test/partition_weights.txt`, `test/partition_weights_min.txt`, `test/partition_weights_latest.txt` | Current full inventory and measured min/latest inventories | VERIFIED | Sorted positive weights; plan 14 ingestion uses three distinct B2 attempt-1 main timing artifacts per lane and validates exact inventory before atomic replacement. |
| `test/threadline/ci_topology_contract_test.exs` | Lane inventory and routing mutation controls | VERIFIED | Substantive contract; 44 focused topology/scope tests passed in the plan 14 receipt, together with both Bash self-tests. |
| `examples/threadline_phoenix/e2e/support/operator-ci-evidence.ts`, `bin/browser-full-projects` | N-leg receipt and fail-closed project resolution | VERIFIED | Contract/unit tests plus PR #96 receipt reconciled 31 journeys across desktop and mobile. |
| `247-LANDING.md`, `247-MEASUREMENT.md`, `247-VALIDATION.md`, `247-B3-MEASUREMENT.json` | Exact landing, numeric gate, and validation receipts | VERIFIED | Same main squash SHA and fixed attempt-1 sample; the machine-readable JSON agrees with the live canonical reader. |

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Playwright JSON report | `slow-specs.ts` | `ci.yml` `always()` summary step | WIRED | The leg passes the report path, emits summary and uploads timing artifact even on failed tests. |
| Playwright project matrix | journey receipt | run-scoped discovered/executed artifacts | WIRED | Exact-head PR #96 receipt log says 31 named journeys validated across desktop and mobile. |
| journey receipt | `ci-required` / branch protection | unconditional `needs`, no allowed skips | WIRED | Workflow and contract include the receipt; post-merge readback confirms sole required context `CI required@15368`. |
| `THREADLINE_CI_LANE` in workflow | lane-specific partition file | `lane_weights` in `bin/ci-test-partitions` | WIRED | `current` and unset use full weights; `min` and `latest` use their exact files; unknown values fail before compilation. |
| lane timing TSVs | committed lane files | strict three-run `--ingest-weights --lane --output` | WIRED | B2 main attempt-1 provenance, 12 TSVs per lane, exact inventory checks and atomic replacement. |
| selected weights + filtered inventory | four `mix test` processes | `assign_files` and `verify_assignment` | WIRED | Local full and min/toolchain partitions each assigned every selected file once; main jobs use the same runner. |
| `PartitionMonitor` | hung ExUnit process | formatter events + deadline watcher | WIRED | Existing monitor tests and the named PR #89-shape run prove both test-body and `setup_all` diagnosis. |
| main run attempts | measurement JSON/report | `bin/measure-main-ci` | WIRED | Independent live invocation returned the same five run IDs, median and first-three ratios. |

## Data-flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `slow-specs.ts` output | browser timings | Playwright JSON reporter written by each browser run | Yes; uploaded per run | FLOWING |
| `PartitionMonitor` TSV | per-file `wall_ms` / `test_ms` | ExUnit module and test timing events in each partition VM | Yes; uploaded as lane/run artifacts | FLOWING |
| lane weight files | per-file milliseconds | Median of three distinct lane-specific main-run TSV sets | Yes; exact inventory validated before atomic write | FLOWING |
| B3 measurement | wall times and `max/min` ratios | attempt-1 GitHub run records, job logs, and runner ratio rows | Yes; source JSON matches independent reader | FLOWING |

No rendered application data is introduced by this phase.

## Behavioral Spot-Checks

| Behavior | Command / receipt | Result | Status |
|---|---|---|---|
| Five-run CI wall median and first-three ratios | `bin/measure-main-ci --since 89add23ede29b7840e6cfa29cd70eb3c8ea59ae2 --count 5 --ratios --format json` | Five attempt-1 successes on `89add23e`; median 444 s; same ratios as committed measurement | PASS for CI-02; CI-03 MISS |
| Exact-head required CI and coverage | `CI=true mix ci.all` at `9fa28fad`; PR #96 attempt 1 | Local gate exit 0; PR run 40432374330 all 17 jobs green; 31 journeys; browser 418 passed / 56 configured skips | PASS |
| Weight generation and routing | plan 14 Bash 5 and Bash 3.2 self-test receipts; focused contracts | Both self-tests and 44 focused contracts green; full local 3381 tests + 32 properties/0 failures; min/toolchain 2561 tests + 32 properties/0 failures | PASS |
| Hung test naming and early termination | monitor hang tests; throwaway PR #89-shape run 40387548421 | Test body and `setup_all` names are asserted; remote run named the stuck `setup_all` and terminated in 525 s | PASS |

The full local test suite was not rerun on unchanged code; the exact-head local `mix ci.all`, committed focused-test receipts, and main runs cover the new changes.

## Probe Execution

Not applicable: no plan or success criterion declares a `probe-*.sh` script.

## Requirements Coverage

| Requirement | Source plans | Status | Evidence |
|---|---|---|---|
| CI-01 | 247-01, 247-03, 247-08, 247-13, 247-15 | SATISFIED | Timing summary/artifact is wired before browser matrix and appears with the live run evidence. |
| CI-02 | 247-03, 247-09–11, 247-13, 247-15 | SATISFIED | Matrix, required receipt, branch protection and five-run median 444 s <= 540 s. |
| CI-03 | 247-01–08, 247-12–15 | BLOCKED | Full/local scope and measured lane weights are implemented, but seven of nine required first-three max/min ratios exceed 1.15. |
| CI-04 | 247-04–05, 247-08, 247-15 | SATISFIED | Named monitor/watchdog behavior, min-lane wiring, and PR #89-shape reproduced run. |

All four requirement IDs appear in plan requirements and REQUIREMENTS.md; no Phase 247 requirement is orphaned. Markers for CI-01/02/04 may retain historical `Gaps Found` in REQUIREMENTS.md while the phase is open; the evidence above independently verifies them. CI-03 remains unmet.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `examples/threadline_phoenix/e2e/support/operator-ci-evidence.ts` | 51–54 | Pre-existing ambiguity when a Playwright title contains ` › ` | WARNING; deferred | Existing WR-01 is dispositioned in `247-REVIEW-DISPOSITION.md`; it predates this phase delta and does not affect the current journey inventory. |

No unreferenced `TBD`, `FIXME`, or `XXX` markers were found in the changed Phase 247 implementation files. The `return null` match in the changed accessibility spec is an existing test helper guard, not a user-visible stub. No console-only or empty implementation was found. Plan 14/15 reviews added no new findings. The separate motion fixture failure from run 40435657557 is retained in `deferred-items.md` and was not retried or folded into the fixed sample.

## Human Verification Required

None. Repository policy prefers automated UAT; the remaining acceptance gap is a deterministic measured CI-03 miss with an automated remeasurement path.

## Gaps Summary

Gap plan 14 fixed the wiring issue that caused min/latest to inherit current weights: each lane now ingests its own three-run main timing sample, validates exact inventory, routes to its own committed weights, and retains exact-once assignment safeguards. The exact tested code landed on main and passes required CI. The five-run median also meets the 540-second gate at 444 seconds. However, the first-three post-landing ratios still miss the unchanged 1.15 requirement on seven observations. This numeric CI-03 gap blocks phase completion; the recorded evidence does not support a pass or an override.

---

_Verified: 2026-10-27T02:37:43Z_
_Verifier: the agent (gsd-verifier)_
