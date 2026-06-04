defmodule ThreadlinePhoenix.DemoContractTest do
  @moduledoc """
  Contract tests for SEED-02..05 demo fiction (manifest heroes, delete, redaction, reset).
  """

  use ThreadlinePhoenix.DataCase, async: false

  @moduletag :demo_contract

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Semantics.{ActorRef, AuditAction}
  alias ThreadlinePhoenix.Demo.{Manifest, Reset, Seed}
  alias ThreadlinePhoenix.HelpDesk.{Organization, Ticket}
  alias ThreadlinePhoenix.Repo

  setup do
    Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
      assert :ok = Reset.run()
    end)

    :ok
  end

  describe "SEED-03 manifest heroes" do
    test "acme, offboarded-co orgs and hero tickets 4521 closed and 4518 present" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        acme = Repo.get_by!(Organization, slug: "acme")
        offboarded = Repo.get_by!(Organization, slug: "offboarded-co")

        ticket_4521 = Repo.get_by!(Ticket, organization_id: acme.id, number: 4521)
        ticket_4518 = Repo.get_by!(Ticket, organization_id: acme.id, number: 4518)

        assert ticket_4521.status == "closed"
        assert ticket_4518
        assert offboarded.slug == "offboarded-co"
        assert acme.slug == "acme"
      end)
    end

    test "ticket_replied_and_closed action on #4521 close transaction" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        acme = Repo.get_by!(Organization, slug: "acme")
        ticket = Repo.get_by!(Ticket, organization_id: acme.id, number: 4521)

        close_tx =
          Repo.one!(
            from(at in AuditTransaction,
              join: ac in assoc(at, :changes),
              where: ac.table_name == "tickets",
              where: ac.op == "update",
              where: fragment("?->>'id' = ?", ac.table_pk, ^to_string(ticket.id)),
              where: fragment("?->>'status' = ?", ac.data_after, "closed"),
              order_by: [desc: at.occurred_at],
              limit: 1
            )
          )

        action =
          Repo.one!(
            from(a in AuditAction,
              where: a.id == ^close_tx.action_id,
              where: a.name == "ticket_replied_and_closed"
            )
          )

        assert action.name == "ticket_replied_and_closed"
      end)
    end

    test "close reply insert is redacted on #4521" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        acme = Repo.get_by!(Organization, slug: "acme")
        ticket = Repo.get_by!(Ticket, organization_id: acme.id, number: 4521)

        close_tx =
          Repo.one!(
            from(at in AuditTransaction,
              join: ac in assoc(at, :changes),
              where: ac.table_name == "tickets",
              where: ac.op == "update",
              where: fragment("?->>'id' = ?", ac.table_pk, ^to_string(ticket.id)),
              where: fragment("?->>'status' = ?", ac.data_after, "closed"),
              order_by: [desc: at.occurred_at],
              limit: 1
            )
          )

        reply_change =
          Repo.one!(
            from(ac in AuditChange,
              where: ac.transaction_id == ^close_tx.id,
              where: ac.table_name == "ticket_replies",
              where: ac.op == "insert"
            )
          )

        encoded = Jason.encode!(reply_change.data_after)
        assert encoded =~ "[REDACTED]"
        refute encoded =~ "WALKTHROUGH-INTERNAL-SECRET-4521"
      end)
    end
  end

  describe "SEED-03 leaving agent window" do
    test "agent2 audit transactions fall within demo_last_tuesday through demo_epoch" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        acme = Repo.get_by!(Organization, slug: "acme")
        agent2_id = "33123cc4-da21-5674-b030-e168cee90521"
        {:ok, agent2_ref} = ActorRef.new(:user, agent2_id)
        from_ts = Manifest.last_tuesday()
        to_ts = Manifest.epoch()

        leaving_ticket_ids =
          Repo.all(
            from(t in Ticket,
              where: t.organization_id == ^acme.id,
              where: t.number >= 4601 and t.number <= 4612,
              select: type(t.id, :string)
            )
          )

        count =
          Repo.one!(
            from(at in AuditTransaction,
              join: ac in assoc(at, :changes),
              where: ac.table_name == "tickets",
              where: fragment("?->>'id'", ac.table_pk) in ^leaving_ticket_ids,
              where: fragment("? @> ?::jsonb", at.actor_ref, ^ActorRef.to_map(agent2_ref)),
              where: at.occurred_at >= ^from_ts,
              where: at.occurred_at <= ^to_ts,
              select: count(at.id, :distinct)
            )
          )

        assert count == 12

        ticket_change_count =
          Repo.aggregate(
            from(ac in AuditChange,
              join: at in assoc(ac, :transaction),
              where: ac.table_name == "tickets",
              where: fragment("?->>'id'", ac.table_pk) in ^leaving_ticket_ids,
              where: fragment("? @> ?::jsonb", at.actor_ref, ^ActorRef.to_map(agent2_ref)),
              where: at.occurred_at >= ^from_ts,
              where: at.occurred_at <= ^to_ts
            ),
            :count
          )

        assert ticket_change_count >= 1
      end)
    end
  end

  describe "SEED-05 delete incident" do
    test "hard delete on ticket_replies for #4518 by deleter not closer" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        acme = Repo.get_by!(Organization, slug: "acme")
        _ticket = Repo.get_by!(Ticket, organization_id: acme.id, number: 4518)
        deleter_id = Manifest.user_id(:deleter)
        closer_id = Manifest.user_id(:closer)

        delete_at = DateTime.add(Manifest.last_tuesday(), 2, :hour)

        {_change, at} =
          Repo.one!(
            from(ac in AuditChange,
              join: at in assoc(ac, :transaction),
              where: ac.table_name == "ticket_replies",
              where: ac.op == "delete",
              where: fragment("?->>'organization_id' = ?", at.meta, ^to_string(acme.id)),
              where: at.occurred_at == ^delete_at,
              select: {ac, at}
            )
          )

        assert %Threadline.Semantics.ActorRef{type: :user, id: ^deleter_id} = at.actor_ref
        refute closer_id == deleter_id
      end)
    end
  end

  describe "SEED-02 idempotency and SEED-04 reset recovery" do
    test "double demo.reset keeps heroes and semantic fingerprint stable" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        first = semantic_fingerprint()

        assert first.org_count == 3
        assert first.acme_ticket_count >= 45
        assert first.ticket_4521_number == 4521
        assert first.acme_slug == "acme"

        assert :ok = Reset.run()
        second = semantic_fingerprint()

        assert second.ticket_4521_number == first.ticket_4521_number
        assert second.acme_slug == first.acme_slug
        assert second.org_count == first.org_count
        assert second.acme_ticket_count == first.acme_ticket_count

        acme = Repo.get_by!(Organization, slug: "acme")
        assert Repo.get_by!(Ticket, organization_id: acme.id, number: 4521).status == "closed"
        assert Repo.get_by!(Ticket, organization_id: acme.id, number: 4518)
        assert Repo.get_by!(Organization, slug: "offboarded-co")
      end)
    end

    # Regression guard for CR-01: mix demo.reset (which calls Seed.run/0) followed
    # by mix demo.seed (which calls Seed.run/0 again on an already-populated DB)
    # must not raise Ecto.NoResultsError when no DML fires on the second pass.
    test "Seed.run/0 twice in sequence (reset-then-seed) does not raise" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        assert :ok = Seed.run()
      end)
    end
  end

  describe "SEED-04 org Y retention end state" do
    test "offboarded-co audit footprint purged with manifest retention evidence" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        org_y_id = Manifest.org_id(:offboarded_co)

        assert Seed.RetentionTail.org_y_audit_change_count(org_y_id) == 0

        run_id = Manifest.evidence_run_id(:offboarded_retention)

        subject_ref = %{
          "run_id" => run_id,
          "org_slug" => Manifest.org_slug(:offboarded_co),
          "organization_id" => org_y_id
        }

        records =
          Threadline.Evidence.list_subject_ref_history(
            "retention_run",
            subject_ref,
            repo: Repo
          )

        assert length(records) >= 1
        assert hd(records).subject_ref["run_id"] == run_id
        assert hd(records).detail["narrative"] == "org Y offboard"
      end)
    end
  end

  describe "WALK-04 redaction policy evidence" do
    test "post-demo.seed redaction_policy row matches manifest subject_ref" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        subject_ref = Manifest.evidence_subject_ref(:redaction_policy)

        records =
          Threadline.Evidence.list_subject_ref_history(
            "redaction_policy",
            subject_ref,
            repo: Repo
          )

        assert length(records) >= 1

        record = hd(records)
        assert record.subject == "redaction_policy"
        assert record.subject_ref == %{"policy" => "walk-demo-redaction-policy"}
      end)
    end
  end

  describe "D-05 persona setup actor attribution" do
    test "org_memberships setup rows have non-null actor_ref on transaction" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        import Ecto.Query

        count =
          Repo.one!(
            from(ac in AuditChange,
              join: at in assoc(ac, :transaction),
              where: ac.table_name == "org_memberships",
              where: not is_nil(at.actor_ref),
              select: count(ac.id)
            )
          )

        assert count >= 1,
               "expected ≥1 org_memberships AuditChange with non-null actor_ref, got #{count}"
      end)
    end

    test "org_memberships setup rows are backdated outside the default 24h window" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        import Ecto.Query

        window_start = DateTime.utc_now() |> DateTime.add(-24, :hour)

        in_window_count =
          Repo.one!(
            from(ac in AuditChange,
              join: at in assoc(ac, :transaction),
              where: ac.table_name == "org_memberships",
              where: at.occurred_at >= ^window_start,
              select: count(ac.id)
            )
          )

        assert in_window_count == 0,
               "expected 0 org_memberships setup rows in default 24h window, got #{in_window_count}"
      end)
    end

    test "untracked null-actor setup rows are backdated outside the default 24h window" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        import Ecto.Query

        window_start = DateTime.utc_now() |> DateTime.add(-24, :hour)

        in_window_count =
          Repo.one!(
            from(ac in AuditChange,
              join: at in assoc(ac, :transaction),
              where: is_nil(at.actor_ref),
              where: at.occurred_at >= ^window_start,
              select: count(ac.id)
            )
          )

        assert in_window_count == 0,
               "expected 0 null-actor setup rows in default 24h window, got #{in_window_count}"
      end)
    end
  end

  describe "D-13 in-window variety guarantee" do
    test "default 24h window contains ≥1 INSERT, ≥1 UPDATE, and ≥1 DELETE" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        import Ecto.Query

        window_start = DateTime.utc_now() |> DateTime.add(-24, :hour)

        for op <- ["insert", "update", "delete"] do
          count =
            Repo.one!(
              from(ac in AuditChange,
                join: at in assoc(ac, :transaction),
                where: ac.op == ^op,
                where: at.occurred_at >= ^window_start,
                select: count(ac.id)
              )
            )

          assert count >= 1,
                 "expected ≥1 #{op} in default 24h window, got #{count}"
        end
      end)
    end
  end

  defp semantic_fingerprint do
    acme = Repo.get_by!(Organization, slug: "acme")

    %{
      org_count: Repo.aggregate(Organization, :count, :id),
      acme_ticket_count:
        Repo.aggregate(from(t in Ticket, where: t.organization_id == ^acme.id), :count),
      ticket_4521_number: Repo.get_by!(Ticket, organization_id: acme.id, number: 4521).number,
      acme_slug: acme.slug
    }
  end
end
