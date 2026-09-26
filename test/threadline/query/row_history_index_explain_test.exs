defmodule Threadline.Query.RowHistoryIndexExplainTest do
  @moduledoc """
  Proves `EXPLAIN` of the real queries `history/3`, `as_of/4`, and
  `row_history_query/3` build names `audit_changes_row_history_idx`
  (IDX-01), never a sequential scan. `enable_seqscan = off` is scoped to one
  rolled-back transaction (D-12); no assertion here is ever made on timing.
  """

  use Threadline.DataCase

  alias Ecto.Adapters.SQL
  alias Ecto.Query, as: EctoQuery
  alias Threadline.Capture.AuditTransaction
  alias Threadline.Query

  @noise_tables ~w(rk_explain_noise_0 rk_explain_noise_1 rk_explain_noise_2 rk_explain_noise_3)
  @keys_per_table 1000
  @history_depth 5
  @seed_source "row_history_index_explain_test"

  defmodule RkExplainUser do
    use Ecto.Schema

    @primary_key {:id, :string, autogenerate: false}
    schema "rk_explain_users" do
      field(:name, :string)
    end
  end

  setup do
    seed_index_data!()
    on_exit(&clean_index_data!/0)
    :ok
  end

  test "history/3's query names the row-history index under enable_seqscan = off" do
    Query.history_query(RkExplainUser, "k-1", repo: Repo)
    |> assert_uses_row_history_index!()
  end

  test "as_of/4's query names the row-history index under enable_seqscan = off" do
    Query.as_of_query(RkExplainUser, "k-1", DateTime.utc_now(), repo: Repo)
    |> assert_uses_row_history_index!()
  end

  test "row_history_query/3's query names the row-history index under enable_seqscan = off" do
    Query.row_history_query(RkExplainUser, "k-1", repo: Repo)
    |> assert_uses_row_history_index!()
  end

  # Seeds several thousand rows across noise tables (one row per key, so a
  # bare `table_name` predicate stays broad) and 5000 rows of real history
  # depth for `rk_explain_users` across 1000 distinct keys (5 captures per
  # key, so the whole-map `table_pk` equality this test exercises is far
  # more selective than `audit_changes_table_name_idx` alone), then
  # `ANALYZE`s so the planner has real statistics to cost from.
  defp seed_index_data! do
    transaction =
      %{
        txid: System.unique_integer([:positive]),
        occurred_at: DateTime.utc_now(),
        source: @seed_source
      }
      |> AuditTransaction.changeset()
      |> Repo.insert!(repo_opts("threadline"))

    transaction_id = Ecto.UUID.dump!(transaction.id)

    for table <- @noise_tables do
      Repo.query!(
        """
        INSERT INTO threadline.audit_changes
          (id, transaction_id, table_schema, table_name, table_pk, op, data_after, captured_at)
        SELECT gen_random_uuid(),
               $1,
               'public',
               $2,
               jsonb_build_object('id', 'noise-' || n::text),
               'insert',
               jsonb_build_object('id', 'noise-' || n::text),
               now() - (n || ' seconds')::interval
        FROM generate_series(1, $3) AS n
        """,
        [transaction_id, table, @keys_per_table]
      )
    end

    Repo.query!(
      """
      INSERT INTO threadline.audit_changes
        (id, transaction_id, table_schema, table_name, table_pk, op, data_after, captured_at)
      SELECT gen_random_uuid(),
             $1,
             'public',
             'rk_explain_users',
             jsonb_build_object('id', 'k-' || key::text),
             'insert',
             jsonb_build_object('id', 'k-' || key::text, 'name', 'user ' || key::text),
             now() - ((key * $2 + depth) || ' seconds')::interval
      FROM generate_series(1, $3) AS key,
           generate_series(1, $2) AS depth
      """,
      [transaction_id, @history_depth, @keys_per_table]
    )

    Repo.query!("ANALYZE threadline.audit_changes")

    :ok
  end

  defp clean_index_data! do
    Repo.query!("DELETE FROM threadline.audit_changes WHERE table_name = ANY($1)", [
      @noise_tables ++ ["rk_explain_users"]
    ])

    Repo.query!("DELETE FROM threadline.audit_transactions WHERE source = $1", [@seed_source])

    :ok
  end

  # `SET LOCAL` and the explain both run on the transaction's own checked-out
  # connection, and the whole thing is rolled back, so `enable_seqscan`
  # never leaks into another test.
  defp assert_uses_row_history_index!(query) do
    Repo.transaction(fn ->
      SQL.query!(Repo, "SET LOCAL enable_seqscan = off", [])

      prefixed = EctoQuery.put_query_prefix(query, "threadline")
      plan = SQL.explain(Repo, :all, prefixed)

      assert plan =~ "audit_changes_row_history_idx"
      Repo.rollback(:explain_only)
    end)
  end
end
