defmodule Threadline.Health.LegacyKeyFindings do
  @moduledoc false

  alias Ecto.Adapters.SQL
  alias Threadline.Health.{Finding, TriggerCatalog}
  alias Threadline.StorageSchema

  @default_statement_timeout_ms 15_000
  @default_count_cap 10_000

  @doc false
  @spec codes() :: [Finding.code()]
  def codes do
    [:unresolved_legacy_keys]
  end

  @doc false
  @spec run(keyword()) :: [Finding.t()]
  def run(opts) do
    repo = Keyword.fetch!(opts, :repo)
    requested_schemas = normalize_schema(opts)

    statement_timeout_ms =
      positive_integer_opt!(opts, :statement_timeout, @default_statement_timeout_ms)

    count_cap = positive_integer_opt!(opts, :count_cap, @default_count_cap)

    probes =
      repo
      |> TriggerCatalog.threadline_triggers()
      |> reject_storage_own_tables()
      |> Enum.filter(&(&1.nargs > 0))
      |> filter_by_schema(requested_schemas)
      |> Enum.group_by(&{&1.schema, &1.table})
      |> Enum.map(fn {_schema_table, group} -> canonical_trigger(group) end)

    if probes == [] do
      []
    else
      {:ok, findings} =
        repo.transaction(fn ->
          _ =
            SQL.query!(repo, "SELECT set_config('statement_timeout', $1, true)", [
              Integer.to_string(statement_timeout_ms)
            ])

          probes
          |> Enum.map(&probe(repo, &1, count_cap, opts))
          |> Enum.reject(&is_nil/1)
        end)

      Enum.sort_by(findings, &{&1.schema, &1.table, Atom.to_string(&1.code), &1.message})
    end
  end

  # One trigger per {schema, table}: the trigger whose name sorts first.
  defp canonical_trigger(group), do: Enum.min_by(group, & &1.trigger)

  defp normalize_schema(opts) do
    case Keyword.fetch(opts, :schema) do
      :error ->
        nil

      {:ok, schema} when is_binary(schema) ->
        [schema]

      {:ok, [_ | _] = list} ->
        if Enum.all?(list, &is_binary/1) do
          list
        else
          invalid_schema!(list)
        end

      {:ok, other} ->
        invalid_schema!(other)
    end
  end

  @spec invalid_schema!(term()) :: no_return()
  defp invalid_schema!(value) do
    raise ArgumentError,
          ":schema must be a string or a non-empty list of strings, got: #{inspect(value)}"
  end

  defp reject_storage_own_tables(rows) do
    storage_schema = StorageSchema.get()

    Enum.reject(rows, fn row ->
      row.schema == storage_schema and StorageSchema.threadline_table?(row.table)
    end)
  end

  defp filter_by_schema(rows, nil), do: rows
  defp filter_by_schema(rows, schemas), do: Enum.filter(rows, &(&1.schema in schemas))

  defp positive_integer_opt!(opts, key, default) do
    case Keyword.fetch(opts, key) do
      :error ->
        default

      {:ok, value} when is_integer(value) and value > 0 ->
        value

      {:ok, value} ->
        raise ArgumentError, ":#{key} must be a positive integer, got: #{inspect(value)}"
    end
  end

  # One capped-count probe per table, never a global GROUP BY over the whole
  # audit_changes table (a seq scan plus detoasting data_after at scale).
  # Capped at cap+1 so the result tells us whether the true count exceeds the
  # cap without scanning past it. Only INSERT/UPDATE rows whose table_pk is
  # still unresolved and whose key columns are all present and non-null in
  # data_after are counted — a DELETE row (no data_after) or a row with a
  # redacted/missing key column never matches the `data_after ?& $3::text[]`
  # + NOT EXISTS NULL guard.
  defp probe(repo, %{schema: schema, table: table, args: args}, cap, opts) do
    qualified = StorageSchema.table("audit_changes", opts)

    sql = """
    SELECT count(*) FROM (
      SELECT 1 FROM #{qualified}
      WHERE table_schema = $1 AND table_name = $2
        AND table_pk = ANY (ARRAY['{"id": null}', '{}']::jsonb[])
        AND op IN ('insert', 'update')
        AND data_after ?& $3::text[]
        AND NOT EXISTS (
          SELECT 1 FROM unnest($3::text[]) k WHERE data_after ->> k IS NULL
        )
      LIMIT $4
    ) s
    """

    %{rows: [[count]]} = SQL.query!(repo, sql, [schema, table, args, cap + 1])

    build_finding(schema, table, args, count, cap)
  end

  defp build_finding(_schema, _table, _args, 0, _cap), do: nil

  defp build_finding(schema, table, args, count, cap) do
    capped = count > cap
    unresolved_count = min(count, cap)

    %Finding{
      code: :unresolved_legacy_keys,
      severity: :warning,
      schema: schema,
      table: table,
      message: message(schema, table, unresolved_count, capped),
      details: %{
        "unresolved_count" => unresolved_count,
        "capped" => capped,
        "key_columns" => args
      }
    }
  end

  defp message(schema, table, count, capped?) do
    count_text = if capped?, do: "at least #{count}", else: Integer.to_string(count)

    "#{schema}.#{table} has #{count_text} INSERT/UPDATE audit rows captured before its " <>
      "trigger was regenerated with no resolved primary key; history/3 cannot find them by " <>
      "key. Run the backfill in " <>
      "guides/upgrading-to-0.11.md#step-6-optional-backfill-unresolved-primary-keys."
  end
end
