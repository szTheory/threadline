# Phase 208: Identifier Foundation - Pattern Map

**Mapped:** 2026-09-25
**Files analyzed:** 17 (4 new lib/test modules + 3 new tests, 10 modified)
**Analogs found:** 16 / 17 (the StreamData property test has no in-repo analog)

All analog paths below were checked with `git ls-files` (tracked source; no mirrors).

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/threadline/capture/naming.ex` (NEW) | utility (pure, `@moduledoc false`) | transform | `lib/threadline/mix/trigger_migration.ex` (resolve_name) + `lib/threadline/storage_schema.ex` (host_table_suffix) | role-match |
| `lib/threadline/mix/migrations_path.ex` (NEW) | utility (Mix plumbing, `@moduledoc false`) | config lookup / request-response | `lib/mix/tasks/threadline.install.ex:143-173` (source of extraction) + `lib/threadline/mix/migration_version.ex` (module shape) | exact (extraction) |
| `lib/threadline/storage_schema.ex` (MOD) | utility / validator | transform | self (`validate!/1`, `invalid_identifier!/1`, `parse_table_identifier/1`) | exact |
| `lib/threadline/mix/trigger_migration.ex` (MOD) | utility | transform + file-I/O scan | self (`resolve_name/2` lines 57-70) | exact |
| `lib/threadline/capture/trigger_sql.ex` (MOD, minimal) | utility (SQL builder) | transform | self (lines 140-164) | exact |
| `lib/mix/tasks/threadline.install.ex` (MOD) | Mix task | file-I/O | `lib/mix/tasks/threadline.gen.triggers.ex:95-107` (strict OptionParser) | exact |
| `lib/mix/tasks/threadline.gen.triggers.ex` (MOD) | Mix task | file-I/O | self (lines 92-192) | exact |
| `mix.exs` (MOD) | config | n/a | self (lines 73-78, 84-118) | exact |
| `release-please-config.json` (MOD) | config | n/a | self (line 4) | exact |
| `CHANGELOG.md` (MOD, install rejects unknown flags) | docs | n/a | existing `## Unreleased — highlights` block (guarded by `changelog_contract_test.exs`) | role-match |
| `test/threadline/capture/naming_test.exs` (NEW) | test (unit + golden) | transform | `test/threadline/mix/trigger_migration_test.exs` (`resolve_name/2` describe) | role-match |
| `test/threadline/capture/naming_property_test.exs` (NEW) | test (property) | transform | none (no StreamData in repo) | no analog |
| `test/threadline/mix/migrations_path_test.exs` (NEW) | test (unit) | config lookup | `test/threadline/storage_schema_test.exs:23-36` (app-env save/restore) + `test/threadline/mix/trigger_migration_test.exs:7-18` (tmp dir) | role-match |
| `test/threadline/storage_schema_test.exs` (MOD) | test | transform | self (lines 175-209) | exact |
| `test/threadline/mix/trigger_migration_test.exs` (MOD) | test | transform | self (lines 31-67) | exact |
| `test/mix/tasks/threadline/install_test.exs` + `gen_triggers_test.exs` (MOD) | test (Mix task) | file-I/O | self (setup lines 15-50 / 32-70); `Mix.Error` assert from `test/threadline/operator_surface/coverage_mix_test.exs:123-129` | exact |
| `test/threadline/changelog_contract_test.exs` (MOD) or new `release_please_config_contract_test.exs` | test (contract) | file-I/O | `test/threadline/changelog_contract_test.exs:146-171` | exact |

## Pattern Assignments

### `lib/threadline/capture/naming.ex` (utility, transform) — NEW

**Analogs:** `lib/threadline/mix/trigger_migration.ex` (module header/comment style, `@doc false` + `@spec` on every function), `lib/threadline/storage_schema.ex:120-129` (legacy suffix), `lib/threadline/capture/trigger_sql.ex:7-8` (63-byte constant with a comment).

**Module header + explanatory comment block (not moduledoc)** — `trigger_migration.ex:1-18`:
```elixir
defmodule Threadline.Mix.TriggerMigration do
  @moduledoc false

  # Ecto names a migration by the text after the version in its file name and
  # refuses to run two pending files with the same name. ...
  # Host migration files are only read as text and matched with regular
  # expressions. ...

  alias Threadline.Mix.MigrationVersion

  @defmodule ~r/^\s*defmodule\s+([A-Z][A-Za-z0-9_.]*)\s+do\b/m
```
Copy this shape: `@moduledoc false`, then a prose `#` comment explaining the invariant (frozen format, SQL reproduction `left(encode(sha256(convert_to('billing.invoices','UTF8')),'hex'),12)`, D-04 injectivity odds ~1.8e-7 at 10k tables). No `Phase 208`/`D-0x` vocabulary and no `file:line` citations in `lib/` (release_artifact_contract / source_comment_location_contract).

**Per-function doc/spec style** — `trigger_migration.ex:26-28, 78-80`:
```elixir
  @doc false
  @spec scan(Path.t()) :: scan()
  def scan(path) do
```

**Constant with comment** — `trigger_sql.ex:7-8`:
```elixir
  # PostgreSQL's NAMEDATALEN - 1.
  @max_identifier_bytes 63
```

**Legacy suffix to reuse, not reimplement** — `storage_schema.ex:120-129`:
```elixir
  @doc "Returns a stable suffix for trigger/function names derived from a host table."
  def host_table_suffix(value) do
    %{schema: schema, table: table} = parse_table_identifier(value)

    if schema == "public" do
      table
    else
      "#{schema}_#{table}"
    end
  end
```
Naming must accept a parsed pair (`%{schema:, table:}`) and must not re-parse it (so hashing uses `schema <> "." <> table` of the canonical pair). Either add a pair-clause helper in Naming or compute the suffix from the pair directly, byte-identical to the above.

**Core formula source** — RESEARCH.md Pattern 1 (`hash12`, `trigger_name`, `legacy_function_name`, `function_name`, `cut/2`) and Pattern 2 (`migration_name/2`). Module naming must stay **per-part** camelize like `trigger_migration.ex:62`:
```elixir
      module = "ThreadlineTriggers" <> Enum.map_join(parts, "", &Macro.camelize/1)
```

---

### `lib/threadline/mix/migrations_path.ex` (Mix plumbing, config lookup) — NEW

**Analog (extraction source):** `lib/mix/tasks/threadline.install.ex:143-173`
```elixir
  defp migrations_path do
    Mix.Project.config()
    |> Keyword.get(:app)
    |> then(fn app ->
      app_env = Application.get_env(app, :ecto_repos, [])

      case app_env do
        [repo | _] ->
          repo_migrations_path(repo)

        [] ->
          "priv/repo/migrations"
      end
    end)
  rescue
    _ -> "priv/repo/migrations"
  end

  # Called inside migrations_path/0, so its rescue still covers a raising repo.
  defp repo_migrations_path(repo) do
    case repo.config()[:priv] do
      nil ->
        Path.join(
          "priv/#{repo |> Module.split() |> List.last() |> Macro.underscore()}",
          "migrations"
        )

      p ->
        Path.join(p, "migrations")
    end
  end
```
Move this body verbatim into `default_repo_path/0` (keep the `rescue _ -> "priv/repo/migrations"` for the default path only). Add the precedence head from RESEARCH Pattern 6: repeated `:repo` (via `Keyword.get_values/2`, parsed as `repo: :keep`) → `Mix.raise("--repo may be given once; Threadline audit tables live in one repo")`; `opts[:migrations_path]` returned as given (repo never loaded); explicit `--repo` → `Module.concat([name])`, `Code.ensure_loaded?/1` + `function_exported?(repo, :config, 0)` else `Mix.raise` naming the module (NO rescue fallback for explicit repo). Reuse `repo_migrations_path/1` for both repo branches.

**Module shape:** `lib/threadline/mix/migration_version.ex:1-15` — `@moduledoc false`, `#` comment explaining why, `@doc false` + `@spec` on the public function.

---

### `lib/threadline/storage_schema.ex` (validator, transform) — MOD

**Current validator to delegate from** (lines 49-73):
```elixir
  @doc "Validates a PostgreSQL identifier used as a schema, table, or function name."
  def validate!(nil), do: invalid_identifier!(nil)
  def validate!(value) when is_boolean(value), do: invalid_identifier!(value)
  def validate!(value) when is_atom(value), do: value |> Atom.to_string() |> validate!()

  def validate!(value) when is_binary(value) do
    value = String.trim(value)

    if Regex.match?(@identifier, value) and byte_size(value) <= @max_identifier_bytes do
      value
    else
      invalid_identifier!(value)
    end
  end

  def validate!(value) do
    invalid_identifier!(value)
  end

  defp invalid_identifier!(value) do
    raise ArgumentError,
          "Threadline storage schema must be a non-empty PostgreSQL identifier " <>
            "matching #{@identifier.source} and at most #{@max_identifier_bytes} bytes, " <>
            "got: #{inspect(value)}"
  end
```
Mirror the same clause ladder (nil / boolean / atom / binary-trim / fallback) in `validate_identifier!(value, role, input \\ nil)`, `@doc false`. `:storage_schema` role must produce the above message byte-for-byte. Other roles: D-10 template with `byte_size`; non-binary values get the prefix without a byte count. Keep "at most 63 bytes" in every template (`trigger_rerun_test.exs:217-218` asserts `~r/at most 63 bytes/`).

**Call sites to switch to role-aware** (lines 99-112):
```elixir
  def parse_table_identifier(value) when is_binary(value) do
    value = String.trim(value)

    case String.split(value, ".", trim: false) do
      [table] when table != "" ->
        %{schema: "public", table: validate!(table)}

      [schema, table] when schema != "" and table != "" ->
        %{schema: validate!(schema), table: validate!(table)}

      _ ->
        raise ArgumentError, "table must be NAME or SCHEMA.NAME, got: #{inspect(value)}"
    end
  end
```
Replace `validate!(table)` → `validate_identifier!(table, :host_table, value)`, `validate!(schema)` → `validate_identifier!(schema, :host_schema, value)`. Also update the `host_table_suffix/1` `@doc` (line 120) to say it is the legacy suffix. Optional: `continuity.ex:89`, `redaction_presenter.ex:35` → `validate_identifier!(v, :host_schema)`.

---

### `lib/threadline/mix/trigger_migration.ex` (utility, transform) — MOD

**Current `resolve_name/2`** (lines 51-70):
```elixir
  @doc false
  @spec resolve_name([String.t()], %{
          required(:names) => MapSet.t(String.t()),
          required(:modules) => MapSet.t(String.t()),
          optional(:sources) => [String.t()]
        }) :: {String.t(), String.t()}
  def resolve_name(suffixes, %{names: names, modules: modules}) do
    Stream.iterate(1, &(&1 + 1))
    |> Enum.find_value(fn ordinal ->
      parts = if ordinal == 1, do: suffixes, else: suffixes ++ [Integer.to_string(ordinal)]
      name = "threadline_triggers_" <> Enum.join(parts, "_")
      module = "ThreadlineTriggers" <> Enum.map_join(parts, "", &Macro.camelize/1)

      if MapSet.member?(names, name) or MapSet.member?(modules, module) do
        nil
      else
        {name, module}
      end
    end)
  end
```
Keep the `Stream.iterate` ordinal loop and the `MapSet.member?` collision check unchanged; replace lines 60-62 with `{name, module} = Naming.migration_name(tables_or_pairs, ordinal)`. First argument changes from suffixes to raw tables/pairs (existing tests pass `["posts"]`, `["a","b"]`, `["AuditLog"]` — all public, so output unchanged). Update the `@spec` accordingly.

**`rerun?/2`** (lines 72-83) — name-based logic stays (D-11). Only the caller's directory changes; per RESEARCH Open Question 1 the planner may pass the cut name from `Naming.trigger_name/1`:
```elixir
  def rerun?(suffix, sources) do
    trigger = Regex.compile!("threadline_audit_" <> Regex.escape(suffix) <> "(?![A-Za-z0-9_])")
    Enum.any?(sources, &Regex.match?(trigger, &1))
  end
```

---

### `lib/threadline/capture/trigger_sql.ex` (SQL builder) — MOD, minimal

**Name sites** (lines 140-164):
```elixir
  defp create_trigger_sql(table_name, function_invocation) do
    trigger_name = "threadline_audit_#{StorageSchema.host_table_suffix(table_name)}"
    host_table = StorageSchema.qualified_host_table(table_name)
    ...
  def drop_trigger(table_name) do
    trigger_name = "threadline_audit_#{StorageSchema.host_table_suffix(table_name)}"
  ...
  defp per_table_function_name(table_name, opts) do
    StorageSchema.function(per_table_function_base(table_name), opts)
  end

  defp per_table_function_base(table_name) do
    "threadline_capture_changes_#{StorageSchema.host_table_suffix(table_name)}"
  end
```
In 208: lines 141 and 153 → `Naming.trigger_name(StorageSchema.parse_table_identifier(table_name))` (or string convenience). `per_table_function_base/1` stays legacy; wrap with `StorageSchema.validate_identifier!(base, :derived)` before `StorageSchema.function/2` (line 159). Leave `per_table_function_fits?/1` (lines 108-110) untouched. Alias line 4-5 style: `alias Threadline.Capture.{Naming, RedactionPolicy}`.

---

### `lib/mix/tasks/threadline.install.ex` (Mix task, file-I/O) — MOD

**Strict OptionParser pattern to copy** — `threadline.gen.triggers.ex:95-107`:
```elixir
    {opts, _rest, invalid} =
      OptionParser.parse(args,
        strict: [
          tables: :string,
          store_changed_from: :boolean,
          except_columns: :string,
          dry_run: :boolean
        ]
      )

    if invalid != [] do
      Mix.raise("Unknown options: #{inspect(invalid)}")
    end
```
For install: `strict: [migrations_path: :string, repo: :keep], aliases: [r: :repo]`. Change `def run(_args)` (line 35) to `run(args)`; line 38 `path = migrations_path()` → `path = MigrationsPath.resolve(opts)`; delete lines 143-173 (moved). Add alias next to line 22 `alias Threadline.Mix.MigrationVersion` → `alias Threadline.Mix.{MigrationsPath, MigrationVersion}`. Update `## Usage` moduledoc (lines 7-9) with `--migrations-path`, `--repo`/`-r`, unknown-flag rejection, and "run from the child app directory in an umbrella". Also consider rejecting stray positional `_rest` args (planner's call; D-09 says unknown flags).

---

### `lib/mix/tasks/threadline.gen.triggers.ex` (Mix task, file-I/O) — MOD

**Sites:** option spec lines 95-103 (add `migrations_path: :string, repo: :keep` + `aliases: [r: :repo]`); table parse at line 119 (`StorageSchema.threadline_table?/1`) is the first `ArgumentError` source — wrap table parsing only in a `defp`:
```elixir
    # target shape (no existing rescue→Mix.raise helper exists in lib/mix/tasks)
    defp parse_tables!(tables) do
      Enum.map(tables, &StorageSchema.parse_table_identifier/1)
    rescue
      e in ArgumentError -> Mix.raise("--tables: " <> Exception.message(e))
    end
```
Write path, lines 158-178 (replace hard-coded path, delete stale comment 162-166):
```elixir
      path = "priv/repo/migrations"
      File.mkdir_p!(path)

      # Versioned after every migration already in the directory, so running
      # this right after `mix threadline.install` cannot repeat a version when
      # both write here. Install resolves the repo's own migrations path, so
      # with a custom `:priv`, or a repo module not named `Repo`, it writes to
      # a different directory.
      [version] = MigrationVersion.next(path, 1)
      scan = TriggerMigration.scan(path)
      suffixes = Enum.map(tables, &StorageSchema.host_table_suffix/1)
      {name, module} = TriggerMigration.resolve_name(suffixes, scan)
```
`run/1` is 101 lines (92-192) against a 120-line cap (`source_size_contract_test.exs`): move option parsing, table parsing and the non-dry-run write branch into `defp`s. Keep the `rescue` off everything except `--tables` parsing (derived-name `ArgumentError` at `trigger_rerun_test.exs:217-223` must stay an `ArgumentError`). Add `## Options` bullets (lines 65-73 style) for `--migrations-path` and `--repo`/`-r`.

---

### `mix.exs` (config) — MOD

Lines 73-78:
```elixir
  def application do
    [
      extra_applications: [:logger],
      mod: {Threadline.Application, []}
    ]
  end
```
→ `extra_applications: [:logger, :crypto]`. Dep list lines 84-118; test-only deps precede with a comment explaining the pin, e.g. lines 104-117 (`yaml_elixir` pinned for the Elixir 1.15 floor). Add `{:stream_data, "~> 1.4", only: :test}` with a short comment that 1.4 floors at `~> 1.14` (dep_floor_guard). Commit `mix.lock` with it.

### `release-please-config.json` (config) — MOD

Line 4: `"bump-minor-pre-major": false,` → `true`. Line 5 stays `false`. First commit of the phase, type `ci:`/`chore:`.

---

### `test/threadline/capture/naming_test.exs` (unit + golden) — NEW

**Analog:** `test/threadline/mix/trigger_migration_test.exs:1-5, 31-66`
```elixir
defmodule Threadline.Mix.TriggerMigrationTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Threadline.Mix.{MigrationVersion, TriggerMigration}
  ...
  describe "resolve_name/2" do
    test "a free base keeps today's name and module" do
      assert TriggerMigration.resolve_name(["posts"], taken([], [])) ==
               {"threadline_triggers_posts", "ThreadlineTriggersPosts"}
    end
```
Golden rows: table-driven `for {input, h12, trigger, function} <- @golden` with literal strings from CONTEXT D-05 plus migration golden (`threadline_triggers_customer_subscription_line_ite_229374fb2418` / `ThreadlineTriggersCustomerSubscriptionLineIte229374fb2418`, recompute first). Add `byte_size <= 63` assertions and the empty-readable, hash-tail exclusion and `Users`/`users` cases.

### `test/threadline/capture/naming_property_test.exs` (property) — NEW, no analog

Use RESEARCH Pattern 5 verbatim as the starting point (`use ExUnit.Case, async: true` + `use ExUnitProperties`). No `@tag`/`@moduletag` excludes (`zero_skips_contract_test.exs`). Assert injectivity for `function_name/1` only (given distinct h12); for triggers assert the exact cut formula (Pitfall 1).

### `test/threadline/mix/migrations_path_test.exs` (unit) — NEW

**App-env save/restore analog** — `test/threadline/storage_schema_test.exs:1-6, 23-36`:
```elixir
  use ExUnit.Case, async: false
  ...
    setup do
      previous = Application.fetch_env(:threadline, :storage_schema)
      Application.delete_env(:threadline, :storage_schema)

      on_exit(fn ->
        case previous do
          {:ok, value} -> Application.put_env(:threadline, :storage_schema, value)
          :error -> Application.delete_env(:threadline, :storage_schema)
        end
      end)
```
Apply to `:ecto_repos` (config/test.exs:49 sets `[Threadline.Test.Repo]`, no `:priv` → default `priv/repo/migrations`). Must be `async: false` (VM-wide env). Stub repo module inside the test file: `defmodule Threadline.TestSupport.CustomPrivRepo do def config, do: [priv: "priv/custom_repo"] end`. Cases: `--migrations-path` wins without loading repo; explicit `--repo` with `:priv`; underscore fallback for repo without `:priv`; `[]` repos → `priv/repo/migrations`; repeated `--repo` → `Mix.Error`; unloadable `--repo` → `Mix.Error` naming module.

### `test/threadline/storage_schema_test.exs` (MOD)

Existing style (lines 203-209):
```elixir
  test "rejects malformed host table identifiers instead of falling back to public" do
    for invalid <- ["", "   ", ".tickets", "support.", "support..tickets", "a.b.c"] do
      assert_raise ArgumentError, fn ->
        StorageSchema.parse_table_identifier(invalid)
      end
    end
  end
```
Add: 70-byte table → `e = assert_raise ArgumentError, fn -> ... end`, then `assert e.message =~ "host table"`, `=~ "70 bytes"`, `=~ table`, `refute e.message =~ "storage schema"`; plus a `validate!/1` message byte-identity assertion.

### `test/mix/tasks/threadline/install_test.exs` + `gen_triggers_test.exs` (MOD)

**Setup/runner pattern** — `install_test.exs:15-50`:
```elixir
  setup do
    previous_shell = Mix.shell()
    previous_schema = Application.fetch_env(:threadline, :storage_schema)
    Mix.shell(Mix.Shell.Process)
    tmp = Path.join(System.tmp_dir!(), "threadline-install-#{System.unique_integer([:positive])}")
    File.mkdir_p!(tmp)
    on_exit(fn -> ... File.rm_rf!(tmp) end)
    %{tmp: tmp}
  end

  defp run_install(tmp) do
    File.cd!(tmp, fn -> Install.run([]) end)
    drain_shell([])
  end
```
`gen_triggers_test.exs:59-62` has the same `run_triggers(tmp, args)` helper; `@migrations "priv/repo/migrations"` (line 9 / install line 52). Add a save/restore of `:ecto_repos` for the custom-`:priv` cases. `run_install/1` needs an args variant.

**Mix.Error assertion analog** — `test/threadline/operator_surface/coverage_mix_test.exs:123-129`:
```elixir
    test "--schema=Public fails the regex (uppercase rejected)" do
      assert_raise Mix.Error, ~r/not a valid PostgreSQL identifier|schema "Public"/, fn ->
        capture_io(fn ->
          Coverage.run(["--schema=Public"])
        end)
      end
    end
```
Use for: `--tables <70-byte>` → `Mix.Error` matching `--tables:`, `host table`, `70 bytes`; unknown install flag → `Mix.Error`.

### Release config contract (MOD `changelog_contract_test.exs` or NEW file)

**Analog** — `test/threadline/changelog_contract_test.exs:24-28, 48, 152-153`:
```elixir
  @root File.cwd!()
  @release_please_config "release-please-config.json"
  defp read!(relative), do: @root |> Path.join(relative) |> File.read!()
  ...
    config = read!(@release_please_config)
    parsed = Jason.decode!(config)
```
Add a test asserting `parsed["bump-minor-pre-major"] == true` and `parsed["bump-patch-for-minor-pre-major"] == false`, with a failure message explaining the pre-1.0 semantics (house style: every assert carries a "why" message).

## Shared Patterns

### Mix task option parsing + unknown-flag rejection
**Source:** `lib/mix/tasks/threadline.gen.triggers.ex:95-107`
**Apply to:** both tasks. Add `repo: :keep` + `aliases: [r: :repo]` so a repeated `--repo` reaches `MigrationsPath.resolve/1` for the "given once" error.

### Error convention
- Library code: `raise ArgumentError, "Threadline ..."` (`storage_schema.ex:68-73`, `:110`). No new exception types (D-10).
- Mix tasks: `Mix.raise("...")` (`gen.triggers.ex:106, 116, 122`). The only rescue in `lib/mix/tasks` today is install's default-path `rescue _ ->` (install.ex:157); the `--tables` `rescue e in ArgumentError -> Mix.raise(...)` is new and must be narrow.

### Internal module style
**Source:** `lib/threadline/mix/trigger_migration.ex:1-28`, `lib/threadline/mix/migration_version.ex:1-15`
`@moduledoc false`, prose `#` rationale block, `@doc false` + `@spec` per public function. Comments cite `Module.function/arity`, never `file:line`, and carry no planning IDs.

### Test isolation
- Pure modules: `async: true` (`trigger_migration_test.exs:3`).
- Anything touching `File.cd!`, `Mix.shell`, or app env: `async: false` with a `# async: false — ...` rationale comment (`install_test.exs:1-4`) and `Application.fetch_env` / `on_exit` restore.
- tmp dirs via `System.tmp_dir!()` + `System.unique_integer([:positive])` + `on_exit(File.rm_rf!)`.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `test/threadline/capture/naming_property_test.exs` | test (property) | transform | StreamData/ExUnitProperties are not used anywhere in the repo yet; use RESEARCH.md Pattern 5 |

## Metadata

**Analog search scope:** `lib/threadline/`, `lib/threadline/mix/`, `lib/threadline/capture/`, `lib/mix/tasks/`, `test/threadline/`, `test/threadline/mix/`, `test/mix/tasks/threadline/`, `test/threadline/operator_surface/`, `mix.exs`, `release-please-config.json`
**Files scanned:** 16
**Pattern extraction date:** 2026-09-25
