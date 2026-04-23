# Phase 10 — Technical Research

**Phase:** 10 — Verify coverage & doc contracts  
**Question:** What do we need to know to plan this phase well?

## Summary

Implement **`mix threadline.verify_coverage`** as a thin Mix façade over **`Threadline.Health.trigger_coverage/1`**: resolve `Ecto.Repo` from the host app after `Mix.Task.run("app.config")` / application start, read **host-supplied expected table names** from `Application.get_env/2`, intersect with trigger_coverage tuples, print a deterministic table + summary to stdout, exit **1** on uncovered expected tables, **Mix.raise** on missing/empty expected set or missing repo. Add a **small pure module** (e.g. `Threadline.Verify.CoveragePolicy`) for testability.

For **TOOL-03**, follow CONTEXT D-11–D-14: add `test/support/readme_contract_*.ex` (or under `test/threadline/doc_contract/`) with modules that **compile** the same API shapes README uses (`Threadline.Plug`, `ActorRef`, `Threadline.record_action/2`, `Threadline.Health.trigger_coverage/1`, etc.); extend **`mix ci.all`** with new aliases **`verify.threadline`** and **`verify.doc_contract`**, update **CI-02** literal in `phase06_nyquist_ci_contract_test.exs`, append steps to **`verify-test`** job in `ci.yml` after `mix verify.test` is wrong — workflow says *after* tests: run as **separate steps before** `mix verify.test` would skip DB — actually CONTEXT D-16 says **extra steps after** `mix verify.test`. So order: compile → **mix verify.test** (includes new tests) OR split: the verify_coverage task needs DB — it should run **after** compile, **with** DB. Simplest: add `mix threadline.verify_coverage` and doc-contract mix alias **inside** the same job **after** `mix verify.test` so migrations/tests ran first; alternatively run verify_coverage as part of test suite via `Mix.Task.run` in a test — CONTEXT prefers real Mix task in CI. **After** `mix verify.test` is correct: DB is up, schema exists from migrations in test helper.

**Config key:** Use `:threadline, :verify_coverage` or `:threadline, :expected_audit_tables` — align with `config/test.exs` for `Threadline.Test.Repo` expected set listing tables that have triggers in test schema.

## Findings

### Health module (single source of truth)

- `Threadline.Health.trigger_coverage/1` already queries `pg_tables` / `pg_trigger` with `threadline_audit_%` pattern; **do not duplicate** SQL in Mix task (D-01).

### Mix task patterns

- Existing tasks use `use Mix.Task`, `@shortdoc`, `@moduledoc`, `Mix.shell().info` for user messages; errors via **`Mix.raise/2`**.
- Repo resolution: follow patterns from community (Oban, Ecto) — `Application.get_env(:my_app, :ecto_repos)` after ensuring app started; for the **library** repo in tests, `config :threadline, ...` is acceptable per CONTEXT.

### CI / Nyquist

- `mix.exs` `ci.all` is a single literal string asserted in **`Threadline.Phase06NyquistCIContractTest`** — any alias change **must** update that test the same commit.
- `verify-test` job: add steps after line 84–85 for `mix threadline.verify_coverage` and `mix verify.doc_contract` (or combined `mix verify.threadline` that chains both).

### Doc contract (Elixir)

- **Doctest** on `@moduledoc` for small API; **separate `.ex` files under `test/`** that mirror README fences compile under `MIX_ENV=test` — renaming `Threadline.Foo` breaks compile.
- Avoid regex-only README parsing as primary gate (D-11).

### Risks

- **False positives:** mitigated by explicit expected table list only (D-02, D-04).
- **CI flakiness:** ensure verify_coverage uses same `DB_HOST`/repo as tests.

## Validation Architecture

This phase is **Elixir / ExUnit** with PostgreSQL in CI.

### Dimension coverage

| Dimension | Strategy |
|-----------|----------|
| Unit | Pure policy functions: expected set ∩ `trigger_coverage` results → violations list; exit code mapping |
| Integration | `DataCase` or dedicated case: create table without trigger, expect **non-zero** exit when invoking Mix programmatically or via `System.cmd("mix", ...)` in tmp dir |
| CI | `mix ci.all` green locally; `verify-test` job runs new steps; CI-02 literal matches `mix.exs` |
| Regression | Extend `health_test.exs` for parity: Mix task output tags match `trigger_coverage/1` for same repo state |

### Commands

- **Quick:** `MIX_ENV=test mix test test/threadline/health_test.exs test/threadline/verify_coverage_test.exs` (paths TBD)
- **Full gate:** `MIX_ENV=test mix ci.all` (Postgres required)

### Sampling

- After each task touching Elixir: `mix compile --warnings-as-errors`
- After each plan wave: `MIX_ENV=test mix test` (subset acceptable during dev; full before verify-work)

### Wave 0

- **None** — test framework and Postgres service already exist from prior phases.

---

## RESEARCH COMPLETE
