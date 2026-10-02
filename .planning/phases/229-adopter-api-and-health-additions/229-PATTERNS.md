# Phase 229: Adopter API and Health Additions - Pattern Map

**Mapped:** 2026-10-02
**Files analyzed:** 9 (6 modify, 3 new/extend-as-new)
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|-----------------|---------------|
| `lib/threadline/query.ex` (`history/3`, `history_query/3`) | service (Ecto query builder) | CRUD (read, capped) | `lib/threadline/evidence.ex` (`validate_limit!/1`, `maybe_limit/2`) | exact |
| `lib/threadline.ex` (`history/3` doc) | public API facade / docs | request-response | same file, existing `history/3` delegation + doc block | exact |
| `lib/mix/tasks/threadline.health.coverage.ex` (`--strict`, `--all-schemas`, invalid-switch raise) | CLI / Mix task | request-response (catalog scan + render) | `lib/mix/tasks/threadline.verify_coverage.ex` | exact (same task family, gate pattern already implemented there) |
| `lib/threadline/health.ex` (`legacy_key_findings/1` delegate) | service (public API) | CRUD (read) | same file's `trigger_findings/1` delegate pattern | exact |
| `lib/threadline/health/finding.ex` (new code in union) | model / struct | transform | same file (extend `@type code`, moduledoc Codes list) | exact |
| `lib/threadline/health/legacy_key_findings.ex` (NEW module) | service (catalog + data probe) | CRUD (capped probe) | `lib/threadline/health/trigger_findings.ex` | exact (sibling `Health.*Findings` module: `codes/0`, `run/1`, `Finding` construction, sort, telemetry-free variant) |
| `lib/threadline/health/coverage_schemas.ex` (`pg_depend` exclusion, all-schemas enumeration) | service (catalog query) | CRUD (read) | same file's `available/1` | exact |
| `test/threadline/query_test.exs` (`:limit` cases) | test | CRUD / property | same file, `"applies support scope"` fixture (~line 411) | exact |
| `test/threadline/operator_surface/coverage_mix_test.exs` (`--strict`/`--all-schemas` matrix) | test | integration | `test/threadline/verify_coverage_task_test.exs` (exit-capture pattern) + same file's existing JSON-key-set test | exact |

## Pattern Assignments

### `lib/threadline/query.ex` — `history/3` `:limit` (service, CRUD)

**Analog:** `lib/threadline/evidence.ex`

**Validator pattern to adapt** (evidence.ex:313-317, read this session):
```elixir
defp validate_limit!(value) when is_integer(value) and value > 0, do: :ok

defp validate_limit!(value) do
  raise ArgumentError, ":limit must be a positive integer, got: #{inspect(value)}"
end
```
Per D-01, `history/3`'s version must diverge exactly one way: `nil` is accepted (unbounded), so write a new clause set in `Threadline.Query` rather than reusing Evidence's (which rejects explicit `nil` elsewhere in that module):
```elixir
defp validate_history_limit!(nil), do: :ok
defp validate_history_limit!(value) when is_integer(value) and value > 0, do: :ok

defp validate_history_limit!(value) do
  raise ArgumentError, ":limit must be a positive integer, got: #{inspect(value)}"
end
```

**Apply pattern** (evidence.ex:345-346, read this session):
```elixir
defp maybe_limit(query, nil), do: query
defp maybe_limit(query, limit), do: limit(query, ^limit)
```
`Threadline.Query` already imports `Ecto.Query` (query.ex:31), so `limit/2` resolves to `Ecto.Query.limit/2` the same way it does in evidence.ex — no new import needed.

**Insertion points in `history/3`/`history_query/3`** (query.ex:396-415, read this session):
```elixir
def history(schema_module, id, opts) do
  repo = Keyword.fetch!(opts, :repo)

  schema_module
  |> history_query(id, Keyword.put(opts, :repo, repo))
  |> repo.all(storage_opts([], opts))
end

@doc false
@spec history_query(module(), term(), keyword()) :: Ecto.Query.t()
def history_query(schema_module, id, opts) when is_list(opts) do
  repo = Keyword.fetch!(opts, :repo)
  matched = RowKey.match!(schema_module, id, repo)

  AuditChange
  |> where_row(matched)
  |> maybe_apply_scope(row_history_scope_opts(schema_module, id, opts))
  |> order_by([ac], desc: ac.captured_at)
  |> order_by([ac], desc: ac.id)
end
```
Per D-01 (validate before any DB access) call `validate_history_limit!(Keyword.get(opts, :limit))` as the first line of `history/3`, before `history_query/3` is invoked (which is what calls `RowKey.match!/3`, the first DB round-trip). Per D-02, append `|> maybe_limit(Keyword.get(opts, :limit))` as the final pipe step in `history_query/3`, after both `order_by` calls — this is already the natural end of the existing pipe, so no reordering of the existing predicate stack is needed.

**Docs pattern** — `lib/threadline.ex` `history/3` Options section and `lib/threadline/query.ex`'s own `history/3` doc (query.ex:363-395, read this session) both need a `:limit` bullet; mirror the existing `:repo` bullet style (`- `:repo` — required `Ecto.Repo` module`) and the wording D-03 pins verbatim.

**Error-ordering pitfall:** do NOT put the validation inside `history_query/3` after `RowKey.match!/3` (query.ex:408) — that hits the DB first. Call it in `history/3` itself, before delegating.

---

### `lib/mix/tasks/threadline.health.coverage.ex` — `--strict`, `--all-schemas`, invalid-switch raise (CLI / Mix task, request-response)

**Analog:** `lib/mix/tasks/threadline.verify_coverage.ex` (full file, read this session) — same task family, already implements the exact `exit({:shutdown, 1})` gate and `OptionParser.parse` → `Mix.raise` shape this phase adds to `health.coverage`.

**`--strict` exit gate pattern** (verify_coverage.ex:80-86, read this session):
```elixir
print_report(expected, coverage, counts)
print_findings(partition)

if violations != [] or partition.gated != [] do
  exit({:shutdown, 1})
end
```
Adapt for `health.coverage` per D-06/D-07: render (existing `render_table`/`render_json`) first, unchanged, then compute `in_scope_error_findings` (per D-05, only `trigger_findings` ++ `legacy_key_findings` results with `severity: :error` — never `trigger_coverage/1` tuples), then:
```elixir
if strict? and in_scope_error_findings != [] do
  Mix.shell().error("strict: FAILED — #{length(in_scope_error_findings)} error finding(s) (uncovered tables are not gated; use mix threadline.verify_coverage)")
  exit({:shutdown, 1})
else
  if strict?, do: Mix.shell().error("strict: passed (#{warning_count} warning(s) not gated)")
end
```
Note `Mix.shell().error/1` writes to stderr (confirmed by its use for `Mix.raise`-adjacent messaging elsewhere in the Mix ecosystem) so stdout under `--json` stays exactly one JSON document, per D-07.

**Current option-parsing to extend** (health.coverage.ex:49-52, read this session):
```elixir
def run(argv) do
  {opts, _, _} = OptionParser.parse(argv, strict: [json: :boolean, schema: :string])
  json? = Keyword.get(opts, :json, false)
  schema = Keyword.get(opts, :schema, "public")
```
Per D-16/Pitfall 5, destructure all three elements and raise on a non-empty `invalid` list; add `strict: :boolean, all_schemas: :boolean` to the `strict:` keyword spec. Per D-15, check `Keyword.has_key?(opts, :schema) and Keyword.has_key?(opts, :all_schemas)` and `Mix.raise` **before** `resolve_repo!/ensure_repo_started!` run (i.e., before the repo starts) — verify_coverage.ex's `resolve_expected_tables!/0` (lines 136-172, read this session) shows the established `Mix.raise` message-construction style to copy for the new `"--schema and --all-schemas cannot be used together"` message.

**`Mix.raise` for config/usage vs `exit({:shutdown,1})` for gate results** — both files show this split consistently: `resolve_repo!/0`, `ensure_repo_started!/1`, `validate_schema!/2`, and `load_capture_config!/0` (health.coverage.ex:83-125, verbatim shared logic with verify_coverage.ex:88-134) all use `Mix.raise`; only the final gate decision uses `exit({:shutdown, 1})`.

**JSON rendering to extend** (health.coverage.ex:196-225, read this session) — `render_json/3` builds a flat payload; for `--all-schemas` (D-13) wrap per-schema payloads (identical shape to today's single-schema payload) under a `"schemas"` key encoded via `Jason.OrderedObject` (sorted key order) plus a `"summary"` key, while leaving the non-`--all-schemas` path byte-identical.

**Table rendering to extend** (health.coverage.ex:127-162, 237-242, read this session) — `render_table/3`'s column-width-then-print idiom (`String.pad_trailing/2` with computed widths, `Enum.max(fn -> fallback end)`) is the pattern to reuse for the `--all-schemas` table's new leading `SCHEMA` column and per-schema rollup rows (D-14).

---

### `lib/threadline/health/legacy_key_findings.ex` (NEW) — `:unresolved_legacy_keys` finding (service, CRUD probe)

**Analog:** `lib/threadline/health/trigger_findings.ex` (full file, read this session) — sibling `Threadline.Health.*Findings` module; mirror its shape (`@moduledoc false`, `codes/0`, `run/1`, `Finding` struct construction, final sort) but note the differences called out below.

**`codes/0` pattern to match exactly** (trigger_findings.ex:8-18, read this session):
```elixir
@doc false
@spec codes() :: [Finding.code()]
def codes do
  [
    :legacy_trigger_no_pk_args,
    :pk_drift,
    :shared_capture_function,
    :duplicate_capture_trigger,
    :capture_trigger_disabled
  ]
end
```
`LegacyKeyFindings.codes/0` must follow this verbatim shape, returning `[:unresolved_legacy_keys]`, per D-24. `test/threadline/health_findings_doc_contract_test.exs` must then iterate `TriggerFindings.codes() ++ LegacyKeyFindings.codes()`.

**`run/1` skeleton to adapt** (trigger_findings.ex:20-48, read this session):
```elixir
@doc false
@spec run(keyword()) :: [Finding.t()]
def run(opts) do
  repo = Keyword.fetch!(opts, :repo)
  requested_schemas = normalize_schema(opts)
  config = TriggerCaptureConfig.load()

  triggers =
    repo
    |> TriggerCatalog.threadline_triggers()
    |> reject_storage_own_tables()
  ...
  findings
  |> filter_by_schema(requested_schemas)
  |> Enum.sort_by(&{&1.schema, &1.table, Atom.to_string(&1.code), &1.message})
```
`legacy_key_findings/1` should reuse the same `:schema` option handling (`normalize_schema/1`, `filter_by_schema/2` at lines 50-68, 83-86) and the same `reject_storage_own_tables/1` helper (lines 75-81) — or, since these are `defp` in `TriggerFindings`, extract a small shared private helper module, or duplicate the (small, stable) functions as `legacy_key_findings.ex`'s own private clauses; D-18 does not mandate code sharing, only identical-shaped filtering semantics. **Per D-18, this module must NOT emit the `findings_checked` telemetry event** — skip the `emit_telemetry/1` call `TriggerFindings.run/1` makes (trigger_findings.ex:45, 88-92); `findings_checked` keeps counting only `trigger_findings/1`.

**`Finding` construction pattern** (trigger_findings.ex:301-314, `legacy_warning/3`, read this session):
```elixir
defp legacy_warning(%{schema: schema, table: table} = trigger, recorded, expected) do
  %Finding{
    code: :legacy_trigger_no_pk_args,
    severity: :warning,
    schema: schema,
    table: table,
    message: legacy_warning_message(trigger),
    details: %{
      trigger: trigger.trigger,
      recorded_key: sorted_key(recorded),
      expected_key: sorted_key(expected)
    }
  }
end
```
Mirror this exact struct-literal shape for the new finding, with `details: %{"unresolved_count" => n, "capped" => boolean, "key_columns" => [...]}` per D-23 (note: this finding's `details` uses **string** keys — not atom keys like `TriggerFindings`'s — per D-23's literal spec; confirm this divergence is intentional and documented).

**Driving the probe from `TriggerCatalog.threadline_triggers/1`** (trigger_catalog.ex:20-37, read this session) — already decodes `tgargs` into `args` (key columns) via `decode_tgargs/1` (lines 210-224). Per D-19, filter to triggers whose `trigger.nargs > 0` (i.e., `trigger.args != []`, meaning the trigger records key args) — this is the same `nargs == 0` branch `TriggerFindings.key_finding/4` already checks (trigger_findings.ex:224-234) for the "legacy no-args" case, confirming legacy no-args tables are excluded from the new probe and instead already covered by `:legacy_trigger_no_pk_args`.

**Capped-count SQL precedent** (export.ex:218-229, read this session):
```elixir
count =
  if is_integer(cap) and cap > 0 do
    capped = base_query |> limit(^cap)

    from(sub in subquery(capped), select: count())
    |> repo.one(Query.storage_opts(filters, opts))
  else
    repo.aggregate(base_query, :count, :id, Query.storage_opts(filters, opts))
```
D-19's probe is raw SQL (not Ecto query-builder) since it targets `audit_changes` directly with a `jsonb ?&` operator and `NOT EXISTS`/`unnest` — use `Ecto.Adapters.SQL.query!/3` the same way `Threadline.Health` and `TriggerCatalog` already do (health.ex:134-150, trigger_catalog.ex:34), with the storage-schema-qualified table name from `StorageSchema.table("audit_changes", opts)` (storage_schema.ex:121, `@threadline_tables` list at lines 25-33) — never an unprefixed reference, per D-22 and the module's own past-defect-class warning.

**Statement timeout pattern** (D-20) — no direct precedent file was found for `SET LOCAL statement_timeout` + `repo.transaction`; this is new within the probe. Follow the general Ecto idiom:
```elixir
repo.transaction(fn ->
  Ecto.Adapters.SQL.query!(repo, "SET LOCAL statement_timeout = $1", [timeout_ms])
  # ... per-table probe queries inside the same transaction
end)
```
Catch the Postgrex `query_canceled` error (`%Postgrex.Error{postgres: %{code: :query_canceled}}`) around each table's probe, per table, and print the one-line hint without failing the whole run (D-20's "carries on").

---

### `lib/threadline/health/finding.ex` — extend `code()` union (model, transform)

**Analog:** same file (full file, read this session).

**Current union to extend** (finding.ex:47-52):
```elixir
@type code ::
        :legacy_trigger_no_pk_args
        | :pk_drift
        | :shared_capture_function
        | :duplicate_capture_trigger
        | :capture_trigger_disabled
```
Add `| :unresolved_legacy_keys`. Also extend the moduledoc's `## Codes` bullet list (finding.ex:9-26) with the new code's description, severity (`:warning`), and the opening-line sentence naming both `trigger_findings/1` and `legacy_key_findings/1`, plus the "may grow in any minor release; match with a catch-all clause" sentence, per D-24.

---

### `lib/threadline/health/coverage_schemas.ex` — `pg_depend` extension exclusion + all-schemas enumeration (service, CRUD)

**Analog:** same file (full file, read this session).

**Current enumeration to extend** (coverage_schemas.ex:39-51):
```elixir
@spec available(module()) :: [String.t()]
def available(repo) do
  sql = """
  SELECT DISTINCT schemaname
  FROM pg_tables
  WHERE schemaname <> 'information_schema'
    AND schemaname NOT LIKE 'pg\\_%' ESCAPE '\\'
  ORDER BY schemaname
  """

  %{rows: rows} = SQL.query!(repo, sql, [])
  List.flatten(rows)
end
```
Per D-12, add a `NOT EXISTS` against `pg_depend` filtered to `classid = 'pg_namespace'::regclass AND deptype = 'e'`, joined on the schema's `pg_namespace.oid` — e.g. appending to the `WHERE`:
```sql
AND NOT EXISTS (
  SELECT 1 FROM pg_depend d
  JOIN pg_namespace ns ON ns.nspname = schemaname
  WHERE d.classid = 'pg_namespace'::regclass
    AND d.objid = ns.oid
    AND d.deptype = 'e'
)
```
**Never** filter on `pg_extension.extnamespace` (would incorrectly drop `public`, per D-12/Anti-Patterns). Per D-11's "task-only" boundary, keep this a `@doc false` / private helper used by the Mix task, not a new `Health` public function — `trigger_coverage(schema: :all)` is explicitly deferred.

**Existing validation pattern to reuse unchanged** (coverage_schemas.ex:8-34) — `validate/2`'s regex + `pg_namespace` existence check is the exact pattern `--all-schemas`'s per-schema enumeration must continue to rely on (reused, not reinvented, per the Security Domain section of RESEARCH.md).

---

## Shared Patterns

### `Mix.raise` for usage/config errors; `exit({:shutdown, 1})` for gate results
**Source:** `lib/mix/tasks/threadline.verify_coverage.ex` (full file) and `lib/mix/tasks/threadline.health.coverage.ex` (full file)
**Apply to:** `lib/mix/tasks/threadline.health.coverage.ex`'s `--strict`, `--all-schemas` mutual-exclusion, and invalid-switch additions.
```elixir
# Mix.raise — usage/config (verify_coverage.ex:99-109, health.coverage.ex:90-100)
defp resolve_repo! do
  case Application.get_env(:threadline, :ecto_repos, []) do
    [] -> Mix.raise("Threadline: set :ecto_repos in config — ...")
    [repo | _] -> repo
  end
end

# exit({:shutdown, 1}) — gate result, after full output (verify_coverage.ex:83-85)
if violations != [] or partition.gated != [] do
  exit({:shutdown, 1})
end
```

### Catalog query via `Ecto.Adapters.SQL.query!/3`, returned as `List.flatten(rows)` or `Map.new(rows, ...)`
**Source:** `lib/threadline/health.ex:133-152`, `lib/threadline/health/coverage_schemas.ex:39-51`, `lib/threadline/health/trigger_catalog.ex` (whole file)
**Apply to:** `LegacyKeyFindings`'s probe queries and `CoverageSchemas`'s extended enumeration.
```elixir
sql = "SELECT tablename FROM pg_tables WHERE schemaname = $1"
%{rows: rows} = SQL.query!(repo, sql, [schema])
List.flatten(rows)
```
Always bind parameters (`$1`, `$2`, ...) — never interpolate schema/table names raw. `TriggerCatalog.qualifying_override_index?/3` (trigger_catalog.ex:118-143) shows the pattern for passing an array bind (`$2::text[]`), which `legacy_key_findings.ex`'s `$3::text[]` key-columns bind should follow identically.

### `Finding` struct construction
**Source:** `lib/threadline/health/trigger_findings.ex` (all `defp ..._finding`/`..._warning` functions), `lib/threadline/health/finding.ex`
**Apply to:** `lib/threadline/health/legacy_key_findings.ex`
```elixir
%Finding{
  code: :some_code,
  severity: :error | :warning,
  schema: schema,
  table: table,
  message: "<human readable text with the exact fix command>",
  details: %{...}
}
```
All six keys are `@enforce_keys`; omitting one raises at construction time, which is a useful fast-fail if a clause is incomplete.

### Storage-schema qualification — never an unprefixed or `search_path` lookup
**Source:** `lib/threadline/storage_schema.ex:121` (`table/2`), `lib/threadline/health/trigger_findings.ex:75-81` (`reject_storage_own_tables/1`)
**Apply to:** `lib/threadline/health/legacy_key_findings.ex`'s `audit_changes` probe query.
```elixir
storage_schema = StorageSchema.get()
table = StorageSchema.table("audit_changes", opts)  # qualified name for the SQL string
Enum.reject(rows, fn row -> row.schema == storage_schema and StorageSchema.threadline_table?(row.table) end)
```
This is a past-defect class (see MEMORY: "Stale public capture function masks CI failures" / "local-test-db-storage-schema-failures") — every new `audit_changes` reference in this phase must go through `StorageSchema.table/2`, never a bare `audit_changes` string.

### Mix-task test harness: `with_io` + `catch_exit`, `async: false`, `Mix.Task.reenable`
**Source:** `test/threadline/verify_coverage_task_test.exs:263,281` (exit-capture), `test/threadline/operator_surface/coverage_mix_test.exs:13,24-30` (reenable + async:false)
**Apply to:** `test/threadline/operator_surface/coverage_mix_test.exs`'s new `--strict` matrix (D-09).
```elixir
use ExUnit.Case, async: false
import ExUnit.CaptureIO

setup do
  Mix.Task.reenable("threadline.health.coverage")
  :ok
end

test "..." do
  {output, exit_reason} =
    with_io(fn -> catch_exit(Coverage.run(["--strict"])) end)
  ...
end
```

## No Analog Found

None — every file this phase touches has a strong (exact-match) analog already identified above; `lib/threadline/health/legacy_key_findings.ex` is a new file but its role (sibling `Health.*Findings` module) is exactly matched by `trigger_findings.ex`.

## Metadata

**Analog search scope:** `lib/threadline/`, `lib/mix/tasks/`, `test/threadline/` (query, health, operator_surface, verify_coverage subtrees)
**Files scanned:** `lib/threadline/query.ex`, `lib/threadline.ex`, `lib/threadline/evidence.ex`, `lib/threadline/export.ex`, `lib/threadline/storage_schema.ex`, `lib/mix/tasks/threadline.health.coverage.ex`, `lib/mix/tasks/threadline.verify_coverage.ex`, `lib/threadline/health.ex`, `lib/threadline/health/finding.ex`, `lib/threadline/health/trigger_findings.ex`, `lib/threadline/health/trigger_catalog.ex`, `lib/threadline/health/coverage_schemas.ex`, `test/threadline/operator_surface/coverage_mix_test.exs`, `test/threadline/verify_coverage_task_test.exs` (all read this session; all confirmed git-tracked source, not gitignored mirrors)
**Pattern extraction date:** 2026-10-02
