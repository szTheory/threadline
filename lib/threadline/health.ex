defmodule Threadline.Health do
  @moduledoc """
  Health checks for Threadline infrastructure.

  Queries the PostgreSQL system catalog to verify trigger installation status
  for all user tables.
  """

  @audit_tables ~w(audit_transactions audit_changes audit_actions)

  @doc """
  Returns a list of tagged tuples indicating trigger coverage for all user
  tables in the `public` schema.

  Audit tables (`audit_transactions`, `audit_changes`, `audit_actions`) are
  excluded from the result — they are not expected to have triggers (CAP-10).

  Returns `[{:covered, table_name} | {:uncovered, table_name}]`.

  ## Options

  - `:repo` — required `Ecto.Repo` module

  ## Example

      Threadline.Health.trigger_coverage(repo: MyApp.Repo)
      #=> [{:covered, "users"}, {:covered, "posts"}, {:uncovered, "orders"}]
  """
  def trigger_coverage(opts) do
    repo = Keyword.fetch!(opts, :repo)

    all_tables = fetch_all_user_tables(repo)
    covered_tables = fetch_threadline_covered_tables(repo)

    covered_set = MapSet.new(covered_tables)

    result =
      all_tables
      |> Enum.reject(&(&1 in @audit_tables))
      |> Enum.map(fn table ->
        if MapSet.member?(covered_set, table) do
          {:covered, table}
        else
          {:uncovered, table}
        end
      end)

    covered_count = Enum.count(result, &match?({:covered, _}, &1))
    uncovered_count = Enum.count(result, &match?({:uncovered, _}, &1))
    Threadline.Telemetry.emit_health_checked(covered_count, uncovered_count)

    result
  end

  defp fetch_all_user_tables(repo) do
    sql = "SELECT tablename FROM pg_tables WHERE schemaname = 'public'"
    %{rows: rows} = Ecto.Adapters.SQL.query!(repo, sql, [])
    List.flatten(rows)
  end

  defp fetch_threadline_covered_tables(repo) do
    sql = """
    SELECT DISTINCT c.relname
    FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    WHERE t.tgname LIKE 'threadline_audit_%'
    """

    %{rows: rows} = Ecto.Adapters.SQL.query!(repo, sql, [])
    List.flatten(rows)
  end
end
