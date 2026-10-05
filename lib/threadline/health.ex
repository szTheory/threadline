defmodule Threadline.Health do
  @moduledoc """
  Reports capture health and trigger coverage for Threadline installations.

  `trigger_findings/1` and `legacy_key_findings/1` return health findings,
  while `trigger_coverage/1` lists covered, uncovered, and expected-uncovered
  user tables.

  Queries the PostgreSQL system catalog to verify trigger installation status
  for all user tables.

  ## Mix-task parity

  See `mix threadline.health.coverage` for a viewer with `--json`,
  `--schema=NAME`, and `--strict` flags. Viewer by default (exits 0);
  `--strict` turns `:error`-severity findings into exit 1. The task does not
  exit non-zero on uncovered tables even with `--strict`; use
  `mix threadline.verify_coverage` for the positive-list CI gate.

  ## Telemetry

  On every successful call, `trigger_coverage/1` emits
  `[:threadline, :health, :checked]` with measurements
  `%{covered: integer, uncovered: integer, expected_uncovered: integer}`.
  The `expected_uncovered` measurement is an additive — old
  subscribers reading only `covered`/`uncovered` keep working unchanged).

  `trigger_findings/1` emits `[:threadline, :health, :findings_checked]` with
  measurements `%{errors: integer, warnings: integer}`, counted over the
  findings list it returns. `legacy_key_findings/1` emits no telemetry event.
  """

  alias Ecto.Adapters.SQL
  alias Threadline.Health.{CoverageSchemas, LegacyKeyFindings, TriggerFindings}

  @typedoc "A status assigned to a host table by trigger coverage."
  @type coverage_status :: :covered | :uncovered | :expected_uncovered

  @typedoc "A host table name paired with its trigger coverage status."
  @type coverage_entry :: {coverage_status(), String.t()}

  @typedoc "A schema name or list of schema names used to select health findings."
  @type schema_filter :: String.t() | [String.t()]

  @typedoc "An option accepted by `trigger_findings/1`."
  @type trigger_findings_opt :: Threadline.repo_opt() | {:schema, schema_filter()}

  @typedoc "An option accepted by `legacy_key_findings/1`."
  @type legacy_key_findings_opt ::
          Threadline.repo_opt()
          | {:schema, schema_filter()}
          | {:statement_timeout, pos_integer()}

  @typedoc "An option accepted by `trigger_coverage/1`."
  @type trigger_coverage_opt :: Threadline.repo_opt() | {:schema, String.t()}

  @audit_tables ~w(audit_transactions audit_changes audit_actions)
  @expected_uncovered_baseline ~w(schema_migrations)

  @doc """
  Returns a list of `Threadline.Health.Finding` structs describing detected
  capture problems: disabled or replica-only triggers, duplicate capture
  triggers, drifted or missing key columns, and shared per-table functions.

  ## Options

  - `:repo` — `Ecto.Repo` module. Required.
  - `:schema` — schema name string or list of strings. Optional.
    Omitting it covers every non-system schema (excludes `pg_catalog`,
    `information_schema`, `pg_toast*`, `pg_temp*`, and the configured
    Threadline storage schema's own tables). This is deliberately different
    from `trigger_coverage/1`'s `"public"` default: two tables with the same
    name in different schemas, and a per-table function shared across
    schemas, cannot be seen one schema at a time. The shared-function check
    always scans the whole catalog regardless of `:schema` — the option only
    filters which findings, by their table's schema, are returned.

  A malformed `:trigger_capture` config raises the same `ArgumentError` that
  the internal trigger-capture config loader raises for capture itself.

  Findings are sorted by `{schema, table, code}`, with message as the final
  tie-break, so two consecutive calls return identical lists. One table may
  produce more than one finding; there is no short-circuit.

  Unknown option keys are ignored.

  ## Example

      Threadline.Health.trigger_findings(repo: MyApp.Repo)
      #=> [%Threadline.Health.Finding{code: :capture_trigger_disabled, ...}]
  """
  @spec trigger_findings([trigger_findings_opt()]) :: [Threadline.Health.Finding.t()]
  def trigger_findings(opts), do: TriggerFindings.run(opts)

  @doc """
  Returns a list of `Threadline.Health.Finding` structs (`:unresolved_legacy_keys`)
  for audit rows captured before their table's trigger was regenerated and
  still carrying an unresolved primary key that a key-based row lookup cannot
  resolve. Unlike `trigger_findings/1`, which is catalog-only, this scans
  `audit_changes` per table.

  ## Options

  - `:repo` — `Ecto.Repo` module. Required.
  - `:schema` — schema name string or list of strings. Optional. Omitting it covers every non-system schema.
  - `:statement_timeout` — milliseconds. Defaults to `15_000`. Applied with a
    transaction-local setting, so it is safe through PgBouncer transaction
    pooling. When the timeout elapses — typically a missing row-history index —
    this function raises `Postgrex.Error` with postgres code `:query_canceled`;
    see [Step 4](upgrading-to-0.11.md#step-4-add-the-row-history-index).

  Each table's probe is capped at 10,000 rows; a capped finding's
  `details["unresolved_count"]` is `10000` and its message reads "at least
  10000". DELETE rows, rows whose key columns were redacted or are otherwise
  absent from `data_after`, and dropped tables are never counted — see
  [What cannot be recovered](upgrading-to-0.11.md#what-cannot-be-recovered).
  A finding's `details` map has string keys `"unresolved_count"` (integer),
  `"capped"` (boolean), and `"key_columns"` (list of strings).

  Emits no telemetry event.

  Unknown option keys are ignored.

  ## Example

      Threadline.Health.legacy_key_findings(repo: MyApp.Repo)
      #=> [%Threadline.Health.Finding{code: :unresolved_legacy_keys, ...}]
  """
  @spec legacy_key_findings([legacy_key_findings_opt()]) :: [Threadline.Health.Finding.t()]
  def legacy_key_findings(opts), do: LegacyKeyFindings.run(opts)

  @doc """
  Returns trigger coverage entries for user tables in a schema, defaulting to `"public"`.

  Audit tables (`audit_transactions`, `audit_changes`, `audit_actions`) are
  excluded from the result — they are not expected to have triggers (CAP-10).

  A third tuple variant `{:expected_uncovered, name}` is supported for
  bookkeeping tables that are intentionally not audited (e.g. `schema_migrations`).
  The bucket is computed from a hardcoded baseline plus
  `config :threadline, :health, expected_uncovered_tables: [...]`, with
  `:audit_anyway` removing entries from the union.

  ## Options

  - `:repo` — `Ecto.Repo` module. Required.
  - `:schema` — schema name string. Defaults to `"public"`. Programmatic
    callers are responsible for sanitizing or trusting their own input —
    this function does NOT validate `:schema` against `pg_namespace`. Surfaces
    that take untrusted input (LV / Mix task) MUST validate at the edge.

  A disabled or replica-only trigger no longer counts as covered — see
  `trigger_findings/1`, which reports it as `:capture_trigger_disabled`.

  Other option keys are ignored.

  ## Returns

  - A list of `coverage_entry()` values in table-name order.
  - Raises `KeyError` when `:repo` is missing; repository errors are reraised.

  ## Example

  Threadline.Health.trigger_coverage(repo: MyApp.Repo)
  #=> [{:covered, "users"}, {:expected_uncovered, "schema_migrations"}, {:uncovered, "orders"}]
  """
  @spec trigger_coverage([trigger_coverage_opt()]) :: [coverage_entry()]
  def trigger_coverage(opts) do
    repo = Keyword.fetch!(opts, :repo)
    schema = Keyword.get(opts, :schema, "public")

    all_tables = fetch_all_user_tables(repo, schema)
    covered_tables = repo |> fetch_threadline_covered_tables([schema]) |> Enum.map(&elem(&1, 1))
    expected_uncovered = compute_expected_uncovered()

    result = classify(all_tables, covered_tables, expected_uncovered)

    covered_count = Enum.count(result, &match?({:covered, _}, &1))
    uncovered_count = Enum.count(result, &match?({:uncovered, _}, &1))
    expected_uncovered_count = Enum.count(result, &match?({:expected_uncovered, _}, &1))

    Threadline.Telemetry.emit_health_checked(
      covered_count,
      uncovered_count,
      expected_uncovered_count
    )

    result
  end

  @doc false
  @spec classify([String.t()], [String.t()], [String.t()]) ::
          [{:covered | :uncovered | :expected_uncovered, String.t()}]
  def classify(all_tables, covered_tables, expected_uncovered) do
    covered_set = MapSet.new(covered_tables)
    expected_set = MapSet.new(expected_uncovered)

    all_tables
    |> Enum.reject(&(&1 in @audit_tables))
    |> Enum.map(fn table ->
      cond do
        MapSet.member?(covered_set, table) -> {:covered, table}
        MapSet.member?(expected_set, table) -> {:expected_uncovered, table}
        true -> {:uncovered, table}
      end
    end)
  end

  # Returns trigger coverage for every reportable schema in one batched
  # catalog snapshot. Task-only — reached only by
  # `mix threadline.health.coverage --all-schemas`; a public multi-schema API
  # is a future decision.
  #
  # Runs exactly two catalog queries total (one for tables via
  # Threadline.Health.CoverageSchemas.all_tables/1, one for covering
  # triggers), never a per-schema loop, and classifies every table through
  # the same classify/3 trigger_coverage/1 itself calls, so the two paths
  # agree by construction. Emits [:threadline, :health, :checked] exactly
  # once, with grand totals across every schema in the result.
  #
  # :repo is required. Returns %{schema => [{:covered | :uncovered |
  # :expected_uncovered, table}]}, one entry per schema with at least one
  # reportable table. Schemas with no reportable tables are absent — a caller
  # wanting a finding's schema represented even with no rows unions it in
  # separately.
  @doc false
  @spec coverage_by_schema(keyword()) :: %{
          String.t() => [{:covered | :uncovered | :expected_uncovered, String.t()}]
        }
  def coverage_by_schema(opts) do
    repo = Keyword.fetch!(opts, :repo)

    all_rows = CoverageSchemas.all_tables(repo)
    schemas = all_rows |> Enum.map(&elem(&1, 0)) |> Enum.uniq()
    covered_rows = fetch_threadline_covered_tables(repo, schemas)
    expected_uncovered = compute_expected_uncovered()

    tables_by_schema = Enum.group_by(all_rows, &elem(&1, 0), &elem(&1, 1))
    covered_by_schema = Enum.group_by(covered_rows, &elem(&1, 0), &elem(&1, 1))

    result =
      Map.new(tables_by_schema, fn {schema, tables} ->
        covered = Map.get(covered_by_schema, schema, [])
        {schema, classify(tables, covered, expected_uncovered)}
      end)

    all_tuples = result |> Map.values() |> List.flatten()
    covered_count = Enum.count(all_tuples, &match?({:covered, _}, &1))
    uncovered_count = Enum.count(all_tuples, &match?({:uncovered, _}, &1))
    expected_uncovered_count = Enum.count(all_tuples, &match?({:expected_uncovered, _}, &1))

    Threadline.Telemetry.emit_health_checked(
      covered_count,
      uncovered_count,
      expected_uncovered_count
    )

    result
  end

  defp fetch_all_user_tables(repo, schema) do
    sql = "SELECT tablename FROM pg_tables WHERE schemaname = $1"
    %{rows: rows} = SQL.query!(repo, sql, [schema])
    List.flatten(rows)
  end

  # Batched across one or more schemas: callers pass a single-element list
  # for the :schema-scoped path and the full schema list for
  # coverage_by_schema/1, so the two paths share one query shape.
  defp fetch_threadline_covered_tables(repo, schemas) do
    sql = """
    SELECT n.nspname, c.relname
    FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE t.tgname LIKE 'threadline_audit_%'
      AND n.nspname = ANY($1::text[])
      AND t.tgenabled NOT IN ('D', 'R')
    """

    %{rows: rows} = SQL.query!(repo, sql, [schemas])
    Enum.map(rows, fn [schema, table] -> {schema, table} end)
  end

  defp compute_expected_uncovered do
    health_cfg = Application.get_env(:threadline, :health, [])
    configured = Keyword.get(health_cfg, :expected_uncovered_tables, [])
    audit_anyway = Keyword.get(health_cfg, :audit_anyway, [])

    (@expected_uncovered_baseline ++ configured)
    |> Enum.uniq()
    |> Enum.reject(&(&1 in audit_anyway))
  end
end
