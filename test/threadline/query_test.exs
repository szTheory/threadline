defmodule Threadline.QueryTest do
  use Threadline.DataCase

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Semantics.{ActorRef, AuditAction}

  @repo Threadline.Test.Repo

  # ── Helpers ──────────────────────────────────────────────────────────────

  defp insert_transaction(attrs \\ %{}) do
    defaults = %{txid: System.unique_integer([:positive]), occurred_at: DateTime.utc_now()}
    @repo.insert!(AuditTransaction.changeset(Map.merge(defaults, attrs)))
  end

  defp insert_change(transaction, attrs \\ %{}) do
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

    @repo.insert!(AuditChange.changeset(Map.merge(defaults, Map.new(attrs))))
  end

  defp actor!(type, id) do
    {:ok, ref} = ActorRef.new(type, id)
    ref
  end

  defp as_of_row_fixture do
    inserted_at = DateTime.add(DateTime.utc_now(), -90, :second)
    updated_at = DateTime.add(inserted_at, 30, :second)
    deleted_at = DateTime.add(updated_at, 30, :second)

    insert_transaction(%{occurred_at: inserted_at})
    |> then(fn txn ->
      insert_change(txn,
        table_name: "users",
        table_pk: %{"id" => "u-asof"},
        op: "insert",
        data_after: %{"id" => "u-asof", "name" => "Alpha"},
        changed_fields: ["id", "name"],
        captured_at: inserted_at
      )
    end)

    insert_transaction(%{occurred_at: updated_at})
    |> then(fn txn ->
      insert_change(txn,
        table_name: "users",
        table_pk: %{"id" => "u-asof"},
        op: "update",
        data_after: %{"id" => "u-asof", "name" => "Beta"},
        changed_fields: ["name"],
        captured_at: updated_at
      )
    end)

    insert_transaction(%{occurred_at: deleted_at})
    |> then(fn txn ->
      insert_change(txn,
        table_name: "users",
        table_pk: %{"id" => "u-asof"},
        op: "delete",
        data_after: nil,
        changed_fields: nil,
        captured_at: deleted_at
      )
    end)

    %{inserted_at: inserted_at, updated_at: updated_at, deleted_at: deleted_at}
  end

  defmodule FakeAsOfUser do
    use Ecto.Schema

    @primary_key {:id, :string, autogenerate: false}
    schema "users" do
      field(:name, :string)
    end
  end

  defp fake_as_of_schema, do: FakeAsOfUser

  # ── history/3 ─────────────────────────────────────────────────────────────

  describe "as_of/4 — ASOF-01/02/05" do
    test "returns the latest stored snapshot at or before the requested timestamp" do
      %{updated_at: updated_at, deleted_at: deleted_at} = as_of_row_fixture()

      {:ok, row} = Threadline.as_of(fake_as_of_schema(), "u-asof", updated_at, repo: @repo)

      assert row == %{"id" => "u-asof", "name" => "Beta"}
      refute DateTime.compare(updated_at, deleted_at) == :gt
    end

    test "returns an explicit deletion error when the latest snapshot is a delete" do
      %{deleted_at: deleted_at} = as_of_row_fixture()

      assert {:error, :deleted_record} =
               Threadline.as_of(fake_as_of_schema(), "u-asof", deleted_at, repo: @repo)
    end

    test "returns before_audit_horizon when the timestamp predates the first snapshot" do
      %{inserted_at: inserted_at} = as_of_row_fixture()
      before_horizon = DateTime.add(inserted_at, -1, :second)

      assert {:error, :before_audit_horizon} =
               Threadline.as_of(fake_as_of_schema(), "u-asof", before_horizon, repo: @repo)
    end
  end

  describe "as_of/4 — ASOF-03/04" do
    test "returns a schema struct when cast: true is enabled" do
      %{updated_at: updated_at} = as_of_row_fixture()

      {:ok, row} =
        Threadline.as_of(fake_as_of_schema(), "u-asof", updated_at, repo: @repo, cast: true)

      assert %FakeAsOfUser{id: "u-asof", name: "Beta"} = row
    end

    test "ignores historical keys that are no longer in the schema when casting" do
      txn = insert_transaction(%{occurred_at: DateTime.utc_now()})

      insert_change(txn,
        table_name: "users",
        table_pk: %{"id" => "u-legacy"},
        op: "insert",
        data_after: %{"id" => "u-legacy", "name" => "Legacy", "legacy_field" => "old"},
        changed_fields: ["id", "name"],
        captured_at: DateTime.utc_now()
      )

      {:ok, row} =
        Threadline.as_of(fake_as_of_schema(), "u-legacy", DateTime.utc_now(),
          repo: @repo,
          cast: true
        )

      assert %FakeAsOfUser{id: "u-legacy", name: "Legacy"} = row
      refute Map.has_key?(Map.from_struct(row), :legacy_field)
    end

    test "returns an explicit cast error when the snapshot cannot be loaded" do
      txn = insert_transaction(%{occurred_at: DateTime.utc_now()})

      insert_change(txn,
        table_name: "users",
        table_pk: %{"id" => "u-bad"},
        op: "insert",
        data_after: %{"id" => "u-bad", "name" => 123},
        changed_fields: ["id", "name"],
        captured_at: DateTime.utc_now()
      )

      assert {:error, {:cast_error, _}} =
               Threadline.as_of(fake_as_of_schema(), "u-bad", DateTime.utc_now(),
                 repo: @repo,
                 cast: true
               )
    end
  end

  describe "history/3 — QUERY-01" do
    test "returns AuditChange records for the given schema/id, ordered by captured_at desc" do
      txn = insert_transaction()
      t1 = DateTime.add(DateTime.utc_now(), -60, :second)
      t2 = DateTime.utc_now()
      insert_change(txn, %{table_name: "users", table_pk: %{"id" => "u-1"}, captured_at: t1})
      insert_change(txn, %{table_name: "users", table_pk: %{"id" => "u-1"}, captured_at: t2})

      defmodule FakeUser do
        use Ecto.Schema

        schema "users" do
          field(:name, :string)
        end
      end

      results = Threadline.history(FakeUser, "u-1", repo: @repo)
      assert length(results) == 2
      [first | _] = results
      assert DateTime.compare(first.captured_at, t2) in [:eq, :gt]
    end

    test "returns empty list when no records exist for the given id" do
      defmodule FakeUser2 do
        use Ecto.Schema

        schema "users" do
          field(:name, :string)
        end
      end

      assert [] = Threadline.history(FakeUser2, "nonexistent", repo: @repo)
    end

    test "only returns records for the specified table" do
      txn = insert_transaction()
      insert_change(txn, %{table_name: "users", table_pk: %{"id" => "u-1"}})
      insert_change(txn, %{table_name: "posts", table_pk: %{"id" => "u-1"}})

      defmodule FakeUser3 do
        use Ecto.Schema

        schema "users" do
          field(:name, :string)
        end
      end

      results = Threadline.history(FakeUser3, "u-1", repo: @repo)
      assert Enum.all?(results, &(&1.table_name == "users"))
    end

    test "history/3 returns changed_from when the column is populated (BVAL-02)" do
      txn = insert_transaction()

      insert_change(txn, %{
        table_name: "users",
        table_pk: %{"id" => "u-bval"},
        changed_from: %{"status" => "pending"}
      })

      defmodule FakeUserBval do
        use Ecto.Schema

        schema "users" do
          field(:name, :string)
        end
      end

      [row] = Threadline.history(FakeUserBval, "u-bval", repo: @repo)
      assert row.changed_from == %{"status" => "pending"}
    end
  end

  # ── audit_changes_for_transaction/2 — XPLO-02 ─────────────────────────────

  describe "audit_changes_for_transaction/2 — XPLO-02" do
    test "orders multiple changes by captured_at desc (timeline tie-break stack)" do
      txn = insert_transaction()
      t_old = DateTime.add(DateTime.utc_now(), -120, :second)
      t_new = DateTime.utc_now()
      assert DateTime.compare(t_new, t_old) == :gt

      insert_change(txn, %{captured_at: t_old, table_pk: %{"id" => "xplo-a"}})
      insert_change(txn, %{captured_at: t_new, table_pk: %{"id" => "xplo-b"}})

      results = Threadline.Query.audit_changes_for_transaction(txn.id, repo: @repo)
      assert length(results) == 2
      assert DateTime.compare(hd(results).captured_at, t_new) == :eq
    end

    test "Threadline delegator matches Threadline.Query" do
      txn = insert_transaction()
      insert_change(txn, %{table_pk: %{"id" => "xplo-deleg"}})

      q = Threadline.Query.audit_changes_for_transaction(txn.id, repo: @repo)
      t = Threadline.audit_changes_for_transaction(txn.id, repo: @repo)
      assert q == t
    end

    test "returns empty list for well-formed UUID with no matching rows" do
      uuid = Ecto.UUID.generate()
      assert Threadline.audit_changes_for_transaction(uuid, repo: @repo) == []
    end

    test "raises ArgumentError for malformed transaction id" do
      assert_raise ArgumentError, ~r/invalid audit transaction id/, fn ->
        Threadline.audit_changes_for_transaction("not-a-uuid", repo: @repo)
      end
    end

    test "preload: [:transaction] loads AuditTransaction on each change" do
      txn = insert_transaction()
      insert_change(txn, %{table_pk: %{"id" => "xplo-pre"}})

      [row] =
        Threadline.audit_changes_for_transaction(txn.id,
          repo: @repo,
          preload: [:transaction]
        )

      assert %AuditTransaction{} = row.transaction
    end

    test "each listed change round-trips through change_diff/2 (FLOW-TEST-01)" do
      txn = insert_transaction()

      insert_change(txn, %{
        table_pk: %{"id" => "flow-a"},
        op: "insert",
        data_after: %{"name" => "A"},
        changed_fields: nil
      })

      insert_change(txn, %{
        table_pk: %{"id" => "flow-b"},
        op: "update",
        data_after: %{"name" => "B2"},
        changed_fields: ["name"],
        changed_from: %{"name" => "B1"}
      })

      for ch <- Threadline.audit_changes_for_transaction(txn.id, repo: @repo) do
        map = Threadline.change_diff(ch, [])
        assert is_map(map)
        assert Map.has_key?(map, "field_changes")
        assert Jason.encode!(map)
      end
    end
  end

  # ── actor_history/2 ───────────────────────────────────────────────────────

  describe "actor_history/2 — QUERY-02" do
    test "returns AuditTransaction records for the given actor" do
      actor = actor!(:user, "u-42")
      actor_map = ActorRef.to_map(actor)
      insert_transaction(%{actor_ref: actor_map})
      insert_transaction(%{actor_ref: actor_map})
      insert_transaction(%{actor_ref: ActorRef.to_map(actor!(:user, "other"))})

      results = Threadline.actor_history(actor, repo: @repo)
      assert length(results) == 2
    end

    test "returns empty list when no transactions exist for the actor" do
      actor = actor!(:service_account, "svc-999")
      assert [] = Threadline.actor_history(actor, repo: @repo)
    end

    test "anonymous actor returns all anonymous transactions" do
      {:ok, anon} = ActorRef.new(:anonymous)
      anon_map = ActorRef.to_map(anon)
      insert_transaction(%{actor_ref: anon_map})
      insert_transaction(%{actor_ref: anon_map})
      insert_transaction(%{actor_ref: ActorRef.to_map(actor!(:user, "u-1"))})

      results = Threadline.actor_history(anon, repo: @repo)
      assert length(results) == 2
    end
  end

  # ── timeline/1 ────────────────────────────────────────────────────────────

  describe "timeline/1 — QUERY-03" do
    test "rejects unknown filter keys with ArgumentError" do
      assert_raise ArgumentError, ~r/allowed|repo/, fn ->
        Threadline.timeline([repo: @repo, not_a_real_filter: true], [])
      end
    end

    test "returns all AuditChange records when no filters given" do
      txn = insert_transaction()
      insert_change(txn, %{table_name: "users"})
      insert_change(txn, %{table_name: "posts"})

      results = Threadline.timeline(repo: @repo)
      assert length(results) >= 2
    end

    test "filters by table name (string)" do
      txn = insert_transaction()
      insert_change(txn, %{table_name: "users"})
      insert_change(txn, %{table_name: "posts"})

      results = Threadline.timeline(table: "users", repo: @repo)
      assert Enum.all?(results, &(&1.table_name == "users"))
    end

    test "filters by table name (atom)" do
      txn = insert_transaction()
      insert_change(txn, %{table_name: "users"})

      results = Threadline.timeline(table: :users, repo: @repo)
      assert Enum.all?(results, &(&1.table_name == "users"))
    end

    test "filters by from (inclusive)" do
      txn = insert_transaction()
      past = DateTime.add(DateTime.utc_now(), -3600, :second)
      now = DateTime.utc_now()
      insert_change(txn, %{captured_at: past})
      insert_change(txn, %{captured_at: now})

      cutoff = DateTime.add(DateTime.utc_now(), -1800, :second)
      results = Threadline.timeline(from: cutoff, repo: @repo)

      assert Enum.all?(results, fn c ->
               DateTime.compare(c.captured_at, cutoff) in [:gt, :eq]
             end)
    end

    test "filters by to (inclusive)" do
      txn = insert_transaction()
      past = DateTime.add(DateTime.utc_now(), -3600, :second)
      insert_change(txn, %{captured_at: past})
      insert_change(txn, %{captured_at: DateTime.utc_now()})

      cutoff = DateTime.add(DateTime.utc_now(), -1800, :second)
      results = Threadline.timeline(to: cutoff, repo: @repo)

      assert Enum.all?(results, fn c ->
               DateTime.compare(c.captured_at, cutoff) in [:lt, :eq]
             end)
    end

    test "filters by actor_ref via JOIN to audit_transactions" do
      actor = actor!(:user, "u-filtered")
      actor_map = ActorRef.to_map(actor)
      other_actor = actor!(:user, "u-other")

      txn_with_actor = insert_transaction(%{actor_ref: actor_map})
      txn_without = insert_transaction(%{actor_ref: ActorRef.to_map(other_actor)})
      insert_change(txn_with_actor, %{table_name: "users"})
      insert_change(txn_without, %{table_name: "users"})

      results = Threadline.timeline(actor_ref: actor, repo: @repo)
      txn_ids = Enum.map(results, & &1.transaction_id) |> MapSet.new()
      assert MapSet.member?(txn_ids, txn_with_actor.id)
      refute MapSet.member?(txn_ids, txn_without.id)
    end

    test "results are ordered by captured_at desc" do
      txn = insert_transaction()
      t1 = DateTime.add(DateTime.utc_now(), -60, :second)
      t2 = DateTime.utc_now()
      insert_change(txn, %{captured_at: t1})
      insert_change(txn, %{captured_at: t2})

      [first | rest] = Threadline.timeline(repo: @repo)

      for r <- rest do
        assert DateTime.compare(first.captured_at, r.captured_at) in [:gt, :eq]
      end
    end
  end

  # ── DX-03: timeline_repo and filter validation ───────────────────────────

  describe "DX-03: timeline_repo!/2 and validate_timeline_filters!/1" do
    test "timeline/2 raises ArgumentError when :repo is missing" do
      assert_raise ArgumentError, ~r/missing :repo/, fn ->
        Threadline.Query.timeline([table: "users"], [])
      end
    end

    test "timeline/2 raises ArgumentError for unknown filter key before repo issues" do
      assert_raise ArgumentError, ~r/unknown timeline filter key :nope/, fn ->
        Threadline.Query.timeline([nope: true, repo: @repo], [])
      end
    end

    test "timeline/2 raises ArgumentError when :repo is not a module atom" do
      assert_raise ArgumentError, ~r/must be an Ecto\.Repo module/, fn ->
        Threadline.Query.timeline([repo: "MyApp.Repo"], [])
      end
    end

    test "timeline_repo!/2 resolves repo from opts" do
      assert Threadline.Query.timeline_repo!([table: "users"], repo: @repo) == @repo
    end
  end

  # ── QUERY-04: repo option ─────────────────────────────────────────────────

  describe "QUERY-04: repo option" do
    test "history/3 accepts explicit repo" do
      assert is_list(Threadline.history(AuditChange, "nonexistent", repo: @repo))
    end

    test "actor_history/2 accepts explicit repo" do
      actor = actor!(:system, "sys-1")
      assert is_list(Threadline.actor_history(actor, repo: @repo))
    end

    test "timeline/1 accepts repo in filter list" do
      assert is_list(Threadline.timeline(repo: @repo))
    end
  end

  # ── QUERY-05: plain Ecto structs ──────────────────────────────────────────

  describe "LOOP-01: :correlation_id filter" do
    defp insert_action(attrs) do
      actor = actor!(:user, "loop01-user")

      defaults = %{
        name: "test.loop01",
        actor_ref: ActorRef.to_map(actor),
        status: :ok,
        correlation_id: "loop01-cid"
      }

      @repo.insert!(AuditAction.changeset(%AuditAction{}, Map.merge(defaults, attrs)))
    end

    test "validate_timeline_filters!/1 accepts correlation_id" do
      assert :ok ==
               Threadline.Query.validate_timeline_filters!(
                 repo: @repo,
                 correlation_id: "  loop01-cid  "
               )
    end

    test "validate_timeline_filters!/1 rejects nil :correlation_id" do
      assert_raise ArgumentError, ~r/omit/, fn ->
        Threadline.Query.validate_timeline_filters!(repo: @repo, correlation_id: nil)
      end
    end

    test "validate_timeline_filters!/1 rejects blank :correlation_id after trim" do
      assert_raise ArgumentError, fn ->
        Threadline.Query.validate_timeline_filters!(repo: @repo, correlation_id: "   ")
      end
    end

    test "validate_timeline_filters!/1 unknown key still mentions unknown timeline filter" do
      assert_raise ArgumentError, ~r/unknown timeline filter/, fn ->
        Threadline.Query.validate_timeline_filters!(repo: @repo, booya: 1)
      end
    end

    test "timeline/2 applies strict correlation join" do
      tname = "loop01_tbl_#{:erlang.unique_integer([:positive])}"
      action = insert_action(%{correlation_id: "loop01-cid"})
      txn_ok = insert_transaction(%{action_id: action.id})
      txn_no_action = insert_transaction()
      insert_change(txn_no_action, %{table_name: tname})
      insert_change(txn_ok, %{table_name: tname})

      results =
        Threadline.timeline(
          repo: @repo,
          table: tname,
          correlation_id: "loop01-cid"
        )

      assert length(results) == 1
      assert hd(results).transaction_id == txn_ok.id
    end
  end

  describe "QUERY-05: results are plain Ecto structs" do
    test "history/3 returns AuditChange structs" do
      txn = insert_transaction()
      insert_change(txn, %{table_name: "users", table_pk: %{"id" => "s-1"}})

      defmodule FakeUser4 do
        use Ecto.Schema

        schema "users" do
          field(:name, :string)
        end
      end

      [result] = Threadline.history(FakeUser4, "s-1", repo: @repo)
      assert %AuditChange{} = result
    end

    test "actor_history/2 returns AuditTransaction structs" do
      actor = actor!(:admin, "a-99")
      insert_transaction(%{actor_ref: ActorRef.to_map(actor)})

      [result] = Threadline.actor_history(actor, repo: @repo)
      assert %AuditTransaction{} = result
    end

    test "timeline/1 returns AuditChange structs" do
      txn = insert_transaction()
      insert_change(txn)

      results = Threadline.timeline(repo: @repo)
      assert Enum.all?(results, &match?(%AuditChange{}, &1))
    end
  end
end
