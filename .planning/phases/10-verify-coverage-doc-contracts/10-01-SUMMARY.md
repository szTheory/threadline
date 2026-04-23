---
phase: 10
plan: "10-01"
status: complete
---

# Plan 10-01 Summary: verify_coverage policy, Mix task, and tests

## Objective

Deliver TOOL-01: `mix threadline.verify_coverage` composing `Threadline.Health.trigger_coverage/1`, host `expected_tables` config (strings only), deterministic stdout report, non-zero exit on violations, plus policy unit tests and an integration test for the failure path.

## What shipped

- `Threadline.Verify.CoveragePolicy` — pure `violations/2` and `summary_counts/2` over Health tuples vs expected names (`:uncovered` and `:missing`).
- `Mix.Tasks.Threadline.VerifyCoverage` — loads app config, starts repo, calls Health only (no duplicated catalog SQL), ASCII `TABLE` / `STATUS` report and `summary:` line, `exit({:shutdown, 1})` on violations.
- Migration `20260423120000_threadline_verify_coverage_canary` — `threadline_ci_coverage_canary` with trigger (pass path) and `threadline_verify_cov_uncovered` without (failure path).
- `config/test.exs` branches on `THREADLINE_VERIFY_COVERAGE_FAILURE_TEST` for integration coverage.
- Tests: `verify_coverage_policy_test.exs`, `verify_coverage_task_test.exs` (including SC4 subset assertion).
- README **Maintainer checks** section for `expected_tables` and `mix threadline.verify_coverage`.

## Key files

- `lib/threadline/verify/coverage_policy.ex`
- `lib/mix/tasks/threadline.verify_coverage.ex`
- `priv/repo/migrations/20260423120000_threadline_verify_coverage_canary.exs`
- `config/test.exs`
- `test/threadline/verify_coverage_policy_test.exs`
- `test/threadline/verify_coverage_task_test.exs`

## Deviations

None.

## Self-Check

- `rg 'pg_tables|pg_trigger' lib/mix/tasks/threadline.verify_coverage.ex` — no matches (orchestrator did not re-verify in no-DB environment).
- Compile: `MIX_ENV=test mix compile --warnings-as-errors` — PASSED.

## Issues encountered

- Local agent shell had no usable PostgreSQL; full `mix test` / `mix ci.all` not executed here — run before merge.
