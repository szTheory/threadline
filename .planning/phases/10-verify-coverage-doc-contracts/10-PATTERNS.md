# Phase 10 — Pattern Map

## Analog: Mix task + `Mix.raise`

**New file:** `lib/mix/tasks/threadline.verify_coverage.ex`  
**Analog:** `lib/mix/tasks/threadline.install.ex`  
**Pattern:** `use Mix.Task`, `@shortdoc`, `@moduledoc` with usage, `def run(args)`, `Mix.raise/2` for invalid config, `Mix.shell().info` / `IO.puts` for stdout.

```elixir
# From threadline.install.ex
use Mix.Task
@impl Mix.Task
def run(_args) do
```

## Analog: Health + SQL

**Extend / call:** `lib/threadline/health.ex`  
**Pattern:** `Ecto.Adapters.SQL.query!(repo, sql, [])` — **do not copy** queries into Mix; call `Threadline.Health.trigger_coverage(repo: repo)` only.

## Analog: CI contract literal

**File:** `test/threadline/phase06_nyquist_ci_contract_test.exs`  
**Pattern:** `read_rel!(["mix.exs"])` then `assert String.contains?(mix, ~s("ci.all": [...]))` — exact string must match `mix.exs` `aliases` key.

## Analog: Integration test with Repo

**File:** `test/threadline/health_test.exs`  
**Pattern:** `use Threadline.DataCase`, `@repo Threadline.Test.Repo`, call library functions against migrated schema.

## Files to create (greenfield)

| Path | Role |
|------|------|
| `lib/threadline/verify/coverage_policy.ex` | Pure `violations/2` from tuples + expected list |
| `lib/mix/tasks/threadline.verify_coverage.ex` | Mix entry |
| `test/threadline/verify_coverage_policy_test.exs` | Unit tests |
| `test/threadline/verify_coverage_task_test.exs` | Exit code / stdout smoke |
| `test/threadline/readme_doc_contract_test.exs` | Compile-checked README API mirrors |
