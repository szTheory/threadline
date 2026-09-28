# Phase 211: Read-Side Agreement - Pattern Map

**Mapped:** 2026-09-25
**Files analyzed:** 12
**Analogs found:** 11 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|----------------|
| `lib/threadline/query/row_key.ex` (NEW) | service (query-helper) | transform + request-response | `lib/threadline/capture/primary_key_sql.ex` | role-match (catalog-driven SQL construction) |
| `lib/threadline/query.ex` (MODIFY: `history/3`, `row_history_query/3`, `as_of/4`) | service | CRUD (read) | itself, `lib/threadline/query.ex` other read functions (`audit_changes_for_transaction/2`, `actor_history/2`) | exact (same file, same conventions) |
| `lib/threadline/capture/row_history_index_sql.ex` (NEW) | utility (shared SQL source) | transform | `lib/threadline/capture/primary_key_sql.ex` | role-match (shared SQL string builder used by both a migration template and a generator) |
| `lib/mix/tasks/threadline.gen.row_history_index.ex` (NEW) | config/generator (Mix task) | file-I/O | `lib/mix/tasks/threadline.gen.triggers.ex` | exact (Mix.Generator + MigrationsPath + MigrationVersion scaffolding) |
| `lib/threadline/capture/migration.ex` (MODIFY: add index to install template) | migration | file-I/O | itself (existing index statements in the same file) | exact |
| `test/threadline/storage_schema_migration_contract_test.exs` (MODIFY: pin new index) | test | transform (string/byte assertions) | itself (existing `assert migration =~ ...` pattern) | exact |
| `lib/threadline/operator_surface/live/transaction_live.ex` (MODIFY: `change_history_path/2`) | component (LiveView) | request-response | `lib/threadline/operator_surface/live/timeline_live/helpers.ex` (`routeable_row_identity/2`, `safe_row_history_path/3`) | exact (same guard concept, different call site) |
| `test/threadline/operator_surface/live/transaction_live_test.exs` (MODIFY: extend render test) | test | request-response | itself / sibling `timeline_live_test.exs` if it tests `routeable_row_identity` | role-match |
| `test/threadline/query/row_key_test.exs` (NEW) | test | CRUD (read) | `test/threadline/capture/trigger_pk_shapes_test.exs` (Phase 210 composite-key/override fixture patterns) | role-match |
| `test/mix/tasks/threadline/gen_row_history_index_test.exs` (NEW) | test | file-I/O | `test/mix/tasks/threadline/gen_triggers_test.exs` | exact |
| `test/threadline/query/row_history_index_explain_test.exs` (NEW) | test | CRUD (read, EXPLAIN) | no direct analog found — nearest is `test/threadline/storage_schema_migration_contract_test.exs` for the "assert on generated SQL/plan text" style | no analog (new pattern for this codebase) |
| `guides/audit-indexing.md` (MODIFY: docs) | config (docs) | — | itself | exact |

## Pattern Assignments

### `lib/threadline/query/row_key.ex` (NEW — service)

**Analog:** `lib/threadline/capture/primary_key_sql.ex` (catalog-driven SQL construction trust model) + `lib/threadline/capture/trigger_capture_config.ex` (`primary_key:` override resolution) + `lib/threadline/query.ex` (existing `history/3`/`as_of/4` shape being replaced)

**Imports pattern** (`lib/threadline/capture/primary_key_sql.ex` lines 1-12):
```elixir
defmodule Threadline.Capture.PrimaryKeySQL do
  @moduledoc false

  alias Threadline.Capture.Naming
  alias Threadline.StorageSchema
```
`RowKey` should follow the same `@moduledoc false` (internal module, `@doc false` boundary already used for `row_history_query/3`) plus targeted `alias`es: `Threadline.Capture.TriggerCaptureConfig`, `Threadline.StorageSchema`.

**Key-column resolution order (D-18), to mirror** (`lib/threadline/capture/trigger_capture_config.ex` lines 80-84, override precedence pattern):
```elixir
raw_primary_key = Keyword.get(entry, :primary_key)
validate_primary_key!(table, raw_primary_key, normalized)
...
|> put_if_present(:primary_key, normalize_primary_key(raw_primary_key))
```
`RowKey.resolve!/1` should call `Threadline.Capture.TriggerCaptureConfig.load()` first (mirrors `capture_tables_by_pair!/1` in `lib/mix/tasks/threadline.gen.triggers.ex` lines 309-325 for schema-qualified lookup: `StorageSchema.parse_table_identifier/1` → `Naming.qualified/1`), falling back to `schema_module.__schema__(:primary_key)`, raising `ArgumentError` if neither exists — same shape as `primary_key_sql.ex`'s "no primary key" refusal (see moduledoc lines 71-79: "A table with no primary key refuses the migration... naming the qualified table").

**Field↔column mapping (D-02)** — use `__schema__(:field_source, field)` per RESEARCH.md Pattern 2 (verified against `deps/ecto/lib/ecto/schema.ex:451-455`); no in-repo analog needed, this is a direct Ecto API call.

**Catalog type lookup + raw parameterized SQL render (D-04/D-05)** — RESEARCH.md's Pattern 1 and "Code Examples" sections give proven, session-verified SQL text (`catalog_types!/3`, `render_comparison!/3`). Follow `primary_key_sql.ex`'s trust model: type text is interpolated **unquoted** (Pitfall 4: `format_type()` output must never be re-quoted with `"..."`), values are always parameterized via `$n` placeholders, never string-interpolated.

**Identifier/string escaping to reuse** — grep confirms `primary_key_sql.ex` already has a `sql_string_literal/1`-style helper for escaping single quotes in column names used as jsonb object key literals; reuse it rather than re-deriving escaping logic. (Exact function name/line to be located by the implementer via `grep -n "sql_string_literal\|escape" lib/threadline/capture/primary_key_sql.ex` since it was not required reading here — RESEARCH.md's Security Domain section names this precedent explicitly.)

**Error style (`ArgumentError`, D-03)** — no `threadline:`-prefix precedent for read-time errors; `Threadline.Query`'s existing `ArgumentError`s (e.g. `validate_correlation_id_filter!/1`, referenced in RESEARCH.md Open Question 2) are the closer analog — bare messages, no prefix. Follow D-03's exact verbatim message shapes:
```
expected keys [:tenant_id, :id] for MyApp.LineItem, got [:id]
expected keys [:tenant_id, :id] for MyApp.LineItem, got a single value; pass a map or keyword list with every key field
```

---

### `lib/threadline/query.ex` (MODIFY — `history/3`, `row_history_query/3`, `as_of/4`)

**Analog:** itself — the three functions already share `maybe_apply_scope/2`, `storage_opts/2`, `row_history_scope_opts/2`.

**Current pattern to replace** (lines 378-443, read this session):
```elixir
def history(schema_module, id, opts) do
  repo = Keyword.fetch!(opts, :repo)
  table = schema_module.__schema__(:source)
  table_schema = schema_module.__schema__(:prefix) || "public"
  [pk_field] = schema_module.__schema__(:primary_key)
  pk_map = %{to_string(pk_field) => id}

  AuditChange
  |> where([ac], ac.table_schema == ^table_schema)
  |> where([ac], ac.table_name == ^table)
  |> where([ac], fragment("? @> ?::jsonb", ac.table_pk, ^pk_map))
  |> maybe_apply_scope(row_history_scope_opts(schema_module, id, opts))
  |> order_by([ac], desc: ac.captured_at)
  |> repo.all(storage_opts([], opts))
end
```
Same shape repeats at lines 396-409 (`row_history_query/3`, no `repo`/`maybe_apply_scope`, used as an Ecto query composed further by `timeline_base_query/1`) and lines 419-443 (`as_of/4`, adds `captured_at <=`, `order_by id desc`, `limit(1)`, `repo.one`).

**Required change per RESEARCH.md "Using the rendered map in the existing query pipeline"** — only the predicate line changes, everything else (the `where(table_schema)`, `where(table_name)`, `maybe_apply_scope`, `storage_opts`, ordering, `repo.all`/`repo.one`) stays exactly as-is:
```elixir
AuditChange
|> where([ac], ac.table_schema == ^table_schema)
|> where([ac], ac.table_name == ^table)
|> where([ac], ac.table_pk == ^rendered_map)   # was: fragment("? @> ?::jsonb", ac.table_pk, ^pk_map)
```
`rendered_map` comes from `RowKey.resolve!/1` → `RowKey.validate!/2` → `RowKey.render!/4` (repo needed earlier than today, since rendering issues catalog + render round trips before the query executes).

**`row_history_scope_opts/2` params passthrough** (lines 656-663) — keep `params: %{schema_module: schema_module, id: id}` forwarding the **raw caller-supplied `id`** unchanged (RESEARCH.md Open Question 1's recommendation), not the resolved/rendered map, so existing `scope_query_fn` callbacks keep working for scalar callers.

---

### `lib/threadline/capture/row_history_index_sql.ex` (NEW — utility)

**Analog:** `lib/threadline/capture/primary_key_sql.ex` (shared SQL-string-builder module pattern, `@moduledoc false`, single-purpose functions returning SQL text for both a migration template and a Mix generator to consume).

**Pattern to mirror** — one function returning the raw `CREATE INDEX` SQL body (no `IF NOT EXISTS`/`CONCURRENTLY` baked in, per D-09/D-10's requirement that new-install and generator share one source but differ in transaction/concurrency mode):
```elixir
@spec row_history_index_ddl(String.t()) :: String.t()
def row_history_index_ddl(audit_changes_table) do
  "ON #{audit_changes_table} (table_schema, table_name, table_pk, captured_at DESC, id DESC)"
end
```
Consumed by `migration.ex` as `CREATE INDEX IF NOT EXISTS audit_changes_row_history_idx #{ddl}` and by the new generator as `CREATE INDEX CONCURRENTLY IF NOT EXISTS audit_changes_row_history_idx #{ddl}`.

---

### `lib/mix/tasks/threadline.gen.row_history_index.ex` (NEW — Mix generator)

**Analog:** `lib/mix/tasks/threadline.gen.triggers.ex` (full generator scaffolding read this session, lines 180-374)

**Imports/alias pattern** (lines 180-185):
```elixir
use Mix.Task
import Mix.Generator

alias Threadline.Capture.{Naming, RedactionPolicy, TriggerCaptureConfig, TriggerSQL}
alias Threadline.Mix.{MigrationsPath, MigrationVersion, TriggerMigration}
alias Threadline.StorageSchema
```
New task needs only `Threadline.Mix.{MigrationsPath, MigrationVersion}` and `Threadline.Capture.RowHistoryIndexSQL`.

**Option parsing pattern** (lines 256-275):
```elixir
defp parse_opts!(args) do
  {opts, _rest, invalid} =
    OptionParser.parse(args,
      strict: [migrations_path: :string, repo: :keep],
      aliases: [r: :repo]
    )

  if invalid != [] do
    Mix.raise("Unknown options: #{inspect(invalid)}")
  end

  opts
end
```

**Migration-file-writing pattern** (lines 345-365, adapt for one static index rather than per-table specs):
```elixir
defp write_migration!(path) do
  File.mkdir_p!(path)
  [version] = MigrationVersion.next(path, 1)
  file = Path.join(path, "#{version}_add_row_history_index.exs")
  create_file(file, migration_content())
end
```

**`@disable_ddl_transaction true` / `@disable_migration_lock true` / `CREATE INDEX CONCURRENTLY`** — no in-repo analog (this is the first `CONCURRENTLY` migration in the codebase); RESEARCH.md D-10 gives the exact required shape:
```elixir
def up do
  execute "CREATE INDEX CONCURRENTLY IF NOT EXISTS audit_changes_row_history_idx #{RowHistoryIndexSQL.row_history_index_ddl(table)}"
end

def down do
  execute "DROP INDEX CONCURRENTLY IF EXISTS audit_changes_row_history_idx"
end
```
Module attributes go above `use Ecto.Migration`, matching standard Ecto convention (`@disable_ddl_transaction true`, `@disable_migration_lock true`), with a comment (per D-10) that a failed concurrent build leaves an INVALID index which `IF NOT EXISTS` then skips — drop and rerun.

---

### `lib/threadline/capture/migration.ex` (MODIFY — add index to install template)

**Analog:** itself — existing index statements in the same file (lines 55-63, read this session):
```elixir
execute \"\"\"
CREATE INDEX IF NOT EXISTS audit_changes_transaction_id_idx ON #{audit_changes} (transaction_id)
\"\"\"

execute \"\"\"
CREATE INDEX IF NOT EXISTS audit_changes_table_name_idx ON #{audit_changes} (table_name)
\"\"\"

execute \"\"\"
CREATE INDEX IF NOT EXISTS audit_changes_captured_at_idx ON #{audit_changes} (captured_at)
\"\"\"
```
Add, in the same block, right after these (before `execute #{sql_literal(TriggerSQL.install_function([]))}`):
```elixir
execute \"\"\"
CREATE INDEX IF NOT EXISTS audit_changes_row_history_idx ON #{audit_changes} (table_schema, table_name, table_pk, captured_at DESC, id DESC)
\"\"\"
```
Per D-11, `audit_changes_table_name_idx` must stay — do not remove it.

---

### `test/threadline/storage_schema_migration_contract_test.exs` (MODIFY — pin new index)

**Analog:** itself — existing `assert migration =~ ~S|...|` byte-pin pattern (lines 20-27, 63-79 read this session).

```elixir
test "generated capture migration quotes the configured Threadline storage schema" do
  migration = Threadline.Capture.Migration.migration_content()

  assert migration =~ ~S|CREATE SCHEMA IF NOT EXISTS "threadline"|
  ...
```
Add an assertion for `audit_changes_row_history_idx` in this same test (or a new one), following the same `~S|...|` sigil style. If the SHA256 byte-pins (`@governance_default_sha256` etc., lines 8-11) apply to the capture migration too, they must be recomputed and updated in the same commit as the index addition (the test file's own comment: "Change these only together with an intended change to the generated migration, and say why in the commit").

---

### `lib/threadline/operator_surface/live/transaction_live.ex` (MODIFY — `change_history_path/2`)

**Analog:** `lib/threadline/operator_surface/live/timeline_live/helpers.ex` — `routeable_row_identity/2` and `safe_row_history_path/3` already implement the "single-key only" guard this bug needs.

**The bug** (`transaction_live.ex` lines 401-406, read this session):
```elixir
defp change_history_path(base_path, change) do
  table = change.change_diff["table_name"]
  record_id = change.change_diff["table_pk"] |> Map.values() |> List.first()
  captured_at = change.change_diff["captured_at"]

  "#{history_path(base_path, table, record_id)}?as_of=#{captured_at}"
end
```
`Map.values() |> List.first()` silently picks one column of a composite key and links to the wrong record.

**The correct guard to mirror** (`timeline_live/helpers.ex` lines 153-165, read this session):
```elixir
defp routeable_row_identity(table, %{} = table_pk) when is_binary(table) do
  table = String.trim(table)

  with true <- table != "",
       [{_key, value}] <- Map.to_list(table_pk),
       true <- routeable_row_value?(value) do
    {table, to_string(value)}
  else
    _ -> nil
  end
end

defp routeable_row_identity(_table, _table_pk), do: nil
```
`[{_key, value}] <- Map.to_list(table_pk)` is a single-clause list-pattern match — it only succeeds when `table_pk` has **exactly one** key; a composite map (2+ keys), `{}` (0 keys) or `{"id": null}` (fails `routeable_row_value?/1`, since `nil` is neither binary/integer/float) all fall through to `nil`.

**Required fix shape for `change_history_path/2`**: change it to return `nil` under the same three conditions and have the caller in the `.link patch={...}` (transaction_live.ex line 239) render conditionally — mirror `timeline_live.ex`'s conditional-link pattern, which itself already consumes `safe_row_history_path/3`'s `nil` return (helpers.ex lines 69-81) to omit the link. `Presentation` / `Icon` component wiring at line 239-242 stays; only the guard is new.

---

## Shared Patterns

### Catalog-driven, never-caller-input SQL construction
**Source:** `lib/threadline/capture/primary_key_sql.ex` (whole file, `create_trigger_block/3` and its `@doc` at lines 51-121)
**Apply to:** `Threadline.Query.RowKey`'s catalog type lookup and comparison-value render step.
Type text is always sourced from PostgreSQL's own catalog (`pg_attribute`/`format_type`), never from caller input or an Ecto-side type map; values are always bound as `$n` parameters, never interpolated. This is the same trust model already audited and shipped for capture-side DDL; the read side reuses it rather than inventing a new one.

### Key-column resolution order (D-18, carried from Phase 210)
**Source:** `lib/threadline/capture/trigger_capture_config.ex` lines 78-92 (override normalization) and its cross-reference in `lib/threadline/capture/primary_key_sql.ex`'s `create_trigger_block/3` `case`
**Apply to:** `RowKey.resolve!/1` — `primary_key:` override first, then `__schema__(:primary_key)`, else raise. Do not re-derive this order; call `TriggerCaptureConfig.load/0` the same way `gen.triggers.ex`'s `load_capture_tables!/0` (lines 331-336) does.

### `ArgumentError` for bad caller input, bare (no `threadline:` prefix), at the API boundary
**Source:** `lib/threadline/query.ex` (existing validators like `validate_correlation_id_filter!/1`, cited in RESEARCH.md; not in the required-reading excerpt above but confirmed present in the file's helper section)
**Apply to:** all of `RowKey`'s validation errors (D-03). Contrast with `threadline:`-prefixed messages, which are migrate-time-only (`primary_key_sql.ex` moduledoc, e.g. "the error names the qualified table").

### Mix.Generator scaffolding (`MigrationsPath.resolve/1`, `MigrationVersion.next/3`, `create_file/2`)
**Source:** `lib/mix/tasks/threadline.gen.triggers.ex` lines 181-184, 240, 345-365
**Apply to:** `lib/mix/tasks/threadline.gen.row_history_index.ex` — do not hand-roll migration-file naming or versioning; reuse `Threadline.Mix.MigrationsPath`/`Threadline.Mix.MigrationVersion` exactly as the trigger generator does.

### Single-key-only row-link guard
**Source:** `lib/threadline/operator_surface/live/timeline_live/helpers.ex` lines 141-165
**Apply to:** `transaction_live.ex`'s `change_history_path/2` fix (READ-04/D-08) — same `[{_key, value}] <- Map.to_list(table_pk)` single-clause match, same `nil`-on-anything-else fallthrough.

### Shared SQL source between install template and CONCURRENTLY generator
**Source:** No single existing shared-SQL module for an index specifically, but the *pattern* (one `lib/threadline/capture/*_sql.ex` module consumed by both `migration.ex`'s install template and a `lib/mix/tasks/threadline.gen.*.ex` generator) is exactly `primary_key_sql.ex`'s relationship to `migration.ex`/`trigger_sql.ex` and `gen.triggers.ex`.
**Apply to:** `lib/threadline/capture/row_history_index_sql.ex`, consumed by both `migration.ex` (new-install branch, D-09) and `threadline.gen.row_history_index.ex` (existing-adopter branch, D-10), so the DDL text cannot drift between the two paths.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `test/threadline/query/row_history_index_explain_test.exs` | test | CRUD (read, EXPLAIN) | No existing test in this codebase asserts on an `EXPLAIN` plan or sets `enable_seqscan = off`. RESEARCH.md's "Pattern 3" (verified this session against real PostgreSQL) is the only reference — use it directly: `EXPLAIN` (or `EXPLAIN (FORMAT JSON)`) the query, assert the plan text/`"Index Name"` contains `"audit_changes_row_history_idx"`, wrapped in a session-scoped `SET LOCAL enable_seqscan = off` inside a transaction so it does not leak to other tests (`Threadline.DataCase` runs `async: false`, no sandbox, per RESEARCH.md's Test Framework table — be careful to reset `enable_seqscan` after, e.g. via a `transaction`/`on_exit`, since there is no sandbox rollback safety net here). |

## Metadata

**Analog search scope:** `lib/threadline/`, `lib/mix/tasks/`, `test/threadline/`, `test/support/`, `test/mix/tasks/` (targeted `Read`/`Bash grep` of files named in CONTEXT.md's `<canonical_refs>` and RESEARCH.md's `Sources` section — no blind `Glob` sweep was needed since both upstream documents already named exact files/line ranges).
**Files scanned (fully or targeted-range read this session):** `lib/threadline/query.ex`, `lib/threadline/capture/primary_key_sql.ex`, `lib/threadline/capture/trigger_capture_config.ex`, `lib/threadline/capture/migration.ex`, `lib/mix/tasks/threadline.gen.triggers.ex`, `lib/threadline/operator_surface/live/transaction_live.ex`, `lib/threadline/operator_surface/live/timeline_live/helpers.ex`, `test/support/legacy_trigger_sql.ex`, `test/threadline/storage_schema_migration_contract_test.exs` (11 files, ~9 with targeted reads, 0 re-reads of the same range).
**Pattern extraction date:** 2026-09-25
