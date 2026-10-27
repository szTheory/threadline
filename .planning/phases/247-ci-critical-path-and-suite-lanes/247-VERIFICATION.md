---
phase: 247-ci-critical-path-and-suite-lanes
verified: 2026-10-27T00:12:26Z
status: gaps_found
score: 3/4 roadmap truths verified
covered_files:
  - .github/workflows/ci.yml
  - .planning/ARCHIVE-REGISTER.md
  - .planning/REQUIREMENTS.md
  - .planning/ROADMAP.md
  - .planning/STATE.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-01-PLAN.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-01-SUMMARY.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-02-PLAN.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-02-SUMMARY.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-03-PLAN.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-03-SUMMARY.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-04-PLAN.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-04-SUMMARY.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-05-PLAN.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-05-SUMMARY.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-06-PLAN.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-06-SUMMARY.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-07-PLAN.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-07-SUMMARY.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-08-PLAN.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-08-SUMMARY.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-09-PLAN.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-09-SUMMARY.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-10-PLAN.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-10-SUMMARY.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-11-PLAN.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-11-SUMMARY.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-12-PLAN.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-12-SUMMARY.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-13-PLAN.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-13-SUMMARY.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-CONTEXT.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-LANDING.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-MEASUREMENT.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-OBSERVATION.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-REGRESSION.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-RESEARCH.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-REVIEW-DISPOSITION.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-REVIEW.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-SECURITY.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-UI-REVIEW.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/247-VALIDATION.md
  - .planning/phases/247-ci-critical-path-and-suite-lanes/deferred-items.md
  - CONTRIBUTING.md
  - bin/browser-full-projects
  - bin/ci-test-partitions
  - bin/measure-main-ci
  - examples/threadline_phoenix/e2e/package.json
  - examples/threadline_phoenix/e2e/playwright.config.ts
  - examples/threadline_phoenix/e2e/support/operator-ci-evidence.test.ts
  - examples/threadline_phoenix/e2e/support/operator-ci-evidence.ts
  - examples/threadline_phoenix/e2e/support/slow-specs.test.ts
  - examples/threadline_phoenix/e2e/support/slow-specs.ts
  - test/partition_weights.txt
  - test/support/partition_monitor.ex
  - test/test_helper.exs
  - test/threadline/adoption_evidence_playbook_doc_contract_test.exs
  - test/threadline/audit_doc_contract_test.exs
  - test/threadline/branch_protection_comparison_contract_test.exs
  - test/threadline/browser_full_projects_contract_test.exs
  - test/threadline/browser_journey_evidence_contract_test.exs
  - test/threadline/changelog_contract_test.exs
  - test/threadline/ci_action_pin_contract_test.exs
  - test/threadline/ci_action_runtime_contract_test.exs
  - test/threadline/ci_attestation_contract_test.exs
  - test/threadline/ci_coverage_doc_contract_test.exs
  - test/threadline/ci_issue_upsert_contract_test.exs
  - test/threadline/ci_sha_gate_contract_test.exs
  - test/threadline/ci_token_permissions_contract_test.exs
  - test/threadline/ci_topology_contract_test.exs
  - test/threadline/ci_workflow_parity_contract_test.exs
  - test/threadline/community_health_contract_test.exs
  - test/threadline/community_health_render_contract_test.exs
  - test/threadline/date_release_changelog_test.exs
  - test/threadline/dependabot_config_contract_test.exs
  - test/threadline/deps_audit_contract_test.exs
  - test/threadline/deps_audit_gate_test.exs
  - test/threadline/deps_health_doc_contract_test.exs
  - test/threadline/deps_health_report_test.exs
  - test/threadline/e2e_preflight_contract_test.exs
  - test/threadline/evaluating_threadline_doc_contract_test.exs
  - test/threadline/evidence_cli_doc_contract_test.exs
  - test/threadline/example_phoenix_schemas_mount_contract_test.exs
  - test/threadline/exploration_routing_doc_contract_test.exs
  - test/threadline/flake_classifier_contract_test.exs
  - test/threadline/guide_graph_contract_test.exs
  - test/threadline/guides/redaction_contract_test.exs
  - test/threadline/guides/stability_contract_test.exs
  - test/threadline/guides/table_shapes_contract_test.exs
  - test/threadline/guides/upgrade_path_contract_test.exs
  - test/threadline/hex_pin_contract_test.exs
  - test/threadline/incident_playbook_doc_contract_test.exs
  - test/threadline/local_docker_dx_contract_test.exs
  - test/threadline/main_ci_observer_contract_test.exs
  - test/threadline/measure_main_ci_contract_test.exs
  - test/threadline/operator_surface/operator_evidence_contract_test.exs
  - test/threadline/operator_surface/operator_surface_fixture_contract_test.exs
  - test/threadline/operator_surface/style_contract_test.exs
  - test/threadline/partition_monitor_test.exs
  - test/threadline/performance_doc_contract_test.exs
  - test/threadline/persona_routing_doc_contract_test.exs
  - test/threadline/planning_dependency_contract_test.exs
  - test/threadline/planning_independence_contract_test.exs
  - test/threadline/playwright_fail_fast_contract_test.exs
  - test/threadline/production_checklist_doc_contract_test.exs
  - test/threadline/public_options_contract_test.exs
  - test/threadline/release_ci_gate_contract_test.exs
  - test/threadline/release_control_plane_contract_test.exs
  - test/threadline/release_distribution_doc_contract_test.exs
  - test/threadline/removed_artifact_contract_test.exs
  - test/threadline/repo_contract_scope_contract_test.exs
  - test/threadline/repo_hygiene_contract_test.exs
  - test/threadline/repo_hygiene_guard_test.exs
  - test/threadline/row_history_focus_evidence_contract_test.exs
  - test/threadline/semver_adopter_doc_contract_test.exs
  - test/threadline/support_playbook_doc_contract_test.exs
  - test/threadline/temp_leak_check_test.exs
  - test/threadline/ui_critic_retirement_doc_contract_test.exs
  - test/threadline/upgrading_to_0_11_doc_contract_test.exs
  - test/threadline/upgrading_to_1_0_doc_contract_test.exs
  - test/threadline/verify_action_pins_test.exs
  - test/threadline/version_truth_doc_contract_test.exs
covered_digest: "v3:sha256:5aeead9ef4a70f06ea1586634e7eb8f0dde9034fdb2d84d3790a5cd032c4c111"
behavior_unverified: 0
gaps:
  - truth: "With partition weights refreshed from CI timings, the slowest/fastest partition ratio is <= 1.15 over 3 runs on each lane."
    status: failed
    reason: "The live main measurement independently selected five successful attempt-1 runs at B2 SHA 29abf565. Every lane exceeded 1.15 in all five runs: current 1.19-1.42, latest 1.40-1.58, min 1.57-1.69. The first required three runs already fail the gate."
    artifacts:
      - path: bin/ci-test-partitions
        issue: "The runner assigns all lanes from test/partition_weights.txt; no lane-specific min/latest weights are selected."
      - path: test/partition_weights.txt
        issue: "Weights were refreshed from current-lane timings only; the min/latest subset lanes remain imbalanced."
      - path: .planning/phases/247-ci-critical-path-and-suite-lanes/247-MEASUREMENT.md
        issue: "Recorded main-run measurements confirm the numeric acceptance miss."
    missing:
      - "Ingest three main-run timing artifacts per min and latest lane and select lane-specific weights in the partition runner."
      - "Re-ingest current-lane timing artifacts if needed to address its residual miss, then measure three consecutive main runs per lane. Keep the 1.15 threshold unchanged."
---

# Phase 247: CI critical path and suite lanes Verification Report

**Phase Goal:** Required CI finishes in <= 9 minutes median on main without dropping coverage, partitions are balanced, and a hung test fails fast and names itself.
**Verified:** 2026-10-27T00:12:26Z
**Status:** gaps_found
**Re-verification:** No — no previous VERIFICATION.md existed.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Every main CI run publishes at least the 20 slowest browser specs with durations, and CI-01 timing visibility landed before the browser split. | VERIFIED | `slow-specs.ts` parses Playwright JSON, sums attempts and writes top-20 summary plus JSON artifact. `ci.yml` runs it under `if: always()` and uploads a 14-day artifact. Fresh `npm --prefix examples/threadline_phoenix/e2e run test:unit` passed 39/39; landing order and main-run observations are recorded in `247-LANDING.md` and `247-OBSERVATION.md`. |
| 2 | Browser E2E runs one parallel job per Playwright project; the receipt reconciles all journeys; median main `ci.yml` wall time across five runs is <= 540 s. | VERIFIED | `ci.yml` has desktop/mobile matrix legs and an unconditional receipt in `ci-required.needs`. PR run 40412545694 reconciled 31 journeys across both legs. Fresh live `bin/measure-main-ci --since 29abf5653a0e1c31b70d73d71a3f6c552d9b9712 --count 5 --ratios --format json` returned five successful attempt-1 runs at that SHA, walls 595/671/468/438/414 s, median 468 s. |
| 3 | Repo-file contract tests run only on current lane while local `mix test` stays whole and docs stay honest; CI-refreshed weights produce max/min <= 1.15 over three runs per lane. | FAILED | Scope filtering is wired through `THREADLINE_TEST_SCOPE` on min/latest; current and local runs retain full scope, with documentation and mutation-controlled contracts. However, fresh live measurement returned current 1.20/1.26/1.42, latest 1.48/1.58/1.43, min 1.57/1.61/1.59 for the first three qualifying runs. CI-03 is the blocking gap. |
| 4 | A hung test fails within its partition timeout and names the stuck test, reproduced against the PR #89 hang shape. | VERIFIED | `PartitionMonitor` tracks in-flight tests and `setup_all`, emits a named hang block and stack, then halts. The runner enforces a 480 s process-group budget before the 12-minute step/20-minute job timeouts. Landing evidence records D-16(c) run 40387548421 failing in 525 s with `Threadline.ZzHangReproTest (setup_all)` named. Phase validation reports 212/212 ExUnit audit tests passed. |

**Score:** 3/4 roadmap truths verified (0 present, behavior-unverified).

### Required Artifacts

The 13 plan files declare 31 artifacts. `gsd-tools query verify.artifacts` reported 31/31 present and pattern checks passed. Plan links to branch/tag and non-file endpoints are not handled by the CLI key-link checker; the critical runtime links below were traced manually.

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `.github/workflows/ci.yml` | Timing output, browser matrix, receipt fan-in, lane scope and watchdog budget | VERIFIED | Substantive YAML with matrix legs feeding required receipt; lane scope and bounded test step are wired. |
| `examples/threadline_phoenix/e2e/support/slow-specs.ts` | Top-20 timings and safe summary/artifact output | VERIFIED | Substantive implementation; fresh Node suite passed 39 tests. |
| `bin/ci-test-partitions` | Lane filtering, weight assignment, process watchdog and ratio report | VERIFIED | Substantive and attached by CI's test step. Numeric balance is separately failed. |
| `test/support/partition_monitor.ex` | Per-file timing TSV and named in-flight diagnostics | VERIFIED | Substantive formatter attached only by the partition runner; CI hang-shape evidence is recorded. |
| `bin/measure-main-ci` | Read-only attempt-1 timing and partition-ratio extraction | VERIFIED | Fresh live execution returned 5/5 qualifying main runs and confirmed the measured gates. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `ci.yml` browser leg | `slow-specs.ts` | `always()` step reads executed JSON | WIRED | Workflow passes the report path, captures timing JSON, then uploads the artifact. |
| Browser project matrix | Receipt job | Run-scoped executed/discovered artifacts and `needs` | WIRED | PR run 40412545694 reconciled both legs and 31 named journeys. |
| Receipt job | `ci-required` | `needs`, no allowed skip | WIRED | Required job list includes the receipt; read-only branch-protection check shows `CI required` as the sole required context. |
| Min/latest lane rows | Partition runner | `THREADLINE_TEST_SCOPE=toolchain` | WIRED | Workflow passes the scope; runner filters tagged files; contract pins exact rows and local/current full scope. |
| Partition runner | Partition monitor | ExUnit formatter plus deadline/timing environment | WIRED | Runner attaches monitor and sets timing/deadline variables; monitor writes TSV and hang diagnostics. |
| Main timing source | `247-MEASUREMENT.md` | Attempt-1 wall and max/min extraction | WIRED | Fresh live run reproduced the 468 s median and all-lanes ratio miss. |

### Data-Flow Trace (Level 4)

Not applicable to rendered application data. CI summaries and artifacts are populated from Playwright JSON results and partition timing TSVs, not a static placeholder.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Browser timing and receipt contracts | `npm --prefix examples/threadline_phoenix/e2e run test:unit` | 39 tests passed, 0 failures | PASS |
| CI-02 and CI-03 main measurements | `bin/measure-main-ci --since 29abf5653a0e1c31b70d73d71a3f6c552d9b9712 --count 5 --ratios --format json` | Five successful attempt-1 main runs; median 468 s; current 1.20-1.42, latest 1.40-1.58, min 1.57-1.69 | CI-02 PASS; CI-03 FAIL |
| Partition watchdog self-test | `bin/ci-test-partitions --self-test` | Exit 2 at the process-tree/`pg_stat_activity` backstop assertion in this restricted environment; process-inspection output was unavailable. The validation report records unrestricted Bash 5 and Bash 3.2 self-tests passed after sandbox denial of `ps`. | ENVIRONMENT-LIMITED |

### Probe Execution

Not applicable: no phase-declared `probe-*.sh` scripts.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| CI-01 | 247-03, 247-08 | Publish top-20 browser timings on main | VERIFIED; marker reset | Workflow wiring, fresh Node tests and main-run observation. |
| CI-02 | 247-03, 247-09–11, 247-13 | Project matrix, complete journey receipt and median <= 9 minutes | VERIFIED; marker reset | Live five-run median 468 s; receipt reconciled 31 journeys across both projects. |
| CI-03 | 247-02, 247-04–08, 247-12–13 | Honest lane scope and partition ratio <= 1.15 | BLOCKED | Scope/docs/coverage hold, but every lane exceeded the numeric threshold. |
| CI-04 | 247-04–05, 247-08 | Hung test fails fast and names itself | VERIFIED; marker reset | Formatter, watchdog and PR #89-shape CI reproduction. |

No orphaned Phase 247 requirement IDs: CI-01 through CI-04 are declared by plans and mapped to this phase in REQUIREMENTS.md. REQUIREMENTS.md resets CI-01, CI-02 and CI-04 completion markers to “Gaps Found” while Phase 247 remains open; this report retains their independently verified outcomes. CI-03 is the sole unmet acceptance criterion.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `examples/threadline_phoenix/e2e/support/operator-ci-evidence.ts` | 51-54 | Pre-existing ambiguity when a Playwright title itself contains ` › ` | WARNING, disposition deferred | Recorded in `247-REVIEW.md` and `247-REVIEW-DISPOSITION.md`; predates Phase 247 and is unrelated to the balance gap. |

No unreferenced TBD/FIXME/XXX debt markers were found in phase implementation files. Other placeholder matches are intentional test fixtures or documented path conventions.

### Human Verification Required

None. The remaining issue is a deterministic numeric gate miss with an automated closure path.

### Gaps Summary

The phase improves the measured CI wall median from 724 s to 468 s and preserves the browser matrix, journey receipt and named hang watchdog. It has not met the goal because partition balance stays outside the fixed 1.15 threshold on every measured lane. The actionable closure is to ingest min- and latest-lane timings into lane-specific weights, keep current-lane weights separate, then remeasure three consecutive main runs per lane. Do not relax the threshold.

---

_Verified: 2026-10-27T00:12:26Z_  
_Verifier: the agent (gsd-verifier)_

