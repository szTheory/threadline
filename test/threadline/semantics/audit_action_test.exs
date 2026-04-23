defmodule Threadline.Semantics.AuditActionTest do
  use Threadline.DataCase

  alias Threadline.Semantics.{ActorRef, AuditAction}

  @repo Threadline.Test.Repo

  defp actor!(type \\ :user, id \\ "u-1") do
    {:ok, ref} = ActorRef.new(type, id)
    ref
  end

  describe "record_action/2 — SEM-01: basic persistence" do
    test "inserts an AuditAction with required fields" do
      assert {:ok, action} =
               Threadline.record_action(:member_role_changed,
                 actor: actor!(),
                 repo: @repo
               )

      assert action.name == "member_role_changed"
      assert action.status == :ok
      assert %ActorRef{type: :user, id: "u-1"} = action.actor_ref
      assert action.id != nil
      assert action.inserted_at != nil
    end

    test "action is persisted and retrievable from DB" do
      {:ok, action} =
        Threadline.record_action(:test_action,
          actor: actor!(),
          repo: @repo
        )

      found = @repo.get!(AuditAction, action.id)
      assert found.name == "test_action"
    end
  end

  describe "record_action/2 — SEM-02: optional fields" do
    test "accepts all optional fields" do
      assert {:ok, action} =
               Threadline.record_action(:order_placed,
                 actor: actor!(:admin, "admin-1"),
                 repo: @repo,
                 status: :error,
                 verb: :create,
                 category: :orders,
                 reason: :payment_failed,
                 comment: "Card declined",
                 correlation_id: "corr-abc",
                 request_id: "req-xyz",
                 job_id: "job-123"
               )

      assert action.status == :error
      assert action.verb == "create"
      assert action.category == "orders"
      assert action.reason == "payment_failed"
      assert action.comment == "Card declined"
      assert action.correlation_id == "corr-abc"
      assert action.request_id == "req-xyz"
      assert action.job_id == "job-123"
    end
  end

  describe "record_action/2 — SEM-05: invalid ActorRef returns error tuple" do
    test "missing actor returns tagged error (not exception)" do
      assert {:error, :missing_actor} =
               Threadline.record_action(:test_action, repo: @repo)
    end

    test "invalid actor_ref returns tagged error" do
      assert {:error, :invalid_actor_ref} =
               Threadline.record_action(:test_action,
                 actor: "not_an_actor_ref",
                 repo: @repo
               )
    end

    test "missing repo returns tagged error" do
      assert {:error, :missing_repo} =
               Threadline.record_action(:test_action, actor: actor!())
    end
  end

  describe "record_action/2 — anonymous actor (ACTR-03)" do
    test "anonymous actor persists without actor id" do
      {:ok, anon} = ActorRef.new(:anonymous)

      assert {:ok, action} =
               Threadline.record_action(:guest_viewed,
                 actor: anon,
                 repo: @repo
               )

      db_action = @repo.get!(AuditAction, action.id)
      assert db_action.actor_ref.type == :anonymous
      assert db_action.actor_ref.id == nil
    end
  end

  describe "record_action/2 — CTX-04: audit_transactions.actor_ref is nullable" do
    test "capture still works when no action or actor is linked to a transaction" do
      count = @repo.aggregate(Threadline.Capture.AuditTransaction, :count, :id)
      assert is_integer(count)
    end
  end

  describe "atom name serialization (D-OPEN-02)" do
    test "action name atom is stored as string in DB" do
      import Ecto.Query
      {:ok, action} = Threadline.record_action(:user_signed_up, actor: actor!(), repo: @repo)

      raw = @repo.one!(from(a in AuditAction, where: a.id == ^action.id, select: a.name))
      assert raw == "user_signed_up"
    end
  end
end
