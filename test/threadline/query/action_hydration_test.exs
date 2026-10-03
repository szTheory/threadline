defmodule Threadline.Query.ActionHydrationTest do
  @moduledoc """
  Covers `Threadline.Query.hydrate_actions/3` (D-08) — the hidden, batched
  replacement for the removed `belongs_to :action` / `has_many :transactions`
  Ecto associations (API-07).
  """

  use Threadline.DataCase

  import Threadline.TelemetryHelpers, only: [attach_telemetry!: 1]

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Query
  alias Threadline.Semantics.{ActorRef, AuditAction}
  alias Threadline.Test.Repo

  @repo Repo
  @query_event Keyword.fetch!(Repo.config(), :telemetry_prefix) ++ [:query]

  defmodule FakeUser do
    use Ecto.Schema

    @primary_key {:id, :string, autogenerate: false}
    schema "users" do
      field(:name, :string)
    end
  end

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
      name: "action_hydration.test",
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

  defp attach_action_query_counter! do
    ref = attach_telemetry!([@query_event])

    count_actions = fn ->
      count_actions_loop(ref, 0)
    end

    {ref, count_actions}
  end

  defp count_actions_loop(ref, acc) do
    receive do
      {@query_event, ^ref, _measurements, %{source: "audit_actions"}} ->
        count_actions_loop(ref, acc + 1)

      {@query_event, ^ref, _measurements, _other} ->
        count_actions_loop(ref, acc)
    after
      100 -> acc
    end
  end

  describe "hydrate_actions/3" do
    test "nil subject returns nil" do
      assert Query.hydrate_actions(nil, @repo, []) == nil
    end

    test "empty list returns empty list and issues zero audit_actions queries" do
      {_ref, count_actions} = attach_action_query_counter!()

      assert Query.hydrate_actions([], @repo, []) == []
      assert count_actions.() == 0
    end

    test "a single transaction with action_id hydrates .action to the matching AuditAction" do
      action = insert_action(%{name: "single.hydrate", correlation_id: "corr-single"})
      txn = insert_transaction(%{action_id: action.id})

      hydrated = Query.hydrate_actions(txn, @repo, [])

      assert %AuditAction{} = hydrated.action
      assert hydrated.action.id == action.id
      assert hydrated.action.name == action.name
      assert hydrated.action.correlation_id == action.correlation_id
    end

    test "a transaction with action_id nil hydrates .action to nil" do
      txn = insert_transaction(%{action_id: nil})

      hydrated = Query.hydrate_actions(txn, @repo, [])

      assert hydrated.action == nil
    end

    test "a list of transactions sharing one action_id issues exactly one audit_actions query, dedupes, and preserves order" do
      shared_action = insert_action(%{name: "shared.action", correlation_id: "corr-shared"})
      t1 = insert_transaction(%{action_id: shared_action.id})
      t2 = insert_transaction(%{action_id: nil})
      t3 = insert_transaction(%{action_id: shared_action.id})

      {_ref, count_actions} = attach_action_query_counter!()

      [h1, h2, h3] = Query.hydrate_actions([t1, t2, t3], @repo, [])

      assert count_actions.() == 1
      assert h1.id == t1.id
      assert h1.action.id == shared_action.id
      assert h2.id == t2.id
      assert h2.action == nil
      assert h3.id == t3.id
      assert h3.action.id == shared_action.id
    end

    test "a list of AuditChange structs with .transaction preloaded hydrates each change.transaction.action, preserving order" do
      action = insert_action(%{name: "change.hydrate", correlation_id: "corr-change"})
      txn = insert_transaction(%{action_id: action.id})

      c1 = insert_change(txn, %{table_pk: %{"id" => "c-1"}})
      c2 = insert_change(txn, %{table_pk: %{"id" => "c-2"}})

      changes =
        [c1, c2]
        |> @repo.preload([:transaction], repo_opts("threadline"))

      [h1, h2] = Query.hydrate_actions(changes, @repo, [])

      assert h1.id == c1.id
      assert h1.transaction.action.id == action.id
      assert h2.id == c2.id
      assert h2.transaction.action.id == action.id
    end

    test "an AuditChange whose .transaction is not preloaded raises ArgumentError naming :transaction" do
      txn = insert_transaction(%{})
      change = insert_change(txn, %{})

      assert_raise ArgumentError, ~r/:transaction/, fn ->
        Query.hydrate_actions([change], @repo, [])
      end
    end

    test "honors the storage_schema prefix: an action in a non-default schema only hydrates when selected" do
      ensure_storage_schema!("audit")

      audit_action =
        insert_action(
          %{name: "audit.schema.action", correlation_id: "corr-audit-schema"},
          "audit"
        )

      # Not persisted — hydrate_actions/3 only reads .action_id off the struct
      # and queries audit_actions directly, so no FK-backed transaction row is
      # needed to prove the storage-schema prefix is honored.
      fake_transaction = %AuditTransaction{action_id: audit_action.id}

      hydrated_with_prefix =
        Query.hydrate_actions(fake_transaction, @repo, storage_schema: "audit")

      assert hydrated_with_prefix.action.id == audit_action.id

      hydrated_without_prefix = Query.hydrate_actions(fake_transaction, @repo, [])
      assert hydrated_without_prefix.action == nil
    end
  end

  describe "deprecated :action preload" do
    import ExUnit.CaptureIO

    defp warning_count(stderr) do
      stderr
      |> String.split("\n")
      |> Enum.count(&String.contains?(&1, "preloading :action is deprecated"))
    end

    test "audit_transaction/2 with preload: :action hydrates .action and warns exactly once" do
      action = insert_action(%{name: "shim.bare", correlation_id: "corr-shim-bare"})
      txn = insert_transaction(%{action_id: action.id})

      {hydrated, stderr} =
        capture_with_result(fn ->
          Query.audit_transaction(txn.id, repo: @repo, preload: :action)
        end)

      assert hydrated.action.id == action.id
      assert warning_count(stderr) == 1
    end

    test "audit_transaction/2 with preload: [:action, :changes] hydrates .action, loads :changes, warns once" do
      action = insert_action(%{name: "shim.list", correlation_id: "corr-shim-list"})
      txn = insert_transaction(%{action_id: action.id})
      insert_change(txn, %{table_pk: %{"id" => "shim-list-1"}})

      {hydrated, stderr} =
        capture_with_result(fn ->
          Query.audit_transaction(txn.id, repo: @repo, preload: [:action, :changes])
        end)

      assert hydrated.action.id == action.id
      assert is_list(hydrated.changes)
      assert length(hydrated.changes) == 1
      assert warning_count(stderr) == 1
    end

    test "audit_changes_for_transaction/2 with preload: [transaction: :action] hydrates transaction.action, warns once" do
      action = insert_action(%{name: "shim.changes.bare", correlation_id: "corr-shim-cb"})
      txn = insert_transaction(%{action_id: action.id})
      insert_change(txn, %{table_pk: %{"id" => "shim-cb-1"}})

      {[change], stderr} =
        capture_with_result(fn ->
          Query.audit_changes_for_transaction(txn.id,
            repo: @repo,
            preload: [transaction: :action]
          )
        end)

      assert change.transaction.action.id == action.id
      assert warning_count(stderr) == 1
    end

    test "audit_changes_for_transaction/2 with preload: [transaction: [:action, :changes]] hydrates action and loads transaction.changes, warns once" do
      action = insert_action(%{name: "shim.changes.list", correlation_id: "corr-shim-cl"})
      txn = insert_transaction(%{action_id: action.id})
      insert_change(txn, %{table_pk: %{"id" => "shim-cl-1"}})

      {[change], stderr} =
        capture_with_result(fn ->
          Query.audit_changes_for_transaction(txn.id,
            repo: @repo,
            preload: [transaction: [:action, :changes]]
          )
        end)

      assert change.transaction.action.id == action.id
      assert is_list(change.transaction.changes)
      assert warning_count(stderr) == 1
    end

    test "audit_transaction/2 with preload: [action: :anything] raises ArgumentError naming :action, no warning" do
      txn = insert_transaction(%{})

      {result, stderr} =
        capture_with_result(fn ->
          try do
            Query.audit_transaction(txn.id, repo: @repo, preload: [action: :anything])
          rescue
            e in ArgumentError -> {:raised, Exception.message(e)}
          end
        end)

      assert {:raised, message} = result
      assert message =~ ":action"
      assert warning_count(stderr) == 0
    end

    test "audit_changes_for_transaction/2 with preload: [transaction: [action: :anything]] raises ArgumentError naming :action, no warning" do
      txn = insert_transaction(%{})

      {result, stderr} =
        capture_with_result(fn ->
          try do
            Query.audit_changes_for_transaction(txn.id,
              repo: @repo,
              preload: [transaction: [action: :anything]]
            )
          rescue
            e in ArgumentError -> {:raised, Exception.message(e)}
          end
        end)

      assert {:raised, message} = result
      assert message =~ ":action"
      assert warning_count(stderr) == 0
    end

    test "preload: [:transaction] with no :action behaves as before, no warning" do
      txn = insert_transaction(%{})
      change = insert_change(txn, %{table_pk: %{"id" => "shim-plain-1"}})

      {[hydrated_change], stderr} =
        capture_with_result(fn ->
          Query.audit_changes_for_transaction(txn.id, repo: @repo, preload: [:transaction])
        end)

      assert hydrated_change.id == change.id
      assert hydrated_change.transaction.id == txn.id
      assert warning_count(stderr) == 0
    end

    test "internal call paths emit no deprecation warning while still hydrating .action" do
      action = insert_action(%{name: "shim.internal", correlation_id: "corr-shim-internal"})
      txn = insert_transaction(%{action_id: action.id})
      insert_change(txn, %{table_pk: %{"id" => "shim-internal-1"}})

      {{:ok, bundle}, stderr} =
        capture_with_result(fn -> Threadline.incident_bundle(txn.id, repo: @repo) end)

      assert bundle.action.id == action.id
      assert warning_count(stderr) == 0

      {context, context_stderr} =
        capture_with_result(fn -> Threadline.transaction_context(txn.id, repo: @repo) end)

      assert context.action.id == action.id
      assert warning_count(context_stderr) == 0

      {_history, history_stderr} =
        capture_with_result(fn ->
          Threadline.row_history(FakeUser, "user-1", repo: @repo)
        end)

      assert warning_count(history_stderr) == 0

      {{:ok, _tl_bundle}, tl_stderr} =
        capture_with_result(fn ->
          Threadline.incident_bundle(txn.id,
            repo: @repo,
            scope: nil,
            scope_query_fn: nil,
            surface: :transaction,
            params: %{transaction_id: txn.id}
          )
        end)

      assert warning_count(tl_stderr) == 0
    end

    test "audit_transaction/2 with a nonexistent id and preload: :action returns nil" do
      assert Query.audit_transaction(Ecto.UUID.generate(), repo: @repo, preload: :action) == nil
    end

    defp capture_with_result(fun) do
      ref = make_ref()

      stderr =
        capture_io(:stderr, fn ->
          send(self(), {ref, fun.()})
        end)

      receive do
        {^ref, result} -> {result, stderr}
      after
        0 -> flunk("capture_with_result/1 did not receive a result")
      end
    end
  end
end
