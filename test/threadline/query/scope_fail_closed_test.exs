defmodule Threadline.Query.ScopeFailClosedTest do
  @moduledoc """
  Covers `Threadline.Query.Scope.apply/2` (D-20) — a misconfigured `:scope`
  (no usable `:scope_query_fn`) must raise instead of silently reading
  unscoped. A `nil` `:scope` is the host's explicit unscoped authorization
  and stays unscoped even when a function is configured.
  """

  use Threadline.DataCase

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Semantics.{ActorRef, AuditAction}
  alias Threadline.Test.Repo

  @repo Repo

  defmodule FakeUser do
    use Ecto.Schema

    @primary_key {:id, :string, autogenerate: false}
    schema "users" do
      field(:name, :string)
    end
  end

  # A 3-arity fn that never gets called when it shouldn't — proves the
  # fail-closed matrix reaches the fn at all when scope is nil, and never
  # silently widens when the scope is non-nil and misconfigured.
  defp unscoped_marker_fn do
    test_pid = self()

    fn query, scope, context ->
      send(test_pid, {:scope_fn_called, scope, context})
      query
    end
  end

  defp bad_scope, do: %{org: "tenant-secret-7"}

  describe "every scoped read fails closed (D-20/D-22)" do
    setup do
      actor = actor!(:user, "investigator")
      actor_ref = ActorRef.to_map(actor)
      transaction = insert_transaction(%{actor_ref: actor_ref})

      action =
        @repo.insert!(
          AuditAction.changeset(%AuditAction{}, %{
            name: "scope_fail_closed.test",
            actor_ref: actor_ref,
            status: :ok,
            correlation_id: "scope-fail-closed-corr-1"
          }),
          repo_opts()
        )

      @repo.update!(Ecto.Changeset.change(transaction, action_id: action.id), repo_opts())
      transaction = @repo.get!(AuditTransaction, transaction.id, repo_opts())

      insert_change(transaction, %{table_pk: %{"id" => "user-1"}})

      %{transaction: transaction, actor: actor, correlation_id: "scope-fail-closed-corr-1"}
    end

    test "timeline_page/2", %{} do
      assert_raise ArgumentError, fn ->
        Threadline.timeline_page([repo: @repo], scope: bad_scope())
      end

      marker_fn = unscoped_marker_fn()
      page = Threadline.timeline_page([repo: @repo], scope: nil, scope_query_fn: marker_fn)
      assert length(page.entries) == 1
      refute_received {:scope_fn_called, _, _}
    end

    test "row_history/3 list", %{} do
      assert_raise ArgumentError, fn ->
        Threadline.row_history(FakeUser, "user-1", repo: @repo, scope: bad_scope())
      end

      marker_fn = unscoped_marker_fn()

      entries =
        Threadline.row_history(FakeUser, "user-1",
          repo: @repo,
          scope: nil,
          scope_query_fn: marker_fn
        )

      assert length(entries) == 1
      refute_received {:scope_fn_called, _, _}
    end

    test "row_history/3 cursor: :start", %{} do
      assert_raise ArgumentError, fn ->
        Threadline.row_history(FakeUser, "user-1",
          repo: @repo,
          cursor: :start,
          scope: bad_scope()
        )
      end

      marker_fn = unscoped_marker_fn()

      page =
        Threadline.row_history(FakeUser, "user-1",
          repo: @repo,
          cursor: :start,
          scope: nil,
          scope_query_fn: marker_fn
        )

      assert length(page.entries) == 1
      refute_received {:scope_fn_called, _, _}
    end

    test "actor_history/2", %{actor: actor} do
      assert_raise ArgumentError, fn ->
        Threadline.actor_history(actor, repo: @repo, scope: bad_scope())
      end

      marker_fn = unscoped_marker_fn()
      page = Threadline.actor_history(actor, repo: @repo, scope: nil, scope_query_fn: marker_fn)
      assert length(page.entries) == 1
      refute_received {:scope_fn_called, _, _}
    end

    test "actor_window/3", %{actor: actor} do
      assert_raise ArgumentError, fn ->
        Threadline.actor_window(actor, [], repo: @repo, scope: bad_scope())
      end

      marker_fn = unscoped_marker_fn()

      entries =
        Threadline.actor_window(actor, [], repo: @repo, scope: nil, scope_query_fn: marker_fn)

      assert length(entries) == 1
      refute_received {:scope_fn_called, _, _}
    end

    test "correlation_bundle/3", %{correlation_id: correlation_id} do
      assert_raise ArgumentError, fn ->
        Threadline.correlation_bundle(correlation_id, [], repo: @repo, scope: bad_scope())
      end

      marker_fn = unscoped_marker_fn()

      entries =
        Threadline.correlation_bundle(correlation_id, [],
          repo: @repo,
          scope: nil,
          scope_query_fn: marker_fn
        )

      assert length(entries) == 1
      refute_received {:scope_fn_called, _, _}
    end

    test "audit_changes_for_transaction/2", %{transaction: transaction} do
      assert_raise ArgumentError, fn ->
        Threadline.audit_changes_for_transaction(transaction.id, repo: @repo, scope: bad_scope())
      end

      marker_fn = unscoped_marker_fn()

      changes =
        Threadline.audit_changes_for_transaction(transaction.id,
          repo: @repo,
          scope: nil,
          scope_query_fn: marker_fn
        )

      assert length(changes) == 1
      refute_received {:scope_fn_called, _, _}
    end

    test "audit_transaction/2", %{transaction: transaction} do
      assert_raise ArgumentError, fn ->
        Threadline.audit_transaction(transaction.id, repo: @repo, scope: bad_scope())
      end

      marker_fn = unscoped_marker_fn()

      assert {:ok, _} =
               Threadline.audit_transaction(transaction.id,
                 repo: @repo,
                 scope: nil,
                 scope_query_fn: marker_fn
               )
    end

    test "transaction_context/2", %{transaction: transaction} do
      assert_raise ArgumentError, fn ->
        Threadline.transaction_context(transaction.id, repo: @repo, scope: bad_scope())
      end

      marker_fn = unscoped_marker_fn()

      assert {:ok, _} =
               Threadline.transaction_context(transaction.id,
                 repo: @repo,
                 scope: nil,
                 scope_query_fn: marker_fn
               )
    end

    test "incident_bundle/2", %{transaction: transaction} do
      assert_raise ArgumentError, fn ->
        Threadline.incident_bundle(transaction.id, repo: @repo, scope: bad_scope())
      end

      marker_fn = unscoped_marker_fn()

      assert {:ok, _} =
               Threadline.incident_bundle(transaction.id,
                 repo: @repo,
                 scope: nil,
                 scope_query_fn: marker_fn
               )
    end

    test "export_csv/2", %{} do
      assert_raise ArgumentError, fn ->
        Threadline.export_csv([repo: @repo], scope: bad_scope())
      end

      marker_fn = unscoped_marker_fn()

      assert {:ok, _} =
               Threadline.export_csv([repo: @repo], scope: nil, scope_query_fn: marker_fn)
    end

    test "export_json/2", %{} do
      assert_raise ArgumentError, fn ->
        Threadline.export_json([repo: @repo], scope: bad_scope())
      end

      marker_fn = unscoped_marker_fn()

      assert {:ok, _} =
               Threadline.export_json([repo: @repo], scope: nil, scope_query_fn: marker_fn)
    end

    test "audit_transaction!/2 raises ArgumentError (not NotFoundError) for a misconfigured scope",
         %{transaction: transaction} do
      error =
        assert_raise ArgumentError, fn ->
          Threadline.audit_transaction!(transaction.id, repo: @repo, scope: bad_scope())
        end

      assert error.message =~ ":scope_query_fn"
    end

    test "transaction_context!/2 raises ArgumentError (not NotFoundError) for a misconfigured scope",
         %{transaction: transaction} do
      error =
        assert_raise ArgumentError, fn ->
          Threadline.transaction_context!(transaction.id, repo: @repo, scope: bad_scope())
        end

      assert error.message =~ ":scope_query_fn"
    end

    test "incident_bundle!/2 raises ArgumentError (not NotFoundError) for a misconfigured scope",
         %{transaction: transaction} do
      error =
        assert_raise ArgumentError, fn ->
          Threadline.incident_bundle!(transaction.id, repo: @repo, scope: bad_scope())
        end

      assert error.message =~ ":scope_query_fn"
    end
  end

  defp actor!(type, id) do
    {:ok, ref} = ActorRef.new(type, id)
    ref
  end

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
