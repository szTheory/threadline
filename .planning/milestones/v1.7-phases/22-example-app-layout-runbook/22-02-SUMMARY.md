---
phase: 22
plan: "22-02"
status: complete
---

# Plan 22-02 Summary — Root `verify.example`, CI prelude, doc contracts

## Outcome

Added root `mix verify.example` (nested `deps.get`, `compile --warnings-as-errors`, `ecto.create` for `ThreadlinePhoenix.Repo`, `mix test` under `MIX_ENV=test`, declining interactive Hex prompts via `printf` for CI/agent shells), `preferred_envs` entry, and folded the alias into `ci.all` after `verify.threadline` and before `verify.doc_contract`. Extended `.github/workflows/ci.yml` `verify-test` with `createdb threadline_phoenix_test` prelude and `mix verify.example`. Tightened `phase06_nyquist_ci_contract_test.exs` to assert `ci.all` ordering using only the `ci.all` block (avoids `preferred_envs` false positives) and extended `readme_doc_contract_test.exs` for `examples/README.md` + example README runbook literals.

## Key files

- `mix.exs`
- `.github/workflows/ci.yml`
- `test/threadline/phase06_nyquist_ci_contract_test.exs`
- `test/threadline/readme_doc_contract_test.exs`

## Verification

- `env DB_PORT=5433 MIX_ENV=test mix verify.example` — pass.
- `env DB_PORT=5433 MIX_ENV=test mix ci.all` — pass.

## Self-Check: PASSED
