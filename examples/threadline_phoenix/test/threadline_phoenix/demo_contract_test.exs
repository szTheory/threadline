defmodule ThreadlinePhoenix.DemoContractTest do
  @moduledoc """
  Contract tests for SEED-02..05 demo fiction (manifest heroes, delete, redaction, reset).
  """

  use ThreadlinePhoenix.DataCase, async: false

  @moduletag :demo_contract

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Governance.ExportJob
  alias Threadline.Semantics.{ActorRef, AuditAction}
  alias Threadline.StorageSchema
  alias ThreadlinePhoenix.Accounts
  alias ThreadlinePhoenix.Accounts.User
  alias ThreadlinePhoenix.Demo.{Manifest, Reset, Seed}
  alias ThreadlinePhoenix.HelpDesk.{Agent, OrgMembership, Organization, Ticket}
  alias ThreadlinePhoenix.Repo

  setup do
    seed_started_at = DateTime.utc_now(:microsecond)

    Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
      assert :ok = Reset.run()
    end)

    seed_finished_at = DateTime.utc_now(:microsecond)

    {:ok, %{seed_started_at: seed_started_at, seed_finished_at: seed_finished_at}}
  end

  describe "D-02 generated export calendar anchor" do
    test "completed downloadable export bytes contain the exact corrected captured_at",
         %{seed_started_at: seed_started_at, seed_finished_at: seed_finished_at} do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        correlation_id = Manifest.correlation_id(:acme_4521_close)

        export_job =
          Repo.all(ExportJob, StorageSchema.repo_opts())
          |> Enum.find(fn job ->
            job.status == "completed" and is_binary(job.file_path) and
              job.query_params["correlation_id"] == correlation_id
          end)

        assert export_job,
               "expected the completed downloadable export for #{correlation_id}"

        run_clock_start = DateTime.truncate(seed_started_at, :second)
        run_clock_end = DateTime.add(DateTime.truncate(seed_finished_at, :second), 1, :second)

        assert DateTime.compare(export_job.inserted_at, run_clock_start) != :lt
        assert DateTime.compare(export_job.inserted_at, run_clock_end) == :lt

        assert DateTime.compare(
                 export_job.expires_at,
                 DateTime.add(export_job.inserted_at, 7, :day)
               ) == :eq

        assert File.read!(export_job.file_path) ==
                 "id,table_name,op,captured_at\ndemo,tickets,update,2026-05-26T14:30:00Z\n"
      end)
    end
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
            ),
            StorageSchema.repo_opts()
          )

        action =
          Repo.one!(
            from(a in AuditAction,
              where: a.id == ^close_tx.action_id,
              where: a.name == "ticket_replied_and_closed"
            ),
            StorageSchema.repo_opts()
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
            ),
            StorageSchema.repo_opts()
          )

        reply_change =
          Repo.one!(
            from(ac in AuditChange,
              where: ac.transaction_id == ^close_tx.id,
              where: ac.table_name == "ticket_replies",
              where: ac.op == "insert"
            ),
            StorageSchema.repo_opts()
          )

        encoded = Jason.encode!(reply_change.data_after)
        assert encoded =~ "[REDACTED]"
        refute encoded =~ "synthetic-secret-canary-239-6f71"
      end)
    end

    test "#4521 row and reply snapshots match the represented close event",
         %{seed_started_at: seed_started_at, seed_finished_at: seed_finished_at} do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        acme = Repo.get_by!(Organization, slug: "acme")
        ticket = Repo.get_by!(Ticket, organization_id: acme.id, number: 4521)
        setup_at = DateTime.add(Manifest.epoch(), -21, :day)
        close_at = Manifest.last_tuesday()
        setup_iso = setup_at |> DateTime.to_naive() |> NaiveDateTime.to_iso8601()
        close_iso = close_at |> DateTime.to_naive() |> NaiveDateTime.to_iso8601()

        ticket_insert =
          Repo.one!(
            from(ac in AuditChange,
              where: ac.table_name == "tickets",
              where: ac.op == "insert",
              where: fragment("?->>'id' = ?", ac.table_pk, ^to_string(ticket.id)),
              limit: 1
            ),
            StorageSchema.repo_opts()
          )

        close_tx =
          Repo.one!(
            from(at in AuditTransaction,
              join: ac in assoc(at, :changes),
              where: ac.table_name == "tickets",
              where: ac.op == "update",
              where: fragment("?->>'id' = ?", ac.table_pk, ^to_string(ticket.id)),
              where: fragment("?->>'status' = ?", ac.data_after, "closed"),
              select: at,
              limit: 1
            ),
            StorageSchema.repo_opts()
          )

        close_change =
          Repo.one!(
            from(ac in AuditChange,
              where: ac.transaction_id == ^close_tx.id,
              where: ac.table_name == "tickets",
              where: ac.op == "update"
            ),
            StorageSchema.repo_opts()
          )

        reply_change =
          Repo.one!(
            from(ac in AuditChange,
              where: ac.transaction_id == ^close_tx.id,
              where: ac.table_name == "ticket_replies",
              where: ac.op == "insert"
            ),
            StorageSchema.repo_opts()
          )

        action = Repo.get!(AuditAction, close_tx.action_id, StorageSchema.repo_opts())

        assert ticket.inserted_at == setup_at
        assert ticket.updated_at == close_at
        assert ticket.closed_at == close_at
        assert ticket_insert.data_after["inserted_at"] == setup_iso
        assert ticket_insert.data_after["updated_at"] == setup_iso
        assert close_change.data_after["inserted_at"] == setup_iso
        assert close_change.data_after["updated_at"] == close_iso
        assert close_change.data_after["closed_at"] == close_iso
        assert DateTime.compare(close_tx.occurred_at, close_at) == :eq
        assert close_tx.actor_ref == %ActorRef{type: :user, id: Manifest.user_id(:closer)}
        assert close_tx.meta["organization_id"] == to_string(acme.id)
        assert action.name == "ticket_replied_and_closed"
        assert action.correlation_id == Manifest.correlation_id(:acme_4521_close)
        assert action.request_id == "demo-seed-4521"
        assert DateTime.compare(seed_started_at, action.inserted_at) in [:lt, :eq]
        assert DateTime.compare(action.inserted_at, seed_finished_at) in [:lt, :eq]
        refute action.inserted_at == close_at

        assert reply_change.data_after["inserted_at"] == close_iso
        assert reply_change.data_after["updated_at"] == close_iso
      end)
    end
  end

  describe "seed setup snapshots" do
    test "audited setup and base ticket writes use S while Sigra users use the reset window",
         %{seed_started_at: seed_started_at, seed_finished_at: seed_finished_at} do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        acme = Repo.get_by!(Organization, slug: "acme")
        setup_at = DateTime.add(Manifest.epoch(), -21, :day)
        setup_iso = snapshot_timestamp(setup_at)
        {:ok, admin_ref} = ActorRef.new(:admin, Manifest.user_id(:admin))

        for {table, actor_ref} <- [
              {"organizations", nil},
              {"org_memberships", admin_ref},
              {"agents", admin_ref}
            ] do
          changes =
            Repo.all(
              from(ac in AuditChange,
                join: at in assoc(ac, :transaction),
                where: ac.table_name == ^table,
                where: ac.op == "insert",
                select: {ac, at}
              ),
              StorageSchema.repo_opts()
            )

          assert changes != [], "expected setup insert snapshots for #{table}"

          for {change, transaction} <- changes do
            assert change.data_after["inserted_at"] == setup_iso
            assert change.data_after["updated_at"] == setup_iso
            assert transaction.actor_ref == actor_ref
          end
        end

        users = Repo.all(User)
        memberships = Repo.all(OrgMembership)
        agents = Repo.all(Agent)

        expected_users =
          Manifest.user_ids()
          |> Enum.map(fn {key, id} -> {Manifest.user_email(key), id} end)
          |> Kernel.++([
            {"agent2@acme.example.com", "33123cc4-da21-5674-b030-e168cee90521"},
            {"agent3@acme.example.com", "fa227cac-3ba9-509f-90a0-dbbc32d348ed"},
            {"agent4@globex.example.com", "27cf320b-2325-5a35-88d0-8e2f0331c368"},
            {"agent5@globex.example.com", "ca9cb4b7-7e94-5da8-af2f-25eab547597b"},
            {"agent6@offboarded-co.example.com", "d605cf4b-5448-59b7-9905-3544fe84bf3b"},
            {"agent7@offboarded-co.example.com", "4d4fa837-6b08-598b-9015-0c23f70532fa"}
          ])

        assert users != []
        assert memberships != []
        assert agents != []

        assert Enum.sort(Enum.map(users, &{&1.email, to_string(&1.id)})) ==
                 Enum.sort(expected_users)

        reset_window_start = DateTime.truncate(seed_started_at, :second)
        reset_window_end = DateTime.add(DateTime.truncate(seed_finished_at, :second), 1, :second)

        for user <- users do
          assert %DateTime{} = user.confirmed_at

          for field <- [:inserted_at, :updated_at, :confirmed_at, :password_changed_at] do
            timestamp = Map.fetch!(user, field)
            assert DateTime.compare(timestamp, reset_window_start) in [:gt, :eq]
            assert DateTime.compare(timestamp, reset_window_end) == :lt
          end
        end

        assert %User{id: admin_id, confirmed_at: %DateTime{}} =
                 Accounts.get_user_by_email_and_password(
                   Manifest.user_email(:admin),
                   Manifest.demo_seed_password()
                 )

        assert to_string(admin_id) == Manifest.user_id(:admin)

        assert Enum.all?(memberships, &(&1.inserted_at == setup_at))
        assert Enum.all?(agents, &(&1.inserted_at == setup_at and &1.updated_at == setup_at))

        ticket = Repo.get_by!(Ticket, organization_id: acme.id, number: 4521)

        ticket_insert_tx =
          Repo.one!(
            from(at in AuditTransaction,
              join: ac in assoc(at, :changes),
              where: ac.table_name == "tickets",
              where: ac.op == "insert",
              where: fragment("?->>'id' = ?", ac.table_pk, ^to_string(ticket.id)),
              select: at
            ),
            StorageSchema.repo_opts()
          )

        assert is_nil(ticket_insert_tx.actor_ref)
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
            ),
            StorageSchema.repo_opts()
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
            :count,
            StorageSchema.repo_opts()
          )

        assert ticket_change_count >= 1
      end)
    end

    test "all twelve agent2 close snapshots match their events and agent3 owns the earlier role change" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        acme = Repo.get_by!(Organization, slug: "acme")
        agent2 = Repo.get_by!(Agent, organization_id: acme.id, display_name: "Agent2")
        agent3 = Repo.get_by!(Agent, organization_id: acme.id, display_name: "Agent3")
        agent2_id = to_string(agent2.user_id)
        {:ok, agent2_ref} = ActorRef.new(:user, agent2_id)
        {:ok, backfill_ref} = ActorRef.new(:system, Manifest.actor_id(:trigger_backfill))

        agent2_membership =
          Repo.get_by!(OrgMembership, organization_id: acme.id, user_id: agent2.user_id)

        agent3_membership =
          Repo.get_by!(OrgMembership, organization_id: acme.id, user_id: agent3.user_id)

        assert agent2_membership.role == "agent"
        assert agent3_membership.role == "support"

        for n <- 1..12 do
          ticket = Repo.get_by!(Ticket, organization_id: acme.id, number: 4600 + n)
          event_at = DateTime.add(Manifest.last_tuesday(), n, :minute)

          {change, transaction} =
            Repo.one!(
              from(ac in AuditChange,
                join: at in assoc(ac, :transaction),
                where: ac.table_name == "tickets",
                where: ac.op == "update",
                where: fragment("?->>'id' = ?", ac.table_pk, ^to_string(ticket.id)),
                select: {ac, at}
              ),
              StorageSchema.repo_opts()
            )

          assert ticket.status == "closed"
          assert DateTime.compare(ticket.closed_at, event_at) == :eq
          assert DateTime.compare(ticket.updated_at, event_at) == :eq
          assert DateTime.compare(transaction.occurred_at, event_at) == :eq
          assert transaction.actor_ref == agent2_ref
          assert change.data_after["closed_at"] == snapshot_timestamp(event_at)
          assert change.data_after["updated_at"] == snapshot_timestamp(event_at)
        end

        agent2_role_change? =
          Repo.exists?(
            from(ac in AuditChange,
              where: ac.table_name == "org_memberships",
              where: ac.op == "update",
              where: fragment("?->>'id' = ?", ac.table_pk, ^to_string(agent2_membership.id)),
              where: fragment("?->>'role' = ?", ac.data_after, "support")
            ),
            StorageSchema.repo_opts()
          )

        refute agent2_role_change?

        {role_change, role_change_tx} =
          Repo.one!(
            from(ac in AuditChange,
              join: at in assoc(ac, :transaction),
              where: ac.table_name == "org_memberships",
              where: ac.op == "update",
              where: fragment("?->>'id' = ?", ac.table_pk, ^to_string(agent3_membership.id)),
              where: fragment("?->>'role' = ?", ac.data_after, "support"),
              select: {ac, at}
            ),
            StorageSchema.repo_opts()
          )

        role_change_at = DateTime.add(Manifest.epoch(), -7, :day)
        assert role_change_tx.actor_ref == backfill_ref
        assert DateTime.compare(role_change_tx.occurred_at, role_change_at) == :eq
        assert role_change.data_after["updated_at"] == snapshot_timestamp(role_change_at)
      end)
    end
  end

  describe "SEED-05 delete incident" do
    test "#4518 closes with a reply before the later capture-only deletion" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        acme = Repo.get_by!(Organization, slug: "acme")
        ticket = Repo.get_by!(Ticket, organization_id: acme.id, number: 4518)
        deleter_id = Manifest.user_id(:deleter)
        closer_id = Manifest.user_id(:closer)
        setup_at = DateTime.add(Manifest.epoch(), -21, :day)
        close_at = DateTime.add(Manifest.last_tuesday(), 1, :hour)
        delete_at = DateTime.add(Manifest.last_tuesday(), 2, :hour)

        ticket_insert =
          Repo.one!(
            from(ac in AuditChange,
              where: ac.table_name == "tickets",
              where: ac.op == "insert",
              where: fragment("?->>'id' = ?", ac.table_pk, ^to_string(ticket.id))
            ),
            StorageSchema.repo_opts()
          )

        {reply_insert, reply_tx} =
          Repo.one!(
            from(ac in AuditChange,
              join: at in assoc(ac, :transaction),
              where: ac.table_name == "ticket_replies",
              where: ac.op == "insert",
              where: fragment("?->>'ticket_id' = ?", ac.data_after, ^to_string(ticket.id)),
              where: at.occurred_at == ^close_at,
              select: {ac, at}
            ),
            StorageSchema.repo_opts()
          )

        {close_change, close_tx} =
          Repo.one!(
            from(ac in AuditChange,
              join: at in assoc(ac, :transaction),
              where: ac.table_name == "tickets",
              where: ac.op == "update",
              where: fragment("?->>'id' = ?", ac.table_pk, ^to_string(ticket.id)),
              where: at.occurred_at == ^close_at,
              select: {ac, at}
            ),
            StorageSchema.repo_opts()
          )

        {delete_change, delete_tx} =
          Repo.one!(
            from(ac in AuditChange,
              join: at in assoc(ac, :transaction),
              where: ac.table_name == "ticket_replies",
              where: ac.op == "delete",
              where: fragment("?->>'organization_id' = ?", at.meta, ^to_string(acme.id)),
              where: at.occurred_at == ^delete_at,
              select: {ac, at}
            ),
            StorageSchema.repo_opts()
          )

        action = Repo.get!(AuditAction, close_tx.action_id, StorageSchema.repo_opts())

        assert ticket.status == "closed"
        assert DateTime.compare(ticket.closed_at, close_at) == :eq
        assert DateTime.compare(ticket.updated_at, close_at) == :eq
        assert ticket_insert.data_after["inserted_at"] == snapshot_timestamp(setup_at)
        assert close_change.data_after["closed_at"] == snapshot_timestamp(close_at)
        assert close_change.data_after["updated_at"] == snapshot_timestamp(close_at)
        assert reply_insert.data_after["inserted_at"] == snapshot_timestamp(close_at)
        assert reply_insert.data_after["updated_at"] == snapshot_timestamp(close_at)
        assert reply_tx.id == close_tx.id
        assert DateTime.compare(reply_tx.occurred_at, close_at) == :eq
        assert DateTime.compare(delete_tx.occurred_at, delete_at) == :eq
        assert delete_tx.id != close_tx.id
        assert delete_change.data_after == nil
        assert delete_change.table_pk["id"] == reply_insert.table_pk["id"]
        assert close_tx.actor_ref == %ActorRef{type: :user, id: closer_id}
        assert delete_tx.actor_ref == %ActorRef{type: :user, id: deleter_id}
        assert action.name == "ticket_replied_and_closed"
        assert action.request_id == "demo-seed-4518-reply"
        assert is_nil(delete_tx.action_id)
      end)
    end
  end

  describe "Globex ordinary close snapshot" do
    test "reply and ticket close snapshots match the represented days-ago event" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        globex = Repo.get_by!(Organization, slug: "globex")
        ticket = Repo.get_by!(Ticket, organization_id: globex.id, number: 2001)
        event_at = DateTime.add(Manifest.epoch(), -3, :day)
        {ticket_change, close_tx} = captured_change("tickets", "update", ticket.id)

        {reply_change, reply_tx} =
          Repo.one!(
            from(ac in AuditChange,
              join: at in assoc(ac, :transaction),
              where: ac.table_name == "ticket_replies",
              where: ac.op == "insert",
              where: fragment("?->>'ticket_id' = ?", ac.data_after, ^to_string(ticket.id)),
              select: {ac, at}
            ),
            StorageSchema.repo_opts()
          )

        action = Repo.get!(AuditAction, close_tx.action_id, StorageSchema.repo_opts())

        assert ticket.status == "closed"
        assert DateTime.compare(ticket.closed_at, event_at) == :eq
        assert DateTime.compare(ticket.updated_at, event_at) == :eq
        assert ticket_change.data_after["closed_at"] == snapshot_timestamp(event_at)
        assert ticket_change.data_after["updated_at"] == snapshot_timestamp(event_at)
        assert reply_change.data_after["inserted_at"] == snapshot_timestamp(event_at)
        assert reply_change.data_after["updated_at"] == snapshot_timestamp(event_at)
        assert reply_tx.id == close_tx.id
        assert DateTime.compare(close_tx.occurred_at, event_at) == :eq
        assert close_tx.actor_ref == %ActorRef{type: :user, id: Manifest.user_id(:support_globex)}
        assert action.name == "ticket_replied_and_closed"
        assert action.request_id == "demo-seed-globex-close"
        assert DateTime.compare(action.inserted_at, event_at) == :gt
      end)
    end
  end

  describe "D-12 current-window story snapshots" do
    test "each story preserves its single run clock, operation order, actor and row snapshots" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        acme = Repo.get_by!(Organization, slug: "acme")
        globex = Repo.get_by!(Organization, slug: "globex")
        support = Repo.get_by!(Agent, organization_id: acme.id, display_name: "Acme Support")
        closer_id = Manifest.user_id(:closer)
        support_id = Manifest.user_id(:support_acme)
        zendesk_id = Manifest.actor_id(:zendesk_sync)
        job_id = Manifest.actor_id(:oban_retention_purge)
        backfill_id = Manifest.actor_id(:trigger_backfill)

        sync_ticket = Repo.get_by!(Ticket, organization_id: acme.id, number: 5005)
        {sync_insert, sync_tx} = captured_change("tickets", "insert", sync_ticket.id)
        run_now = sync_tx.occurred_at |> DateTime.truncate(:second) |> DateTime.add(6, :hour)
        assert run_now.microsecond == {0, 0}

        assert sync_insert.data_after["inserted_at"] ==
                 snapshot_timestamp(DateTime.add(run_now, -6, :hour))

        assert sync_insert.data_after["updated_at"] ==
                 snapshot_timestamp(DateTime.add(run_now, -6, :hour))

        assert sync_insert.data_after["assignee_id"] == to_string(support.id)
        assert sync_tx.actor_ref == %ActorRef{type: :service_account, id: zendesk_id}

        reply_ticket = Repo.get_by!(Ticket, organization_id: acme.id, number: 5001)

        {reply_insert, reply_insert_tx} =
          Repo.one!(
            from(ac in AuditChange,
              join: at in assoc(ac, :transaction),
              where: ac.table_name == "ticket_replies",
              where: ac.op == "insert",
              where: fragment("?->>'ticket_id' = ?", ac.data_after, ^to_string(reply_ticket.id)),
              select: {ac, at}
            ),
            StorageSchema.repo_opts()
          )

        reply_id = reply_insert.table_pk["id"]
        {reply_update, reply_update_tx} = captured_change("ticket_replies", "update", reply_id)
        reply_insert_at = DateTime.add(run_now, -1, :hour)
        reply_update_at = DateTime.add(run_now, -55, :minute)
        assert reply_insert.data_after["inserted_at"] == snapshot_timestamp(reply_insert_at)
        assert reply_insert.data_after["updated_at"] == snapshot_timestamp(reply_insert_at)
        assert reply_update.data_after["updated_at"] == snapshot_timestamp(reply_update_at)
        assert DateTime.compare(reply_insert_tx.occurred_at, reply_insert_at) == :eq
        assert DateTime.compare(reply_update_tx.occurred_at, reply_update_at) == :eq
        assert reply_insert_tx.actor_ref == %ActorRef{type: :service_account, id: zendesk_id}
        assert reply_update_tx.actor_ref == %ActorRef{type: :user, id: closer_id}

        reopen_ticket = Repo.get_by!(Ticket, organization_id: acme.id, number: 5002)
        {reopen_base, _reopen_base_tx} = captured_change("tickets", "insert", reopen_ticket.id)
        setup_at = DateTime.add(Manifest.epoch(), -21, :day)
        assert reopen_base.data_after["status"] == "closed"
        assert reopen_base.data_after["inserted_at"] == snapshot_timestamp(setup_at)
        assert reopen_base.data_after["updated_at"] == snapshot_timestamp(setup_at)

        reopen_updates =
          Repo.all(
            from(ac in AuditChange,
              join: at in assoc(ac, :transaction),
              where: ac.table_name == "tickets",
              where: ac.op == "update",
              where: fragment("?->>'id' = ?", ac.table_pk, ^to_string(reopen_ticket.id)),
              order_by: at.occurred_at,
              select: {ac, at}
            ),
            StorageSchema.repo_opts()
          )

        assert length(reopen_updates) == 2
        [{reopen_change, reopen_tx}, {reassign_change, reassign_tx}] = reopen_updates
        reopen_at = DateTime.add(run_now, -2, :hour)
        reassign_at = DateTime.add(run_now, -110, :minute)
        assert reopen_change.data_after["status"] == "open"
        assert is_nil(reopen_change.data_after["closed_at"])
        assert reopen_change.data_after["updated_at"] == snapshot_timestamp(reopen_at)
        assert DateTime.compare(reopen_tx.occurred_at, reopen_at) == :eq
        assert reopen_tx.actor_ref == %ActorRef{type: :job, id: job_id}
        assert reassign_change.data_after["status"] == "in_progress"
        assert reassign_change.data_after["assignee_id"] == to_string(support.id)
        assert reassign_change.data_after["updated_at"] == snapshot_timestamp(reassign_at)
        assert DateTime.compare(reassign_tx.occurred_at, reassign_at) == :eq
        assert reassign_tx.actor_ref == %ActorRef{type: :user, id: support_id}
        assert reopen_ticket.status == "in_progress"
        assert reopen_ticket.assignee_id == support.id
        assert DateTime.compare(reopen_ticket.updated_at, reassign_at) == :eq

        reply_delete_ticket = Repo.get_by!(Ticket, organization_id: acme.id, number: 5003)

        {spam_insert, spam_insert_tx} =
          Repo.one!(
            from(ac in AuditChange,
              join: at in assoc(ac, :transaction),
              where: ac.table_name == "ticket_replies",
              where: ac.op == "insert",
              where:
                fragment("?->>'ticket_id' = ?", ac.data_after, ^to_string(reply_delete_ticket.id)),
              where: fragment("?->>'body' = ?", ac.data_after, ^"Spam reply to be removed."),
              select: {ac, at}
            ),
            StorageSchema.repo_opts()
          )

        {spam_delete, spam_delete_tx} =
          captured_change("ticket_replies", "delete", spam_insert.table_pk["id"])

        spam_insert_at = DateTime.add(run_now, -4, :hour)
        spam_delete_at = DateTime.add(run_now, -225, :minute)
        assert spam_insert.data_after["inserted_at"] == snapshot_timestamp(spam_insert_at)
        assert spam_insert.data_after["updated_at"] == snapshot_timestamp(spam_insert_at)
        assert spam_delete.data_after == nil
        assert spam_delete.table_pk["id"] == spam_insert.table_pk["id"]
        assert DateTime.compare(spam_insert_tx.occurred_at, spam_insert_at) == :eq
        assert DateTime.compare(spam_delete_tx.occurred_at, spam_delete_at) == :eq
        assert spam_insert_tx.actor_ref == %ActorRef{type: :anonymous, id: nil}
        assert spam_delete_tx.actor_ref == %ActorRef{type: :user, id: closer_id}

        {ticket_5004_insert, ticket_5004_insert_tx} =
          Repo.one!(
            from(ac in AuditChange,
              join: at in assoc(ac, :transaction),
              where: ac.table_name == "tickets",
              where: ac.op == "insert",
              where: fragment("?->>'number' = ?", ac.data_after, ^"5004"),
              where: fragment("?->>'organization_id' = ?", ac.data_after, ^to_string(acme.id)),
              select: {ac, at}
            ),
            StorageSchema.repo_opts()
          )

        {ticket_5004_delete, ticket_5004_delete_tx} =
          captured_change("tickets", "delete", ticket_5004_insert.table_pk["id"])

        setup_at = DateTime.add(Manifest.epoch(), -21, :day)
        ticket_delete_at = DateTime.add(run_now, -5, :hour)
        assert is_nil(ticket_5004_insert_tx.actor_ref)
        assert ticket_5004_insert.data_after["inserted_at"] == snapshot_timestamp(setup_at)
        assert ticket_5004_insert.data_after["updated_at"] == snapshot_timestamp(setup_at)
        assert ticket_5004_delete.data_after == nil
        assert ticket_5004_delete.table_pk["id"] == ticket_5004_insert.table_pk["id"]
        assert DateTime.compare(ticket_5004_delete_tx.occurred_at, ticket_delete_at) == :eq
        assert ticket_5004_delete_tx.actor_ref == %ActorRef{type: :system, id: backfill_id}
        assert is_nil(Repo.get_by(Ticket, organization_id: acme.id, number: 5004))

        stale_ticket = Repo.get_by!(Ticket, organization_id: acme.id, number: 5006)
        {stale_change, stale_tx} = captured_change("tickets", "update", stale_ticket.id)
        stale_at = DateTime.add(run_now, -210, :minute)
        assert stale_change.data_after["closed_at"] == snapshot_timestamp(stale_at)
        assert stale_change.data_after["updated_at"] == snapshot_timestamp(stale_at)
        assert DateTime.compare(stale_tx.occurred_at, stale_at) == :eq
        assert stale_tx.actor_ref == %ActorRef{type: :job, id: job_id}
        assert DateTime.compare(stale_ticket.closed_at, stale_at) == :eq
        assert DateTime.compare(stale_ticket.updated_at, stale_at) == :eq

        backfill_ticket = Repo.get_by!(Ticket, organization_id: acme.id, number: 5007)
        {backfill_change, backfill_tx} = captured_change("tickets", "update", backfill_ticket.id)
        backfill_at = DateTime.add(run_now, -165, :minute)
        assert backfill_change.data_after["updated_at"] == snapshot_timestamp(backfill_at)
        assert DateTime.compare(backfill_tx.occurred_at, backfill_at) == :eq
        assert backfill_tx.actor_ref == %ActorRef{type: :system, id: backfill_id}

        anonymous_ticket = Repo.get_by!(Ticket, organization_id: acme.id, number: 5008)

        {anonymous_insert, anonymous_tx} =
          captured_change("tickets", "insert", anonymous_ticket.id)

        anonymous_at = DateTime.add(run_now, -330, :minute)
        assert anonymous_insert.data_after["inserted_at"] == snapshot_timestamp(anonymous_at)
        assert anonymous_insert.data_after["updated_at"] == snapshot_timestamp(anonymous_at)
        assert DateTime.compare(anonymous_tx.occurred_at, anonymous_at) == :eq
        assert anonymous_tx.actor_ref == %ActorRef{type: :anonymous, id: nil}

        assert Repo.get_by!(Ticket, organization_id: globex.id, number: 2001).status == "closed"
      end)
    end
  end

  describe "ordinary filler snapshots" do
    test "Acme and Globex filler insert/update/delete histories share each event instant" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        for {slug, first_number} <- [{"acme", 5009}, {"globex", 2002}] do
          organization = Repo.get_by!(Organization, slug: slug)
          rows = filler_rows(organization.id, first_number)
          grouped = Enum.group_by(rows, fn {_change, transaction} -> transaction.id end)

          assert map_size(grouped) > 0, "expected #{slug} filler change snapshots"

          for changes <- Map.values(grouped) do
            assert length(changes) == 2
            transaction = elem(hd(changes), 1)
            [{insert, _}] = Enum.filter(changes, fn {change, _} -> change.op == "insert" end)

            [{changed, _}] =
              Enum.filter(changes, fn {change, _} -> change.op in ["update", "delete"] end)

            event_at = transaction.occurred_at

            assert transaction.actor_ref.type == :user
            assert insert.data_after["inserted_at"] == snapshot_timestamp(event_at)
            assert insert.data_after["updated_at"] == snapshot_timestamp(event_at)
            assert is_binary(insert.data_after["assignee_id"])

            case changed.op do
              "update" ->
                assert changed.data_after["updated_at"] == snapshot_timestamp(event_at)

                if changed.data_after["status"] == "closed" do
                  assert changed.data_after["closed_at"] == snapshot_timestamp(event_at)
                end

              "delete" ->
                assert is_nil(changed.data_after)
                assert changed.table_pk == insert.table_pk
            end
          end

          ops = Enum.frequencies_by(rows, fn {change, _} -> change.op end)
          assert ops["insert"] > 0
          assert ops["update"] > 0
          assert ops["delete"] > 0

          assert Enum.any?(rows, fn {change, _} ->
                   change.op == "update" and change.data_after["status"] == "closed"
                 end)
        end
      end)
    end
  end

  describe "SEED-02 idempotency and SEED-04 reset recovery" do
    test "double demo.reset keeps heroes and semantic fingerprint stable" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        first = semantic_fingerprint()
        run_id = Manifest.evidence_run_id(:offboarded_retention)

        subject_ref = %{
          "run_id" => run_id,
          "org_slug" => Manifest.org_slug(:offboarded_co),
          "organization_id" => Manifest.org_id(:offboarded_co)
        }

        assert length(
                 Threadline.Evidence.list_subject_ref_history("retention_run", subject_ref,
                   repo: Repo
                 )
               ) == 3

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
        assert second == first

        assert length(
                 Threadline.Evidence.list_subject_ref_history("retention_run", subject_ref,
                   repo: Repo
                 )
               ) == 3

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

        # Pin the manifest's declared value (CR-03, restored). This is a
        # published demo contract, so a drift in
        # `Manifest.evidence_subject_ref(:redaction_policy)` must be a
        # deliberate, reviewed change — not one silently absorbed by a
        # self-satisfying comparison further down. Verified against
        # examples/threadline_phoenix/lib/threadline_phoenix/demo/manifest.ex
        # before writing this literal.
        assert subject_ref == %{"policy" => "walk-demo-redaction-policy"}

        records =
          Threadline.Evidence.list_subject_ref_history(
            "redaction_policy",
            subject_ref,
            repo: Repo
          )

        assert length(records) >= 1

        record = hd(records)
        assert record.subject == "redaction_policy"
        # Round-trip documentation, not a real assertion (CR-03): this compares
        # a query result against the same value the query filtered on
        # (Threadline.Evidence.list_subject_ref_history/3 puts both `subject`
        # and `subject_ref` into the SQL WHERE clause), so every returned
        # record satisfies this equality by construction. It cannot fail. Kept
        # to document the query's filter contract; the load-bearing assertion
        # is the manifest pin above.
        assert record.subject_ref == subject_ref
      end)
    end
  end

  describe "D-05 persona setup actor attribution" do
    test "org_memberships setup rows have non-null actor_ref on transaction" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        import Ecto.Query

        # Non-emptiness first: an empty org_memberships change set must fail this test,
        # never pass it vacuously by virtue of there being nothing to check.
        total_count =
          Repo.one!(
            from(ac in AuditChange,
              where: ac.table_name == "org_memberships",
              select: count(ac.id)
            ),
            StorageSchema.repo_opts()
          )

        assert total_count >= 1,
               "expected ≥1 org_memberships AuditChange rows to exist, got #{total_count}"

        count =
          Repo.one!(
            from(ac in AuditChange,
              join: at in assoc(ac, :transaction),
              where: ac.table_name == "org_memberships",
              where: not is_nil(at.actor_ref),
              select: count(ac.id)
            ),
            StorageSchema.repo_opts()
          )

        assert count >= 1,
               "expected ≥1 org_memberships AuditChange with non-null actor_ref, got #{count}"
      end)
    end

    test "org_memberships setup rows are backdated outside the default 24h window" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        import Ecto.Query

        # Non-emptiness first: with zero org_memberships rows at all, "0 in window" would
        # pass vacuously without proving anything was actually backdated.
        total_count =
          Repo.one!(
            from(ac in AuditChange,
              where: ac.table_name == "org_memberships",
              select: count(ac.id)
            ),
            StorageSchema.repo_opts()
          )

        assert total_count >= 1,
               "expected ≥1 org_memberships AuditChange rows to exist, got #{total_count}"

        window_start = DateTime.utc_now() |> DateTime.add(-24, :hour)

        # Boundary: `>=` is strict-inclusive on the window's near edge, so a row landing
        # exactly on `window_start` counts as INSIDE the 24h window (and therefore would
        # fail this "outside the window" assertion, not pass it).
        in_window_count =
          Repo.one!(
            from(ac in AuditChange,
              join: at in assoc(ac, :transaction),
              where: ac.table_name == "org_memberships",
              where: at.occurred_at >= ^window_start,
              select: count(ac.id)
            ),
            StorageSchema.repo_opts()
          )

        assert in_window_count == 0,
               "expected 0 org_memberships setup rows in default 24h window, got #{in_window_count}"
      end)
    end

    test "untracked null-actor setup rows are backdated outside the default 24h window" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        import Ecto.Query

        # Non-emptiness first: with zero null-actor rows at all, "0 in window" would pass
        # vacuously without proving anything was actually backdated.
        total_count =
          Repo.one!(
            from(ac in AuditChange,
              join: at in assoc(ac, :transaction),
              where: is_nil(at.actor_ref),
              select: count(ac.id)
            ),
            StorageSchema.repo_opts()
          )

        assert total_count >= 1,
               "expected ≥1 null-actor AuditChange rows to exist, got #{total_count}"

        window_start = DateTime.utc_now() |> DateTime.add(-24, :hour)

        # Boundary: `>=` is strict-inclusive on the window's near edge, so a row landing
        # exactly on `window_start` counts as INSIDE the 24h window (and therefore would
        # fail this "outside the window" assertion, not pass it).
        in_window_count =
          Repo.one!(
            from(ac in AuditChange,
              join: at in assoc(ac, :transaction),
              where: is_nil(at.actor_ref),
              where: at.occurred_at >= ^window_start,
              select: count(ac.id)
            ),
            StorageSchema.repo_opts()
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

        # Set-membership over the distinct operations present in the window, checked
        # independently per op — not a positional/ordered check, so a change in seed
        # emission order can never flip this assertion.
        for op <- ["insert", "update", "delete"] do
          count =
            Repo.one!(
              from(ac in AuditChange,
                join: at in assoc(ac, :transaction),
                where: ac.op == ^op,
                where: at.occurred_at >= ^window_start,
                select: count(ac.id)
              ),
              StorageSchema.repo_opts()
            )

          assert count >= 1,
                 "expected ≥1 #{op} in default 24h window, got #{count}"
        end
      end)
    end
  end

  defp semantic_fingerprint do
    acme = Repo.get_by!(Organization, slug: "acme")
    globex = Repo.get_by!(Organization, slug: "globex")
    offboarded = Repo.get_by!(Organization, slug: "offboarded-co")
    agent2 = Repo.get_by!(Agent, organization_id: acme.id, display_name: "Agent2")
    agent3 = Repo.get_by!(Agent, organization_id: acme.id, display_name: "Agent3")

    %{
      org_count: Repo.aggregate(Organization, :count, :id),
      acme_ticket_count:
        Repo.aggregate(from(t in Ticket, where: t.organization_id == ^acme.id), :count),
      globex_ticket_count:
        Repo.aggregate(from(t in Ticket, where: t.organization_id == ^globex.id), :count),
      ticket_4521_number: Repo.get_by!(Ticket, organization_id: acme.id, number: 4521).number,
      ticket_4518_status: Repo.get_by!(Ticket, organization_id: acme.id, number: 4518).status,
      globex_2001_status: Repo.get_by!(Ticket, organization_id: globex.id, number: 2001).status,
      acme_slug: acme.slug,
      agent2_role:
        Repo.get_by!(OrgMembership, organization_id: acme.id, user_id: agent2.user_id).role,
      agent3_role:
        Repo.get_by!(OrgMembership, organization_id: acme.id, user_id: agent3.user_id).role,
      acme_filler_ops:
        filler_rows(acme.id, 5009) |> Enum.frequencies_by(fn {change, _} -> change.op end),
      globex_filler_ops:
        filler_rows(globex.id, 2002) |> Enum.frequencies_by(fn {change, _} -> change.op end),
      offboarded_ticket_count:
        Repo.aggregate(from(t in Ticket, where: t.organization_id == ^offboarded.id), :count),
      offboarded_audit_changes: Seed.RetentionTail.org_y_audit_change_count(offboarded.id)
    }
  end

  defp captured_change(table, op, row_id) do
    Repo.one!(
      from(ac in AuditChange,
        join: at in assoc(ac, :transaction),
        where: ac.table_name == ^table,
        where: ac.op == ^op,
        where: fragment("?->>'id' = ?", ac.table_pk, ^to_string(row_id)),
        select: {ac, at}
      ),
      StorageSchema.repo_opts()
    )
  end

  defp filler_rows(organization_id, first_number) do
    Repo.all(
      from(ac in AuditChange,
        join: at in assoc(ac, :transaction),
        where: ac.table_name == "tickets",
        where: fragment("?->>'organization_id' = ?", at.meta, ^to_string(organization_id)),
        select: {ac, at}
      ),
      StorageSchema.repo_opts()
    )
    |> Enum.group_by(fn {_change, transaction} -> transaction.id end)
    |> Enum.flat_map(fn {_transaction_id, changes} ->
      inserted_number =
        Enum.find_value(changes, fn {change, _transaction} ->
          if change.op == "insert", do: change.data_after["number"]
        end)

      if is_integer(inserted_number) and inserted_number >= first_number, do: changes, else: []
    end)
  end

  defp snapshot_timestamp(%DateTime{} = timestamp) do
    timestamp |> DateTime.truncate(:second) |> DateTime.to_naive() |> NaiveDateTime.to_iso8601()
  end
end
