---
status: passed
phase: 10
updated: "2026-04-23"
---

# Phase 10 verification

## Goal

Verify coverage and documentation contracts for maintainer tooling (TOOL-01, TOOL-03): `mix threadline.verify_coverage`, CI parity, doc contract compilation.

## Must-haves

| ID | Criterion | Evidence |
|----|-----------|----------|
| MH-01 | `mix threadline.verify_coverage` delegates to `Threadline.Health.trigger_coverage/1` only | `grep Threadline.Health.trigger_coverage lib/mix/tasks/threadline.verify_coverage.ex`; no `pg_tables` / `pg_trigger` in task or policy modules |
| MH-02 | Policy + task tests exist | `test/threadline/verify_coverage_policy_test.exs`, `test/threadline/verify_coverage_task_test.exs` |
| MH-03 | `ci.all` includes verify.threadline and verify.doc_contract after tests | `mix.exs` aliases |
| MH-04 | GitHub Actions `verify-test` runs same mix steps | `.github/workflows/ci.yml` |
| MH-05 | Doc contract module references `Threadline.Plug` | `grep Threadline.Plug test/support/readme_quickstart_fixtures.ex` |
| MH-06 | README documents `threadline.verify_coverage` and `expected_tables` | README Maintainer checks |
| MH-07 | README **CI:** mentions verify-test follow-on commands | README CI paragraph |

## Automated checks (orchestrator)

| Check | Result |
|-------|--------|
| `MIX_ENV=test mix compile --warnings-as-errors` | PASS |

## Automated checks (requires PostgreSQL — not run here)

Run locally or in CI:

1. `MIX_ENV=test mix test test/threadline/verify_coverage_policy_test.exs test/threadline/verify_coverage_task_test.exs test/threadline/readme_doc_contract_test.exs test/threadline/phase06_nyquist_ci_contract_test.exs`
2. `MIX_ENV=test mix ci.all`

## human_verification

None required once the Postgres-backed commands above pass in your environment.

## Gaps

None identified in static review.
