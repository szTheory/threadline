---
phase: 10
plan: "10-02"
status: complete
---

# Plan 10-02 Summary: Doc contract tests, ci.all, Actions, Nyquist

## Objective

TOOL-03 compile-checked README mirrors; extend `ci.all`, GitHub Actions `verify-test`, Nyquist CI-02 literal, and README / CONTRIBUTING for parity with `verify.threadline` and `verify.doc_contract`.

## What shipped

- `test/support/readme_quickstart_fixtures.ex` — `Threadline.ReadmeQuickstartFixtures`, `Threadline.ReadmeDocContractRouter`, `Threadline.ReadmeDocContractAuth` mirroring Quick Start Plug, `ActorRef`, `Jason.encode!`, `record_action/2`, `Health.trigger_coverage/1`.
- `test/threadline/readme_doc_contract_test.exs` — loads fixtures and exercises calls under `DataCase`.
- `mix.exs` aliases: `verify.threadline`, `verify.doc_contract`, extended `ci.all` ordering.
- `.github/workflows/ci.yml` — post-`mix verify.test` steps for `mix verify.threadline` and `mix verify.doc_contract`.
- `test/threadline/phase06_nyquist_ci_contract_test.exs` — CI-02 asserts full `ci.all` step list and ordering.
- README **CI:** paragraph and CONTRIBUTING setup mention expanded `ci.all` / Postgres expectations.

## Key files

- `test/support/readme_quickstart_fixtures.ex`
- `test/threadline/readme_doc_contract_test.exs`
- `mix.exs`
- `.github/workflows/ci.yml`
- `README.md`, `CONTRIBUTING.md`
- `test/threadline/phase06_nyquist_ci_contract_test.exs`

## Deviations

- README shows `ActorRef.anonymous/0` style; fixtures use `ActorRef.new/2` with a short moduledoc note — same public types, documented constructors.

## Self-Check

- `MIX_ENV=test mix compile --warnings-as-errors` — PASSED.

## Issues encountered

- Full test suite not run without PostgreSQL in orchestrator environment.
