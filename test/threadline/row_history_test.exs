defmodule Threadline.RowHistoryTest do
  @moduledoc """
  Covers `Threadline.row_history/3` (D-01, D-03, D-04, D-12): the 200-row
  bounded default, `:limit` overrides, the retired `row_history/4` shape as a
  separate unbounded deprecated clause, and the arity-collision proof that
  `/2` and `/3` carry no deprecation.
  """

  use Threadline.DataCase
  import Ecto.Query
  import Threadline.TelemetryHelpers, only: [attach_telemetry!: 1]

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Investigation.LinkedChange

  @truncated_event [:threadline, :row_history, :truncated]

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

      deprecated_row_history_args = [FakeUser, "row-deprecated-unbounded", [], [repo: @repo]]
      results = apply(Threadline, :row_history, deprecated_row_history_args)

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

  describe "row_history/3 cursor mode" do
    defp walk_row_history(schema_module, id, opts, acc \\ []) do
      opts = Keyword.put_new(opts, :cursor, :start)
      page = Threadline.row_history(schema_module, id, opts)
      acc = acc ++ page.entries

      if page.has_more do
        walk_row_history(schema_module, id, Keyword.put(opts, :cursor, page.cursor), acc)
      else
        {acc, page}
      end
    end

    test "walking cursor: :start with page_size: 60 over 250 rows concatenates to limit: :infinity" do
      txn = insert_transaction()
      table_pk = %{"id" => "row-cursor-walk"}
      insert_n_changes(txn, table_pk, 250)

      {walked, _last_page} =
        walk_row_history(FakeUser, "row-cursor-walk", repo: @repo, page_size: 60)

      unbounded =
        Threadline.row_history(FakeUser, "row-cursor-walk", repo: @repo, limit: :infinity)

      assert Enum.map(walked, & &1.audit_change.id) == Enum.map(unbounded, & &1.audit_change.id)
      assert Enum.all?(walked, &match?(%Threadline.Investigation.LinkedChange{}, &1))
    end

    test "walking cursor: :start with page_size: 60 over an exact multiple (240 rows) yields four pages, the last with has_more: false and cursor: nil" do
      txn = insert_transaction()
      table_pk = %{"id" => "row-cursor-exact-multiple"}
      insert_n_changes(txn, table_pk, 240)

      {pages, final_page} =
        walk_counting_pages(FakeUser, "row-cursor-exact-multiple", repo: @repo, page_size: 60)

      assert pages == 4
      assert final_page.has_more == false
      assert final_page.cursor == nil
    end

    defp walk_counting_pages(schema_module, id, opts, page_count \\ 0) do
      opts = Keyword.put_new(opts, :cursor, :start)
      page = Threadline.row_history(schema_module, id, opts)
      page_count = page_count + 1

      if page.has_more do
        walk_counting_pages(schema_module, id, Keyword.put(opts, :cursor, page.cursor), page_count)
      else
        {page_count, page}
      end
    end

    test "every Page entry is a LinkedChange" do
      txn = insert_transaction()
      table_pk = %{"id" => "row-cursor-entries"}
      insert_n_changes(txn, table_pk, 5)

      page = Threadline.row_history(FakeUser, "row-cursor-entries", repo: @repo, cursor: :start)

      assert %Threadline.Page{} = page
      assert Enum.all?(page.entries, &match?(%Threadline.Investigation.LinkedChange{}, &1))
    end

    test ":limit combined with :cursor raises ArgumentError" do
      txn = insert_transaction()
      insert_change(txn, %{table_pk: %{"id" => "row-limit-and-cursor"}})

      assert_raise ArgumentError, fn ->
        Threadline.row_history(FakeUser, "row-limit-and-cursor",
          repo: @repo,
          limit: 5,
          cursor: :start
        )
      end
    end

    test ":page_size without :cursor raises ArgumentError" do
      txn = insert_transaction()
      insert_change(txn, %{table_pk: %{"id" => "row-page-size-no-cursor"}})

      assert_raise ArgumentError, fn ->
        Threadline.row_history(FakeUser, "row-page-size-no-cursor", repo: @repo, page_size: 10)
      end
    end

    test "cursor: nil raises ArgumentError naming :start" do
      txn = insert_transaction()
      insert_change(txn, %{table_pk: %{"id" => "row-cursor-nil"}})

      assert_raise ArgumentError, ~r/:start/, fn ->
        Threadline.row_history(FakeUser, "row-cursor-nil", repo: @repo, cursor: nil)
      end
    end

    test "support scope (scope_query_fn) applies in cursor mode as in bare-list mode" do
      support_time = ~U[2026-10-02 10:00:00.000000Z]
      admin_time = DateTime.add(support_time, 60, :second)

      support_txn = insert_transaction(%{occurred_at: support_time, source: "support"})
      admin_txn = insert_transaction(%{occurred_at: admin_time, source: "admin"})

      table_pk = %{"id" => "row-cursor-scoped"}

      support_change =
        insert_change(support_txn, %{table_pk: table_pk, captured_at: support_time})

      insert_change(admin_txn, %{table_pk: table_pk, captured_at: admin_time})

      page =
        Threadline.row_history(FakeUser, "row-cursor-scoped",
          repo: @repo,
          cursor: :start,
          scope: %{source: "support"},
          scope_query_fn: &scope_by_source/3
        )

      assert Enum.map(page.entries, & &1.audit_change.id) == [support_change.id]
      assert Enum.all?(page.entries, &(&1.transaction.source == "support"))
    end

    defp scope_by_source(query, %{source: source}, %{surface: :row_history}) do
      source_txn_ids =
        from(at in AuditTransaction, where: at.source == ^source, select: at.id)

      from(ac in query, where: ac.transaction_id in subquery(source_txn_ids))
    end

    defp scope_by_source(query, _scope, _context), do: query
  end

  describe "[:threadline, :row_history, :truncated] telemetry" do
    test "201 changes, no :limit: exactly one event with %{limit: 200} and %{schema: FakeUser}" do
      ref = attach_telemetry!([@truncated_event])
      txn = insert_transaction()
      table_pk = %{"id" => "row-telemetry-201"}
      insert_n_changes(txn, table_pk, 201)

      Threadline.row_history(FakeUser, "row-telemetry-201", repo: @repo)

      assert_receive {@truncated_event, ^ref, %{limit: 200}, %{schema: FakeUser}}
      refute_receive {@truncated_event, ^ref, _, _}
    end

    test "exactly 200 changes, no :limit: no event" do
      ref = attach_telemetry!([@truncated_event])
      txn = insert_transaction()
      table_pk = %{"id" => "row-telemetry-200"}
      insert_n_changes(txn, table_pk, 200)

      Threadline.row_history(FakeUser, "row-telemetry-200", repo: @repo)

      refute_receive {@truncated_event, ^ref, _, _}
    end

    test "250 changes with limit: 5, limit: :infinity, or cursor: :start: no event" do
      ref = attach_telemetry!([@truncated_event])
      txn = insert_transaction()
      table_pk = %{"id" => "row-telemetry-250"}
      insert_n_changes(txn, table_pk, 250)

      Threadline.row_history(FakeUser, "row-telemetry-250", repo: @repo, limit: 5)
      Threadline.row_history(FakeUser, "row-telemetry-250", repo: @repo, limit: :infinity)
      Threadline.row_history(FakeUser, "row-telemetry-250", repo: @repo, cursor: :start)

      refute_receive {@truncated_event, ^ref, _, _}
    end
  end

  describe "export/as_of stay unbounded past the row_history default" do
    test "export_json over a 250-change row's table yields 250 changes" do
      tname = "row_history_export_#{System.unique_integer([:positive])}"
      txn = insert_transaction()
      table_pk = %{"id" => "row-export-250"}

      for i <- 1..250 do
        insert_change(txn, %{
          table_name: tname,
          table_pk: table_pk,
          captured_at: DateTime.add(~U[2026-01-01 00:00:00.000000Z], i, :microsecond)
        })
      end

      assert {:ok, %{returned_count: 250, truncated: false}} =
               Threadline.export_json([table: tname, repo: @repo], [])
    end

    test "as_of/4 resolves a snapshot older than the newest 200 changes" do
      txn = insert_transaction()
      table_pk = %{"id" => "row-as-of-250"}
      base = ~U[2026-01-01 00:00:00.000000Z]

      changes =
        for i <- 1..250 do
          insert_change(txn, %{
            table_pk: table_pk,
            data_after: %{"name" => "state-#{i}"},
            captured_at: DateTime.add(base, i, :microsecond)
          })
        end

      # The 10th-oldest change sits well outside row_history/3's default
      # 200-row window (only the newest 200 of 250 are in it).
      tenth_oldest = Enum.at(changes, 9)

      assert {:ok, snapshot} =
               Threadline.as_of(FakeUser, "row-as-of-250", tenth_oldest.captured_at, repo: @repo)

      assert snapshot["name"] == "state-10"
    end
  end
end
