---
phase: 67
plan: 02
subsystem: redaction-drift-mix-parity
tags:
  - elixir
  - threadline
  - mix-task
  - policy
  - redaction
requires:
  - "67-01 shared redaction presenter"
provides:
  - "`mix threadline.policy.show` human viewer output with aligned policy drift table"
  - "Stable `--json` policy drift contract for capture-only adopters"
  - "Repo-backed Mix integration coverage for drift, introspection failure, ordering, and viewer semantics"
affects:
  - "capture-only operator workflows inspecting deployed trigger redaction drift"
tech-stack:
  added: []
  patterns:
    - "Mix viewer task boot sequence mirrored from Phase 66 coverage task"
    - "Single shared fact source via Threadline.Policy.RedactionPresenter"
    - "Repo-backed catalog fixtures for drift_detected / could_not_introspect / config_matches_deployed"
key-files:
  created:
    - "lib/mix/tasks/threadline.policy.show.ex"
    - "test/threadline/operator_surface/policy_show_mix_test.exs"
  modified: []
decisions:
  - "Kept `mix threadline.policy.show` viewer-only: drift renders in output but never exits non-zero."
  - "Used one compact terminal DSL for CONFIG and DEPLOYED cells: `exclude=[...] mask=[...] placeholder=[...]` when relevant."
  - "Locked JSON to top-level summary counts plus ordered `tables` entries with stable snake_case status enums."
metrics:
  duration: ~18 min
  completed: 2026-05-07T22:24:00Z
  tasks: 2
  files: 3
  tests_added: 3
---

# Phase 67 Plan 02: Policy Show Mix Task Summary

Phase 67's capture-only parity viewer now exists as `mix threadline.policy.show`. The task follows the same boot posture as the Phase 66 coverage viewer, starts the configured repo, calls `Threadline.Policy.RedactionPresenter.build(repo: repo, schema: "public")`, and keeps all reconciliation logic in the shared presenter. Default human output prints one summary line, one aligned `TABLE / STATUS / CONFIG / DEPLOYED / HINT` table, and detail blocks only for `Drift detected` and `Could not introspect` rows. `--json` emits additive summary fields plus an ordered `tables` array with the locked machine statuses `config_matches_deployed`, `drift_detected`, and `could_not_introspect`.

The new integration test exercises the task against live PostgreSQL trigger fixtures, not mocks. It seeds one drift row, one malformed-introspection row, and one match row, then proves viewer-not-gate behavior, stable JSON shape, rerun-hint copy, and canonical presenter ordering. Assertions also lock the no-sample-values invariant by checking that neither human nor JSON output surfaces example payload values.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Test Fixture Isolation] Scoped assertions to owned fixture rows instead of assuming an empty public schema**
- **Found during:** Task 2 / GREEN verification
- **Issue:** The shared test database already contains unrelated Threadline triggers in `public`, so summary counts and full table inventory were larger than the owned fixture alone.
- **Fix:** Kept the real repo-backed test, but changed assertions to validate the owned fixture rows, ordering, and contract shape without assuming no other deployed triggers exist.
- **Files modified:** `test/threadline/operator_surface/policy_show_mix_test.exs`
- **Verification:** `mix test test/threadline/operator_surface/policy_show_mix_test.exs`
- **Commit:** `1442f23`

**Total deviations:** 1 auto-fixed (`Rule 3`: 1). **Impact:** keeps the test robust against the current workspace state without weakening the policy-show contract.

## Tasks -> Commits

| Task | Description | Commit(s) |
| ---- | ----------- | --------- |
| 1 (RED baseline) | Failing parity/integration test for the new policy viewer task | `f739f1a` |
| 1-2 (GREEN) | Presenter-backed `mix threadline.policy.show` implementation plus final fixture-aware test contract | `1442f23` |

## Plan-Level Verification Results

| Check | Status |
| ----- | ------ |
| `mix test test/threadline/operator_surface/policy_show_mix_test.exs` | 3 tests / 0 failures |
| `mix verify.compile_no_optional` | clean |

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: `lib/mix/tasks/threadline.policy.show.ex`
- FOUND: `test/threadline/operator_surface/policy_show_mix_test.exs`
- FOUND commit: `f739f1a`
- FOUND commit: `1442f23`
