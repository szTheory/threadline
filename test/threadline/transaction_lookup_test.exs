defmodule Threadline.TransactionLookupTest do
  @moduledoc """
  Covers `Threadline.audit_transaction/2`, `Threadline.transaction_context/2`,
  and their `!` siblings (D-01, D-07..D-19) — the facade lookups built on the
  hidden shared existence fetch `Threadline.Query.TransactionLookup`.
  """

  use Threadline.DataCase

  import Threadline.TelemetryHelpers, only: [attach_telemetry!: 1]

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Investigation.{IncidentBundle, LinkedChange, LinkedTransaction}
  alias Threadline.Retention
  alias Threadline.Semantics.{ActorRef, AuditAction}
  alias Threadline.Test.Repo

  @repo Repo
  @query_event Keyword.fetch!(Repo.config(), :telemetry_prefix) ++ [:query]

  defp insert_transaction(attrs, storage_schema \\ "threadline") do
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

  defp count_query_events(ref, acc \\ 0) do
    receive do
      {@query_event, ^ref, _measurements, _metadata} -> count_query_events(ref, acc + 1)
    after
      100 -> acc
    end
  end

  defp scope_query(query, %{organization_id: org_id}, %{surface: :transaction_header}) do
    where(query, [at], fragment("?->>'organization_id' = ?", at.meta, ^org_id))
  end

  defp scope_query(_query, _scope, _context) do
    raise "scope_query/3 catch-all hit — this test scope fn only handles :transaction_header"
  end

  # Admits the row ([at] binding) but rejects every change ([ac, at] binding) —
  # covers the D-22 scope-parity shape: an existing-but-invisible-changes
  # transaction still returns {:ok, %LinkedTransaction{changes: []}}.
  defp row_visible_changes_hidden_scope_query(query, _scope, %{surface: :transaction_header}) do
    query
  end

  defp row_visible_changes_hidden_scope_query(query, _scope, %{surface: :transaction}) do
    where(query, [ac, _at], false)
  end

  # Rejects the row itself — both surfaces resolve the same way so
  # transaction_context/2 reports :not_found regardless of which query runs
  # first.
  defp row_hidden_scope_query(query, _scope, %{surface: :transaction_header}) do
    where(query, [at], false)
  end

  defp row_hidden_scope_query(query, _scope, %{surface: :transaction}) do
    where(query, [ac, _at], false)
  end

  test "single-subject lookups require :repo before resolving a malformed id" do
    assert_raise KeyError, fn -> Threadline.audit_transaction("garbage") end
    assert_raise KeyError, fn -> Threadline.transaction_context("garbage") end
    assert_raise KeyError, fn -> Threadline.incident_bundle("garbage") end
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

  describe "audit_transaction!/2" do
    test "returns the bare %AuditTransaction{} for an existing id" do
      txn = insert_transaction(%{action_id: nil})

      assert %AuditTransaction{} = result = Threadline.audit_transaction!(txn.id, repo: @repo)
      assert result.id == txn.id
    end

    test "raises NotFoundError with resource :audit_transaction and the passed id for a missing UUID" do
      missing_id = Ecto.UUID.generate()

      error =
        assert_raise Threadline.NotFoundError, fn ->
          Threadline.audit_transaction!(missing_id, repo: @repo)
        end

      assert error.resource == :audit_transaction
      assert error.id == missing_id
    end

    test "raises NotFoundError (not ArgumentError) for \"garbage\"; raises ArgumentError for nil" do
      assert_raise Threadline.NotFoundError, fn ->
        Threadline.audit_transaction!("garbage", repo: @repo)
      end

      assert_raise ArgumentError, fn ->
        Threadline.audit_transaction!(nil, repo: @repo)
      end
    end

    test "preload: raises ArgumentError (allowlist applies to the bang too)" do
      assert_raise ArgumentError, ~r/unknown audit_transaction option key :preload/, fn ->
        Threadline.audit_transaction!(Ecto.UUID.generate(), repo: @repo, preload: [:changes])
      end
    end

    test "a scope-rejected row's bang message leaks nothing and is byte-equal to the missing-row message" do
      distinctive_actor_id = "secret-actor-9f3"
      {:ok, actor} = ActorRef.new(:user, distinctive_actor_id)

      txn =
        insert_transaction(%{
          action_id: nil,
          actor_ref: ActorRef.to_map(actor),
          meta: %{"organization_id" => "org-1"}
        })

      scope_rejected_message =
        assert_raise Threadline.NotFoundError, fn ->
          Threadline.audit_transaction!(txn.id,
            repo: @repo,
            scope: %{organization_id: "org-2"},
            scope_query_fn: &scope_query/3
          )
        end

      scope_rejected_message = Exception.message(scope_rejected_message)

      refute scope_rejected_message =~ distinctive_actor_id
      refute scope_rejected_message =~ "org-"
      refute scope_rejected_message =~ "scope"
      assert scope_rejected_message =~ txn.id

      @repo.delete!(txn, repo_opts("threadline"))

      missing_row_message =
        assert_raise Threadline.NotFoundError, fn ->
          Threadline.audit_transaction!(txn.id, repo: @repo)
        end

      missing_row_message = Exception.message(missing_row_message)

      assert scope_rejected_message == missing_row_message
    end
  end

  describe "transaction_context/2 and transaction_context!/2" do
    test "existing transaction with action and one change returns {:ok, %LinkedTransaction{}} with each change's transaction the same hydrated row" do
      action = insert_action(%{correlation_id: "corr-tc-1", name: "tc.with_change"})
      txn = insert_transaction(%{action_id: action.id})
      change = insert_change(txn, %{table_pk: %{"id" => "tc-1"}})

      assert {:ok, %LinkedTransaction{} = result} =
               Threadline.transaction_context(txn.id, repo: @repo)

      assert result.transaction.id == txn.id
      assert result.action.id == action.id
      assert [%LinkedChange{} = linked_change] = result.changes
      assert linked_change.audit_change.id == change.id
      assert linked_change.transaction == result.transaction
      assert linked_change.action.id == action.id
    end

    test "existing transaction with zero changes returns {:ok, %LinkedTransaction{changes: []}}" do
      action = insert_action(%{correlation_id: "corr-tc-2", name: "tc.no_changes"})
      txn = insert_transaction(%{action_id: action.id})

      assert {:ok, %LinkedTransaction{} = result} =
               Threadline.transaction_context(txn.id, repo: @repo)

      assert result.transaction.id == txn.id
      assert result.action.id == action.id
      assert result.changes == []
    end

    test "a well-formed but missing UUID and a non-UUID binary return {:error, :not_found}; nil and 123 raise ArgumentError" do
      assert {:error, :not_found} =
               Threadline.transaction_context(Ecto.UUID.generate(), repo: @repo)

      assert {:error, :not_found} = Threadline.transaction_context("garbage", repo: @repo)

      assert_raise ArgumentError, ~r/invalid audit transaction id/, fn ->
        Threadline.transaction_context(nil, repo: @repo)
      end

      assert_raise ArgumentError, ~r/invalid audit transaction id/, fn ->
        Threadline.transaction_context(123, repo: @repo)
      end
    end

    test "transaction_context!/2 returns the bare struct for an existing id" do
      txn = insert_transaction(%{action_id: nil})

      assert %LinkedTransaction{} = result = Threadline.transaction_context!(txn.id, repo: @repo)
      assert result.transaction.id == txn.id
    end

    test "transaction_context!/2 raises NotFoundError resource :audit_transaction for a missing UUID and for \"garbage\"; raises ArgumentError for nil" do
      missing_id = Ecto.UUID.generate()

      error =
        assert_raise Threadline.NotFoundError, fn ->
          Threadline.transaction_context!(missing_id, repo: @repo)
        end

      assert error.resource == :audit_transaction
      assert error.id == missing_id

      assert_raise Threadline.NotFoundError, fn ->
        Threadline.transaction_context!("garbage", repo: @repo)
      end

      assert_raise ArgumentError, fn ->
        Threadline.transaction_context!(nil, repo: @repo)
      end
    end

    test "opts containing :surface, :params, or :preload raise ArgumentError from both the plain and bang form" do
      txn = insert_transaction(%{action_id: nil})

      assert_raise ArgumentError, ~r/unknown transaction_context option key :surface/, fn ->
        Threadline.transaction_context(txn.id, repo: @repo, surface: :transaction_header)
      end

      assert_raise ArgumentError, ~r/unknown transaction_context option key :params/, fn ->
        Threadline.transaction_context(txn.id, repo: @repo, params: %{})
      end

      assert_raise ArgumentError, ~r/unknown transaction_context option key :preload/, fn ->
        Threadline.transaction_context(txn.id, repo: @repo, preload: [:transaction])
      end

      assert_raise ArgumentError, ~r/unknown transaction_context option key :surface/, fn ->
        Threadline.transaction_context!(txn.id, repo: @repo, surface: :transaction_header)
      end
    end

    test "storage_schema: \"audit\" finds an audit-schema transaction; the same id without storage_schema is {:error, :not_found}" do
      ensure_storage_schema!("audit")
      txn = insert_transaction(%{action_id: nil}, "audit")

      assert {:ok, result} =
               Threadline.transaction_context(txn.id, repo: @repo, storage_schema: "audit")

      assert result.transaction.id == txn.id
      assert {:error, :not_found} = Threadline.transaction_context(txn.id, repo: @repo)
    end

    test "a scope fn admitting the row but rejecting every change returns {:ok, %LinkedTransaction{changes: []}}" do
      txn = insert_transaction(%{action_id: nil})
      insert_change(txn, %{table_pk: %{"id" => "tc-scope-hidden"}})

      assert {:ok, %LinkedTransaction{} = result} =
               Threadline.transaction_context(txn.id,
                 repo: @repo,
                 scope: :pass,
                 scope_query_fn: &row_visible_changes_hidden_scope_query/3
               )

      assert result.transaction.id == txn.id
      assert result.changes == []
    end

    test "a scope fn rejecting the row returns {:error, :not_found}" do
      txn = insert_transaction(%{action_id: nil})

      assert {:error, :not_found} =
               Threadline.transaction_context(txn.id,
                 repo: @repo,
                 scope: :pass,
                 scope_query_fn: &row_hidden_scope_query/3
               )
    end
  end

  describe "incident_bundle/2 and incident_bundle!/2" do
    test "incident_bundle!/2 returns the bare struct for an existing id" do
      txn = insert_transaction(%{action_id: nil})

      assert %IncidentBundle{} = result = Threadline.incident_bundle!(txn.id, repo: @repo)
      assert result.transaction.id == txn.id
    end

    test "incident_bundle!/2 raises NotFoundError resource :audit_transaction for a missing UUID and for \"garbage\"; raises ArgumentError for nil and 123" do
      missing_id = Ecto.UUID.generate()

      error =
        assert_raise Threadline.NotFoundError, fn ->
          Threadline.incident_bundle!(missing_id, repo: @repo)
        end

      assert error.resource == :audit_transaction
      assert error.id == missing_id

      assert_raise Threadline.NotFoundError, fn ->
        Threadline.incident_bundle!("garbage", repo: @repo)
      end

      assert_raise ArgumentError, fn ->
        Threadline.incident_bundle!(nil, repo: @repo)
      end

      assert_raise ArgumentError, fn ->
        Threadline.incident_bundle!(123, repo: @repo)
      end
    end

    test "opts containing :surface, :params, or :preload raise ArgumentError from both the plain and bang form" do
      txn = insert_transaction(%{action_id: nil})

      assert_raise ArgumentError, ~r/unknown incident_bundle option key :surface/, fn ->
        Threadline.incident_bundle(txn.id, repo: @repo, surface: :transaction)
      end

      assert_raise ArgumentError, ~r/unknown incident_bundle option key :params/, fn ->
        Threadline.incident_bundle(txn.id, repo: @repo, params: %{})
      end

      assert_raise ArgumentError, ~r/unknown incident_bundle option key :preload/, fn ->
        Threadline.incident_bundle(txn.id, repo: @repo, preload: [:transaction])
      end

      assert_raise ArgumentError, ~r/unknown incident_bundle option key :surface/, fn ->
        Threadline.incident_bundle!(txn.id, repo: @repo, surface: :transaction)
      end
    end
  end

  describe "query count" do
    test "incident_bundle/2 issues at most 3 repo query events for a transaction with an action and two changes" do
      action = insert_action(%{correlation_id: "corr-qc-1", name: "qc.with_action"})
      txn = insert_transaction(%{action_id: action.id})
      insert_change(txn, %{table_pk: %{"id" => "qc-1"}})
      insert_change(txn, %{table_pk: %{"id" => "qc-2"}})

      ref = attach_telemetry!([@query_event])
      assert {:ok, _bundle} = Threadline.incident_bundle(txn.id, repo: @repo)
      assert count_query_events(ref) <= 3
    end

    test "incident_bundle/2 issues at most 2 repo query events when action_id is nil" do
      txn = insert_transaction(%{action_id: nil})
      insert_change(txn, %{table_pk: %{"id" => "qc-3"}})

      ref = attach_telemetry!([@query_event])
      assert {:ok, _bundle} = Threadline.incident_bundle(txn.id, repo: @repo)
      assert count_query_events(ref) <= 2
    end
  end

  describe "zero-change transactions via retention" do
    setup do
      prev = Application.get_env(:threadline, :retention)
      on_exit(fn -> Application.put_env(:threadline, :retention, prev) end)
      :ok
    end

    test "a transaction whose only change is purged with delete_empty_transactions: false still exists for audit_transaction/2, transaction_context/2, and incident_bundle/2" do
      Application.put_env(:threadline, :retention,
        enabled: true,
        keep_days: 1,
        delete_empty_transactions: false
      )

      action = insert_action(%{correlation_id: "corr-retention", name: "retention.purged"})
      cutoff = DateTime.utc_now(:microsecond)
      past = DateTime.add(cutoff, -10, :day)
      txn = insert_transaction(%{action_id: action.id, occurred_at: cutoff})

      @repo.insert!(
        AuditChange.changeset(%{
          transaction_id: txn.id,
          table_schema: "public",
          table_name: "users",
          table_pk: %{"id" => "retention-victim"},
          op: "insert",
          data_after: %{},
          captured_at: past
        }),
        repo_opts("threadline")
      )

      assert %{deleted_changes: 1, deleted_transactions: 0} =
               Retention.purge(repo: @repo, batch_size: 10, max_batches: 5)

      assert {:ok, %AuditTransaction{} = row} = Threadline.audit_transaction(txn.id, repo: @repo)
      assert row.id == txn.id

      assert {:ok, %LinkedTransaction{changes: []}} =
               Threadline.transaction_context(txn.id, repo: @repo)

      assert {:ok, %IncidentBundle{changes: []}} =
               Threadline.incident_bundle(txn.id, repo: @repo)
    end
  end

  describe "scope parity across lookups" do
    test "a row-rejecting scope fn returns {:error, :not_found} from all three lookups; bang messages are byte-equal to the post-delete messages" do
      txn = insert_transaction(%{action_id: nil})

      assert {:error, :not_found} =
               Threadline.audit_transaction(txn.id,
                 repo: @repo,
                 scope: :pass,
                 scope_query_fn: &row_hidden_scope_query/3
               )

      assert {:error, :not_found} =
               Threadline.transaction_context(txn.id,
                 repo: @repo,
                 scope: :pass,
                 scope_query_fn: &row_hidden_scope_query/3
               )

      assert {:error, :not_found} =
               Threadline.incident_bundle(txn.id,
                 repo: @repo,
                 scope: :pass,
                 scope_query_fn: &row_hidden_scope_query/3
               )

      audit_transaction_scope_rejected =
        assert_raise(Threadline.NotFoundError, fn ->
          Threadline.audit_transaction!(txn.id,
            repo: @repo,
            scope: :pass,
            scope_query_fn: &row_hidden_scope_query/3
          )
        end)
        |> Exception.message()

      transaction_context_scope_rejected =
        assert_raise(Threadline.NotFoundError, fn ->
          Threadline.transaction_context!(txn.id,
            repo: @repo,
            scope: :pass,
            scope_query_fn: &row_hidden_scope_query/3
          )
        end)
        |> Exception.message()

      incident_bundle_scope_rejected =
        assert_raise(Threadline.NotFoundError, fn ->
          Threadline.incident_bundle!(txn.id,
            repo: @repo,
            scope: :pass,
            scope_query_fn: &row_hidden_scope_query/3
          )
        end)
        |> Exception.message()

      @repo.delete!(txn, repo_opts("threadline"))

      audit_transaction_missing =
        assert_raise(Threadline.NotFoundError, fn ->
          Threadline.audit_transaction!(txn.id, repo: @repo)
        end)
        |> Exception.message()

      transaction_context_missing =
        assert_raise(Threadline.NotFoundError, fn ->
          Threadline.transaction_context!(txn.id, repo: @repo)
        end)
        |> Exception.message()

      incident_bundle_missing =
        assert_raise(Threadline.NotFoundError, fn ->
          Threadline.incident_bundle!(txn.id, repo: @repo)
        end)
        |> Exception.message()

      assert audit_transaction_scope_rejected == audit_transaction_missing
      assert transaction_context_scope_rejected == transaction_context_missing
      assert incident_bundle_scope_rejected == incident_bundle_missing
    end

    test "existing ordering (newer change first, ties by id desc) still holds for incident_bundle/2" do
      action = insert_action(%{correlation_id: "corr-order", name: "order.check"})
      txn = insert_transaction(%{action_id: action.id})
      older = ~U[2026-09-04 09:00:00.000000Z]
      newer = DateTime.add(older, 60, :second)

      older_change = insert_change(txn, %{table_pk: %{"id" => "order-older"}, captured_at: older})
      newer_change = insert_change(txn, %{table_pk: %{"id" => "order-newer"}, captured_at: newer})

      assert {:ok, %IncidentBundle{changes: [first, second]}} =
               Threadline.incident_bundle(txn.id, repo: @repo)

      assert first.linked_change.audit_change.id == newer_change.id
      assert second.linked_change.audit_change.id == older_change.id
    end
  end
end
