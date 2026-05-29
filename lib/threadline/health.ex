defmodule Threadline.Health do
  @moduledoc """
  Health checks for Threadline infrastructure.

  Queries the PostgreSQL system catalog to verify trigger installation status
  for all user tables.

  ## Mix-task parity

  See `mix threadline.health.coverage` for a viewer with `--json` and
  `--schema=NAME` flags. The Mix task does not exit non-zero on uncovered
  tables (it is a viewer, not a CI gate); use `mix threadline.verify_coverage`
  for the positive-list CI gate.

  ## Telemetry

  On every successful call, emits `[:threadline, :health, :checked]` with
  measurements `%{covered: integer, uncovered: integer, expected_uncovered: integer}`.
  The `expected_uncovered` measurement is an additive — old
  subscribers reading only `covered`/`uncovered` keep working unchanged).
  """

  @audit_tables ~w(audit_transactions audit_changes audit_actions)
  @expected_uncovered_baseline ~w(schema_migrations)

  @doc """
  Returns a list of tagged tuples indicating trigger coverage for all user
  tables in the given schema (default `"public"`).

  Audit tables (`audit_transactions`, `audit_changes`, `audit_actions`) are
  excluded from the result — they are not expected to have triggers (CAP-10).

  A third tuple variant `{:expected_uncovered, name}` is supported for
  bookkeeping tables that are intentionally not audited (e.g. `schema_migrations`).
  The bucket is computed from a hardcoded baseline plus
  `config :threadline, :health, expected_uncovered_tables: [...]`, with
  `:audit_anyway` removing entries from the union.

  ## Options

  - `:repo` — required `Ecto.Repo` module
  - `:schema` — optional schema name string (default `"public"`). Programmatic
    callers are responsible for sanitizing or trusting their own input —
    this function does NOT validate `:schema` against `pg_namespace`. Surfaces
    that take untrusted input (LV / Mix task) MUST validate at the edge.

  Returns `[{:covered | :uncovered | :expected_uncovered, table_name}]`.

  ## Example

      Threadline.Health.trigger_coverage(repo: MyApp.Repo)
      #=> [{:covered, "users"}, {:expected_uncovered, "schema_migrations"}, {:uncovered, "orders"}]
  """
  def trigger_coverage(opts) do
    repo = Keyword.fetch!(opts, :repo)
    schema = Keyword.get(opts, :schema, "public")

    all_tables = fetch_all_user_tables(repo, schema)
    covered_tables = fetch_threadline_covered_tables(repo, schema)
    expected_uncovered = compute_expected_uncovered()

    covered_set = MapSet.new(covered_tables)
    expected_set = MapSet.new(expected_uncovered)

    result =
      all_tables
      |> Enum.reject(&(&1 in @audit_tables))
      |> Enum.map(fn table ->
        cond do
          MapSet.member?(covered_set, table) -> {:covered, table}
          MapSet.member?(expected_set, table) -> {:expected_uncovered, table}
          true -> {:uncovered, table}
        end
      end)

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

  defp fetch_all_user_tables(repo, schema) do
    sql = "SELECT tablename FROM pg_tables WHERE schemaname = $1"
    %{rows: rows} = Ecto.Adapters.SQL.query!(repo, sql, [schema])
    List.flatten(rows)
  end

  defp fetch_threadline_covered_tables(repo, schema) do
    sql = """
    SELECT DISTINCT c.relname
    FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE t.tgname LIKE 'threadline_audit_%'
      AND n.nspname = $1
    """

    %{rows: rows} = Ecto.Adapters.SQL.query!(repo, sql, [schema])
    List.flatten(rows)
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
