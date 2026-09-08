---
phase: 198-green-bringup
reviewed: 2026-09-08T21:07:24Z
depth: standard
files_reviewed: 90
files_reviewed_list:
  - .github/rulesets/main.json
  - .github/workflows/branch-protection.yml
  - .github/workflows/browser-full.yml
  - .github/workflows/ci.yml
  - .github/workflows/flake-detection.yml
  - .github/workflows/release.yml
  - CONTRIBUTING.md
  - bin/classify-flake-run
  - bin/compare-required-contexts
  - bin/record-ci-attestation
  - bin/verify-branch-protection
  - config/test.exs
  - examples/threadline_phoenix/e2e/playwright.config.ts
  - examples/threadline_phoenix/e2e/run-e2e.sh
  - examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-phase-135-uat.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-phase-173-uat.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-phase-175-uat.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-phase-177-uat.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-tier-a-capture.spec.ts
  - examples/threadline_phoenix/e2e/tests/register.spec.ts
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/reset.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_tail.ex
  - examples/threadline_phoenix/test/support/walkthrough_case.ex
  - examples/threadline_phoenix/test/threadline_phoenix/demo/advisory_lock_pinning_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_evidence_test.exs
  - lib/threadline/operator_surface/controllers/theme_controller.ex
  - lib/threadline/operator_surface/live/actor_live.ex
  - lib/threadline/operator_surface/live/coverage_live.ex
  - lib/threadline/operator_surface/live/evidence_live.ex
  - lib/threadline/operator_surface/live/export_status_live.ex
  - lib/threadline/operator_surface/live/policy_redaction_live.ex
  - lib/threadline/operator_surface/live/retention_history_live.ex
  - lib/threadline/operator_surface/live/row_history_live.ex
  - lib/threadline/operator_surface/live/start_live.ex
  - lib/threadline/operator_surface/live/stress_live.ex
  - lib/threadline/operator_surface/live/timeline_live.ex
  - lib/threadline/operator_surface/live/transaction_live.ex
  - lib/threadline/operator_surface/presentation.ex
  - lib/threadline/operator_surface/ui.ex
  - mix.exs
  - test/mix/tasks/threadline.evidence_show_test.exs
  - test/mix/tasks/threadline/export_test.exs
  - test/mix/tasks/threadline.incident_test.exs
  - test/support/storage_schema_case.ex
  - test/test_helper.exs
  - test/threadline/branch_protection_comparison_contract_test.exs
  - test/threadline/capture/trigger_changed_from_test.exs
  - test/threadline/capture/trigger_context_test.exs
  - test/threadline/capture/trigger_redaction_test.exs
  - test/threadline/capture/trigger_test.exs
  - test/threadline/ci_attestation_contract_test.exs
  - test/threadline/ci_coverage_doc_contract_test.exs
  - test/threadline/ci_topology_contract_test.exs
  - test/threadline/e2e_preflight_contract_test.exs
  - test/threadline/evidence/proof_test.exs
  - test/threadline/flake_classifier_contract_test.exs
  - test/threadline/governance/evidence_record_test.exs
  - test/threadline/idle_transaction_reaper_contract_test.exs
  - test/threadline/operator_surface/breadcrumb_test.exs
  - test/threadline/operator_surface/component_contract_test.exs
  - test/threadline/operator_surface/copy_contract_test.exs
  - test/threadline/operator_surface/exports_mix_parity_test.exs
  - test/threadline/operator_surface/live/export_status_live_test.exs
  - test/threadline/operator_surface/live/row_history_live_test.exs
  - test/threadline/operator_surface/mechanical_checker_test.exs
  - test/threadline/operator_surface/policy_show_mix_test.exs
  - test/threadline/operator_surface/presentation_test.exs
  - test/threadline/operator_surface/row_history_component_test.exs
  - test/threadline/operator_surface/stress_ledger_test.exs
  - test/threadline/operator_surface/stress_router_test.exs
  - test/threadline/operator_surface/transaction_live_test.exs
  - test/threadline/operator_surface/ui_form_policy_contract_test.exs
  - test/threadline/optional_deps_contract_test.exs
  - test/threadline/pgbouncer_topology_test.exs
  - test/threadline/phase06_nyquist_ci_contract_test.exs
  - test/threadline/phase198_decision_attestation_test.exs
  - test/threadline/storage_schema_call_site_contract_test.exs
  - test/threadline/storage_schema_prefix_contract_test.exs
  - test/threadline/zero_skips_contract_test.exs
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 198: Code Review Report

**Reviewed:** 2026-09-08T21:07:24Z
**Depth:** standard
**Files Reviewed:** 90
**Status:** clean

## Narrative Findings (AI reviewer)

This final convergence iteration re-reviewed the exact 90-file scope persisted by the original Phase 198 review and inspected every fix commit from `4c4bcbc9` through `365659e9`. All four original Critical findings and all three original Warnings are fully resolved. Direct LiveView probes confirmed that non-string `hours` values (`24`, `nil`, `[]`, and `%{}`) take the safe fallback without changing the selected valid window or terminating the process. No regression or new issue was found in the reviewed scope.

All reviewed files meet quality standards. No issues found.

### Prior-finding resolution

| Finding | Resolution | Evidence |
|---|---|---|
| CR-01 | Resolved | `bin/verify-branch-protection` treats only an observed HTTP 404 as absence and fails closed for other API/transport outcomes; focused fixtures cover 403, 429, 500, and 503. |
| CR-02 | Resolved | The release gate deterministically selects the newest main-branch push run by creation time and run ID, then requires that run itself to succeed. |
| CR-03 | Resolved | The sole aggregate decision action is pinned to the full commit SHA `b5b5b37504aa4183270bd3d855c52a67f212be35`. |
| CR-04 | Resolved | Attestations render and validate in a same-directory temporary file before atomic replacement; failed renders preserve existing evidence. |
| WR-01 | Resolved | The session-scoped `SET lock_timeout` was removed; the bounded non-blocking advisory-lock retry loop remains. |
| WR-02 | Resolved | `Application.fetch_env/2` distinguishes a prior value from absence, and the `after` block restores the corresponding state. |
| WR-03 | Resolved | The parsing clause is binary-guarded and allowlists the four supported windows. Invalid strings, missing keys, `24`, `nil`, `[]`, and `%{}` all use the fallback, preserve a previously selected valid `168`-hour window, and leave the LiveView alive. |

## Verification

- Root full suite: 1,481 tests, 0 failures, 1 excluded.
- Root focused fix-regression suite: 59 tests, 0 failures.
- Release CI gate contract: 1 test, 0 failures.
- ActorLive wrong-type boundary probe: 1 test, 0 failures; exercised `24`, `nil`, `[]`, `%{}`, malformed strings, a missing key, valid selection, unchanged fallback state, and process liveness.
- Phoenix demo lock/retention regression suite: 7 tests, 0 failures.
- `mix compile --warnings-as-errors` passed.
- `actionlint -shellcheck=''` passed for `.github/workflows/ci.yml` and `.github/workflows/release.yml`.
- `shellcheck` passed for `bin/record-ci-attestation` and `bin/verify-branch-protection`.
- `mix format --check-formatted` passed for the modified in-scope Elixir files.
- `git diff --check fd56d8cc..HEAD` passed.

---

_Reviewed: 2026-09-08T21:07:24Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
