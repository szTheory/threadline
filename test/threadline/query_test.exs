defmodule Threadline.QueryTest do
  use Threadline.DataCase

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Semantics.ActorRef

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

    @repo.insert!(AuditChange.changeset(Map.merge(defaults, attrs)))
  end

  defp actor!(type, id) do
    {:ok, ref} = ActorRef.new(type, id)
    ref
  end

  # ── history/3 ─────────────────────────────────────────────────────────────

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
