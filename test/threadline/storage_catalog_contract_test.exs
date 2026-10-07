defmodule Threadline.StorageCatalogContractTest do
  @moduledoc """
  Pins the installed PostgreSQL storage contract from live catalogs. The
  literal facts below are independent of generated migration SQL: update them
  only when an intentional, reviewed storage contract change is made.
  """

  use Threadline.DataCase, async: false

  @tables ~w(audit_actions audit_changes audit_transactions)

  @columns %{
    "audit_transactions" =>
      MapSet.new([
        {"id", "uuid", false},
        {"txid", "bigint", false},
        {"occurred_at", "timestamp with time zone", false},
        {"source", "text", true},
        {"meta", "jsonb", true},
        {"actor_ref", "jsonb", true},
        {"action_id", "uuid", true}
      ]),
    "audit_changes" =>
      MapSet.new([
        {"id", "uuid", false},
        {"transaction_id", "uuid", false},
        {"table_schema", "text", false},
        {"table_name", "text", false},
        {"table_pk", "jsonb", false},
        {"op", "text", false},
        {"data_after", "jsonb", true},
        {"changed_fields", "text[]", true},
        {"changed_from", "jsonb", true},
        {"captured_at", "timestamp with time zone", false}
      ]),
    "audit_actions" =>
      MapSet.new([
        {"id", "uuid", false},
        {"name", "text", false},
        {"actor_ref", "jsonb", false},
        {"status", "text", false},
        {"verb", "text", true},
        {"category", "text", true},
        {"reason", "text", true},
        {"comment", "text", true},
        {"correlation_id", "text", true},
        {"request_id", "text", true},
        {"job_id", "text", true},
        {"inserted_at", "timestamp with time zone", false}
      ])
  }

  # {index name, unique?, ordered key columns, partial-index predicate}.
  @indexes %{
    "audit_transactions" =>
      MapSet.new([
        {"audit_transactions_pkey", true, ["id"], nil},
        {"audit_transactions_txid_key", true, ["txid"], nil},
        {"audit_transactions_txid_idx", false, ["txid"], nil},
        {"audit_transactions_actor_ref_gin", false, ["actor_ref"], nil}
      ]),
    "audit_changes" =>
      MapSet.new([
        {"audit_changes_pkey", true, ["id"], nil},
        {"audit_changes_transaction_id_idx", false, ["transaction_id"], nil},
        {"audit_changes_table_name_idx", false, ["table_name"], nil},
        {"audit_changes_captured_at_idx", false, ["captured_at"], nil},
        {
          "audit_changes_row_history_idx",
          false,
          ["table_schema", "table_name", "table_pk", "captured_at", "id"],
          nil
        }
      ]),
    "audit_actions" =>
      MapSet.new([
        {"audit_actions_pkey", true, ["id"], nil},
        {"audit_actions_actor_ref_idx", false, ["actor_ref"], nil},
        {"audit_actions_inserted_at_idx", false, ["inserted_at"], nil},
        {"audit_actions_name_idx", false, ["name"], nil}
      ])
  }

  test "installed audit tables match the literal live catalog contract" do
    schema = Threadline.StorageSchema.get()
    assert is_binary(schema) and schema != "", "configured storage schema is empty"

    relations =
      Repo.query!(
        """
        SELECT c.relname
          FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
         WHERE n.nspname = $1
           AND c.relkind IN ('r', 'p')
           AND c.relname = ANY($2)
        """,
        [schema, @tables]
      ).rows
      |> List.flatten()
      |> MapSet.new()

    assert_catalog_set!(relations, MapSet.new(@tables), "#{schema} relation names")

    columns =
      Repo.query!(
        """
        SELECT c.relname, a.attname, format_type(a.atttypid, a.atttypmod), NOT a.attnotnull
          FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
          JOIN pg_attribute a ON a.attrelid = c.oid
         WHERE n.nspname = $1
           AND c.relname = ANY($2)
           AND c.relkind IN ('r', 'p')
           AND a.attnum > 0
           AND NOT a.attisdropped
        """,
        [schema, @tables]
      ).rows
      |> Enum.group_by(&hd/1, fn [_table, name, type, nullable] -> {name, type, nullable} end)
      |> Map.new(fn {table, facts} -> {table, MapSet.new(facts)} end)

    for table <- @tables do
      actual = Map.get(columns, table, MapSet.new())
      assert_catalog_set!(actual, Map.fetch!(@columns, table), "#{schema}.#{table} columns")
    end

    indexes =
      Repo.query!(
        """
        SELECT t.relname,
               i.relname,
               x.indisunique,
               ARRAY(
                 SELECT a.attname
                   FROM unnest(x.indkey) WITH ORDINALITY AS k(attnum, ord)
                   JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = k.attnum
                  WHERE k.ord <= x.indnkeyatts
                  ORDER BY k.ord
               ),
               pg_get_expr(x.indpred, x.indrelid)
          FROM pg_index x
          JOIN pg_class t ON t.oid = x.indrelid
          JOIN pg_class i ON i.oid = x.indexrelid
          JOIN pg_namespace n ON n.oid = t.relnamespace
         WHERE n.nspname = $1
           AND t.relname = ANY($2)
         ORDER BY t.relname, i.relname
        """,
        [schema, @tables]
      ).rows
      |> Enum.group_by(&hd/1, fn [_table, name, unique?, key_columns, predicate] ->
        {name, unique?, key_columns, predicate}
      end)
      |> Map.new(fn {table, facts} -> {table, MapSet.new(facts)} end)

    for table <- @tables do
      actual = Map.get(indexes, table, MapSet.new())
      assert_catalog_set!(actual, Map.fetch!(@indexes, table), "#{schema}.#{table} indexes")
    end
  end

  test "a removed required catalog fact makes the contract red" do
    table = "audit_transactions"
    expected = Map.fetch!(@columns, table)
    actual = MapSet.delete(expected, {"txid", "bigint", false})

    assert_raise ExUnit.AssertionError, ~r/missing=.*txid/, fn ->
      assert_catalog_set!(actual, expected, "mutation control")
    end
  end

  defp assert_catalog_set!(actual, expected, label) do
    missing = MapSet.difference(expected, actual)
    added = MapSet.difference(actual, expected)

    assert MapSet.size(missing) == 0 and MapSet.size(added) == 0,
           "#{label} differs; missing=#{inspect(MapSet.to_list(missing) |> Enum.sort())}, " <>
             "added=#{inspect(MapSet.to_list(added) |> Enum.sort())}"
  end
end
