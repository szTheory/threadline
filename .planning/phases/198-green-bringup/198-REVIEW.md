---
phase: 198-green-bringup
reviewed: 2026-09-08T19:53:58Z
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
  critical: 4
  warning: 3
  info: 0
  total: 7
status: issues_found
---

# Phase 198: Code Review Report

**Reviewed:** 2026-09-08T19:53:58Z
**Depth:** standard
**Files Reviewed:** 90
**Status:** issues_found

## Narrative Findings (AI reviewer)

The review scope is the sorted union of `key_files.created` / `key_files.modified` from all 42 Phase 198 summaries and the reliable diff `4a17d742a52995b850637a272640892b0be0aabc^..HEAD`, after the workflow's planning, lockfile, generated-file, and deleted-file exclusions. The summaries named 102 paths; the diff supplied 33 paths omitted from those summaries; 90 current source files remained after filtering.

Seven present-HEAD defects were found. Five were introduced during Phase 198. CR-02 and WR-03 predate the supplied diff base but remain active in files inside the full Phase 198 source surface; they are called out as historical rather than attributed to the gap-closure plans. Plans 198-41 and 198-42 changed evidence/planning only and did not fix any finding below.

Static validation run during this review: `actionlint` was available and reported no workflow syntax errors; `shellcheck` reported no diagnostics for the five reviewed shell scripts. Those tools do not exercise the semantic failure paths below. No application or browser test suite was run as part of this review.

## Critical Issues

### CR-01 (BLOCKER): Classic-protection API failures are interpreted as proof that protection is absent

**File:** `bin/verify-branch-protection:95-99`

**Issue:** The command substitution maps every non-zero `gh api repos/.../protection` result to `absent`. A genuine 404 (no classic rule) is indistinguishable from a 401/403, rate limit, network failure, malformed repository slug, or GitHub outage. The workflow can therefore print “no classic protection is stacking” and pass precisely when it could not inspect classic protection. This defeats the script's stated fail-closed contract and can hide an extra required check or stale strict-up-to-date rule.

**Fix:** Capture the HTTP status separately and accept only the documented not-found response as absence; treat every transport/auth/5xx response as an error. Prefer `gh api --silent --include` or a small tested helper that exposes the HTTP code without parsing unrelated stderr, and add fixtures for 404, 403, 429, and 5xx.

### CR-02 (BLOCKER, pre-existing): The release gate accepts any old successful run even when the newest CI run failed

**File:** `.github/workflows/release.yml:256-276`

**Issue:** Runs are sorted newest-first, but after they all complete the gate calls `runs.find(...success)`. If a SHA has an older successful CI run and a newer completed rerun that failed, the old success is enough to publish. The same defect applies across workflow events/attempts on the SHA. This is a release-safety bypass: the guard does not establish that the selected/latest CI execution is green. `git blame` places this logic before the Phase 198 diff base, so this is a current-surface historical defect, not a regression from plans 198-41/42.

**Fix:** Select one authoritative run deterministically (normally newest by `created_at`, tie-broken by `id`, and constrained to the intended event/ref where appropriate), wait only for that run, then require its conclusion to equal `success`. If it completes unsuccessfully, fail immediately and name its URL/conclusion rather than searching older runs.

### CR-03 (BLOCKER): The sole required-check decision executes a mutable third-party action reference

**File:** `.github/workflows/ci.yml:751-773`

**Issue:** `CI required`, the only context protected by the main ruleset, delegates its entire pass/fail decision to `re-actors/alls-green@release/v1`. `release/v1` is a mutable ref rather than an immutable commit SHA. A compromised upstream account or retargeted ref can make this job exit successfully regardless of the twelve `needs` results, bypassing every required lane without changing this repository. Restricting the token to `contents: read` limits repository writes but does not protect the integrity of the status result the ruleset trusts.

**Fix:** Pin the action to a reviewed full commit SHA and use dependency automation to propose explicit updates, or implement the small needs-result check inline from trusted workflow expressions/code so the branch-protection decision has no mutable third-party execution dependency.

### CR-04 (BLOCKER): Attestation regeneration can destroy the previous evidence file on any rendering/write failure

**File:** `bin/record-ci-attestation:61-100`

**Issue:** The script redirects `jq` directly over the final `ci-attestation-${RUN_ID}.json`. Shell redirection opens and truncates an existing attestation before `jq` starts. If the GitHub response shape changes (for example `.jobs` is absent), `jq` fails, the filesystem fills, or the process is interrupted, the prior evidence is replaced by an empty or partial file. Because attestations are evidence artifacts and the same run ID intentionally maps to the same filename, this is a concrete data-loss/corruption path. The current recorder contract tests only check executability and refusal of in-flight runs; they do not falsify partial overwrite.

**Fix:** Render into a `mktemp` file in the destination directory, validate the completed JSON and required schema/status fields, then atomically rename it over `OUT_FILE` only after success. Install an `EXIT` trap that removes the temporary file on every failure path.

## Warnings

### WR-01 (WARNING): The demo advisory-lock helper leaks a session-wide 45-second lock timeout into the connection pool

**File:** `examples/threadline_phoenix/lib/threadline_phoenix/demo/reset.ex:80-105`

**Issue:** `SET lock_timeout = '45s'` is session-scoped. `Repo.checkout/2` pins the session but does not reset arbitrary PostgreSQL session parameters when returning that connection to the pool. Both successful execution and the acquisition-timeout path therefore leave `lock_timeout` changed for whichever unrelated query later borrows the connection. That later query can fail after 45 seconds even though it never opted into the demo lock policy. The acquisition-failure path is especially notable because it raises before entering the existing `try/after` release block.

**Fix:** The lock operation uses non-blocking `pg_try_advisory_lock`, so remove this unrelated session setting. If it must remain, read the prior setting and restore it in an outer `after` that begins before acquisition and runs for acquisition failures as well as callback failures; use parameter-safe `set_config('lock_timeout', $1, false)` rather than interpolating SQL.

### WR-02 (WARNING): Retention configuration restoration does not restore the “unset” state

**File:** `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_tail.ex:82-105`

**Issue:** When `:threadline, :retention` was absent before the seed, `Application.get_env/2` returns `nil`, but the `after` block restores it as an explicitly present empty list. Code using `Application.fetch_env/2`, `Application.get_all_env/1`, or configuration-presence checks observes a different state after seeding. This contradicts the comment's claim that the prior environment is restored on every path and can mask a missing host configuration.

**Fix:** Preserve `Application.fetch_env(:threadline, :retention)` and, in `after`, call `put_env` for `{:ok, value}` or `delete_env` for `:error`.

### WR-03 (WARNING, pre-existing): A forged actor-window event crashes the LiveView process

**File:** `lib/threadline/operator_surface/live/actor_live.ex:253-255`

**Issue:** `hours_str` is client-controlled LiveView event data, but `String.to_integer/1` is called without validation. A forged value such as `"abc"` raises `ArgumentError`; negative or extremely large values can request nonsensical windows or overflow `DateTime.add/3`. This lets any user who can reach the operator surface repeatedly terminate their own LiveView process and generate avoidable server errors. `git blame` places this handler before Phase 198, so it is a current-surface historical defect.

**Fix:** Parse with `Integer.parse/1`, require the entire string to be consumed, and allowlist the supported windows (for example `[1, 6, 12, 24, 72, 168]`). On invalid input, leave the socket intact and show a validation flash instead of raising.

---

_Reviewed: 2026-09-08T19:53:58Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
