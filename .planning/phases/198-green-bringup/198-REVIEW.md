---
phase: 198-green-bringup
reviewed: 2026-09-09T15:18:49Z
depth: standard
files_reviewed: 104
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
  - bin/observe-main-ci
  - bin/record-ci-attestation
  - bin/upsert-ci-issue
  - bin/verify-branch-protection
  - bin/verify-phase198-evidence
  - bin/verify-playwright-fail-fast
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
  - examples/threadline_phoenix/test/threadline_phoenix/demo/retention_tail_env_contract_test.exs
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
  - test/mix/tasks/threadline.incident_test.exs
  - test/mix/tasks/threadline/export_test.exs
  - test/support/storage_schema_case.ex
  - test/test_helper.exs
  - test/threadline/branch_protection_comparison_contract_test.exs
  - test/threadline/capture/trigger_changed_from_test.exs
  - test/threadline/capture/trigger_context_test.exs
  - test/threadline/capture/trigger_redaction_test.exs
  - test/threadline/capture/trigger_test.exs
  - test/threadline/ci_attestation_contract_test.exs
  - test/threadline/ci_coverage_doc_contract_test.exs
  - test/threadline/ci_issue_upsert_contract_test.exs
  - test/threadline/ci_topology_contract_test.exs
  - test/threadline/e2e_preflight_contract_test.exs
  - test/threadline/evidence/proof_test.exs
  - test/threadline/flake_classifier_contract_test.exs
  - test/threadline/governance/evidence_record_test.exs
  - test/threadline/idle_transaction_reaper_contract_test.exs
  - test/threadline/main_ci_observer_contract_test.exs
  - test/threadline/operator_surface/breadcrumb_test.exs
  - test/threadline/operator_surface/component_contract_test.exs
  - test/threadline/operator_surface/copy_contract_test.exs
  - test/threadline/operator_surface/exports_mix_parity_test.exs
  - test/threadline/operator_surface/live/actor_live_test.exs
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
  - test/threadline/phase198_automation_policy_test.exs
  - test/threadline/phase198_decision_attestation_test.exs
  - test/threadline/phase198_nyquist_contract_test.exs
  - test/threadline/phase198_zero_human_uat_contract_test.exs
  - test/threadline/playwright_fail_fast_contract_test.exs
  - test/threadline/release_ci_gate_contract_test.exs
  - test/threadline/release_control_plane_contract_test.exs
  - test/threadline/storage_schema_call_site_contract_test.exs
  - test/threadline/storage_schema_prefix_contract_test.exs
  - test/threadline/zero_skips_contract_test.exs
findings:
  critical: 2
  warning: 1
  info: 0
  total: 3
status: issues_found
---

# Phase 198: Code Review Report

**Reviewed:** 2026-09-09T15:18:49Z
**Depth:** standard
**Files Reviewed:** 104
**Status:** issues_found

## Summary

The submitted CI and evidence changes contain two failures that make the new required test lane non-portable to the clean GitHub-hosted runner it is intended to gate. A browser preflight also accepts an unrelated cross-origin redirect as proof that the operator route is correctly mounted. Shell syntax checks passed; the targeted Mix tests could not be executed in this workspace because no Mix version is configured for the active tool manager.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Required test suite depends on an uninstalled developer-global GSD executable

**File:** `/Users/jon/projects/threadline/test/threadline/phase198_zero_human_uat_contract_test.exs:58-75`

**Issue:** `classifier_command!/0` requires either a `gsd-tools` executable on `PATH` or `~/.codex/gsd-core/bin/gsd-tools.cjs`. Neither artifact belongs to this repository or is installed by `verify-test` in `.github/workflows/ci.yml`. A clean GitHub-hosted runner therefore raises at line 71 before performing an assertion. Since this file is included by the ordinary `mix verify.test` alias, both required test-matrix jobs can fail based on a maintainer's local Codex installation rather than the submitted code. It also lets local results vary as the global GSD installation changes.

**Fix:** Vendor the exact classifier implementation/version used by the contract into the repository and invoke that committed path, or replace this test with project-owned parsing logic. For example:

```elixir
@classifier Path.expand("../../bin/classify-uat-coverage", __DIR__)

defp classifier_command! do
  assert File.regular?(@classifier), "committed coverage classifier is missing"
  {@classifier, []}
end
```

### CR-02: Archive-tag contract cannot pass under CI's shallow checkout

**File:** `/Users/jon/projects/threadline/test/threadline/phase198_nyquist_contract_test.exs:88-103`

**Issue:** The test resolves every `archive/*` tag with `git rev-parse` and `git cat-file`, but every checkout in the required `verify-test` job uses the default `actions/checkout` depth. That default fetches a single commit and does not provide the repository's annotated tag objects. On a clean runner, the pattern match `{object, 0}` fails as soon as the first archive tag is absent, independently of whether the archive register is correct. Release jobs explicitly use `fetch-depth: 0`, demonstrating that the repository already accounts for this checkout behavior elsewhere, but the CI test matrix does not.

**Fix:** Fetch tag history in the `verify-test` checkout (or in a dedicated archive-contract job) before running this test:

```yaml
- uses: actions/checkout@v5
  with:
    fetch-depth: 0
```

If the full history cost is unwanted, explicitly fetch the registered tag refs and their peeled objects before the assertion.

## Warnings

### WR-01: Operator preflight accepts a cross-origin redirect as a valid auth mount

**File:** `/Users/jon/projects/threadline/examples/threadline_phoenix/e2e/run-e2e.sh:79-92`

**Issue:** The 3xx branch checks only whether the raw `Location` value contains `/users/log_in`. A response such as `Location: https://unrelated.example/users/log_in` therefore passes, even though it proves neither the example application's auth pipeline nor a valid local login route. This weakens the fail-fast check precisely on the routing/misconfiguration path it was added to detect.

**Fix:** Accept only a relative local login target, or parse an absolute target and require its origin to equal `BASE_URL` before checking the path. For the current Phoenix redirect contract, a strict shell check is sufficient:

```bash
case "$location" in
  /users/log_in|/users/log_in\?*) return 0 ;;
  *) return 1 ;;
esac
```

---

_Reviewed: 2026-09-09T15:18:49Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
