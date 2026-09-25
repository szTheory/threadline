# Phase 207: Trigger Migration Rerun and Storage-Schema Default Docs - Pattern Map

**Mapped:** 2026-09-24
**Files analyzed:** 16 (4 lib, 6 test, 5 guides, CHANGELOG)
**Analogs found:** 16 / 16 (every file has an in-repo analog; most are edits to the analog itself)

All analog paths below are git-tracked (verified with `git ls-files`).

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/threadline/mix/migration_version.ex` (MODIFY: expose shared discovery) | utility (hidden Mix helper) | file-I/O (dir scan) | itself, `existing_versions/1` lines 57-70 | exact |
| `lib/threadline/mix/trigger_migration.ex` (NEW, `@moduledoc false`: name/module resolver + rerun detector) | utility (hidden Mix helper) | transform (pure over scanned files) | `lib/threadline/mix/migration_version.ex` | exact (sibling) |
| `lib/threadline/capture/trigger_sql.ex` (MODIFY: `CREATE OR REPLACE TRIGGER`, new non-CASCADE orphan drop) | service (SQL builder) | transform | itself, `create_trigger_sql/2` 117-126, `drop_function_for_table/2` 91-95, `drop_function/1` 86-89 | exact |
| `lib/mix/tasks/threadline.gen.triggers.ex` (MODIFY: name/module, up/down assembly, moduledoc) | controller (Mix task / codegen assembler) | file-I/O | itself, `run/1` 130-145, `migration_content/1` 201-262 | exact |
| `test/mix/tasks/threadline/gen_triggers_test.exs` (NEW, file tier) | test | file-I/O | `test/mix/tasks/threadline/install_test.exs` | exact |
| `test/threadline/mix/trigger_migration_test.exs` (NEW, optional pure unit) | test | transform | `test/threadline/mix/migration_version_test.exs` | exact |
| `test/threadline/capture/trigger_rerun_test.exs` (NEW, DB tier) | test (DataCase) | request-response (SQL) | `test/threadline/capture/trigger_changed_from_test.exs` (+ `trigger_test.exs`) | exact |
| `test/threadline/capture/trigger_sql_storage_schema_test.exs` (MODIFY line 25; add orphan-helper assertion) | test (pure SQL text) | transform | itself, lines 22-27 and 39-46 | exact |
| `test/threadline/storage_schema_test.exs` (MODIFY: widen doc/default guard) | test (doc contract) | file-I/O (reads guides) | itself, lines 36-56; matcher positive-control from `test/threadline/release_artifact_contract_test.exs:249-267` | exact |
| `guides/audit-indexing.md:7` | docs | — | `guides/configuration-and-commands.md:32`, `guides/getting-started-saas.md:63` | exact (voice) |
| `guides/production-checklist.md:14, :45` | docs | — | same as above | exact |
| `guides/how-threadline-works.md:94` | docs | — | same as above | exact |
| `guides/domain-reference.md:52-53, :311` | docs | — | same as above | exact |
| `CHANGELOG.md` (Unreleased — highlights) | docs (release notes) | — | the 206 entry already there, `CHANGELOG.md:20-66` | exact |

## Pattern Assignments

### `lib/threadline/mix/migration_version.ex` (utility, file-I/O) — MODIFY

**Analog:** itself.

The private scan to promote into a public `@doc false` function (lines 57-70). Keep the comment; return `{version, name, path}` triples so `existing_versions/1` becomes `Enum.map(existing(path), &elem(&1, 0))` and the resolver reuses the same set:
```elixir
  # Mirrors how Ecto discovers migrations: every .exs file under the
  # directory, including subdirectories, whose name starts with an integer
  # followed by "_".
  defp existing_versions(path) do
    [path, "**", "*.exs"]
    |> Path.join()
    |> Path.wildcard()
    |> Enum.flat_map(fn file ->
      case Integer.parse(Path.basename(file, ".exs")) do
        {version, "_" <> _} -> [version]
        _ -> []
      end
    end)
  end
```
Change the match to `{version, "_" <> name} -> [{version, name, file}]`. The public-function convention in this module is `@doc false` + `@spec` (lines 13-15):
```elixir
  @doc false
  @spec next(Path.t(), non_neg_integer(), NaiveDateTime.t()) :: [String.t()]
  def next(path, count, now \\ NaiveDateTime.utc_now())
```

---

### `lib/threadline/mix/trigger_migration.ex` (NEW utility, transform)

**Analog:** `lib/threadline/mix/migration_version.ex`

**Module header pattern** (lines 1-9): `@moduledoc false`, then a plain `#` comment block that explains the Ecto rule. Keep that comment style. Do not write decision IDs or phase numbers in it (the packaged-source vocabulary scan, `release_artifact_contract_test.exs:7-14`, would fail):
```elixir
defmodule Threadline.Mix.MigrationVersion do
  @moduledoc false

  # Ecto names a migration by the integer before the first "_" in its file name
  # and refuses to run a directory where two files share that integer. ...
```

**Name base to reproduce byte-for-byte** (from `lib/mix/tasks/threadline.gen.triggers.ex:140` and `:236-237`):
```elixir
table_suffix = Enum.map_join(tables, "_", &StorageSchema.host_table_suffix/1)
file = Path.join(path, "#{version}_threadline_triggers_#{table_suffix}.exs")
...
module_name =
  "ThreadlineTriggers#{Enum.map_join(tables, "", &(StorageSchema.host_table_suffix(&1) |> Macro.camelize()))}"
```
The resolver must yield exactly these for ordinal 1: `parts = Enum.map(tables, &StorageSchema.host_table_suffix/1)`, `name = "threadline_triggers_" <> Enum.join(parts, "_")`, `module = "ThreadlineTriggers" <> Enum.map_join(parts, "", &Macro.camelize/1)`, then `parts ++ ["2"]`, `["3"]` and so on (RESEARCH Pattern 2). A candidate is taken if its name is in the scanned names **or** its module is in the scanned `defmodule` aliases (regex scan, never compile/eval; RESEARCH Pattern 3). Rerun detection: `Regex.compile!("threadline_audit_" <> Regex.escape(suffix) <> "(?![A-Za-z0-9_])")` over file sources (RESEARCH Pattern 4).

---

### `lib/threadline/capture/trigger_sql.ex` (service, transform) — MODIFY

**Analog:** itself.

**Change the one statement** (lines 117-126). Only `CREATE TRIGGER` becomes `CREATE OR REPLACE TRIGGER`; the trigger name stays `threadline_audit_<suffix>`, because the catalog readers match `LIKE 'threadline_audit_%'`:
```elixir
  defp create_trigger_sql(table_name, function_invocation) do
    trigger_name = "threadline_audit_#{StorageSchema.host_table_suffix(table_name)}"
    host_table = StorageSchema.qualified_host_table(table_name)

    """
    CREATE TRIGGER #{StorageSchema.quote_ident(trigger_name)}
    AFTER INSERT OR UPDATE OR DELETE ON #{host_table}
    FOR EACH ROW EXECUTE FUNCTION #{function_invocation}
    """
  end
```

**New non-CASCADE drop helper.** Copy the shape of `drop_function/1` (86-89) and `drop_function_for_table/2` (91-95). Reuse `per_table_function_name/2` (135-138), but leave out ` CASCADE`:
```elixir
  @doc "Returns SQL to drop the global trigger function."
  def drop_function(opts \\ []) do
    "DROP FUNCTION IF EXISTS #{StorageSchema.function("threadline_capture_changes", opts)}()"
  end

  @doc "Returns SQL to drop a per-table capture function (use after dropping triggers, or with CASCADE)."
  def drop_function_for_table(table_name, opts \\ []) do
    name = per_table_function_name(table_name, opts)
    "DROP FUNCTION IF EXISTS #{name}() CASCADE"
  end
  ...
  defp per_table_function_name(table_name, opts) do
    function_name = "threadline_capture_changes_#{StorageSchema.host_table_suffix(table_name)}"
    StorageSchema.function(function_name, opts)
  end
```
The module is `@moduledoc false` (line 2). Keep the one-line `@doc "..."` style on the new public function.

---

### `lib/mix/tasks/threadline.gen.triggers.ex` (controller / codegen, file-I/O) — MODIFY

**Analog:** itself. The task stays a thin assembler, and every SQL string comes from `TriggerSQL`.

**Aliases** (lines 57-59). Add the new hidden helper here:
```elixir
  alias Threadline.Capture.{RedactionPolicy, TriggerCaptureConfig, TriggerSQL}
  alias Threadline.Mix.MigrationVersion
  alias Threadline.StorageSchema
```

**File write site** (lines 130-145). Replace the inline `table_suffix`/`file` with the resolver output, and pass the module and the rerun set into `migration_content`. Keep the `create_file` + `Mix.shell().info` pattern (optionally add one info line naming rerun tables; RESEARCH Open Q4):
```elixir
      path = "priv/repo/migrations"
      File.mkdir_p!(path)
      ...
      [version] = MigrationVersion.next(path, 1)
      table_suffix = Enum.map_join(tables, "_", &StorageSchema.host_table_suffix/1)
      file = Path.join(path, "#{version}_threadline_triggers_#{table_suffix}.exs")

      create_file(file, migration_content(table_specs))
      Mix.shell().info("Run `mix ecto.migrate` to install the triggers.")
```
Do not change the hardcoded `priv/repo/migrations` here. That is W3, which is deferred.

**Up/down assembly pattern** (lines 212-232, 239-261). Keep the `"    execute #{inspect(sql)}"` line format and the `Enum.reject(&(&1 == "")) |> Enum.join("\n\n")` joining. Changes:
- `trigger_ups`: after each default-mode table (`per? == false`), append `execute` of the new orphan-drop helper **after** that table's trigger statement (RESEARCH Pitfall 3).
- `trigger_downs` / `function_downs`: filter out rerun tables; if the rerun set is non-empty, add the comment block to `def down do`.
- `module_name` at lines 236-237 is replaced by the resolver's module.
```elixir
    trigger_ups =
      Enum.map_join(table_specs, "\n\n", fn {t, %{needs_per_table: per?}} ->
        trig =
          if per?,
            do: TriggerSQL.create_trigger(t, :per_table),
            else: TriggerSQL.create_trigger(t)

        "    execute #{inspect(trig)}"
      end)

    trigger_downs =
      Enum.map_join(table_specs, "\n\n", fn {t, _} ->
        "    execute #{inspect(TriggerSQL.drop_trigger(t))}"
      end)
    ...
    """
    defmodule #{module_name} do
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

**Moduledoc** (line 13-14) currently says "`CREATE TRIGGER` statements". Update it to describe OR REPLACE, what a rerun writes, and what rolling a rerun back does. Do not name `Threadline.Capture.TriggerSQL` in backticks. Keep the `StorageSchema.threadline_table?` call at line 91, which is an anchor for `code_walkthrough_doc_contract_test.exs:12-14`.

---

### `test/mix/tasks/threadline/gen_triggers_test.exs` (NEW test, file-I/O)

**Analog:** `test/mix/tasks/threadline/install_test.exs`

**Header + async rationale** (lines 1-6):
```elixir
defmodule Mix.Tasks.Threadline.InstallTest do
  # async: false — the task writes relative to the working directory and reads
  # the global :storage_schema application env, and both are VM-wide.
  use ExUnit.Case, async: false

  alias Mix.Tasks.Threadline.Gen.Triggers
```

**Setup to copy verbatim** (lines 15-37). Change only the tmp prefix, for example `"threadline-gen-triggers-"`:
```elixir
  setup do
    previous_shell = Mix.shell()
    previous_schema = Application.fetch_env(:threadline, :storage_schema)
    Mix.shell(Mix.Shell.Process)

    tmp =
      Path.join(System.tmp_dir!(), "threadline-install-#{System.unique_integer([:positive])}")

    File.mkdir_p!(tmp)

    on_exit(fn ->
      Mix.shell(previous_shell)

      case previous_schema do
        {:ok, value} -> Application.put_env(:threadline, :storage_schema, value)
        :error -> Application.delete_env(:threadline, :storage_schema)
      end

      File.rm_rf!(tmp)
    end)

    %{tmp: tmp}
  end
```

**Run + drain helpers** (lines 39-50, 238-251):
```elixir
  defp drain_shell(acc) do
    receive do
      {:mix_shell, :info, [msg]} -> drain_shell([msg | acc])
    after
      0 -> acc |> Enum.reverse() |> Enum.join("\n")
    end
  end
  ...
      File.cd!(tmp, fn -> Triggers.run(["--tables", "posts"]) end)
      drain_shell([])
```

**Seed + version helpers** (lines 52-80): `@migrations "priv/repo/migrations"`, `seed/2` (writes a stub file into the dir), and `assert_valid_increasing!/1` (14-digit, valid `NaiveDateTime`, strictly increasing). Copy `assert_valid_increasing!/1` for D-08 case 1, or share it through a support module.

**Additional helpers** (from RESEARCH D-08 skeleton): `trigger_files/1` (recursive glob sorted), `ecto_name/1` (`Integer.parse(Path.rootname(basename))` → `{_, "_" <> name}`), `module_of/1` (`Code.string_to_quoted!` → `{:defmodule, _, [{:__aliases__, _, parts}, _]}`), and `down_body/1`.

**Legacy fixture for case 3:** `priv/ci/hex_evaluator/priv/repo/migrations/20260424080642_threadline_triggers_posts.exs` (tracked). `File.cp!` it into `tmp/priv/repo/migrations/` **before** `File.cd!`, because the source path is relative to the repo root.

**Storage schema pin:** `config/test.exs:50` sets `"threadline"`. Call `Application.delete_env(:threadline, :storage_schema)` (→ `public`) at the start of each test that asserts SQL text, as install_test does at line 231/245. `--tables test_redaction_users` gives per-table mode through `config/test.exs:62-69` without extra flags.

**Do not** run `Ecto.Migrator` against the tmp dir.

---

### `test/threadline/mix/trigger_migration_test.exs` (NEW, optional pure unit)

**Analog:** `test/threadline/mix/migration_version_test.exs` (lines 1-26)
```elixir
defmodule Threadline.Mix.MigrationVersionTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Threadline.Mix.MigrationVersion

  setup do
    dir =
      Path.join(
        System.tmp_dir!(),
        "threadline-migration-version-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)

    %{dir: dir}
  end

  defp touch(dir, relative) do
    file = Path.join(dir, relative)
    File.mkdir_p!(Path.dirname(file))
    File.write!(file, "# test fixture\n")
  end
```
For the detector and module scan, write real contents rather than `"# test fixture\n"`, for example `"defmodule ThreadlineTriggersPosts do\n  ... threadline_audit_posts_archive ...\nend\n"`. Cover the `posts` vs `posts_archive` lookahead boundary and the `posts_2` and `a_b` vs `a,b` lookalikes. `async: true` is fine because there is no app env and no cwd.

---

### `test/threadline/capture/trigger_rerun_test.exs` (NEW DB tier)

**Analog:** `test/threadline/capture/trigger_changed_from_test.exs` (per-test trigger lifecycle, which the rerun cases need). `trigger_test.exs` uses a shared `setup_all` trigger, which is the wrong shape here.

**Header + scratch table + cleanup** (lines 1-35):
```elixir
defmodule Threadline.Capture.TriggerChangedFromTest do
  use Threadline.DataCase

  alias Threadline.Capture.{AuditChange, TriggerSQL}

  @table "test_audit_changed_from"

  setup_all do
    Repo.query!("""
    CREATE TABLE IF NOT EXISTS #{@table} (
      id    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      name  text NOT NULL,
      value integer
    )
    """)

    Repo.query!(TriggerSQL.install_function([]))

    on_exit(fn ->
      Repo.query!(TriggerSQL.drop_trigger(@table))
      Repo.query!(TriggerSQL.drop_function_for_table(@table))
      Repo.query!("DROP TABLE IF EXISTS #{@table}")
    end)

    :ok
  end

  setup do
    Repo.query!(TriggerSQL.drop_trigger(@table))
    Repo.query!(TriggerSQL.drop_function_for_table(@table))
    Repo.query!("TRUNCATE #{@table} CASCADE")
    Repo.delete_all(AuditChange, repo_opts())
    Repo.delete_all(Threadline.Capture.AuditTransaction, repo_opts())
    :ok
  end
```
Use a unique table name, for example `"test_trigger_rerun_target"`.

**Per-table install + UPDATE assertion** (lines 80-110). This is the template for D-09 case 2:
```elixir
      sql =
        TriggerSQL.install_function_for_table(@table,
          store_changed_from: true,
          except_columns: []
        )

      Repo.query!(sql)
      Repo.query!(TriggerSQL.create_trigger(@table, :per_table))
      ...
      %{rows: [[id]]} =
        Repo.query!("INSERT INTO #{@table} (name, value) VALUES ('c', 10) RETURNING id")

      Repo.delete_all(AuditChange, repo_opts())
      Repo.delete_all(Threadline.Capture.AuditTransaction, repo_opts())

      Repo.query!("UPDATE #{@table} SET value = 20, name = 'c2' WHERE id = $1", [id])

      [change] = Repo.all(AuditChange, repo_opts())
      assert is_map(change.changed_from)
```
Every `Repo.all/delete_all` on audit schemas takes `repo_opts()`, which `storage_schema_call_site_contract_test.exs` enforces. Check the trigger function through a `pg_trigger` ⋈ `pg_proc` ⋈ `pg_namespace` join on `nspname`/`proname`. Do not string-compare `tgfoid::regproc` (RESEARCH Pitfall 8). The RESEARCH "D-09 DB tier skeleton" gives the join query.

---

### `test/threadline/capture/trigger_sql_storage_schema_test.exs` — MODIFY

**Analog:** itself. It is `async: true` and pure SQL text. The test env schema is `"threadline"`.

Line 25 changes to `CREATE OR REPLACE TRIGGER` (edit the assertion **before** the SQL so the RED run is recorded):
```elixir
  test "qualified host tables create schema-qualified triggers" do
    sql = TriggerSQL.create_trigger("support.tickets")

    assert sql =~ ~S|CREATE TRIGGER "threadline_audit_support_tickets"|
```
Model the orphan-helper assertion on lines 39-46, and add `refute ... =~ "CASCADE"`:
```elixir
    assert TriggerSQL.drop_function_for_table("support.tickets") =~
             ~S|DROP FUNCTION IF EXISTS "threadline"."threadline_capture_changes_support_tickets"()|
```

---

### `test/threadline/storage_schema_test.exs` — MODIFY (D-11 guard)

**Analog:** itself, the `describe "default storage schema (D-01)"` block (lines 10-23 setup clears the env so `StorageSchema.get([])` is the code default), and the existing doc tie at lines 36-56:
```elixir
    test "the configuration reference states the default the code actually resolves" do
      default = StorageSchema.get([])

      row =
        "guides/configuration-and-commands.md"
        |> File.read!()
        |> String.split("\n")
        |> Enum.find(&String.starts_with?(&1, "| `config :threadline, storage_schema:"))

      assert row, "guides/configuration-and-commands.md lost its `storage_schema` row"
      ...
      assert String.starts_with?(String.trim(default_cell), ~s(`"#{default}"`)),
             "guides/configuration-and-commands.md documents the storage_schema default as " <>
               "#{String.trim(default_cell)}, but StorageSchema resolves #{inspect(default)} " <>
               "when no key is configured"
```
The failure-message style uses a full sentence built with `<>` that names the file and the resolved default. Copy it, and list `path:line` for every offender.

**Positive-control matcher pattern** (non-vacuous guard): `test/threadline/release_artifact_contract_test.exs:249-267`
```elixir
  test "planning-vocabulary matcher rejects every representative offender" do
    offenders = [
      {"README.md", "Phase 200 prepared this text"},
      ...
    ]

    for {path, content} <- offenders do
      assert [_ | _] = planning_vocabulary_matches(%{path => content}),
             "positive control did not flag #{path}: #{content}"
    end

    assert planning_vocabulary_matches(%{
             "lib/logo.ex" => "path d=\"M13 4 C13 8\"",
             "README.md" => "Threadline 0.9 audit data"
           }) == []
  end
```
Apply it as follows. The four current bad sentences (quoted below) must be flagged. `storage_schema: "threadline"` examples and the correct sites must pass. The real-tree scan (`Path.wildcard("guides/**/*.md") ++ ["README.md"]`) must find at least 3 correct claims. The regexes are in the RESEARCH "D-11 guard" section.

---

### Guides (docs) — MODIFY

**Voice to match:**
- `guides/getting-started-saas.md:63`: `` `storage_schema` **defaults to `"public"`**, your host's default schema. ``
- `guides/configuration-and-commands.md:32` (default column): `` `"public"`, your host's default schema, so an existing install keeps reading the tables it already has. A new install can opt into a dedicated schema such as `"threadline"`; set it before `mix threadline.install`, because the generated migrations freeze the choice. ``

**Current wrong text (exact, for the guard's positive controls):**
- `guides/audit-indexing.md:7`: `` (`threadline` by default, explicit `public` for the historical footprint) ``
- `guides/production-checklist.md:14`: `` (default `threadline`, explicit `public` for the historical footprint) ``
- `guides/how-threadline-works.md:94`: `` The storage schema defaults to `threadline`. ``
- `guides/domain-reference.md:311`: `` usually `threadline` unless you configured `storage_schema: "public"` or another name ``

**Rerun prescription sites (D-12):**
- `guides/production-checklist.md:45`: `` rerun `mix threadline.gen.triggers`, apply the generated migration, and re-check ``
- `guides/domain-reference.md:52-53`: `` Rerun `mix threadline.gen.triggers` and apply the migration. `` / `` Rerun `mix threadline.gen.triggers`; do not assume capture is aligned. ``

Contract constraints (RESEARCH Q7): keep the `## 1. Capture and triggers` heading in production-checklist, do not touch `domain-reference.md:240`, do not put `Threadline.Capture.TriggerSQL` in how-threadline-works, and do not use planning vocabulary (`D-xx`, `Phase N`, `v1.4x`).

---

### `CHANGELOG.md` — MODIFY

**Analog:** the existing 206 entry under `## Unreleased — highlights` (lines 20-66). Structure: a prose paragraph (the bug, affected releases, what changed), then `### Breaking changes` (`None.`), then `### Required action`, then `### Fixed` (bullets that quote the exact error in backticks). Add a second prose paragraph after the 206 paragraph, and append to the existing `### Required action` and `### Fixed` sections. Do not create a second set of `###` headings. Exact-error bullet style to copy:
```markdown
- `mix threadline.install` no longer writes duplicate migration versions, which
  made `mix ecto.migrate` fail with
  `(Ecto.MigrationError) migrations can't be executed, migration version <N> is duplicated`.
```
Affected releases: 0.1.0 through 0.10.1 (verified in RESEARCH Q8). Name the hidden SQL module without backticks, or not at all.

## Shared Patterns

### App-env storage schema save/restore (async: false)
**Source:** `test/mix/tasks/threadline/install_test.exs:15-37`, `test/threadline/storage_schema_test.exs:11-23`
**Apply to:** `gen_triggers_test.exs` and the storage_schema guard. Save the value with `Application.fetch_env`, restore it in `on_exit` with the `{:ok, v}`/`:error` case, and mark the module `async: false` with a comment saying why.

### Identifier-safe SQL
**Source:** `lib/threadline/capture/trigger_sql.ex:117-138` (`StorageSchema.quote_ident/1`, `qualified_host_table/1`, `function/2`, `host_table_suffix/1`)
**Apply to:** all new SQL (orphan drop) and naming (resolver, detector). Never interpolate raw table names. Use `Regex.escape/1` on the suffix in the detector.

### Mix task output
**Source:** `lib/mix/tasks/threadline.gen.triggers.ex:143-144`: `create_file(file, content)` from `Mix.Generator`, then `Mix.shell().info(...)`. Tests capture the output with `Mix.Shell.Process` + `drain_shell/1`.

### Durable vocabulary in packaged files
**Source:** `test/threadline/release_artifact_contract_test.exs:7-14`
**Apply to:** lib comments, the generated migration's rollback comment, guides, and CHANGELOG. No `D-\d\d`, `Phase N`, `phase207`, or `v1.41`.

### DB test hygiene
**Source:** `test/threadline/capture/trigger_changed_from_test.exs:7-35`
**Apply to:** the DB tier. `use Threadline.DataCase`, a scratch table created with `CREATE TABLE IF NOT EXISTS`, `on_exit` drops the trigger, the function and the table, and `repo_opts()` is passed on every audit-schema Repo call.

## No Analog Found

None. The only new logic with no existing code is the resolver/detector in `trigger_migration.ex`. It follows `migration_version.ex` structurally, and its algorithm is specified in RESEARCH Patterns 2-4.

## Metadata

**Analog search scope:** `lib/mix/tasks/`, `lib/threadline/mix/`, `lib/threadline/capture/`, `test/mix/tasks/threadline/`, `test/threadline/mix/`, `test/threadline/capture/`, `test/threadline/storage_schema_test.exs`, `test/threadline/release_artifact_contract_test.exs`, `guides/`, `CHANGELOG.md`, `priv/ci/hex_evaluator/`
**Files scanned:** 14
**Pattern extraction date:** 2026-09-24
