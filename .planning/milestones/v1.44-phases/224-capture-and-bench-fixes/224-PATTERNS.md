# Phase 224: Capture and Bench Fixes - Pattern Map

**Mapped:** 2026-09-30
**Files analyzed:** 12 (2 source edits, 6 new/extended test files, 1 CI job edit, 2 doc edits, 1 alias/mix.exs edit)
**Analogs found:** 12 / 12 (every file has a concrete same-repo analog; several files ARE their own analog — this phase edits existing code in place rather than creating new modules for the source fix)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mix/tasks/threadline.gen.triggers.ex` (`down_body/2`, new comment helper) | generator (Mix task, code-gen) | transform | itself — `retire_ups/1` / `rerun_rollback_comment/2` in the same file | exact (self-analog, established idiom in-file) |
| `bench/mix.exs` (`def cli`) | config | config | root `mix.exs` `def cli` | exact |
| `mix.exs` (root) — new `"verify.bench_compile"` alias + `verify_bench_compile/1` + `ci.all` insertion | config/utility (Mix alias) | batch (shell-out) | `verify_deps_audit/1` / `verify_repo_hygiene/1` (same file) | exact |
| `.github/workflows/ci.yml` — new step in `verify-compile-no-optional` job | config (CI) | batch | the job's own existing "Compile without optional deps (warnings-as-errors)" step | exact |
| `test/threadline/capture/trigger_rerun_test.exs` — new `describe` block + `apply_down!/1` | test (integration, DB-backed) | CRUD (DDL apply/rollback) | `test/threadline/upgrade_rollback_test.exs` (`Harness.migrate_down/1`, `Harness.cleanup!/1`) + the file's own `generate!/2`/`apply_up!/1` | exact |
| `test/threadline/capture/trigger_rerun_property_test.exs` (new file) | test (property, DB-backed) | event-driven / batch (sequence application) | `test/threadline/mix/trigger_migration_property_test.exs` (structure) + `test/threadline/upgrade_rollback_test.exs` (DB-backed `DataCase async:false` idiom + orphan-check SQL) | role-match (pure-property structure) + exact (DB-backed idiom) |
| `test/support/trigger_run_generators.ex` (new file) | utility (StreamData generator module) | transform | `test/support/naming_generators.ex` | exact |
| `test/mix/tasks/threadline/gen_triggers_test.exs` — update 5 pinned assertion blocks | test (unit, exact-output) | transform | itself — the existing `describe "down body"` block | exact (self-analog) |
| `test/threadline/ci_topology_contract_test.exs` OR a small new contract test file — pin `bench/mix.exs`'s `preferred_envs` | test (text-contract) | transform | `test/threadline/ci_topology_contract_test.exs` ("ci.all alias does not include verify.bench" test, lines 19-31) | exact |
| `guides/upgrading-to-0.11.md` §"## Rolling back" — extend prose | config/doc | transform | itself — the existing pinned `<!-- threadline:rollback-cleanup-sql:start/end -->` block | exact (self-analog) |
| `CHANGELOG.md` — new `Fixed` entry | doc | transform | existing CHANGELOG `Fixed`-section entries (house style, human-owned) | role-match |
| `CONTRIBUTING.md` — update `verify-compile-no-optional` job-table row | doc | transform | itself — the existing job-table row | exact (self-analog) |

## Pattern Assignments

### `lib/mix/tasks/threadline.gen.triggers.ex` (generator, transform) — D-01/D-02/D-03/D-04/D-05

**Analog:** the file's own `retire_ups/1` (lines 558-562) and `rerun_rollback_comment/2` (lines 616-629) — this is an in-place edit, not a new module, so the "analog" is the sibling function whose idiom the new code must match.

**Current `down_body/2` to change** (lines 588-606):
```elixir
defp down_body(table_specs, rerun_tables) do
  first_run_specs = Enum.reject(table_specs, fn {t, _} -> t in rerun_tables end)

  trigger_downs =
    Enum.map_join(first_run_specs, "\n\n", fn {t, _} ->
      execute_line(TriggerSQL.drop_trigger(t))
    end)

  function_downs =
    first_run_specs
    |> Enum.filter(fn {_t, %{needs_per_table: n?}} -> n? end)     # <- D-01: DELETE this filter
    |> Enum.map_join("\n\n", fn {t, _} ->
      execute_line(TriggerSQL.drop_function_if_unused(Naming.function_name(t)))
    end)

  [rerun_rollback_comment(table_specs, rerun_tables), trigger_downs, function_downs]
  |> Enum.reject(&(&1 == ""))
  |> Enum.join("\n\n")
end
```

**D-01 change:** delete the `Enum.filter(fn {_t, %{needs_per_table: n?}} -> n? end)` line so `function_downs` maps over ALL `first_run_specs`, unconditionally. `retire_ups/1` already establishes the "call `drop_function_if_unused` unconditionally over a candidate set" idiom this mirrors — `retire_ups/1` just has a different candidate set (`retire_set/1`) and no per-line comment.

**D-04 comment idiom to mirror** (`rerun_rollback_comment/2`, lines 616-629):
```elixir
defp rerun_rollback_comment(table_specs, rerun_tables) do
  ([
     "This migration replaced the audit trigger of #{Enum.join(rerun_tables, ", ")} in place.",
     "Rolling it back does not restore the earlier capture policy.",
     ...
   ] ++ retired_lines(table_specs, rerun_tables))
  |> Enum.map_join("\n", &("    # " <> &1))
end
```
The new first-run per-table comment is a SHORT version of this same idiom (`Enum.map_join("\n", &("    # " <> &1))`), one or two lines, prepended per-table before its `execute_line(TriggerSQL.drop_function_if_unused(...))` call — CONTEXT's suggested wording: "This also removes the per-table capture function of `<table>` if a later rerun created one and no trigger still uses it."

**`execute_line/1` helper (unchanged, reuse as-is)** (line 611-612):
```elixir
defp execute_line(sql),
  do: "    execute #{inspect(sql, printable_limit: :infinity, limit: :infinity)}"
```
The D-04 comment line(s) are plain strings joined with `\n\n` alongside the `execute_line` output in the same `Enum.map_join`, not passed through `execute_line/1` (comments are never `execute`d SQL).

**Do NOT touch:** `retire_ups/1` (lines 558-562), `guard_ups/1`, `trigger_ups/1`, `function_ups/1` — none of these are part of the down path. Also do not touch the rerun-side `down` behavior (the `[]` branch tested at `gen_triggers_test.exs:816-817`).

---

### `bench/mix.exs` (config) — D-13

**Full current file** (30 lines, no `def cli/0`):
```elixir
defmodule Bench.MixProject do
  use Mix.Project

  def project do
    [
      app: :bench,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end
  ...
  defp deps do
    [
      {:threadline, path: "..", env: :test},
      ...
    ]
  end
end
```

**Analog — root `mix.exs`'s own `def cli`** (`mix.exs:7-32`):
```elixir
def cli do
  # Run the whole CI chain in :test so `test` picks up config/test.exs (Postgres, repo).
  # Topology tasks need `test/support` (Threadline.Test.Repo) on the compile path.
  [
    preferred_envs: [
      "ci.all": :test,
      ...
      "verify.test": :test,
      ...
    ]
  ]
end
```

**Change:** add, inside `Bench.MixProject`, right after `defmodule ... do` (before `def project`):
```elixir
def cli do
  [preferred_envs: [compile: :test, run: :test]]
end
```
`run: :test` is required alongside `compile: :test` because `bench/bench_helper.exs`'s `setup/0` halts unless `Mix.env() == :test`. Keep `{:threadline, path: "..", env: :test}` in `deps/0` unchanged.

---

### `mix.exs` (root) — new alias, D-14

**Analog — existing small shell-out alias** (`mix.exs:268-273`, `verify_deps_audit/1`):
```elixir
defp verify_deps_audit(_args) do
  case Mix.shell().cmd("bin/verify-deps-audit") do
    0 -> :ok
    status -> Mix.raise("verify.deps_audit failed (#{status})")
  end
end
```

**New alias to add** — same pattern, but with an inline `bash -lc` command mirroring `verify_bench/1` (`mix.exs:258-266`):
```elixir
defp verify_bench(_args) do
  cmd =
    "bash -lc 'set -euo pipefail && cd bench && mix deps.get && MIX_ENV=test mix run ...'"

  case Mix.shell().cmd(cmd) do
    0 -> :ok
    status -> Mix.raise("verify.bench failed (#{status})")
  end
end
```

**D-14 shape:**
```elixir
defp verify_bench_compile(_args) do
  cmd = "bash -lc 'set -euo pipefail && cd bench && mix deps.get && mix compile --warnings-as-errors'"

  case Mix.shell().cmd(cmd) do
    0 -> :ok
    status -> Mix.raise("verify.bench_compile failed (#{status})")
  end
end
```
Register it in `aliases/0` right next to `"verify.bench": &verify_bench/1` (line 180):
```elixir
"verify.bench": &verify_bench/1,
"verify.bench_compile": &verify_bench_compile/1,
```
Then insert `"verify.bench_compile"` into the `"ci.all": [...]` list (lines 222-254) immediately after `"verify.compile_no_optional"` (line 232) — per D-14. Note NO `MIX_ENV=` prefix in this command, unlike `verify_bench/1`'s `MIX_ENV=test mix run ...` lines — the whole point is that `bench/mix.exs`'s new `preferred_envs` resolves the env, not an explicit env var.

Confirm (per D-14) that `test/threadline/ci_topology_contract_test.exs`'s "ci.all alias does not include verify.bench" test (lines 19-31, quoted below) matches only the literal `"verify.bench"` substring and does not false-positive on `"verify.bench_compile"`:
```elixir
test "ci.all alias does not include verify.bench" do
  mix_exs = read_rel!(["mix.exs"])
  assert mix_exs =~ "\"ci.all\": ["
  [_, ci_all_block] = String.split(mix_exs, "\"ci.all\": [")
  [ci_all_list | _] = String.split(ci_all_block, "]")
  refute String.contains?(ci_all_list, "\"verify.bench\"")
end
```
This does a plain substring `contains?` check for the exact quoted token `"verify.bench"` (with the closing quote), so `"verify.bench_compile"` — whose next character after `verify.bench` is `_`, not `"` — does not match. No change needed to this test.

---

### `.github/workflows/ci.yml` (CI config) — D-15

**Analog — the job's own existing step it is added after** (lines 189-206):
```yaml
verify-compile-no-optional:
  name: Compile without optional deps
  runs-on: ubuntu-24.04
  timeout-minutes: 10
  steps:
    - uses: actions/checkout@v5

    - uses: erlef/setup-beam@v1
      id: beam
      with:
        version-file: .tool-versions
        version-type: strict

    - name: Install dependencies
      run: mix deps.get

    - name: Compile without optional deps (warnings-as-errors)
      run: mix verify.compile_no_optional
```

**Change:** append one step after "Compile without optional deps (warnings-as-errors)", keeping the job `name:` ("Compile without optional deps") and `id:` untouched, and adding NO cache step:
```yaml
    - name: Compile bench project (bare mix compile)
      run: mix verify.bench_compile
```

**Constraint (Pitfall 4 / anti-pattern):** `test/threadline/ci_workflow_parity_contract_test.exs`'s `no_optional_cache_errors/1` (around line 4032) scans the WHOLE `verify-compile-no-optional` job block for any `- uses: actions/cache` line — do not add one.

---

### `test/threadline/capture/trigger_rerun_test.exs` — new `describe` block, D-08/D-09

**Analog 1 — `test/threadline/upgrade_rollback_test.exs`'s use of `MigrationHarness`** (`test/threadline/upgrade_rollback_test.exs:34-38, 79-98`):
```elixir
alias Threadline.Test.MigrationHarness, as: Harness
...
on_exit(fn ->
  ...
  Repo.query!(TriggerSQL.install_function([]))
  Harness.cleanup!(Harness.migration_files(tmp))
  ...
end)
```

**`MigrationHarness` itself** (`test/support/migration_harness.ex`, full file read — reuse unchanged):
```elixir
def generate!(tmp, args) do
  before = migration_files(tmp)
  File.cd!(tmp, fn -> Triggers.run(args) end)
  case migration_files(tmp) -- before do
    [file] -> file
    other -> raise "expected one new migration file, got: #{inspect(other)}"
  end
end

def migrate_up(file), do: migrate(file, :up)
def migrate_down(file), do: migrate(file, :down)

defp migrate(file, direction) do
  module = load!(file)
  version = version(file)
  ...
  result = apply(Ecto.Migrator, direction, [Repo, version, module])
  ...
end

def cleanup!(files) do
  for file <- files do
    Repo.query!("DELETE FROM schema_migrations WHERE version = $1", [version(file)])
    ...
  end
  :ok
end
```
This is the exact `Ecto.Migrator`-based apply/rollback mechanism CONTEXT's D-08 fidelity question asks about — reuse `Harness.generate!/2`, `Harness.migrate_up/1`, and add/reuse `Harness.migrate_down/1` as the `apply_down!/1` D-08 calls for (it already exists under the name `migrate_down/1`; the new `describe` block can alias it as `apply_down!` locally or call it directly). `Harness.cleanup!/1` is the teardown to call in `on_exit`.

**Analog 2 — the file's OWN existing `generate!/2`/`apply_up!/1` idiom** (lines 317-348, `test/threadline/upgrade_rollback_test.exs`, reused as the older/simpler sibling pattern already in `trigger_rerun_test.exs` too, lines 221/244/261/334):
```elixir
defp generate!(tmp, args) do
  before = migration_files(tmp)
  File.cd!(tmp, fn -> Triggers.run(args) end)
  [file] = migration_files(tmp) -- before
  file
end

defp apply_up!(file) do
  ast = file |> File.read!() |> Code.string_to_quoted!()
  {_, [body]} =
    Macro.prewalk(ast, [], fn
      {:def, _, [{:up, _, _}, [do: body]]} = node, acc -> {node, [body | acc]}
      node, acc -> {node, acc}
    end)
  {_, sqls} =
    Macro.prewalk(body, [], fn
      {:execute, _, [sql]} = node, acc when is_binary(sql) -> {node, [sql | acc]}
      node, acc -> {node, acc}
    end)
  sqls |> Enum.reverse() |> Enum.each(&Repo.query!/1)
end
```
**Per D-08/Research Pattern 3:** this text-extraction pattern cannot exercise `down` at all (no `Ecto.Migrator`, no real rollback), so it is NOT sufficient for CAPT-02's partial/full-rollback assertions — use `MigrationHarness`'s `Ecto.Migrator`-based `migrate_up/1`/`migrate_down/1` for the new `describe` block instead, per the Research's explicit recommendation.

**D-09 orphan-check SQL to port** — copy from `test/threadline/upgrade_rollback_test.exs`'s own helpers (lines 322-337+, already live-tested):
```elixir
defp suffixed_functions(storage) do
  %{rows: rows} =
    Repo.query!(
      """
      SELECT p.proname
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = $1
        AND p.proname LIKE 'threadline\\_capture\\_changes\\_%' ESCAPE '\\'
      ORDER BY p.proname
      """,
      [storage]
    )

  Enum.map(rows, fn [name] -> name end)
end

defp function_has_trigger?(storage, function_name) do
  %{rows: [[count]]} =
    Repo.query!(
      """
      SELECT count(*)
      FROM pg_trigger t
      JOIN pg_proc p ON p.oid = t.tgfoid
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = $1 AND p.proname = $2 AND NOT t.tgisinternal
      ...
      """,
      [storage, function_name]
    )
  count > 0
end
```
D-09 additionally requires filtering on `t.tgparentid = 0` (partition-clone exclusion) — this exact join shape (`pg_trigger t JOIN pg_proc p ON p.oid = t.tgfoid`, filtered `tgparentid = 0`) is also already used inside `TriggerSQL.drop_function_if_unused/2`'s own `DO` block (`lib/threadline/capture/trigger_sql.ex:138-141`) — port that exact predicate, parameterized on `StorageSchema.get()`, never hardcoded `'public'` and never relying on `search_path` (D-09's explicit warning).

---

### `test/threadline/capture/trigger_rerun_property_test.exs` (new file) — D-10

**Analog 1 — pure-property structure to mirror (NOT to modify)** — `test/threadline/mix/trigger_migration_property_test.exs` (full file, 35 lines):
```elixir
defmodule Threadline.Mix.TriggerMigrationPropertyTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Threadline.Test.NamingGenerators

  alias Threadline.Capture.{Naming, TriggerSQL}
  alias Threadline.Mix.TriggerMigration

  property "a table's own generated trigger migration is a rerun of it" do
    check all(pair <- pair_gen(), max_runs: 300) do
      assert TriggerMigration.rerun?(pair, [generated(pair)])
    end
  end
end
```
D-10 explicitly says the NEW file sits "next to the rerun test, not in the pure `trigger_migration_property_test.exs`" — do not add to this file; only mirror its `use ExUnit.Case`/`use ExUnitProperties`/`property "..." do check all(...) end` shape.

**Analog 2 — DB-backed `async: false` idiom** — `test/threadline/upgrade_rollback_test.exs:32`:
```elixir
use Threadline.DataCase, async: false
```
The new file uses `use Threadline.DataCase` (per D-10, `async: false`) instead of `use ExUnit.Case, async: true`, because each `check all` iteration performs real DDL against Postgres.

**`@max_runs` module attribute (D-10):**
```elixir
@max_runs 20
```
Named exactly this way so Phase 226 can later swap it for `THREADLINE_PROPERTY_SCALE` in one line (per D-10 — do not build that env var now).

**Unique-name-per-iteration + `try/after` idiom** — mirror `System.unique_integer` usage already established in `test/threadline/upgrade_rollback_test.exs:67` (`System.unique_integer([:positive])`) and D-10's own guidance: use `System.unique_integer([:positive, :monotonic])` per iteration, with `try/after` cleanup inside `check all` (NOT `on_exit`, which does not fire between property iterations).

---

### `test/support/trigger_run_generators.ex` (new file) — D-10

**Analog:** `test/support/naming_generators.ex` (full file, reused above) — same module shape:
```elixir
defmodule Threadline.Test.NamingGenerators do
  @moduledoc """..."""
  use ExUnitProperties

  def ident(max) do
    gen all(head <- member_of(@first), tail <- string(@rest, max_length: max - 1)) do
      <<head>> <> tail
    end
  end

  def pair_gen do
    frequency([
      {4, map(ident(63), &public/1)},
      ...
    ])
  end
end
```
`Threadline.Test.TriggerRunGenerators` follows this exact idiom: `use ExUnitProperties`, a `frequency([...])` generator (here producing 1-4 ordered `:default`/per-table-forcing runs per D-10, instead of `naming_generators.ex`'s identifier-pair bias), `gen all(...)` blocks building the run list. Do NOT reuse `pair_gen()`'s collision-biased long names for the DB property (D-10 explicitly says not to — use a plain unique table name via `System.unique_integer/1` instead, generated in the property test itself, not this generator module).

---

### `test/mix/tasks/threadline/gen_triggers_test.exs` — update 5 pinned assertion blocks, D-12

**Analog:** the file's own existing `describe "down body"` block (self-analog; this is a pin update, not new code).

**Current assertions to update** (lines 787-807, read this session):
```elixir
test "a first-run table keeps today's rollback", %{tmp: tmp} do
  Application.delete_env(:threadline, :storage_schema)
  run_triggers(tmp, ["--tables", "posts"])

  [file] = trigger_files(tmp)
  assert executes(file, :down) == [TriggerSQL.drop_trigger("posts")]
  refute File.read!(file) =~ "does not restore the earlier capture policy"

  per_table = Path.join(tmp, "per_table")
  File.mkdir_p!(per_table)
  run_triggers(per_table, ["--tables", "test_redaction_users"])

  [file] = trigger_files(per_table)

  assert executes(file, :down) == [
           TriggerSQL.drop_trigger("test_redaction_users"),
           TriggerSQL.drop_function_if_unused(Naming.function_name("test_redaction_users"))
         ]

  refute File.read!(file) =~ "does not restore the earlier capture policy"
end

test "a rerun table's rollback leaves capture on", %{tmp: tmp} do
  ...
  assert executes(first, :down) == [TriggerSQL.drop_trigger("posts")]
  assert executes(rerun, :down) == []
  ...
end
```
After D-01, the FIRST assertion (`executes(file, :down) == [TriggerSQL.drop_trigger("posts")]` for a plain `posts` table with no per-table opts) must become:
```elixir
assert executes(file, :down) == [
         TriggerSQL.drop_trigger("posts"),
         TriggerSQL.drop_function_if_unused(Naming.function_name("posts"))
       ]
```
because `posts` is now a first-run table and D-01 makes the function drop unconditional. The rerun-side assertion (`executes(rerun, :down) == []`) is UNCHANGED — D-01 never touches rerun downs. Also update the `refute ... "does not restore the earlier capture policy"` lines to additionally check for the new D-04 comment wording if it is pinned, and the mixed-table-set test (lines 831-843) and the "names the function it retired" test (lines 845-862+) per Pitfall 2's full line-range list (`@generated_down_phrases`/`@rerun_doc_phrases` around lines 21-31, describe block 907-953).

**Helper functions already in the file to reuse unchanged** (lines 60, 74, 102):
```elixir
defp run_triggers(tmp, args) do ... end
defp trigger_files(tmp) do ... end
defp executes(file, fun_name) do ... end
```

---

### Contract test pinning `bench/mix.exs`'s `preferred_envs` — D-16

**Analog:** `test/threadline/ci_topology_contract_test.exs`'s existing "ci.all alias does not include verify.bench" test (lines 19-31, full text quoted above under the `mix.exs` section) — same `read_rel!/1` + plain string-contains idiom:
```elixir
defmodule Threadline.CiTopologyContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  test "..." do
    yaml = read_rel!([".github", "workflows", "ci.yml"])
    assert String.contains?(yaml, "...")
  end
end
```
New test (either added to this file or a small new file near it, per Research's A1 discretion note):
```elixir
test "bench/mix.exs declares preferred_envs with compile: :test" do
  bench_mix_exs = read_rel!(["bench", "mix.exs"])
  assert bench_mix_exs =~ "def cli do"
  assert bench_mix_exs =~ "compile: :test"
end
```

---

### `guides/upgrading-to-0.11.md` §"## Rolling back" — extend prose, D-06

**Analog:** the section's own existing prose immediately preceding the pinned SQL block (lines ~245-256, read this session):
```markdown
## Rolling back

Trigger migrations generated by 0.10.x end their `down` with a function drop
that cascades. Rolling one of those back after you upgrade can drop a
sibling table's live trigger along with it, if the two ever shared a
function. Do not roll back a pre-0.11 trigger migration as generated --
regenerate forward instead. If you must roll one back, edit its `down` first
so it drops its own triggers (`DROP TRIGGER ...`, no cascade), then runs the
rollback-cleanup SQL below in place of its function drop.

<!-- threadline:rollback-cleanup-sql:start -->
```sql
...
```
<!-- threadline:rollback-cleanup-sql:end -->
```
**D-06 change:** add prose broadening the section (plain, specific, no hype — Claude's Discretion for exact wording) to also cover "a first trigger migration generated before this fix, followed by a rerun that added redaction, exclusions, or `store_changed_from`" and point that case at the SAME existing marker pair — do not add a second `<!-- threadline:rollback-cleanup-sql:... -->` pair (this is pinned by `test/threadline/upgrading_to_0_11_doc_contract_test.exs`, which asserts on the markers and heading — update its assertions only if the heading/pinned text itself changes, not for new prose added under it).

---

## Shared Patterns

### `TriggerSQL.drop_function_if_unused/2` — reused completely unchanged (D-02)
**Source:** `lib/threadline/capture/trigger_sql.ex:124-149` (already read/confirmed this session per RESEARCH.md)
**Apply to:** `down_body/2`'s new unconditional `function_downs` call — no `quiet:` option, no new parameter, no change to its SQL or WARNING text. It is `@moduledoc false` and idempotent/usage-checked already (no-op if the function doesn't exist; skips + WARNs if a live trigger still uses it).

### `Naming.function_name/1` — deterministic per-table name, the core fact behind D-01
**Source:** `lib/threadline/capture/naming.ex` (full file read this session)
**Apply to:** both `down_body/2` (generation-time call) and the D-09 orphan-check helper (optional secondary assertion per D-09 — never the ONLY orphan check, since that would be tautological against the structural `pg_proc`/`pg_trigger` check).

### `MigrationHarness` — the one apply/rollback mechanism for all DB-backed capture tests
**Source:** `test/support/migration_harness.ex` (full file)
**Apply to:** the CAPT-02 regression `describe` block AND (by generator-level composition inside `check all`) the CAPT-02 property test. Do not build a second isolated-migrations mechanism — `Harness.generate!/2` + `Harness.migrate_up/1` + `Harness.migrate_down/1` + `Harness.cleanup!/1` is the complete, already-proven cycle.

### Structural orphan-check SQL — one shape, three call sites
**Source:** `guides/upgrading-to-0.11.md`'s pinned cleanup SQL (lines 255-273) == `test/threadline/upgrade_rollback_test.exs`'s `suffixed_functions/1` + `function_has_trigger?/2` (lines 322+) == `TriggerSQL.drop_function_if_unused/2`'s own internal `DO` block join (`lib/threadline/capture/trigger_sql.ex:138-141`).
**Apply to:** the new D-09 orphan-check helper in the CAPT-02 regression test and the CAPT-02 property test — port this exact `pg_proc JOIN pg_namespace ... LIKE 'threadline\_capture\_changes\_%'` + `pg_trigger ... tgparentid = 0` shape a fourth time, parameterized on `StorageSchema.get()`, never on `search_path`.

### `Mix.shell().cmd(...)` alias pattern for shell-out verification tasks
**Source:** `mix.exs` root — `verify_bench/1` (258-266), `verify_deps_audit/1` (268-273), `verify_repo_hygiene/1` (275-280)
**Apply to:** the new `verify_bench_compile/1`. All three existing examples follow `case Mix.shell().cmd(cmd) do 0 -> :ok; status -> Mix.raise("verify.X failed (#{status})") end`.

## No Analog Found

None — every file this phase touches has a direct same-repo analog (several are self-analogs, since this phase is dominated by in-place edits to existing generator/test/CI/doc code rather than net-new architecture).

## Metadata

**Analog search scope:** `lib/mix/tasks/`, `lib/threadline/capture/`, `test/support/`, `test/threadline/capture/`, `test/threadline/mix/`, `test/mix/tasks/threadline/`, `test/threadline/ci_*_contract_test.exs`, `bench/`, root `mix.exs`, `.github/workflows/ci.yml`, `guides/upgrading-to-0.11.md`, `CONTRIBUTING.md`.
**Files scanned:** 17 read in full or targeted-range this session (see list below); all confirmed git-tracked via `git ls-files`.
**Pattern extraction date:** 2026-09-30

**Files read this session (all confirmed tracked):**
`lib/mix/tasks/threadline.gen.triggers.ex`, `lib/threadline/capture/trigger_sql.ex` (via CONTEXT/RESEARCH citation), `lib/threadline/capture/naming.ex` (via citation), `test/support/migration_harness.ex`, `test/support/naming_generators.ex`, `test/threadline/mix/trigger_migration_property_test.exs`, `test/threadline/capture/trigger_rerun_test.exs`, `test/threadline/upgrade_rollback_test.exs`, `test/mix/tasks/threadline/gen_triggers_test.exs`, `test/threadline/ci_topology_contract_test.exs`, `bench/mix.exs`, `mix.exs` (root), `.github/workflows/ci.yml`, `guides/upgrading-to-0.11.md`.
