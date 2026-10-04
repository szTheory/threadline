defmodule Threadline.TransactionLookupTest do
  @moduledoc """
  Covers `Threadline.audit_transaction/2` (D-01, D-08..D-10, D-13..D-19) — the
  facade lookup built on the hidden shared existence fetch
  `Threadline.Query.TransactionLookup.fetch_row/2`.
  """

  use Threadline.DataCase

  import Threadline.TelemetryHelpers, only: [attach_telemetry!: 1]

  alias Threadline.Capture.AuditTransaction
  alias Threadline.Semantics.{ActorRef, AuditAction}
  alias Threadline.Test.Repo

  @repo Repo

  defp insert_transaction(attrs, storage_schema \\ "threadline") do
    defaults = %{txid: System.unique_integer([:positive]), occurred_at: DateTime.utc_now()}

    @repo.insert!(
      AuditTransaction.changeset(Map.merge(defaults, attrs)),
      repo_opts(storage_schema)
    )
  end

  defp insert_action(attrs, storage_schema \\ "threadline") do
    actor = actor!(:user, "investigator")

    defaults = %{
      name: "transaction_lookup.test",
      actor_ref: ActorRef.to_map(actor),
      status: :ok,
      correlation_id: "corr-default"
    }

    @repo.insert!(
      AuditAction.changeset(%AuditAction{}, Map.merge(defaults, attrs)),
      repo_opts(storage_schema)
    )
  end

  defp actor!(type, id) do
    {:ok, ref} = ActorRef.new(type, id)
    ref
  end

  defp scope_query(query, %{organization_id: org_id}, %{surface: :transaction_header}) do
    where(query, [at], fragment("?->>'organization_id' = ?", at.meta, ^org_id))
  end

  defp scope_query(_query, _scope, _context) do
    raise "scope_query/3 catch-all hit — this test scope fn only handles :transaction_header"
  end

  describe "audit_transaction/2" do
    test "existing transaction with an action returns {:ok, txn} with action hydrated" do
      action = insert_action(%{name: "lookup.with_action", correlation_id: "corr-lookup-1"})
      txn = insert_transaction(%{action_id: action.id})

      assert {:ok, %AuditTransaction{} = result} =
               Threadline.audit_transaction(txn.id, repo: @repo)

      assert result.id == txn.id
      assert %AuditAction{} = result.action
      assert result.action.id == action.id
    end

    test "existing transaction with action_id nil returns {:ok, txn} with action nil" do
      txn = insert_transaction(%{action_id: nil})

      assert {:ok, %AuditTransaction{action: nil} = result} =
               Threadline.audit_transaction(txn.id, repo: @repo)

      assert result.id == txn.id
    end

    test "a well-formed but missing UUID returns {:error, :not_found}" do
      assert {:error, :not_found} =
               Threadline.audit_transaction(Ecto.UUID.generate(), repo: @repo)
    end

    test "a non-UUID binary returns {:error, :not_found}" do
      assert {:error, :not_found} = Threadline.audit_transaction("garbage", repo: @repo)
    end

    test "a non-binary id raises ArgumentError" do
      assert_raise ArgumentError, ~r/invalid audit transaction id/, fn ->
        Threadline.audit_transaction(nil, repo: @repo)
      end

      assert_raise ArgumentError, ~r/invalid audit transaction id/, fn ->
        Threadline.audit_transaction(123, repo: @repo)
      end
    end

    test "opts containing :surface raise ArgumentError naming the key and the allowed set" do
      txn = insert_transaction(%{action_id: nil})

      assert_raise ArgumentError,
                   ~r/unknown audit_transaction option key :surface.*:repo.*:storage_schema.*:scope.*:scope_query_fn/s,
                   fn ->
                     Threadline.audit_transaction(txn.id,
                       repo: @repo,
                       surface: :transaction_header
                     )
                   end
    end

    test "opts containing :params raise ArgumentError naming the key and the allowed set" do
      txn = insert_transaction(%{action_id: nil})

      assert_raise ArgumentError, ~r/unknown audit_transaction option key :params/, fn ->
        Threadline.audit_transaction(txn.id, repo: @repo, params: %{})
      end
    end

    test "opts containing :preload raise ArgumentError naming the key and the allowed set" do
      txn = insert_transaction(%{action_id: nil})

      assert_raise ArgumentError, ~r/unknown audit_transaction option key :preload/, fn ->
        Threadline.audit_transaction(txn.id, repo: @repo, preload: [:changes])
      end
    end

    test "a scope fn keyed only on :transaction_header matches an in-scope row" do
      txn = insert_transaction(%{action_id: nil, meta: %{"organization_id" => "org-1"}})

      assert {:ok, result} =
               Threadline.audit_transaction(txn.id,
                 repo: @repo,
                 scope: %{organization_id: "org-1"},
                 scope_query_fn: &scope_query/3
               )

      assert result.id == txn.id
    end

    test "a scope fn rejecting the row returns {:error, :not_found}" do
      txn = insert_transaction(%{action_id: nil, meta: %{"organization_id" => "org-1"}})

      assert {:error, :not_found} =
               Threadline.audit_transaction(txn.id,
                 repo: @repo,
                 scope: %{organization_id: "org-2"},
                 scope_query_fn: &scope_query/3
               )
    end

    test "the scope fn receives surface: :transaction_header and params: %{transaction_id: id}" do
      txn = insert_transaction(%{action_id: nil})
      test_pid = self()

      capture_fn = fn query, _scope, context ->
        send(test_pid, {:scope_context, context})
        query
      end

      assert {:ok, _} =
               Threadline.audit_transaction(txn.id,
                 repo: @repo,
                 scope: :pass,
                 scope_query_fn: capture_fn
               )

      assert_received {:scope_context, %{surface: :transaction_header, params: params}}
      assert params == %{transaction_id: txn.id}
    end

    test "storage_schema: \"audit\" finds a row inserted in the audit schema" do
      ensure_storage_schema!("audit")
      txn = insert_transaction(%{action_id: nil}, "audit")

      assert {:ok, result} =
               Threadline.audit_transaction(txn.id, repo: @repo, storage_schema: "audit")

      assert result.id == txn.id

      assert {:error, :not_found} = Threadline.audit_transaction(txn.id, repo: @repo)
    end

    test "storage_schema: \"bad schema!\" raises ArgumentError" do
      txn = insert_transaction(%{action_id: nil})

      assert_raise ArgumentError, fn ->
        Threadline.audit_transaction(txn.id, repo: @repo, storage_schema: "bad schema!")
      end
    end

    test "a well-formed nonexistent storage_schema raises Postgrex undefined_table" do
      txn = insert_transaction(%{action_id: nil})

      assert_raise Postgrex.Error, ~r/undefined_table/, fn ->
        Threadline.audit_transaction(txn.id, repo: @repo, storage_schema: "nonexistent_schema")
      end
    end

    test "no [:threadline, ...] telemetry event fires for a not-found call" do
      events = Enum.map(Threadline.Telemetry.__events__(), & &1.name)
      ref = attach_telemetry!(events)

      assert {:error, :not_found} =
               Threadline.audit_transaction(Ecto.UUID.generate(), repo: @repo)

      for event <- events do
        refute_received {^event, ^ref, _measurements, _metadata}
      end
    end
  end
end
