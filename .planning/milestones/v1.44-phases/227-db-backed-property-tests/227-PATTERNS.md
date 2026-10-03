# Phase 227: DB-Backed Property Tests - Pattern Map

**Mapped:** 2026-10-01
**Files analyzed:** 14 (new) + 3 (modified example tests) + 1 (contract extension) + 1 (tooling fix) + mutation patches
**Analogs found:** 14 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `test/support/db_property.ex` | test-utility (harness) | event-driven (per-iteration DB side effects) | `test/support/data_case.ex` + `test/threadline/capture/trigger_rerun_property_test.exs` (its inline setup/cleanup block) | role-match |
| `test/support/leak_oracle.ex` | test-utility (oracle) | transform (bytes-in, assertions-out) | `test/threadline/capture/trigger_redaction_test.exs` (its structural assertions) + `lib/threadline/change_diff.ex`/`lib/threadline/export.ex` (surfaces it must call) | role-match |
| `test/support/redaction_leak_generators.ex` | test-utility (generator) | transform | `test/support/redaction_policy_generators.ex` | exact |
| `test/support/row_history_generators.ex` | test-utility (generator) | transform | `test/support/change_fact_generators.ex` (pure fold-style generator) + `test/support/cursor_generators.ex` | role-match |
| `test/support/retention_cutoff_generators.ex` | test-utility (generator) | transform | `test/support/change_fact_generators.ex` | role-match |
| `test/threadline/capture/redaction_leak_property_test.exs` | test (property, DB-backed) | CRUD + event-driven | `test/threadline/capture/trigger_rerun_property_test.exs` (DB property shape) + `test/threadline/capture/trigger_redaction_test.exs` (domain: redaction assertions) | role-match (shape) / exact (domain) |
| `test/threadline/query/as_of_property_test.exs` | test (property, DB-backed) | CRUD + request-response | `test/threadline/query/cursors_property_test.exs` (file location, `describe`/property layout) + `test/threadline/capture/trigger_rerun_property_test.exs` (DB-backed mechanics) | role-match |
| `test/threadline/retention/cutoff_property_test.exs` | test (property, DB-backed) | CRUD + batch | `test/threadline/retention_test.exs` (domain: fixtures, put_env pattern) + `test/threadline/capture/trigger_rerun_property_test.exs` (DB-backed mechanics) | role-match |
| `test/threadline/capture/trigger_redaction_test.exs` (modified, D-13) | test (example) | CRUD | itself (existing file, add 2 assertions to the UPDATE test) | exact |
| `test/threadline/query_test.exs` (modified, D-17) | test (example) | request-response | itself, `describe "as_of/4"` block + `as_of_row_fixture/0` | exact |
| `test/threadline/retention_test.exs` (modified, D-20/D-22) | test (example) | CRUD | itself, existing `setup`/`insert_transaction`/`insert_change` helpers | exact |
| `test/threadline/property_scale_contract_test.exs` (modified, D-06) | test (contract/meta) | transform (AST scan) | itself, existing `classify_max_runs/3` dispatch chain | exact |
| `lib/threadline/retention.ex` (modified, D-20 fix) | service | CRUD | itself, `dry_run_result/4` | exact |
| `.planning/phases/227-db-backed-property-tests/tools/mutation-control.sh` | tooling (fork of 226's) | batch | `.planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh` | exact |
| `.planning/phases/227-db-backed-property-tests/tools/mutations/*.patch` (12 patches across D-12/D-16/D-21) | tooling (fixture) | — | `.planning/phases/226-.../tools/mutations/redaction_policy.patch` et al. | exact |

## Pattern Assignments

### `test/support/db_property.ex` (test-utility/harness)

**Analogs:** `test/support/data_case.ex` (whole file, 29 lines) + the inline per-iteration setup/cleanup block in `test/threadline/capture/trigger_rerun_property_test.exs`

**DataCase shape to NOT duplicate** (`test/support/data_case.ex:1-29`):
```elixir
defmodule Threadline.DataCase do
  defmacro __using__(opts) do
    opts = Keyword.merge([async: false], opts)
    quote do
      use ExUnit.Case, unquote(opts)
      alias Threadline.Capture.{AuditChange, AuditTransaction}
      alias Threadline.Test.Repo
      import Ecto.Query
      import Threadline.AsyncHelpers
      import Threadline.StorageSchemaCase
      setup do
        Threadline.StorageSchemaCase.clean_storage_schemas!()
        :ok
      end
    end
  end
end
```
D-02's moduledoc explicitly forbids `DbProperty` from growing a `__using__`/`setup` of its own — it must stay plain functions imported into each property test file (`use Threadline.DataCase` + `use ExUnitProperties` + `import Threadline.Test.DbProperty`), never a second macro-based harness next to this one.

**Per-iteration key + try/after cleanup pattern to copy** (`test/threadline/capture/trigger_rerun_property_test.exs:24-123`):
```elixir
property "..." do
  check all(runs <- run_sequence(), max_runs: @max_runs) do
    n = System.unique_integer([:positive, :monotonic])
    table = "trp_" <> Integer.to_string(n)
    # ... setup state scoped to n ...
    try do
      # ... real DDL/DML + assertions ...
    after
      # ... cleanup in reverse FK/dependency order, every statement guarded ...
      # (this file's cleanup restores Application env, drops temp files,
      #  drains a mailbox — DbProperty's `with_iteration/1` must generalize
      #  this exact try/after shape, but make the cleanup *rescue* so a
      #  cleanup error can't mask the real assertion failure, per D-01)
    end
  end
end
```
Map this onto `DbProperty.with_iteration/1`: `n = System.unique_integer([:positive, :monotonic])` generated **inside** the body (never as a generated StreamData value — this file already does it right), real work in the body, cleanup in `after`, each cleanup statement individually rescued and `IO.warn`-ed rather than letting one failure skip the rest (D-01 is stricter than this analog: it requires rescue+warn, this file currently lets `after` raise).

**Storage-qualified raw read pattern** (`lib/threadline/storage_schema.ex:120-123`):
```elixir
def table(name, opts \\ []) when name in @threadline_tables do
  qualify(get(opts), name)
end
```
Every raw SQL read `DbProperty`/`LeakOracle` issue against `audit_changes`/`audit_transactions` must build the table name with `Threadline.StorageSchema.table(:audit_changes)` / `table(:audit_transactions)`, never a bare string — this is the exact function CONTEXT.md D-02 cites and the one Research flags as a documented CI-only failure vector when skipped.

---

### `test/support/leak_oracle.ex` (test-utility/oracle, PROP-04)

**Analog:** `test/threadline/capture/trigger_redaction_test.exs` (structural assertion style) + the four functions it must call from `lib/`

**Structural assertion style to copy** (`test/threadline/capture/trigger_redaction_test.exs:56-93`):
```elixir
[change] = Repo.all(AuditChange, repo_opts())
assert change.op == "insert"
assert change.data_after
assert Map.has_key?(change.data_after, "public_bio")
refute Map.has_key?(change.data_after, "password")
assert Map.get(change.data_after, "email") == "[REDACTED]"
# ...
assert "email" in change.changed_fields
assert is_map(change.changed_from)
assert Map.get(change.changed_from, "email") == "[REDACTED]"
```
`LeakOracle`'s structural rules (D-10.3) generalize exactly these assertions — excluded key absent from `data_after`/`changed_from`/`changed_fields`, masked keys equal the placeholder exactly — but driven by raw `row_to_json` reads (per `db_property.ex`'s qualified-table pattern above) instead of `Repo.all(AuditChange, ...)`, so a column added later is covered automatically (D-10.1).

**Setup-fixture-table pattern to copy for `prop_redaction_leak`** (`test/threadline/capture/trigger_redaction_test.exs:10-38`):
```elixir
setup_all do
  Repo.query!("""
  CREATE TABLE IF NOT EXISTS #{@table} (...)
  """)
  Repo.query!(TriggerSQL.install_function([]))
  on_exit(fn ->
    Repo.query!(TriggerSQL.drop_trigger(@table))
    Repo.query!(TriggerSQL.drop_function_for_table(@table))
    Repo.query!("DROP TABLE IF EXISTS #{@table}")
  end)
  :ok
end
```
D-07 requires the per-table trigger variant instead of `install_function([])`:
```elixir
TriggerSQL.install_function_for_table(@t,
  store_changed_from: true,
  exclude: ["secret_excluded"],
  mask: ["secret_masked", "profile_masked"]
)
# then create_trigger(@t, :per_table, redacted_columns: [...])
```
(see the `per-table capture with exclude and mask` describe block at lines 40-54 of the same file for the `install_function_for_table` call shape to copy verbatim, substituting the new column names).

**Surfaces to call (not reimplement) — from `lib/`:**
- `Threadline.ChangeDiff` (default, `expand_insert_fields: true`, `format: :export_compat` variants) — `lib/threadline/change_diff.ex`
- `Threadline.Export.to_csv_iodata/2`, `to_json_document/2` (`:wrapped`, `:ndjson`), `stream_export_rows/2` piped into `format_changes_iodata/3` — `lib/threadline/export.ex`

---

### `test/support/redaction_leak_generators.ex`, `row_history_generators.ex`, `retention_cutoff_generators.ex` (generators)

**Analog:** `test/support/redaction_policy_generators.ex` (full file, 268 lines) — this is the canonical 226-era generator-module convention to mirror exactly.

**Moduledoc-states-its-bias convention** (`test/support/redaction_policy_generators.ex:1-31`):
```elixir
defmodule Threadline.Test.RedactionPolicyGenerators do
  @moduledoc """
  StreamData generators for ... [full prose describing every bias, every
  rung of every ladder, named pool, and why each exists] ...
  """
  use ExUnitProperties
  @exclude_pool ~w(ssn ein tax_id ...)
  ...
```
Every new generator module (`RedactionLeakGenerators`, `RowHistoryGenerators`, `RetentionCutoffGenerators`) must have this shape: `use ExUnitProperties`, named/documented constant pools (`@canary` shapes, `@blank_forms`-equivalent hostile wrapper list), and a moduledoc that states the bias in prose (D-03's explicit requirement, citing "226 convention").

**`frequency`-driven biased picker pattern to copy** (`test/support/redaction_policy_generators.ex:88-103`, `placeholder_pair_gen/0`):
```elixir
defp placeholder_pair_gen do
  frequency([
    {3, constant(:absent)},
    {1, constant({:present, false})},
    {1, constant({:present, nil})},
    {1, constant({:present, String.duplicate("a", 200)})},
    ...
  ])
end
```
This is the direct template for D-08's "value for a redacted slot, by `frequency`" (≈70% wrapped canary, ≈10% each nil/""/exact placeholder) and D-19's cutoff-offset `frequency` ladder (`{4, constant(0)}, {3, member_of([-1,1])}, ...`).

**Size-independent list/subset pattern to copy** (`test/support/redaction_policy_generators.ex:74-79`, `names_subset_gen/1`):
```elixir
defp names_subset_gen(pool) do
  map(list_of(member_of(pool), max_length: 3), &Enum.uniq/1)
end
```
This is exactly D-04's "DB generators must not depend on size" rule in practice — `member_of`/bounded `list_of(max_length:)`, never `uniq_list_of` on a small pool. Reuse this shape for PROP-07's transaction/row lists and PROP-06's step batches (`list_of(list_of(step, 1..3), 1..4)`).

**`gen all` composite generator with disjoint sub-generators** (`test/support/redaction_policy_generators.ex:130-141`, `valid_policy_gen/0`):
```elixir
def valid_policy_gen do
  gen all(
        exclude_names <- names_subset_gen(@exclude_pool),
        mask_names <- names_subset_gen(@mask_pool),
        exclude_entries <- entries_gen(exclude_names),
        mask_entries <- entries_gen(mask_names),
        opts_shape <- opts_shape_gen(),
        placeholder <- placeholder_pair_gen()
      ) do
    {:valid, build_opts(opts_shape, exclude_entries, mask_entries, placeholder)}
  end
end
```
Template for `RowHistoryGenerators`'s step/batch generator (D-15) and `RetentionCutoffGenerators`'s cutoff+transactions generator (D-19) — compose independent `gen all` clauses into one tagged tuple/struct.

---

### `test/threadline/capture/redaction_leak_property_test.exs` (PROP-04)

**Analogs:** `test/threadline/capture/trigger_rerun_property_test.exs` (DB-backed property mechanics, full file) + `test/threadline/capture/trigger_redaction_test.exs` (redaction domain assertions, above)

**Module header / `@max_runs` pattern to copy** (`test/threadline/capture/trigger_rerun_property_test.exs:1-25`):
```elixir
defmodule Threadline.Capture.TriggerRerunPropertyTest do
  @moduledoc """ ... """
  use Threadline.DataCase, async: false
  use ExUnitProperties
  import Threadline.Test.TriggerRunGenerators
  alias Threadline.Capture.Naming
  alias Threadline.StorageSchema
  alias Threadline.Test.MigrationHarness, as: Harness
  alias Threadline.Test.PropertyRuns
  @max_runs PropertyRuns.db(20)
  property "..." do
    check all(runs <- run_sequence(), max_runs: @max_runs) do
      ...
    end
  end
end
```
Same shape for `RedactionLeakPropertyTest`, swapping `TriggerRunGenerators` for `RedactionLeakGenerators`, adding `import Threadline.Test.DbProperty` and `import Threadline.Test.LeakOracle`, and `@max_runs PropertyRuns.db(20)` per D-05 (dropping to `db(15)`/`db(10)` only if measured cost requires it).

---

### `test/threadline/query/as_of_property_test.exs` (PROP-06)

**Analogs:** `test/threadline/query/cursors_property_test.exs` (file location + `describe`/property-per-invariant layout) + `test/threadline/capture/trigger_rerun_property_test.exs` (DB mechanics) + `lib/threadline/query.ex:467-495` (the exact function under test)

**`describe`-free, one-property-per-invariant layout to mirror** (`test/threadline/query/cursors_property_test.exs:1-37`):
```elixir
defmodule Threadline.Query.CursorsPropertyTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use ExUnitProperties
  import Threadline.Test.CursorGenerators
  alias Threadline.Test.KeysetModel
  alias Threadline.Test.PropertyRuns

  property "actor-history paging returns every entry exactly once ..." do
    check all({entries, k} <- paging_gen(), max_runs: PropertyRuns.pure(200)) do
      assert {:ok, forward_pages, backward_pages} = KeysetModel.walk_actor_history(entries, k),
             "walker did not hit its bound without a nil continuation cursor"
      ...
    end
  end
end
```
D-03 explicitly says "mirror `cursors_property_test.exs`" for `describe` layout — but note this file is `async: true` + `PropertyRuns.pure` (no DB); `as_of_property_test.exs` must instead be `use Threadline.DataCase, async: false` + `PropertyRuns.db(20)`, per D-06's new contract rule. Keep the labeled-assertion-message convention (`assert ..., "explanation"`) — every assertion in this file explains *why*, not just *what*.

**Exact `as_of`/`as_of_query` contract to replay against** (`lib/threadline/query.ex:467-495`, verbatim — this is also the mutation-control target for D-16):
```elixir
def as_of(schema_module, id, timestamp, opts) do
  repo = Keyword.fetch!(opts, :repo)
  snapshot = schema_module |> as_of_query(id, timestamp, opts) |> repo.one(storage_opts([], opts))
  case snapshot do
    %AuditChange{op: "delete"} -> {:error, :deleted_record}
    %AuditChange{data_after: data_after} -> load_as_of_snapshot(schema_module, data_after, opts)
    nil -> {:error, :before_audit_horizon}
  end
end

def as_of_query(schema_module, id, timestamp, opts) do
  repo = Keyword.fetch!(opts, :repo)
  matched = RowKey.match!(schema_module, id, repo)
  AuditChange
  |> where_row(matched)
  |> where([ac], ac.captured_at <= ^timestamp)        # D-16 mutation target: <= -> <
  |> maybe_apply_scope(row_history_scope_opts(schema_module, id, opts))
  |> order_by([ac], desc: ac.captured_at)              # D-16 mutation target: desc -> asc
  |> order_by([ac], desc: ac.id)                       # expected to SURVIVE (D-17)
  |> limit(1)
end
```

**Existing fixture to reuse ONLY for the D-17 tie example** (`test/threadline/query_test.exs:72`, `as_of_row_fixture/0`, and `describe "as_of/4"` blocks at lines 173/234) — read this helper directly when writing the D-17 pinning test; it is the synthetic `AuditTransaction`/`AuditChange` insert pattern CONTEXT.md says is rejected as the PROP-06 *property* oracle (D-14) but is exactly right for the one deterministic tie example (D-17), using `DbProperty.ordered_id(rank, n)` for the two colliding timestamps.

---

### `test/threadline/retention/cutoff_property_test.exs` (PROP-07)

**Analogs:** `test/threadline/retention_test.exs` (domain fixtures, put_env save/restore) + `test/threadline/capture/trigger_rerun_property_test.exs` (DB-backed mechanics) + `lib/threadline/retention.ex:131-164` (oracle target, also the D-20 fix site)

**`Application.put_env` save/restore pattern to copy exactly** (`test/threadline/retention_test.exs:40-55`):
```elixir
setup do
  prev = Application.get_env(:threadline, :retention)
  on_exit(fn ->
    Application.put_env(:threadline, :retention, prev)
  end)
  Application.put_env(:threadline, :retention,
    enabled: true,
    keep_days: 1,
    delete_empty_transactions: true
  )
  Repo.delete_all(RetentionRun, repo_opts())
  :ok
end
```
D-18 step 2 cites this exact block ("the `retention_test.exs` L46-55 pattern") — the property's per-iteration setup reuses it, but note D-18 says a setup/`on_exit` *pair*, not per-iteration (the module is `async: false`, and this config is test-module-scoped, unlike the per-row cleanup which is per-iteration).

**Fixture-row insert helpers to copy the shape of** (`test/threadline/retention_test.exs:7-30`):
```elixir
defp insert_transaction(storage_schema, attrs) do
  defaults = %{txid: System.unique_integer([:positive]), occurred_at: DateTime.utc_now(:microsecond)}
  Repo.insert!(AuditTransaction.changeset(%AuditTransaction{}, Map.merge(defaults, Map.new(attrs))), repo_opts(storage_schema))
end

defp insert_change(storage_schema, transaction, attrs) do
  defaults = %{
    transaction_id: transaction.id,
    table_schema: "public",
    table_name: "purge_fixture",
    table_pk: %{"id" => Ecto.UUID.generate()},
    op: "insert",
    captured_at: DateTime.add(DateTime.utc_now(:microsecond), -10, :day),
    data_after: %{"n" => 1}
  }
  Repo.insert!(AuditChange.changeset(%AuditChange{}, Map.merge(defaults, Map.new(attrs))), repo_opts(storage_schema))
end
```
D-18 step 3 instead uses `insert_all` with explicit ids/txids/precision-6 `captured_at` for the property (changesets are fine for the three D-22 example tests, but the property needs bulk `insert_all` for generated transaction/row counts).

**`dry_run_result/4` — exact function under test and D-20 fix site** (`lib/threadline/retention.ex:131-156`, verbatim):
```elixir
defp dry_run_result(repo, cutoff, policy, storage_opts) do
  eligible_changes =
    repo.one(
      from(ac in AuditChange, where: ac.captured_at < ^cutoff, select: count(ac.id)),
      storage_opts
    )

  eligible_txns =
    if policy.delete_empty_transactions do
      repo.one(
        from(at in AuditTransaction,
          as: :audit_transaction,
          where:
            not exists(
              from(c in AuditChange,
                where: c.transaction_id == parent_as(:audit_transaction).id,
                select: 1
              )
            ),
          select: count(at.id)
        ),
        storage_opts
      )
    else
      0
    end

  %{deleted_changes: eligible_changes, deleted_transactions: eligible_txns, batches_run: 0, dry_run: true}
end
```
D-20's fix adds `and c.captured_at >= ^cutoff` inside the inner `where:` of the `not exists` subquery (the `c.transaction_id == parent_as(:audit_transaction).id` clause) — this is the only line to change.

---

## Shared Patterns

### Per-iteration isolation, never `on_exit`-once (D-01)
**Source:** `test/threadline/capture/trigger_rerun_property_test.exs:24-123` (try/after around a `check all` body, key generated inside the body)
**Apply to:** All three new property files, via `DbProperty.with_iteration/1`.
```elixir
check all(input <- generator(), max_runs: PropertyRuns.db(20)) do
  n = System.unique_integer([:positive, :monotonic])
  try do
    # ... real DB work, assertions ...
  after
    # ... delete only this iteration's rows, FK order, rescue+warn per row ...
  end
end
```

### Storage-qualified raw SQL (every property, D-02/D-10)
**Source:** `lib/threadline/storage_schema.ex:120-123` (`table/2`)
**Apply to:** Every raw `Repo.query!`/`Repo.query` against `audit_changes`/`audit_transactions` in `db_property.ex`, `leak_oracle.ex`, and all three property test files.
```elixir
Repo.query!(
  "SELECT row_to_json(c)::text FROM #{Threadline.StorageSchema.table(:audit_changes)} c WHERE c.table_name = $1 AND c.table_pk->>'id' = $2",
  [table_name, id]
)
```

### `Application.put_env`/`get_env` restore pattern (PROP-07 only, but generalizable)
**Source:** `test/threadline/retention_test.exs:40-55`
**Apply to:** `cutoff_property_test.exs`'s `:retention` config save/restore; also the pattern cited as safe for `async: false` modules (Pitfall 14).

### Generator-module conventions (naming, moduledoc bias, `use ExUnitProperties`)
**Source:** `test/support/redaction_policy_generators.ex` (whole file)
**Apply to:** `redaction_leak_generators.ex`, `row_history_generators.ex`, `retention_cutoff_generators.ex`.

### Mutation-control tooling (D-23)
**Source:** `.planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh`
**Apply to:** `.planning/phases/227-db-backed-property-tests/tools/mutation-control.sh` — copy the file, then apply the single fix D-23 names: in `extract_counterexample()` (currently at the `awk '/Failed with generated values/{flag=1} flag{print} flag && /^\s*$/{exit}'` line), replace `\s` with the POSIX bracket class `[[:space:]]` so the blank-line match is portable across awk implementations and compares the *whole* generated-values block, not just the header. Re-run one 226 patch (e.g. `redaction_policy.patch` against `trigger_redaction_test.exs`-adjacent coverage, or any 226 pure property) afterward to confirm backward compatibility, as D-23 requires.
```elixir
# 226's patch-file shape to copy for every new mutation (one hunk, lib/-only):
diff --git a/lib/threadline/capture/redaction_policy.ex b/lib/threadline/capture/redaction_policy.ex
index f2d5a141..12f0371d 100644
--- a/lib/threadline/capture/redaction_policy.ex
+++ b/lib/threadline/capture/redaction_policy.ex
@@ -76,7 +76,6 @@ defmodule Threadline.Capture.RedactionPolicy do
   defp normalize_columns(list, _key) when is_list(list) do
     list
     |> Enum.map(&to_string/1)
-    |> Enum.map(&String.trim/1)
     |> Enum.reject(&(&1 == ""))
   end
```

## No Analog Found

None. Every file in CONTEXT.md's file list (explicit D-02/D-03/D-07/D-23 names, plus the implied `property_generator_coverage_test.exs` extension and `partition_weights.txt` append) has a direct or close analog already in the repo, because this phase is explicitly built as an extension of phase 226's machinery rather than a new subsystem. The one genuinely new structural element — `test/threadline/retention/` as a directory (today only the flat `retention_test.exs` file exists) — is a location decision, not a missing pattern; the file inside it (`cutoff_property_test.exs`) still follows the DB-property + retention-domain analogs above.

## Metadata

**Analog search scope:** `test/support/`, `test/threadline/capture/`, `test/threadline/query/` and `query_test.exs`, `test/threadline/retention_test.exs`, `lib/threadline/{retention,query,storage_schema,change_diff,export}.ex`, `lib/threadline/capture/trigger_sql.ex`, `.planning/phases/226-pure-property-tests-and-run-budget/tools/`
**Files scanned:** ~20 read directly (full or targeted ranges); file list and line numbers cross-checked against 227-RESEARCH.md's independent re-verification
**Pattern extraction date:** 2026-10-01
