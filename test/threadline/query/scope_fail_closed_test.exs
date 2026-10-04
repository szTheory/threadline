defmodule Threadline.Query.ScopeFailClosedTest do
  @moduledoc """
  Covers `Threadline.Query.Scope.apply/2` (D-20) — a misconfigured `:scope`
  (no usable `:scope_query_fn`) must raise instead of silently reading
  unscoped. A `nil` `:scope` is the host's explicit unscoped authorization
  and stays unscoped even when a function is configured.
  """

  use Threadline.DataCase

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Test.Repo

  @repo Repo

  defp insert_transaction(attrs \\ %{}, storage_schema \\ "threadline") do
    defaults = %{txid: System.unique_integer([:positive]), occurred_at: DateTime.utc_now()}

    @repo.insert!(
      AuditTransaction.changeset(Map.merge(defaults, attrs)),
      repo_opts(storage_schema)
    )
  end

  defp insert_change(transaction, attrs \\ %{}, storage_schema \\ "threadline") do
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

  describe "Scope.apply/2 rules via timeline/2" do
    test "a non-nil scope with no scope_query_fn raises ArgumentError without leaking the scope" do
      transaction = insert_transaction()
      insert_change(transaction)

      error =
        assert_raise ArgumentError, fn ->
          Threadline.timeline([repo: @repo], scope: %{org: "tenant-secret-7"})
        end

      assert error.message =~ ":scope_query_fn"
      refute error.message =~ "tenant-secret-7"
    end

    test "a non-nil scope with a wrong-arity scope_query_fn raises ArgumentError mentioning arity 3" do
      transaction = insert_transaction()
      insert_change(transaction)

      error =
        assert_raise ArgumentError, fn ->
          Threadline.timeline([repo: @repo],
            scope: %{org: "a"},
            scope_query_fn: fn q, _s -> q end
          )
        end

      assert error.message =~ "3"
    end

    test "a nil scope with a wrong-arity scope_query_fn still raises ArgumentError (wiring error)" do
      transaction = insert_transaction()
      insert_change(transaction)

      assert_raise ArgumentError, fn ->
        Threadline.timeline([repo: @repo], scope: nil, scope_query_fn: fn q, _s -> q end)
      end
    end

    test "a nil scope with a 3-arity scope_query_fn reads unscoped and never calls the fn" do
      transaction = insert_transaction()
      insert_change(transaction)

      test_pid = self()

      three_arity_fn = fn query, scope, context ->
        send(test_pid, {:scope_fn_called, query, scope, context})
        query
      end

      results =
        Threadline.timeline([repo: @repo], scope: nil, scope_query_fn: three_arity_fn)

      assert length(results) == 1
      refute_received {:scope_fn_called, _, _, _}
    end

    test "no scope and no scope_query_fn stays unscoped" do
      transaction = insert_transaction()
      insert_change(transaction)

      results = Threadline.timeline(repo: @repo)
      assert length(results) == 1
    end

    test "a scope with a 3-arity fn filters to only matching changes" do
      matching_transaction = insert_transaction()
      insert_change(matching_transaction, %{table_pk: %{"id" => "match"}})

      other_transaction = insert_transaction()
      insert_change(other_transaction, %{table_pk: %{"id" => "nomatch"}})

      scope_query_fn = fn query, scope, _context ->
        import Ecto.Query
        where(query, [ac], ac.table_pk["id"] == ^scope.only_id)
      end

      results =
        Threadline.timeline([repo: @repo],
          scope: %{only_id: "match"},
          scope_query_fn: scope_query_fn
        )

      assert length(results) == 1
      assert hd(results).table_pk["id"] == "match"
    end
  end
end
