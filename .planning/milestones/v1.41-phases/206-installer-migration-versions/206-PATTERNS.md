# Phase 206: Installer Migration Versions - Pattern Map

**Mapped:** 2026-09-24
**Files analyzed:** 6 (1 new lib, 2 edited lib, 1 edited test, 1 optional new test, 1 edited doc)
**Analogs found:** 6 / 6 (all analogs are git-tracked; checked with `git ls-files`)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/threadline/mix/migration_version.ex` (NEW) | utility (hidden, pure) | transform (dir listing + clock → versions) | `lib/threadline/operator_surface/exports/filename.ex` (pure `@moduledoc false` stamp formatter); `lib/threadline/critic_trust/rank_metrics.ex` (hidden helper called from a Mix task) | role-match |
| `lib/mix/tasks/threadline.install.ex` (EDIT) | Mix task / generator | file-I/O | itself (lines 22-69, 71-113, 147-161) | exact |
| `lib/mix/tasks/threadline.gen.triggers.ex` (EDIT) | Mix task / generator | file-I/O | itself (lines 129-138, 257-263); alias block at :57-58 | exact |
| `test/mix/tasks/threadline/install_test.exs` (EDIT) | test (file-level, tmp dir) | file-I/O | itself (lines 1-56 harness) | exact |
| `test/threadline/mix/migration_version_test.exs` (OPTIONAL NEW) | test (pure unit) | transform | `test/threadline/operator_surface/exports/filename_test.exs` | exact |
| `CHANGELOG.md` (EDIT, Unreleased) | doc | n/a | `CHANGELOG.md` `[0.10.1]` entry, lines 29-65 | exact |

## Pattern Assignments

### `lib/threadline/mix/migration_version.ex` (utility, transform) — NEW

**Analog:** `lib/threadline/operator_surface/exports/filename.ex` (31 lines). Same shape: `@moduledoc false`, module attribute for the format, `@spec`-ed public fn, private `Calendar.strftime` formatter.

```elixir
defmodule Threadline.OperatorSurface.Exports.Filename do
  @moduledoc false

  @valid_formats ~w(csv json ndjson)

  @doc """
  Returns the canonical export filename for the given format and datetime.
  ...
  """
  @spec for(String.t(), DateTime.t()) :: String.t()
  def for(format, %DateTime{} = dt) when format in @valid_formats do
    stamp = format_stamp(dt)
    "threadline-changes-#{stamp}.#{format}"
  end

  defp format_stamp(%DateTime{} = dt) do
    dt
    |> DateTime.shift_zone!("Etc/UTC")
    |> Calendar.strftime("%Y-%m-%dT%H-%MZ")
  end
end
```

Second analog for the "hidden lib module with `@spec` + guard clauses + fallback clause" style: `lib/threadline/critic_trust/rank_metrics.ex:1-15` (`@moduledoc false`, `@doc` on public fns, `@spec ... :: ...`, a guarded clause then a catch-all clause). Called from `lib/mix/tasks/critic.measure.ex:8` via `alias Threadline.CriticTrust.{...}` — precedent that a Mix task calling a hidden `lib/threadline/**` module is fine for Dialyzer/xref.

**Core algorithm:** use RESEARCH.md "Pattern 1" verbatim (prototype-proven). Key points to carry into the plan:
- `def next(path, count, now \\ NaiveDateTime.utc_now())` with a `count == 0 → []` clause and `0..(count - 1)//1` ranges (Pitfall 3).
- Existing versions mirror Ecto: recursive `Path.join([path, "**", "*.exs"]) |> Path.wildcard()`, `Integer.parse(Path.basename(file, ".exs"))` → `{n, "_" <> _}`.
- Step with `NaiveDateTime.add(&1, :second)` + `Calendar.strftime("%Y%m%d%H%M%S")`; never integer +1 except the D-03 non-datetime fallback.

**Constraints:** no planning IDs in comments (`D-0x`, `WR-03`, `Phase 206`, `v1.41` fail `release_artifact_contract_test.exs` vocabulary scan since `lib/` is packaged). Do not put it under `Mix.Tasks.*` (public_surface task partition, `public_surface_contract_test.exs:393-407`).

---

### `lib/mix/tasks/threadline.install.ex` (Mix task, file-I/O) — EDIT

**Current structure to change** (read in full, 162 lines):

- `run/1` lines 22-57: three inline `generate(path, suffix, label, content_fun)` calls, then `|> Enum.reject(&is_nil/1)`, then `recommend_dedicated_storage_schema(written)`.
- `generate/4` lines 59-69 — the defect line is 65:
  ```elixir
  file = Path.join(path, "#{timestamp()}#{suffix}")
  create_file(file, content_fun.())
  file
  ```
  Returns `nil` on skip. Change to return `{:written, file}` / `:skipped`, with the version passed in (computed once in `run/1`, before any write; see RESEARCH Pattern 2 `Enum.map_reduce` shape).
- Comment lines 71-79: rewrite; its last sentence ("When nothing was written ... the advice is withheld") is the false premise. Describe three branches (fresh / partial / nothing-or-configured) without planning IDs.
- `recommend_dedicated_storage_schema/1` lines 80-113: keep the heading text at :88-107 (tests assert `No \`:storage_schema\` is configured`, `Delete the migration files this run just generated`, `config :threadline, storage_schema: "threadline"`). **Delete lines 109-110** (D-08 paragraph `Existing installs need no action: ...`). Gate the fresh advice on "all three written"; add a partial-run note containing the literal `Keep \`:storage_schema\` unset` and NOT containing `No \`:storage_schema\` is configured`.
- Keep the heredoc style (`Mix.shell().info("""\n ... """)`, leading blank line) and the `is_nil(Application.get_env(:threadline, :storage_schema))` gate from :83.
- Keep `migrations_path/0` :115-131, `repo_migrations_path/1` :134-145, `existing_migration?/2` :147-153 unchanged.
- **Delete** `timestamp/0` :155-158 and `pad/1` :160-161.
- Add `alias Threadline.Mix.MigrationVersion` after `import Mix.Generator` (:20), matching gen.triggers' alias placement (:55-58).

---

### `lib/mix/tasks/threadline.gen.triggers.ex` (Mix task, file-I/O) — EDIT

**Write branch** (lines 129-138, non-dry-run only):
```elixir
    else
      path = "priv/repo/migrations"
      File.mkdir_p!(path)

      table_suffix = Enum.map_join(tables, "_", &StorageSchema.host_table_suffix/1)
      file = Path.join(path, "#{timestamp()}_threadline_triggers_#{table_suffix}.exs")

      create_file(file, migration_content(table_specs))
      Mix.shell().info("Run `mix ecto.migrate` to install the triggers.")
    end
```
Replace line 134 with `[version] = MigrationVersion.next(path, 1)` + `Path.join(path, "#{version}_threadline_triggers_#{table_suffix}.exs")`. Do not touch the dry-run branch (:120-128) or the hard-coded path (out of scope).

**Alias block** (lines 54-58) — add the helper here:
```elixir
  use Mix.Task
  import Mix.Generator

  alias Threadline.Capture.{RedactionPolicy, TriggerCaptureConfig, TriggerSQL}
  alias Threadline.StorageSchema
```
**Delete** `timestamp/0` :257-260 and `pad/1` :262-263 (byte-identical to install's). Do not touch `StorageSchema.threadline_table?` at :90 (pinned by `code_walkthrough_doc_contract_test.exs:12-14`).

---

### `test/mix/tasks/threadline/install_test.exs` (test, file-I/O) — EDIT

**Harness to reuse** (lines 1-56, unchanged):
```elixir
  use ExUnit.Case, async: false
  alias Mix.Tasks.Threadline.Install

  @suffixes [
    "_threadline_audit_schema.exs",
    "_threadline_semantics_schema.exs",
    "_threadline_governance_schema.exs"
  ]

  setup do
    previous_shell = Mix.shell()
    previous_schema = Application.fetch_env(:threadline, :storage_schema)
    Mix.shell(Mix.Shell.Process)
    tmp = Path.join(System.tmp_dir!(), "threadline-install-#{System.unique_integer([:positive])}")
    File.mkdir_p!(tmp)
    on_exit(fn -> ... restore shell + env ...; File.rm_rf!(tmp) end)
    %{tmp: tmp}
  end

  defp run_install(tmp) do
    File.cd!(tmp, fn -> Install.run([]) end)
    drain_shell([])
  end
```
**Test shape to copy** (lines 102-114 — per-test `Application.delete_env`, then run, then `assert`/`refute output =~`):
```elixir
  test "a re-run over an existing install skips every migration and gives no schema advice",
       %{tmp: tmp} do
    Application.delete_env(:threadline, :storage_schema)
    run_install(tmp)
    before = generated(tmp)

    output = run_install(tmp)

    assert generated(tmp) == before
    assert output =~ "already exists — skipping"
    refute output =~ "No `:storage_schema` is configured"
    refute output =~ "Run `mix ecto.migrate`"
  end
```
**Assertion-message style** (lines 70-73): long `assert ..., "explanation " <> "..."` messages that state the adopter-visible consequence — use this for the duplicate-version message quoting Ecto's `migration version ... is duplicated`.

**Additions:** `prefixes/2` and `assert_valid_increasing!/1` helpers + cases 1-4 from RESEARCH "Regression test skeleton". Seeds go in `Path.join(tmp, "priv/repo/migrations")` (mkdir first). Case 4: `File.cd!(tmp, fn -> Mix.Tasks.Threadline.Gen.Triggers.run(["--tables", "posts"]) end)` then `drain_shell([])`; assert all 4 prefixes unique + increasing (Pitfall 4). Case 3 seeds far-future valid prefixes (`20991231235958_…audit…`, `20991231235959_…semantics…`). All 4 existing tests must stay green unchanged. Prove new cases RED on unmodified code first.

---

### `test/threadline/mix/migration_version_test.exs` (test, transform) — OPTIONAL NEW

**Analog:** `test/threadline/operator_surface/exports/filename_test.exs`:
```elixir
defmodule Threadline.OperatorSurface.Exports.FilenameTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Threadline.OperatorSurface.Exports.Filename

  describe "for/2" do
    test "returns the canonical CSV filename with HYPHEN between hours and minutes" do
      dt = ~U[2026-05-06 12:00:00.000Z]
      assert Filename.for("csv", dt) == "threadline-changes-2026-05-06T12-00Z.csv"
    end
```
Use `describe "next/3"`, fixed `~N[...]` `now` via the optional third arg, and a per-test tmp dir (copy the `System.tmp_dir!()` + `System.unique_integer([:positive])` + `on_exit(File.rm_rf!)` setup from install_test.exs:19-33). Can be `async: true` (no cwd/app-env). Cases: empty dir → `count` consecutive; `count = 0` → `[]`; `20991231235959_x.exs` → `21000101000000..`; `99999999999999_bad.exs` → integer fallback `100000000000000..`; small-int `7_legacy.exs` → now-based; subdirectory file counted (recursive).

---

### `CHANGELOG.md` (doc) — EDIT Unreleased

**Location:** lines 20-27. Keep heading `## Unreleased — highlights` and its paragraph (:22-25); replace `_Nothing yet for the next release._` (:27).

**Template to copy:** `[0.10.1]` entry, lines 29-65:
```markdown
A patch release that corrects the storage-schema advice `mix threadline.install`
prints on a new install, ... No library behavior changes: ...

### Breaking changes

None.

### Required action

None for most installs. ...

- **Not yet migrated:** ...
- **Already migrated:** ...

### Fixed

- `mix threadline.install` now gives its storage-schema advice after generating,
  names the migration files it just wrote, ...
```
Order: lead prose → `### Breaking changes` → `### Required action` → `### Fixed`. Required content per D-12 (exact Ecto string, "every release through 0.10.1", semantics-then-governance rename workaround, gen.triggers mention, partial re-run advice mention). Forbidden: backticked `Threadline.Mix.MigrationVersion`, `WR-03`/`CR-01`/`D-xx`/`Phase 206`/`v1.41`, `## [Unreleased]`, generated `([abcdef0](...commit...))` bullets.

## Shared Patterns

### Hidden internal module
**Source:** `lib/threadline/operator_surface/exports/filename.ex:1-2`, `lib/threadline/capture/migration.ex:1-2`
**Apply to:** the new helper. `@moduledoc false` passes `public_surface_contract_test.exs` visibility (hidden modules excluded) and Credo `Readability.ModuleDoc`.

### Mix shell output
**Source:** `lib/mix/tasks/threadline.install.ex:53,62,86-111`
**Apply to:** all installer messages — `Mix.shell().info/1`, multi-line advice as a heredoc with a leading blank line; tests capture via `Mix.Shell.Process` + `drain_shell/1`.

### Packaged-file vocabulary gate
**Source:** `test/threadline/release_artifact_contract_test.exs:7-14`
**Apply to:** every `lib/` comment and `CHANGELOG.md`. Test files are not packaged.

## No Analog Found

None. The version algorithm itself has no in-repo precedent (both existing `timestamp/0` copies are the defect); use RESEARCH.md Pattern 1.

## Metadata

**Analog search scope:** `lib/mix/tasks/`, `lib/threadline/**` (`@moduledoc false` modules), `test/mix/tasks/threadline/`, `test/threadline/operator_surface/exports/`, `CHANGELOG.md`
**Files scanned:** ~10
**Pattern extraction date:** 2026-09-24
