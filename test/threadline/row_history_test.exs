defmodule Threadline.RowHistoryTest do
  @moduledoc """
  Covers `Threadline.row_history/3` (D-01, D-03, D-04, D-12): the 200-row
  bounded default, `:limit` overrides, the retired `row_history/4` shape as a
  separate unbounded deprecated clause, and the arity-collision proof that
  `/2` and `/3` carry no deprecation.
  """

  use Threadline.DataCase

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Investigation.LinkedChange

  @repo Threadline.Test.Repo

  defmodule FakeUser do
    use Ecto.Schema

    @primary_key {:id, :string, autogenerate: false}
    schema "users" do
      field(:name, :string)
    end
  end

  defp insert_transaction(attrs \\ %{}, storage_schema \\ "threadline") do
    defaults = %{txid: System.unique_integer([:positive]), occurred_at: DateTime.utc_now()}

    @repo.insert!(
      AuditTransaction.changeset(Map.merge(defaults, attrs)),
      repo_opts(storage_schema)
    )
  end

  defp insert_change(transaction, attrs, storage_schema \\ "threadline") do
    defaults = %{
      table_schema: "public",
      table_name: "users",
      table_pk: %{"id" => "user-1"},
      op: "insert",
      data_after: %{"name" => "Alice"},
      changed_fields: ["name"],
      captured_at: DateTime.utc_now(),
      transaction_id: transaction.id
    }

    @repo.insert!(
      AuditChange.changeset(Map.merge(defaults, Map.new(attrs))),
      repo_opts(storage_schema)
    )
  end

  # Inserts `n` changes on `table_pk`, each one microsecond apart (strictly
  # increasing `captured_at`, so eager/paged/limited reads all agree on a
  # single unambiguous newest-first order). Returns the inserted changes in
  # insertion (oldest-first) order.
  defp insert_n_changes(txn, table_pk, n, base_time \\ ~U[2026-01-01 00:00:00.000000Z]) do
    for i <- 1..n do
      insert_change(txn, %{
        table_pk: table_pk,
        captured_at: DateTime.add(base_time, i, :microsecond)
      })
    end
  end

  describe "row_history/3 bounded default" do
    test "250 changes on one row returns 200 entries, newest first, as a bare list" do
      txn = insert_transaction()
      table_pk = %{"id" => "row-250"}
      changes = insert_n_changes(txn, table_pk, 250)

      results = Threadline.row_history(FakeUser, "row-250", repo: @repo)

      assert is_list(results)
      assert length(results) == 200
      assert Enum.all?(results, &match?(%LinkedChange{}, &1))

      expected_ids = changes |> Enum.reverse() |> Enum.take(200) |> Enum.map(& &1.id)
      assert Enum.map(results, & &1.audit_change.id) == expected_ids
    end

    test "limit: 5 returns 5 entries" do
      txn = insert_transaction()
      table_pk = %{"id" => "row-limit-5"}
      insert_n_changes(txn, table_pk, 250)

      results = Threadline.row_history(FakeUser, "row-limit-5", repo: @repo, limit: 5)

      assert length(results) == 5
    end

    test "limit: :infinity returns all 250" do
      txn = insert_transaction()
      table_pk = %{"id" => "row-limit-inf"}
      insert_n_changes(txn, table_pk, 250)

      results = Threadline.row_history(FakeUser, "row-limit-inf", repo: @repo, limit: :infinity)

      assert length(results) == 250
    end

    test "limit: 1 returns 1 entry" do
      txn = insert_transaction()
      table_pk = %{"id" => "row-limit-1"}
      insert_n_changes(txn, table_pk, 250)

      results = Threadline.row_history(FakeUser, "row-limit-1", repo: @repo, limit: 1)

      assert length(results) == 1
    end

    test "exactly 200 changes returns 200 entries" do
      txn = insert_transaction()
      table_pk = %{"id" => "row-exact-200"}
      insert_n_changes(txn, table_pk, 200)

      results = Threadline.row_history(FakeUser, "row-exact-200", repo: @repo)

      assert length(results) == 200
    end

    for bad_limit <- [nil, 0, -1, "5"] do
      bad_limit_name = inspect(bad_limit)

      test "limit: #{bad_limit_name} raises ArgumentError mentioning :infinity" do
        txn = insert_transaction()
        row_id = "row-bad-limit-#{System.unique_integer([:positive])}"
        insert_change(txn, %{table_pk: %{"id" => row_id}})
        bad_limit = unquote(Macro.escape(bad_limit))

        assert_raise ArgumentError, ~r/:infinity/, fn ->
          Threadline.row_history(FakeUser, row_id, repo: @repo, limit: bad_limit)
        end
      end
    end

    test "an unknown option key raises ArgumentError listing the allowed keys" do
      txn = insert_transaction()
      insert_change(txn, %{table_pk: %{"id" => "row-unknown-key"}})

      assert_raise ArgumentError, ~r/unknown row_history option key/, fn ->
        Threadline.row_history(FakeUser, "row-unknown-key", repo: @repo, bogus: true)
      end
    end

    test "a 0.12-style row_history(schema, id, from: t, repo: R) call (old filter keys as new opts) still works and is capped" do
      txn = insert_transaction()
      table_pk = %{"id" => "row-filters-style"}
      base = ~U[2026-02-01 00:00:00.000000Z]

      insert_change(txn, %{table_pk: table_pk, captured_at: base})
      insert_change(txn, %{table_pk: table_pk, captured_at: DateTime.add(base, 1, :second)})

      results = Threadline.row_history(FakeUser, "row-filters-style", from: base, repo: @repo)

      assert length(results) == 2
    end
  end

  describe "row_history/4 (deprecated, unbounded)" do
    test "row_history(schema, id, [from: t], repo: R) via apply/3 (deprecated /4) returns all rows unbounded" do
      txn = insert_transaction()
      table_pk = %{"id" => "row-deprecated-unbounded"}
      insert_n_changes(txn, table_pk, 250)

      results = apply(Threadline, :row_history, [FakeUser, "row-deprecated-unbounded", [], [repo: @repo]])

      assert length(results) == 250
      assert Enum.all?(results, &match?(%LinkedChange{}, &1))
    end

    test "Threadline.__info__(:deprecated) contains {:row_history, 4} and not {:row_history, 2} or {:row_history, 3}" do
      deprecated_funs = Threadline.__info__(:deprecated) |> Enum.map(&elem(&1, 0))

      assert {:row_history, 4} in deprecated_funs
      refute {:row_history, 2} in deprecated_funs
      refute {:row_history, 3} in deprecated_funs
    end

    test "Threadline.Investigation.__info__(:deprecated) contains {:row_history, 4} and not {:row_history, 2} or {:row_history, 3}" do
      deprecated_funs =
        Threadline.Investigation.__info__(:deprecated) |> Enum.map(&elem(&1, 0))

      assert {:row_history, 4} in deprecated_funs
      refute {:row_history, 2} in deprecated_funs
      refute {:row_history, 3} in deprecated_funs
    end

    test "compiling a call to row_history/2 and /3 emits no deprecation diagnostic; row_history/4 does" do
      src = """
      defmodule Threadline.RowHistoryTest.DeprecationCaller do
        def run(repo) do
          Threadline.row_history(Threadline.RowHistoryTest.FakeUser, "x")
          Threadline.row_history(Threadline.RowHistoryTest.FakeUser, "x", repo: repo)
          Threadline.row_history(Threadline.RowHistoryTest.FakeUser, "x", [], repo: repo)
        end
      end
      """

      {_result, diagnostics} =
        Code.with_diagnostics(fn ->
          Code.compile_string(src)
        end)

      :code.purge(Threadline.RowHistoryTest.DeprecationCaller)
      :code.delete(Threadline.RowHistoryTest.DeprecationCaller)

      messages = Enum.map(diagnostics, & &1.message)

      assert Enum.any?(messages, &String.contains?(&1, "row_history/4 is deprecated")),
             "expected a diagnostic naming row_history/4 is deprecated, got: #{inspect(messages)}"

      refute Enum.any?(messages, &String.contains?(&1, "row_history/2 is deprecated"))
      refute Enum.any?(messages, &String.contains?(&1, "row_history/3 is deprecated"))
    end
  end
end
