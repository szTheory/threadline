# Phase 212: Detection and Adopter Twins - Pattern Map

**Mapped:** 2026-09-26
**Files analyzed:** 14 (new/modified)
**Analogs found:** 14 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|----------------|
| `lib/threadline/health/finding.ex` (new) | model (public read struct) | request-response | `lib/threadline/health/coverage_schemas.ex` (module-in-namespace precedent); struct shape per CONTEXT D-01 | role-match |
| `lib/threadline/health/findings.ex` (new, or grows `health.ex`) | service (catalog query) | CRUD (read-only catalog query) | `lib/threadline/health.ex` (`trigger_coverage/1`) | exact |
| `lib/threadline/health.ex` (modified: D-05 `tgenabled` filter) | service | CRUD | itself, surgical diff | exact |
| `lib/threadline/telemetry.ex` (modified: `emit_findings_checked/2`) | utility (telemetry emitter) | event-driven | itself, `emit_health_checked/3` | exact |
| `lib/threadline/verify/coverage_policy.ex` (modified: severity-aware gate fn) | service (pure policy) | transform | itself, `violations/2` | exact |
| `lib/mix/tasks/threadline.verify_coverage.ex` (modified) | route (Mix task / CI gate) | request-response | itself | exact |
| `lib/mix/tasks/threadline.health.coverage.ex` (modified) | route (Mix task / viewer) | request-response | itself | exact |
| `test/threadline/health_test.exs` (extended, or new `test/threadline/health/findings_test.exs`) | test | CRUD (real-PG fixtures) | `test/threadline/health_test.exs`, `test/support/legacy_trigger_sql.ex` | exact |
| new non-owner-role test helper/module | test | event-driven (role DDL) | `test/threadline/pgbouncer_topology_test.exs` (closest role/DDL-adjacent test) | role-match (no `CREATE ROLE` precedent exists) |
| `test/threadline/pgbouncer_topology_test.exs` (extended: findings-through-pooler test) | test | request-response | itself | exact |
| `priv/ci/topology_bootstrap.exs` (possibly extended for seeded findings) | config/fixture (direct-connection DDL) | batch | itself | exact |
| `examples/threadline_phoenix/priv/repo/migrations/<new>_threadline_triggers_shape_*.exs` (generated) | migration | batch | `examples/threadline_phoenix/priv/repo/migrations/20260527154557_...exs` (generator-produced) | exact |
| `priv/ci/hex_evaluator/priv/repo/migrations/<new>_threadline_triggers_shape_*.exs` (generated, first generator-produced migration in this twin) | migration | batch | `examples/threadline_phoenix/...` generated migration (cross-twin analog; hex_evaluator's own migrations are hand-written, pre-generator) | role-match |
| new regenerate-diff contract test (both twins) | test | file-I/O (diff generated vs committed) | `test/support/migration_harness.ex` (`generate!/2`) — no existing regenerate-diff test to copy structure from | role-match (build from scratch per RESEARCH pitfall 5) |
| new round-trip tests (both twins, per shape) | test | CRUD | existing twin test suites (`examples/threadline_phoenix/test/`, `priv/ci/hex_evaluator/test/`) exercising `Threadline.history/3` | role-match |
| `examples/threadline_phoenix/config/config.exs` / `priv/ci/hex_evaluator/config/config.exs` (extended: shape fixture `:trigger_capture` overrides) | config | CRUD | themselves | exact |

## Pattern Assignments

### `lib/threadline/health/finding.ex` (model, new)

**Analog:** `lib/threadline/health/coverage_schemas.ex` (namespacing precedent: `Threadline.Health.<Submodule>`, `@moduledoc false` for internal-but-public modules)

**Struct shape** (from CONTEXT.md D-01 / RESEARCH.md, directly authoritative — no existing struct to copy verbatim, but follow this shape exactly):
```elixir
defmodule Threadline.Health.Finding do
  @enforce_keys [:code, :severity, :schema, :table, :message, :details]
  defstruct [:code, :severity, :schema, :table, :message, :details]

  @type severity :: :error | :warning
  @type t :: %__MODULE__{
          code: atom(),
          severity: severity(),
          schema: String.t(),
          table: String.t(),
          message: String.t(),
          details: map()
        }
end
```

---

### `lib/threadline/health/findings.ex` (service, new — or grow `lib/threadline/health.ex`)

**Analog:** `lib/threadline/health.ex` lines 1–120 (full file, small enough for one read)

**Imports pattern** (line 23):
```elixir
alias Ecto.Adapters.SQL
```

**Public API + moduledoc pattern** (lines 1–55, `trigger_coverage/1`):
```elixir
def trigger_coverage(opts) do
  repo = Keyword.fetch!(opts, :repo)
  schema = Keyword.get(opts, :schema, "public")
  ...
end
```
`trigger_findings/1` differs per D-02: it must NOT default `:schema` to `"public"` — when `:schema` is omitted it scans all non-system schemas (see `CoverageSchemas.available/1` below) and only filters the *returned* findings by `:schema` afterward.

**Catalog query pattern** (lines 91–109, `fetch_all_user_tables/2`, `fetch_threadline_covered_tables/2`):
```elixir
defp fetch_threadline_covered_tables(repo, schema) do
  sql = """
  SELECT DISTINCT c.relname
  FROM pg_trigger t
  JOIN pg_class c ON t.tgrelid = c.oid
  JOIN pg_namespace n ON c.relnamespace = n.oid
  WHERE t.tgname LIKE 'threadline_audit_%'
    AND n.nspname = $1
  """

  %{rows: rows} = SQL.query!(repo, sql, [schema])
  List.flatten(rows)
end
```
Copy this exact `SQL.query!/3` + parameterized-`$1` pattern for every new catalog read. D-15 forbids `SET`, temp tables, advisory locks, or named prepared statements — this pattern already satisfies that (no such constructs present).

**D-05 change to `trigger_coverage/1` itself** — add a `tgenabled NOT IN ('D','R')` predicate to the WHERE clause at line 103–104 (surgical, isolated per RESEARCH pitfall 2); do not rewrite the whole function.

**Telemetry emission call site** (lines 82–86):
```elixir
Threadline.Telemetry.emit_health_checked(
  covered_count,
  uncovered_count,
  expected_uncovered_count
)
```
Mirror this exact call shape for `Threadline.Telemetry.emit_findings_checked(errors_count, warnings_count)`.

**Reusable SQL fragments to call directly (not re-derive), per RESEARCH pitfall 1:**
- `Threadline.Capture.PrimaryKeySQL.qualifying_index_predicate/0` (`lib/threadline/capture/primary_key_sql.ex:436-438`, already `@doc false` public) — call directly for D-10's override-qualification check.
- `Threadline.Capture.PrimaryKeySQL`'s private `override_index_key_set_sql/0` (lines 305-312) — **promote to `@doc false` public** (same treatment as `qualifying_index_predicate/0`) rather than copy-pasting the SQL text, per RESEARCH's explicit recommendation. This is a small, surgical edit to `primary_key_sql.ex`.
- `Threadline.Capture.TriggerSQL.function_owner_guard/2` (`lib/threadline/capture/trigger_sql.ex:168-195`) — adapt its query shape (below) for D-11, dropping the "exclude this table's own oid" clause and adding `GROUP BY ... HAVING count(DISTINCT t.tgrelid) > 1`:
```sql
-- lib/threadline/capture/trigger_sql.ex:182-188
SELECT string_agg(format('%I.%I', n.nspname, c.relname), ', ' ORDER BY n.nspname, c.relname), ...
  FROM pg_trigger t JOIN pg_class c ON c.oid = t.tgrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
 WHERE t.tgfoid = fn AND t.tgparentid = 0 AND t.tgrelid <> owner
```
Note the `tgparentid = 0` filter (excludes triggers PostgreSQL auto-clones onto partitions) — carry this into every new D-11/D-12 query.

**Schema discovery pattern for D-02's all-schema default** (`lib/threadline/health/coverage_schemas.ex:39-51`):
```elixir
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
Additionally exclude the storage schema's own audit tables via `Threadline.StorageSchema.threadline_table?/1` (table-name based, not schema-based — the storage schema is an ordinary schema that may also hold host tables).

**D-03 trigger identification — the underscore-escaping fix RESEARCH flags:**
Existing `trigger_coverage/1` uses an unescaped `LIKE 'threadline_audit_%'` (health.ex:103) — D-03 requires `LIKE 'threadline\_audit\_%' ESCAPE '\'`, pinned by a test against `Naming`'s prefixes. Do not copy the unescaped form into new findings code.

**D-08 tgargs decoding (no SQL analog — decode in Elixir):**
```elixir
tgargs
|> :binary.split(<<0>>, [:global])
|> Enum.reject(&(&1 == ""))
```

---

### `lib/threadline/telemetry.ex` (modified)

**Analog:** itself, `emit_health_checked/3` (lines 67-81) and its moduledoc entry (lines 16-21)

**Pattern to copy exactly:**
```elixir
@doc """
Emits the `[:threadline, :health, :checked]` event with covered / uncovered /
expected_uncovered measurements.
...
"""
def emit_health_checked(covered, uncovered, expected_uncovered) do
  :telemetry.execute(
    [:threadline, :health, :checked],
    %{covered: covered, uncovered: uncovered, expected_uncovered: expected_uncovered},
    %{}
  )
end
```
Add a new sibling `emit_findings_checked/2` for `[:threadline, :health, :findings_checked]` with `%{errors: n, warnings: n}`, plus a fifth bullet in the moduledoc's event list (lines 5-26), following the exact prose style of the existing four bullets.

---

### `lib/threadline/verify/coverage_policy.ex` (modified)

**Analog:** itself, `violations/2` (lines 23-38) and `summary_counts/2` (lines 46-51)

**Pattern to copy** (pure function over tagged tuples, `Map.new`/`Enum.flat_map`/sort):
```elixir
def violations(coverage, expected_tables)
    when is_list(coverage) and is_list(expected_tables) do
  by_table = Map.new(coverage, fn {status, name} -> {name, status} end)

  expected_tables
  |> Enum.uniq()
  |> Enum.flat_map(fn table ->
    case Map.fetch(by_table, table) do
      :error -> [{:missing, table}]
      {:ok, :uncovered} -> [{:uncovered, table}]
      {:ok, :covered} -> []
      {:ok, :expected_uncovered} -> []
    end
  end)
  |> Enum.sort_by(fn {kind, name} -> {violation_rank(kind), name} end)
end
```
Add a new function (e.g. `gate_violations/2`) with the same shape, intersecting `[%Finding{}]` against `expected_tables` by severity per D-17: `:error` findings on listed tables fail the gate; `:error` findings on unlisted tables go under a separate "not gated" bucket; `:warning` findings never fail. Keep this additive — do not touch `violations/2`'s existing three-bucket contract (RESEARCH pitfall 2).

---

### `lib/mix/tasks/threadline.verify_coverage.ex` (modified)

**Analog:** itself, `run/1` (lines 40-63)

**Pattern to copy (task skeleton, repo resolution, schema validation, gate + exit):**
```elixir
def run(argv) do
  {opts, _, _} = OptionParser.parse(argv, strict: [schema: :string])
  schema = Keyword.get(opts, :schema, "public")

  Mix.Task.run("app.config", [])
  {:ok, _} = Application.ensure_all_started(:ssl)
  {:ok, _} = Application.ensure_all_started(:postgrex)
  {:ok, _} = Application.ensure_all_started(:ecto_sql)

  repo = resolve_repo!()
  ensure_repo_started!(repo)
  validate_schema!(repo, schema)
  expected = resolve_expected_tables!()

  coverage = Threadline.Health.trigger_coverage(repo: repo, schema: schema)
  violations = CoveragePolicy.violations(coverage, expected)
  counts = CoveragePolicy.summary_counts(coverage, expected)

  print_report(expected, coverage, counts)

  if violations != [] do
    exit({:shutdown, 1})
  end
end
```
Add a call to `Threadline.Health.trigger_findings(repo: repo, schema: schema)` alongside the existing `trigger_coverage/1` call, OR into `TriggerCaptureConfig.load/0`. Per D-07 / RESEARCH D-07 section, wrap the config-dependent call the same way `mix threadline.gen.triggers` wraps `load_capture_tables!/0` — `rescue ... -> Mix.raise(...)`. Print error findings on unlisted tables under a "not gated" heading (new `print_report`-style helper, same `String.pad_trailing` column style as `print_report/3` lines 148-182). OR the existing `violations != []` check with a new findings-gate check so either failure triggers `exit({:shutdown, 1})`.

**Report/table-printing style to copy** (lines 148-182, `print_report/3`):
```elixir
table_w = max(5, rows |> Enum.map(&byte_size(elem(&1, 0))) |> Enum.max(fn -> 5 end))
table_w = max(table_w, byte_size("TABLE"))

header = String.pad_trailing("TABLE", table_w) <> "  STATUS"
rule = String.duplicate("-", String.length(header))

Mix.shell().info(header)
Mix.shell().info(rule)
```

---

### `lib/mix/tasks/threadline.health.coverage.ex` (modified)

**Analog:** itself, `render_table/2` (lines 102-128) and `render_json/2` (lines 130-147)

**Text section pattern to copy and append a new FINDINGS block after** (column-padding style, lines 106-114):
```elixir
table_w = max(24, rows |> Enum.map(&byte_size(elem(&1, 0))) |> Enum.max(fn -> 5 end))
status_w = 12

header =
  String.pad_trailing("TABLE", table_w) <>
    "  " <> String.pad_trailing("STATUS", status_w) <> "  SOURCE"
```
Build a parallel SEVERITY/CODE/TABLE/MESSAGE header+rows block per D-18, reusing the same `pad_trailing`/rule/`Mix.shell().info` sequence.

**JSON additive-key pattern to copy** (lines 130-147 + moduledoc lines 21-24 — `expected_uncovered` is the existing additive-key precedent CONTEXT.md cites):
```elixir
defp render_json(schema, coverage) do
  covered = for {:covered, t} <- coverage, do: t
  ...
  payload = %{
    "schema" => schema,
    "covered" => Enum.sort(covered),
    "uncovered" => Enum.sort(uncovered),
    "expected_uncovered" => Enum.sort_by(expected_uncovered, & &1["table"])
  }

  IO.puts(Jason.encode!(payload))
end
```
Add a `"findings"` key (list of `%{code, severity, schema, table, message, details}` with string `code`/`severity`) to `payload` without touching existing keys.

---

### `test/threadline/health_test.exs` (extended) / non-owner-role test

**Analog for non-owner role DDL and cleanup:** `test/threadline/pgbouncer_topology_test.exs` is the closest existing pattern for a test interacting with pooling/role state, though CONTEXT.md/RESEARCH confirm **no `CREATE ROLE` precedent exists anywhere in `test/`** — this must be built new. Follow the project's general scratch-object convention: create in `setup`, drop in `on_exit`, wrap in a transaction:
```elixir
setup do
  Repo.query!("CREATE ROLE threadline_probe_role NOLOGIN")
  on_exit(fn -> Repo.query!("DROP ROLE IF EXISTS threadline_probe_role") end)
  :ok
end
```
Run the check itself inside `Repo.transaction(fn -> Repo.query!("SET LOCAL ROLE threadline_probe_role") ... end)` so the role switch never escapes the test's own connection/transaction.

**Analog for real-PG legacy trigger fixtures (HLTH-02 / `:pk_drift` legacy case):** `test/support/legacy_trigger_sql.ex` — use `Threadline.Test.LegacyTriggerSQL.v0_9_create_trigger/2` or `v0_10_2_create_trigger/3` verbatim to seed a genuine no-arg legacy trigger; do not hand-write equivalent SQL:
```elixir
# test/support/legacy_trigger_sql.ex:30-37
def v0_9_create_trigger(table, function_ref \\ "threadline_capture_changes()") do
  """
  CREATE TRIGGER threadline_audit_#{table}
  AFTER INSERT OR UPDATE OR DELETE ON #{table}
  FOR EACH ROW EXECUTE FUNCTION #{function_ref}
  """
end
```

---

### `test/threadline/pgbouncer_topology_test.exs` (extended)

**Analog:** itself, full file (45 lines, read in one pass)

**Pattern to copy** (moduletag, setup, transaction-wrapped assertion):
```elixir
@moduletag :pgbouncer_topology

test "GUC + audited insert through PgBouncer transaction pool (STG-01 CI)" do
  ...
  Repo.transaction(fn ->
    Repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])
    Repo.query!("INSERT INTO #{@table} (name, value) VALUES ('through-pgbouncer', 1)")
  end)

  assert [%AuditTransaction{} = txn] = ...
end
```
Add a new `test "..."` in this module (or a sibling tagged `:pgbouncer_topology`) calling `Threadline.Health.trigger_findings(repo: Repo)` through the same pooled `Threadline.Test.Repo` connection — no new bootstrap needed for the healthy-path case since `threadline_pooler_topology_ctx` already has a real trigger. If a specific finding needs seeding (e.g. disabled trigger), add the DDL to `priv/ci/topology_bootstrap.exs` (direct connection — PgBouncer transaction mode cannot run `ALTER TABLE ... DISABLE TRIGGER`).

---

### Adopter twin migrations (`examples/threadline_phoenix/`, `priv/ci/hex_evaluator/`)

**Analog:** `examples/threadline_phoenix/priv/repo/migrations/20260527154557_threadline_triggers_organizations_org_memberships_agents_tickets_ticket_replies.exs` — confirmed generator-produced (module name matches `Naming.module_for/1`'s camelization, body matches `TriggerSQL` rendering).

**Do NOT copy the style of** `priv/ci/hex_evaluator/priv/repo/migrations/20260424080642_threadline_triggers_posts.exs` for the *new* shape fixtures — this file is hand-written, pre-generator:
```elixir
defmodule ThreadlineTriggersPosts do
  use Ecto.Migration

  def up do
    execute "CREATE TRIGGER threadline_audit_posts\nAFTER INSERT OR UPDATE OR DELETE ON posts\nFOR EACH ROW EXECUTE FUNCTION threadline.threadline_capture_changes()\n"
  end
  ...
end
```
D-20 requires the new `shape_*` fixture migrations in **both** twins to be produced by actually running `mix threadline.gen.triggers --tables shape_a,shape_b,...` in each twin directory and committing the output — the example app's generator-produced migration is the shape to match; `posts`'s hand-written migration must stay untouched (it is a separate legacy fixture already load-bearing for `AdoptFromHexTest`/`LegacyPublicSchemaTest`).

**Regenerate-diff contract test — no existing analog, build from scratch.** Use `Threadline.Test.MigrationHarness.generate!/2` as the generation primitive:
```elixir
# test/support/migration_harness.ex:24-33
def generate!(tmp, args) do
  before = migration_files(tmp)
  File.cd!(tmp, fn -> Triggers.run(args) end)

  case migration_files(tmp) -- before do
    [file] -> file
    other -> raise "expected one new migration file, got: #{inspect(other)}"
  end
end
```
Per RESEARCH pitfall 5, compare only migration **body content** (not file/module name, which is ordinal-dependent on directory state) — normalize/strip the leading 14-digit timestamp and any `_N` ordinal suffix before diffing.

---

### Config files (`examples/threadline_phoenix/config/config.exs`, `priv/ci/hex_evaluator/config/config.exs`)

**Analog:** each file, itself.

**Example app** already sets a dedicated storage schema (line 14-16):
```elixir
config :threadline,
  ecto_repos: [ThreadlinePhoenix.Repo],
  storage_schema: "threadline"
```
Add the join-table override fixture here as a new `:trigger_capture` key, e.g. `config :threadline, :trigger_capture, [{"shape_join_table", primary_key: [...]}]` — follow `Threadline.Capture.TriggerCaptureConfig.load/0`'s expected shape (`lib/threadline/capture/trigger_capture_config.ex:100-139`).

**Hex evaluator** (`priv/ci/hex_evaluator/config/config.exs`, 13 lines, full file) currently has **no** `:storage_schema` key — this is load-bearing per `legacy_public_schema_test.exs` (RESEARCH pitfall 3). Any new fixture config must add only `:trigger_capture` (for the join-table `primary_key:` override) or extend `:ecto_repos`; never add `:storage_schema` here.

## Shared Patterns

### Parameterized catalog SQL (SC1 / D-15)
**Source:** `lib/threadline/health.ex:91-109`, `lib/threadline/health/coverage_schemas.ex:24-30,41-49`
**Apply to:** every new catalog query in `trigger_findings/1`'s implementation.
```elixir
sql = "SELECT tablename FROM pg_tables WHERE schemaname = $1"
%{rows: rows} = SQL.query!(repo, sql, [schema])
List.flatten(rows)
```
Never string-interpolate schema/table names into findings SQL; use `$1`/`$2` binds throughout, matching the existing `Health` module's convention exactly.

### Mix task skeleton (repo resolution, app boot, schema validation)
**Source:** `lib/mix/tasks/threadline.verify_coverage.ex:40-100`, `lib/mix/tasks/threadline.health.coverage.ex:37-100` (near-identical between the two tasks)
**Apply to:** no new Mix tasks this phase, but any refactor of the two existing tasks must keep `resolve_repo!/0`, `ensure_repo_started!/1`, `validate_schema!/2` in their current form — both files share this block byte-for-byte today.

### `Mix.raise` on setup/config errors, `exit({:shutdown, 1})` on gate failures
**Source:** `lib/mix/tasks/threadline.verify_coverage.ex:60-62,68-75`; `lib/mix/tasks/threadline.gen.triggers.ex:331-336` (rescue pattern for `TriggerCaptureConfig.load/0` errors)
**Apply to:** `verify_coverage`'s new findings-gate call and `health.coverage`'s new findings render call.

### Additive JSON keys
**Source:** `lib/mix/tasks/threadline.health.coverage.ex:130-147`, moduledoc lines 21-24 (`expected_uncovered` precedent)
**Apply to:** the new `"findings"` key in `health.coverage --json` output (D-18).

### Telemetry event emission
**Source:** `lib/threadline/telemetry.ex:67-95` (`emit_health_checked/3`, `emit_health_checked_error/1`)
**Apply to:** new `emit_findings_checked/2` for `[:threadline, :health, :findings_checked]`.

### Frozen historical SQL fixtures, never re-derived
**Source:** `test/support/legacy_trigger_sql.ex` (whole file philosophy: "reproduces one historical template byte for byte and never calls the current SQL or naming code")
**Apply to:** any HLTH-02/HLTH-03 test needing a genuine legacy no-arg trigger — always call `LegacyTriggerSQL`, never hand-write equivalent SQL.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| Non-owner-role (`CREATE ROLE ... NOLOGIN`) test helper | test | event-driven (role DDL) | No `CREATE ROLE` precedent exists anywhere in `test/` (confirmed by RESEARCH.md search); build per D-16 using the general scratch-object create/transaction/`on_exit`-drop convention, no closer analog than `pgbouncer_topology_test.exs`'s connection-handling style |
| Regenerate-diff contract test (D-20, both twins) | test | file-I/O | No "regenerate to temp dir and diff against committed file" pattern exists anywhere in the repo (confirmed by RESEARCH.md `find`/`grep`); build from `Threadline.Test.MigrationHarness.generate!/2` as the sole existing primitive |
| `:invalid_config` finding code | — | — | Explicitly deferred (CONTEXT.md `<deferred>`); malformed config raises instead (D-07) |
| hex_evaluator generator-produced migration (first time this twin uses the generator instead of hand-written SQL) | migration | batch | Only a cross-twin analog exists (`examples/threadline_phoenix`'s generated migration); no in-twin precedent since all of hex_evaluator's existing migrations predate `mix threadline.gen.triggers` |

## Metadata

**Analog search scope:** `lib/threadline/`, `lib/mix/tasks/`, `test/threadline/`, `test/support/`, `examples/threadline_phoenix/`, `priv/ci/hex_evaluator/` (source tree only; hex_evaluator's `deps/`/`_build/` mirrors excluded as gitignored, non-tracked)
**Files scanned:** 17 read directly this session (all confirmed git-tracked via `git ls-files`)
**Pattern extraction date:** 2026-09-26
