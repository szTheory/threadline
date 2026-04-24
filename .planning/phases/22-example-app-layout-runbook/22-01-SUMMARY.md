---
phase: 22
plan: "22-01"
status: complete
---

# Plan 22-01 Summary — Scaffold `examples/threadline_phoenix`

## Outcome

Added the canonical Phoenix API example at `examples/threadline_phoenix/` with `{:threadline, path: "../.."}`, `posts` migration + schema + seeds, `mix threadline.install` + `mix threadline.gen.triggers --tables posts` migrations (including a manual bump so audit vs semantics migrations do not share the same version), `test/test_helper.exs` mirroring root `storage_up` + migrate discipline, ExUnit coverage for `Post`, and contributor README content (generator flags, `MIX_ENV` / `Mix.Task.run("app.config", [])`, `mix setup` Postgres caveat, `DB_HOST` / `DB_PORT`, install/triggers flow). Replaced `examples/README.md` with an index linking to `threadline_phoenix/README.md`.

## Key files

- `examples/threadline_phoenix/` (Mix project, configs, migrations, tests, README)
- `examples/README.md`

## Verification

- `cd examples/threadline_phoenix && mix compile --warnings-as-errors` — pass (with Postgres reachable for DB tasks as documented).
- `env DB_PORT=5433 MIX_ENV=test mix test` in example — pass.

## Deviations

- `mix threadline.install` emitted two migrations sharing the same timestamp; renamed `*_threadline_semantics_schema.exs` to the next second so `mix ecto.migrate` succeeds.

## Self-Check: PASSED
