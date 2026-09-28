# Phase 209: Collision-Free Emission - Pattern Map

**Mapped:** 2026-09-25
**Files analyzed:** 17 (3 lib modified, 7 test created, 7 test modified/rewritten)
**Analogs found:** 16 / 17 (the D-01/D-05 DO-block SQL has no in-repo analog; use RESEARCH.md Code Examples verbatim)

All analog paths below were checked with `git ls-files` (tracked source; no mirror paths).

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/threadline/capture/trigger_sql.ex` (modify) | utility (SQL builder) | transform | itself: `drop_trigger/1` (151-156), `create_trigger_sql/2` (140-149), `drop_function/1` (89-92) | exact (in-file) |
| `lib/threadline/mix/trigger_migration.ex` (modify: `parse_triggers/1`, `rerun?/2`) | utility (text parser) | transform | itself: `scan/1` + `@defmodule` regex (19, 29-50) | exact (in-file) |
| `lib/mix/tasks/threadline.gen.triggers.ex` (modify: `write_migration!/3`, `migration_content/3`, delete `orphan_function_drop/1`, extend `rerun_rollback_comment/1`, D-06 advisory) | Mix task / generator | file-I/O | itself: lines 204-235, 290-381 | exact (in-file) |
| `test/support/notice_guard.ex` (new) | test support | event-driven (telemetry) | `test/threadline/telemetry_test.exs` (attach/detach) + RESEARCH skeleton | role-match |
| `test/test_helper.exs` (modify: attach + `after_suite` + `client_min_messages` assert) | config (test boot) | request-response | itself: stale-DB tripwire lines 52-77 | exact (in-file) |
| `test/support/notice_guard_canary.exs` (new, run only by explicit path) | test fixture | batch | `test/support/stress_router_prod_compile.exs` (+ its invocation at `stress_router_test.exs:285`) | role-match |
| `test/threadline/capture/notice_guard_test.exs` (new: positive/negative control + canary contract) | test | request-response + subprocess | `test/threadline/verify_coverage_task_test.exs:14-55` | exact (env-flag canary) |
| `test/support/legacy_trigger_sql.ex` (new: frozen 0.9 / 0.10.0 / 0.10.2 renderers) | test support | transform | `lib/threadline/capture/trigger_sql.ex:140-156` (copied template shape) + `trigger_rerun_test.exs:231-248` | role-match |
| `test/fixtures/legacy_trigger_migrations/*.exs` (new literal texts) | test fixture | file-I/O | `priv/ci/hex_evaluator/priv/repo/migrations/20260424080642_threadline_triggers_posts.exs` | exact |
| `test/threadline/capture/collision_free_emission_test.exs` (new real-PG SC1-SC3 via `Ecto.Migrator`) | test (integration) | CRUD / DDL | `test/threadline/capture/trigger_rerun_test.exs` (setup, `generate!`, catalog helpers) + `router_test.exs:44-49` (purge) | role-match |
| `test/threadline/mix/trigger_migration_test.exs` (rewrite `rerun?/2` describe, add property) | test (unit + property) | transform | itself lines 156-206 + `test/threadline/capture/naming_property_test.exs` | exact |
| `test/threadline/capture/trigger_rerun_test.exs` (modify 81-111, 195-228, 231-248) | test (integration) | CRUD / DDL | itself | exact |
| `test/threadline/capture/trigger_sql_storage_schema_test.exs` (modify 38-55) | test (unit) | transform | itself | exact |
| `test/mix/tasks/threadline/gen_triggers_test.exs` (modify 458-527; add D-06/D-07/D-11 tests) | test (Mix task) | file-I/O | itself: `executes/2` (99-117), `run_triggers/2` + `drain_shell/1` (59-70), `assert_received {:mix_shell, :error, …}` (360-362) | exact |
| `test/threadline/operator_surface/policy_show_mix_test.exs`, `trigger_redaction_test.exs`, `trigger_changed_from_test.exs` | test | CRUD | unchanged callers of `drop_function_for_table` (RESTRICT still works because `drop_trigger` runs first) | n/a - verify only |
| DO-block SQL text (D-01 drop-if-unused, D-05 guard) | SQL builder output | transform | none in repo | no analog |

---

## Pattern Assignments

### `lib/threadline/capture/trigger_sql.ex` (utility, transform)

**Analog:** itself.

**Imports / attributes** (lines 1-8) - keep; `@max_identifier_bytes 63` becomes unused once `per_table_function_fits?/1` is deleted, so delete it too (compile is `--warnings-as-errors`):
```elixir
defmodule Threadline.Capture.TriggerSQL do
  @moduledoc false

  alias Threadline.Capture.{Naming, RedactionPolicy}
  alias Threadline.StorageSchema

  # PostgreSQL's NAMEDATALEN - 1.
  @max_identifier_bytes 63
```

**Name builder to replace** (lines 158-170). Today:
```elixir
defp per_table_function_name(table_name, opts) do
  table_name
  |> per_table_function_base()
  |> StorageSchema.validate_identifier!(:derived)
  |> StorageSchema.function(opts)
end

defp per_table_function_base(table_name) do
  "threadline_capture_changes_#{StorageSchema.host_table_suffix(table_name)}"
end
```
New shape: `table_name |> Naming.function_name() |> StorageSchema.validate_identifier!(:derived) |> StorageSchema.function(opts)`. Delete `per_table_function_base/1`. Used at lines 96, 114, 136, 223, 312 - all five call sites keep calling `per_table_function_name/2`.

**Deletions** (lines 94-115): `drop_function_for_table/2` loses ` CASCADE` (keep it, RESTRICT, for test cleanup callers); delete `per_table_function_fits?/1` and `drop_orphan_function_for_table/2`.

**Builder style to copy for new DO-block builders** (lines 140-156) - heredoc SQL, identifiers via `StorageSchema.quote_ident/1` / `qualified_host_table/1`, never raw interpolation:
```elixir
defp create_trigger_sql(table_name, function_invocation) do
  trigger_name = Naming.trigger_name(table_name)
  host_table = StorageSchema.qualified_host_table(table_name)

  """
  CREATE OR REPLACE TRIGGER #{StorageSchema.quote_ident(trigger_name)}
  AFTER INSERT OR UPDATE OR DELETE ON #{host_table}
  FOR EACH ROW EXECUTE FUNCTION #{function_invocation}
  """
end

@doc "Returns SQL to drop a trigger from the given table."
def drop_trigger(table_name) do
  trigger_name = Naming.trigger_name(table_name)
  host_table = StorageSchema.qualified_host_table(table_name)
  "DROP TRIGGER IF EXISTS #{StorageSchema.quote_ident(trigger_name)} ON #{host_table}"
end
```
New builders (names at discretion), e.g. `drop_function_if_unused(function_name, opts)` taking a **bare function name** (retire set holds names no table owns) and `function_owner_guard(table, opts)`:
- Build the `to_regprocedure` literal as `'` <> `StorageSchema.function(StorageSchema.validate_identifier!(name, :derived), opts)` <> `()'` -> yields `'"threadline"."threadline_capture_changes_x"()'` (fully quoted, D-01).
- Owner literal: `'` <> `StorageSchema.qualified_host_table(table)` <> `'` for `to_regclass`.
- SQL body: copy RESEARCH.md "D-01 block (with the ORDER BY fix)" and "Pattern 3" verbatim; use `ORDER BY n.nspname, c.relname`, double `'` inside RAISE strings, use `$$` (function bodies use `$threadline_trigger$`, so no clash - see `global_install_function_sql_legacy` line 178).
- File is 561 lines; limit is 800 (`source_size_contract_test.exs`). If the builders push it near the limit, split into a sibling module (e.g. `Threadline.Capture.TriggerSQL.Cleanup`).

**Moduledocs to rewrite:** lines 40-41 (`threadline_capture_changes_<table>()`), 94, 100-112, 121. No planning vocabulary (`Phase \d`, `D-\d\d`, `NAME-0`).

---

### `lib/threadline/mix/trigger_migration.ex` (utility, text parser)

**Analog:** itself - module-attribute regex + `Regex.scan` over `sources` (lines 19, 40-43):
```elixir
@defmodule ~r/^\s*defmodule\s+([A-Z][A-Za-z0-9_.]*)\s+do\b/m
...
modules =
  for source <- sources, [_, module] <- Regex.scan(@defmodule, source), into: MapSet.new() do
    module
  end
```
Text-only contract to preserve (lines 11-14): "Host migration files are only read as text and matched with regular expressions. They are never compiled or evaluated".

**Replace** lines 71-95 (`@max_identifier_bytes`, `rerun?(trigger_name, sources)`). New shape per D-08 / RESEARCH Pattern 4:
- `parse_triggers(sources) :: [%{trigger: String.t(), schema: String.t() | nil, table: String.t()}]` - normalize `\"`->`"`, `\n`/`\t`/`\r` escapes -> space; `Regex.scan(..., capture: :all_but_first)`; branch on 2 vs 3 captures.
- Note the attribute comment at `naming.ex:53-55`: regex kept as a **source string** and compiled at call time (`Regex.compile!(@hash_tail)`) because some OTP releases refuse compiled regexes in module attributes. Follow that for the long D-08 regex (it needs the `"i"` flag): `@create_trigger_source "..."` + `Regex.compile!(@create_trigger_source, "i")`.
- `rerun?(%{schema: s, table: t}, sources)` built on `parse_triggers/1`; spec changes from `@spec rerun?(String.t(), [String.t()])` to `@spec rerun?(Naming.pair(), [String.t()])`.
- The `Naming` alias (line 16) is already present.

---

### `lib/mix/tasks/threadline.gen.triggers.ex` (Mix task, file-I/O)

**Analog:** itself.

**Rerun call site** (lines 218-232) - change `TriggerMigration.rerun?(Naming.trigger_name(pair), scan.sources)` to `TriggerMigration.rerun?(pair, scan.sources)`; add the D-06 advisory next to the existing `Mix.shell().info` block, using `Mix.shell().error` (test collects it via `assert_received {:mix_shell, :error, [warning]}`, `gen_triggers_test.exs:360-362`):
```elixir
rerun_tables =
  for {table, pair} <- tables_and_pairs,
      TriggerMigration.rerun?(Naming.trigger_name(pair), scan.sources),
      do: table

create_file(file, migration_content(table_specs, module, rerun_tables))

if rerun_tables != [] do
  Mix.shell().info(
    "These tables already have a Threadline trigger migration: " <>
      Enum.join(rerun_tables, ", ") <>
      ". Rolling back the new migration keeps their capture on."
  )
end
```

**Assembly pattern to extend** (lines 290-356). Copy the string-building idioms: `"    execute #{inspect(sql)}"`, `Enum.map_join(..., "\n\n", ...)`, `[parts] |> Enum.reject(&(&1 == "")) |> Enum.join("\n\n")`, and the final heredoc module template:
```elixir
up_body =
  [function_ups, trigger_ups]
  |> Enum.reject(&(&1 == ""))
  |> Enum.join("\n\n")

down_parts =
  [rerun_rollback_comment(rerun_tables), trigger_downs, function_downs]
  |> Enum.reject(&(&1 == ""))
  |> Enum.join("\n\n")

"""
defmodule #{module} do
  use Ecto.Migration

  def up do
#{up_body}
  end

  def down do
#{down_parts}
  end
end
"""
```
New order: `[function_ups, trigger_ups, guard_blocks, retire_blocks]` in up; `[comment, trigger_downs, function_drop_if_unused_blocks]` in down. Stop interleaving (line 313 `<> orphan_function_drop(t)`); delete `orphan_function_drop/1` (358-364). Retire-set computation: RESEARCH Pattern 2. Split into `defp` helpers to keep each function < 120 lines.

**First-run vs rerun split to keep** (lines 316-331):
```elixir
first_run_specs = Enum.reject(table_specs, fn {t, _} -> t in rerun_tables end)
...
function_downs =
  first_run_specs
  |> Enum.filter(fn {_t, %{needs_per_table: n?}} -> n? end)
  |> Enum.map_join("\n\n", fn {t, _} ->
    "    execute #{inspect(TriggerSQL.drop_function_for_table(t))}"   # -> D-01 block
  end)
```

**Comment builder to extend (D-07)** (lines 366-381) - add lines naming retired `<old>` / kept `<new>`; must keep the three `@generated_down_phrases` ("does not restore the earlier capture policy", "unredacted", "mix threadline.policy.show") and "Capture stays on", "continues unredacted" (asserted at `gen_triggers_test.exs:541-548`):
```elixir
defp rerun_rollback_comment(rerun_tables) do
  [
    "This migration replaced the audit trigger of #{Enum.join(rerun_tables, ", ")} in place.",
    "Rolling it back does not restore the earlier capture policy.",
    ...
  ]
  |> Enum.map_join("\n", &("    # " <> &1))
end
```
Signature will need the retired/new names per table (pass `table_specs` or a precomputed map).

**Stale docs:** moduledoc 17-29, 49-54, 84-92; comment 196-197 (`parse_tables!`). Moduledoc must keep `@rerun_doc_phrases` (`gen_triggers_test.exs:20-25`) including "replaces the trigger in place".

---

### `test/support/notice_guard.ex` (test support, event-driven)

**Analog:** `test/threadline/telemetry_test.exs:14-25` for attach/detach idiom; RESEARCH "NoticeGuard skeleton" for the body.
```elixir
:telemetry.attach(
  "test-action-recorded-ok",
  [:threadline, :action, :recorded],
  fn _name, measurements, _meta, pid ->
    send(pid, {:action_recorded, measurements})
  end,
  self()
)

on_exit(fn -> :telemetry.detach("test-action-recorded-ok") end)
```
Differences for the guard: use a **named module function capture** (`&__MODULE__.handle/4`) not an anonymous fn (telemetry warns on local fns and it must survive the whole suite); never detach; wrap body in `rescue`; ETS `:public, :named_table, :duplicate_bag`; key by `List.last(Process.get(:"$callers", [])) || self()` (Ecto.Migrator runs in `Task.async`). Repo event: `[:threadline, :test, :repo, :query]` (repo at `test/support/repo.ex` has no `telemetry_prefix`). Compiled automatically: `mix.exs:81` `elixirc_paths(:test) -> ["lib", "test/support"]`. Module naming follows `Threadline.Test.Repo` (`test/support/repo.ex:1`): `Threadline.Test.NoticeGuard`, `@moduledoc false` or a short moduledoc listing coverage limits.

---

### `test/test_helper.exs` (test boot config)

**Analog:** itself - the stale-DB tripwire (lines 52-77) is the pattern for a boot-time assertion that raises with a named cause and fix:
```elixir
stale_public_audit_tables =
  Ecto.Adapters.SQL.query!(repo, """
  select table_name from information_schema.tables
  ...
  """, []).rows
  |> List.flatten()

if stale_public_audit_tables != [] do
  raise """
  Threadline tests: ...
  Fix: `mix test.reset` ...
  """
end
```
Placement: `NoticeGuard.attach!()` right after `{:ok, _} = repo.start_link()` (line 35) and **before** `Ecto.Migrator.run` (line 38); `ExUnit.after_suite(&Threadline.Test.NoticeGuard.verify!/1)` anywhere after `ExUnit.start()` (line 1); `SHOW client_min_messages` assert via the same `Ecto.Adapters.SQL.query!(repo, …)` form. Decide behaviour inside `unless topology_pooler?` (lines 12, 37) - RESEARCH Open Question 2 recommends attaching in both lanes, skipping only the `client_min_messages` assert under topology. Do not touch `ExUnit.configure(exclude: …)` (line 6-7): `zero_skips_contract_test.exs:64-79` pins it.

---

### `test/support/notice_guard_canary.exs` (fixture run by explicit path)

**Analog:** `test/support/stress_router_prod_compile.exs` - a `.exs` in `test/support` that is never compiled by `elixirc_paths` and never matched by `*_test.exs`; it is executed only by explicit path from a test (`stress_router_test.exs:285`: `["-lc", "MIX_ENV=prod mix run --no-start test/support/stress_router_prod_compile.exs"]`). The canary instead is a small `use ExUnit.Case` module run via `mix test test/support/notice_guard_canary.exs`, guarded by `if System.get_env("THREADLINE_TRUNCATION_GUARD_CANARY") == "1"` so a manual run is harmless. It must **not** use a skip/exclude tag (`zero_skips_contract_test.exs` forbids new exclusions and scans test files for skip needles).

Note `test_structure_contract_test.exs:37-44` allowlists `stress_router_prod_compile.exs` only because it contains `use Phoenix.Router`; the canary contains no router/endpoint, so no allowlist entry is needed.

---

### `test/threadline/capture/notice_guard_test.exs` (test, request-response + subprocess contract)

**Analog:** `test/threadline/verify_coverage_task_test.exs:1-55`.

**Module header + env helper** (lines 1-18):
```elixir
defmodule Threadline.VerifyCoverageTaskTest do
  use ExUnit.Case, async: false
  ...
  defp cmd_env(extra) do
    System.get_env()
    |> Map.merge(Map.new(extra))
    |> Map.to_list()
  end
```

**Env-flag failure contract** (lines 35-55):
```elixir
test "mix threadline.verify_coverage exits 1 when expected table lacks trigger (SC1)" do
  env =
    cmd_env(%{
      "MIX_ENV" => "test",
      "THREADLINE_VERIFY_COVERAGE_FAILURE_TEST" => "1"
    })

  assert {output, exit_status} =
           System.cmd(
             "mix",
             ["threadline.verify_coverage"],
             cd: File.cwd!(),
             env: env,
             stderr_to_stdout: true
           )

  assert exit_status == 1
  assert output =~ "threadline_verify_cov_uncovered"
```
Copy with args `["test", "test/support/notice_guard_canary.exs"]`, env `THREADLINE_TRUNCATION_GUARD_CANARY=1`; assert `exit_status != 0` and output names `42622` / the identifier. Positive/negative controls (`SELECT 1 AS <64 x c>` -> one hit via `take/0`; 63-byte alias -> `[]`) can live in a separate `async: true` describe/module since `take/1` is per-process - but the canary contract test module must be `async: false`. The canary hit belongs to the nested VM's ETS, so it never pollutes the parent suite.

---

### `test/support/legacy_trigger_sql.ex` + `test/fixtures/legacy_trigger_migrations/*.exs` (frozen historical forms)

**Analog A (renderer style):** `lib/threadline/capture/trigger_sql.ex:140-156` - copy the heredoc shape but **as frozen copies**, never calling current `TriggerSQL`/`Naming` (so current-code changes cannot move fixtures). The three historical bodies are in RESEARCH.md "Historical SQL" (v0.9.0 unquoted `CREATE TRIGGER threadline_audit_#{t}` / `ON #{t}`; v0.10.0 quoted `CREATE TRIGGER "…" … ON "s"."t"`; v0.10.2 `CREATE OR REPLACE TRIGGER`). Parameterize by `{schema, table, storage_schema}`; moduledoc cites tags `v0.9.0` 7378b75a, `v0.10.0` 3d148435, `v0.10.2` ee137e51.

**Analog B (0.9 fixture install in the real DB):** `trigger_rerun_test.exs:231-248` - legacy function created in the **storage schema** (Pitfall 7) with a stub body, then a byte-faithful 0.9 trigger:
```elixir
defp install_legacy_per_table_trigger! do
  full_name = "threadline_capture_changes_" <> @long_per_table

  Repo.query!("""
  CREATE FUNCTION #{StorageSchema.quote_ident(StorageSchema.get())}.#{full_name}()
  RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN RETURN NEW; END $$
  """)

  Repo.query!("""
  CREATE TRIGGER #{StorageSchema.quote_ident("threadline_audit_" <> @long_per_table)}
  AFTER INSERT OR UPDATE OR DELETE ON #{@long_per_table}
  FOR EACH ROW EXECUTE FUNCTION #{shared_function_ref()}()
  """)
```
(`full_name` here is 67 bytes -> the 42622 hit that must be fixed/drained when the guard lands.)

**Analog C (literal migration text):** `priv/ci/hex_evaluator/priv/repo/migrations/20260424080642_threadline_triggers_posts.exs`, already consumed by `gen_triggers_test.exs:11, 233-247` via `File.cp!`. Put new literal `.exs` fixtures under `test/fixtures/legacy_trigger_migrations/` (not `*_test.exs`, so `mix test` never loads them; `test/fixtures/` already exists with `dialyzer/`, `operator_surface/`, `style/`).

---

### `test/threadline/capture/collision_free_emission_test.exs` (real-PG integration via `Ecto.Migrator`)

**Analog:** `test/threadline/capture/trigger_rerun_test.exs`.

**Header / case** (lines 1-13): `use Threadline.DataCase` (defaults `async: false`, imports `AsyncHelpers`, `StorageSchemaCase`, aliases `Repo`, `AuditChange`, `AuditTransaction`; see `test/support/data_case.ex:11-27`).

**Setup with Mix shell + app env restore + tmp dir** (lines 125-165):
```elixir
setup do
  previous_shell = Mix.shell()
  previous_capture = Application.fetch_env(:threadline, :trigger_capture)
  Mix.shell(Mix.Shell.Process)

  tmp =
    Path.join(
      System.tmp_dir!(),
      "threadline-trigger-long-names-#{System.unique_integer([:positive])}"
    )

  File.mkdir_p!(tmp)
  ...
  on_exit(fn ->
    Mix.shell(previous_shell)

    case previous_capture do
      {:ok, value} -> Application.put_env(:threadline, :trigger_capture, value)
      :error -> Application.delete_env(:threadline, :trigger_capture)
    end
    ...
    File.rm_rf!(tmp)
  end)
```
Per-table mode is driven by `Application.put_env(:threadline, :trigger_capture, tables: %{"billing.invoices" => [mask: [...]]})` (line 214-216 form).

**Generate** (lines 276-289) - reuse `generate!/2` + `migration_files/1` as-is:
```elixir
defp generate!(tmp, args) do
  before = migration_files(tmp)
  File.cd!(tmp, fn -> Triggers.run(args) end)
  [file] = migration_files(tmp) -- before
  file
end
```

**Run via Migrator (replaces `apply_up!/1`, lines 291-309, which runs outside a transaction):** RESEARCH Pattern 1 sketch - `Code.compile_file(file)`, version from `Integer.parse(Path.basename(file))`, `ExUnit.CaptureLog.capture_log([level: :warning], fn -> Ecto.Migrator.up(Repo, version, module) end)`, `Ecto.Migrator.down/4`, `assert_raise Postgrex.Error, ~r/hint: .*--tables/`. Module purge in `on_exit` copies `router_test.exs:44-49`:
```elixir
for {module, _} <- modules do
  :code.delete(module)
  :code.purge(module)
end
```
plus `Repo.query!("DELETE FROM schema_migrations WHERE version = $1", [version])`.

**Catalog assertion helpers** (lines 322-354) - copy `trigger_function/1` (tgfoid -> `{nspname, proname}`, matches on bare name not `regprocedure::text`) and `per_table_function_count/0`; add a per-table `pg_trigger` count (`tgname LIKE 'threadline_audit_%'`, `tgenabled = 'O'`) and a "users per function" query:
```elixir
defp trigger_function(table \\ @table) do
  %{rows: [[nsp, proname]]} =
    Repo.query!(
      """
      SELECT n.nspname, p.proname
      FROM pg_trigger t
      JOIN pg_proc p ON p.oid = t.tgfoid
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE t.tgrelid = $1::text::regclass AND t.tgname = $2 AND NOT t.tgisinternal
      """,
      [table, "threadline_audit_" <> table]
    )

  {nsp, proname}
end
```

**Mask assertion** - copy `test/threadline/capture/trigger_redaction_test.exs:55-68`:
```elixir
[change] = Repo.all(AuditChange, repo_opts())
refute Map.has_key?(change.data_after, "password")
assert Map.get(change.data_after, "email") == "[REDACTED]"
```
Always `repo_opts()` (storage-schema prefix) - never unprefixed `Repo.all(AuditChange)` (memory: 79 unprefixed-call defects).

**Non-public schema table setup/teardown** - copy `verify_coverage_task_test.exs:132-148` (`DROP SCHEMA IF EXISTS support CASCADE` / `CREATE SCHEMA` / `CREATE TABLE`), adapted to `billing`.

Golden names (from `naming_test.exs:14-29`): `threadline_capture_changes_billing_invoices_9bba11019407` (billing.invoices), `threadline_capture_changes_billing_invoices` (public), `…_support_tickets_0a670b783726`.

---

### `test/threadline/mix/trigger_migration_test.exs` (unit + property)

**Analog:** itself (lines 156-206) for sigil-escaped source fixtures, which mimic `execute #{inspect(sql)}` escaping:
```elixir
test "finds the trigger as the generator writes it" do
  source = ~S|    execute "CREATE OR REPLACE TRIGGER \"threadline_audit_posts\"\nAFTER INSERT|
  assert TriggerMigration.rerun?("threadline_audit_posts", [source])
end
```
Rewrite each to `rerun?(%{schema: "public", table: "posts"}, [source])`; sources must now include the `ON …` clause. Delete the 63-byte/boundary tests (180-205); add the D-08 cases listed in CONTEXT specifics.

**Property analog:** `test/threadline/capture/naming_property_test.exs` - header (lines 1-6: `use ExUnit.Case, async: true` + `use ExUnitProperties`), `pair_gen/0` and `pair_of_pairs_gen/0` (132-174) cover exactly the `public.a_b` vs `a.b`, case, and 36-byte-prefix collisions. Either copy the generators or extract them into a shared `test/support` module (e.g. `Threadline.Test.NamingGenerators`) - generator bodies are private in the property test today. The round-trip generator for `gen(p)` should be `inspect(TriggerSQL.create_trigger(p))` wrapped as `"    execute " <> …`. Note: the property uses `TriggerSQL`, which reads `:storage_schema` app env; keep `async: true` only if it passes `storage_schema:` explicitly or uses `:default` mode (no env write).

---

### `test/mix/tasks/threadline/gen_triggers_test.exs` (Mix task)

**Analog:** itself. Helpers to reuse unchanged: `run_triggers/2` + `drain_shell/1` (59-70; collects `:info` only - D-06 test must `assert_received {:mix_shell, :error, [warning]}` like 360-362), `trigger_files/1` (73-78), `executes/2` (99-117). Legacy-fixture rerun test (233-247) must stay green under the new `rerun?` (unqualified `ON posts` matches `public.posts`).

Tests to rewrite: 458-504 (`drop_orphan_function_for_table` expectations -> DO-block after triggers), 507-527 (per-table down -> `[drop_trigger, drop_function_if_unused(Naming.function_name(t))]`). Existing CASCADE refute to generalize for D-11 (line 474):
```elixir
refute Enum.any?(sqls, &String.contains?(&1, "CASCADE"))
```
D-11 static check: over a matrix of generated files, `refute Regex.match?(~r/CASCADE/i, sql)` for every `executes(file, :up) ++ executes(file, :down)`, and every `~r/"([^"]+)"/` capture has `byte_size <= 63`.

---

### `test/threadline/capture/trigger_rerun_test.exs` and `trigger_sql_storage_schema_test.exs` (modify)

- `trigger_rerun_test.exs:83-112` - replace `drop_orphan_function_for_table` calls with the new DO-block builder; "refuses to cascade" (93-104) becomes "keeps and warns" (use `ExUnit.CaptureLog` only if run through the migrator; raw `Repo.query!` returns the WARNING in `%Postgrex.Result{messages: …}` instead - assert on `messages`).
- `trigger_rerun_test.exs:195-228` - flip: shared function now dropped (count 0); per-table long pair generates distinct hashed functions instead of `assert_raise ArgumentError`.
- `trigger_rerun_test.exs:231-248` - fix the 67-byte `CREATE FUNCTION` in the same commit as the NoticeGuard (use `@shared_function`, the 63-byte cut, which is what PG stored).
- `trigger_sql_storage_schema_test.exs:38-55` - expected name becomes `"threadline"."threadline_capture_changes_support_tickets_0a670b783726"`; replace the orphan-drop test with a DO-block text assertion (`to_regprocedure('"threadline"."…"()')`, no `CASCADE`).

---

## Shared Patterns

### Identifier validation and quoting
**Source:** `lib/threadline/storage_schema.ex:68-117, 128-130, 156-159`
**Apply to:** every name the generator emits (TriggerSQL builders, gen.triggers retire/guard)
```elixir
def quote_ident(identifier), do: ~s("#{validate!(identifier)}")
def qualify(schema, name), do: "#{quote_ident(schema)}.#{quote_ident(name)}"
def function(name, opts \\ []) do
  qualify(get(opts), name)
end
def qualified_host_table(value) do
  %{schema: schema, table: table} = parse_table_identifier(value)
  qualify(schema, table)
end
```
Call `StorageSchema.validate_identifier!(name, :derived)` before any name enters a `to_regprocedure` literal (Pitfall 6: silent truncation, no NOTICE).

### Name derivation (single source)
**Source:** `lib/threadline/capture/naming.ex:98-117`
**Apply to:** TriggerSQL, gen.triggers retire set, D-06 advisory, all new tests (never hand-concatenate `"threadline_capture_changes_" <> …` in lib)
```elixir
def trigger_name(table), do: cut(@trigger_prefix <> suffix(table), @max_identifier_bytes)
def legacy_function_name(table),
  do: cut(@function_prefix <> suffix(table), @max_identifier_bytes)
def function_name(table) do
  pair = pair(table)
  if legacy_function?(pair) do
    @function_prefix <> pair.table
  else
    @function_prefix <> cut(suffix(pair), @stem_max) <> "_" <> hash12(qualified(pair))
  end
end
```

### Generated-file SQL embedding
**Source:** `lib/mix/tasks/threadline.gen.triggers.ex:296, 310, 323`
**Apply to:** guard and retire blocks
```elixir
"    execute #{inspect(sql)}"
```
`inspect/1` escapes `"` and newlines; the `executes/2` test helper round-trips it via `Code.string_to_quoted!`.

### Test env/app-state restore
**Source:** `test/mix/tasks/threadline/gen_triggers_test.exs:32-57`, `verify_coverage_task_test.exs:150-151`
**Apply to:** every new test that sets `:storage_schema`, `:trigger_capture`, or `Mix.shell`
```elixir
defp restore_env(key, nil), do: Application.delete_env(:threadline, key)
defp restore_env(key, value), do: Application.put_env(:threadline, key, value)
```
Such modules must be `async: false` (VM-wide env + cwd).

### Catalog queries on bare names
**Source:** `trigger_rerun_test.exs:337-354` comment: "Identifies the trigger's function by catalog name and namespace rather than its text rendering, which varies with search_path. The table name is sent as text and cast, because Postgrex encodes a bare regclass parameter as an oid."
**Apply to:** all real-PG assertions in new tests (`$1::text::regclass`, never assert on `regprocedure::text`).

### No planning vocabulary in shipped code
**Source:** `test/threadline/source_size_contract_test.exs:43-47` (`@file_limit 800`, `@function_limit 120`, `~r/Phase \d|STRUCT-\d|\bD-\d{2}\b/`)
**Apply to:** `trigger_sql.ex`, `trigger_migration.ex`, `threadline.gen.triggers.ex` edits, and generated SQL comments/WARNING/HINT text.

## No Analog Found

| File / artifact | Role | Data Flow | Reason |
|---|---|---|---|
| D-01 drop-if-unused and D-05 post-condition guard `DO $$ … $$` SQL | SQL builder output | transform | No generated PL/pgSQL DO blocks exist in the repo. Use RESEARCH.md "Code Examples > D-01 block (with the ORDER BY fix)" and "Pattern 3" verbatim (both run on PG 14.17). |
| Running a generated migration through `Ecto.Migrator.up/4` / `down/4` in a test | test harness | DDL transaction | No test calls `Ecto.Migrator.up/down` or `Code.compile_file` today; only `test_helper.exs:38` uses `Ecto.Migrator.run`. Use RESEARCH Pattern 1 sketch; purge idiom from `router_test.exs:44-49`. |
| `ExUnit.after_suite` + `System.at_exit` suite failure | test infra | event-driven | No existing usage; RESEARCH Pattern 5 / A5 (self-verified by the canary contract test). |

## Metadata

**Analog search scope:** `lib/threadline/capture/`, `lib/threadline/mix/`, `lib/mix/tasks/`, `lib/threadline/storage_schema.ex`, `test/support/`, `test/test_helper.exs`, `test/threadline/capture/`, `test/threadline/mix/`, `test/mix/tasks/threadline/`, `test/threadline/{verify_coverage_task,telemetry,zero_skips_contract,test_structure_contract}_test.exs`, `test/threadline/operator_surface/{router,stress_router}_test.exs`, `priv/ci/hex_evaluator/`
**Files scanned:** ~25
**Pattern extraction date:** 2026-09-25
