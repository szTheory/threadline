defmodule ThreadlinePhoenix.Demo.Seed.Anchors do
  @moduledoc false

  import Ecto.Query

  alias Threadline.Capture.AuditTransaction
  alias ThreadlinePhoenix.Demo.Manifest
  alias ThreadlinePhoenix.Demo.Seed.Support
  alias ThreadlinePhoenix.HelpDesk
  alias ThreadlinePhoenix.HelpDesk.{Agent, OrgMembership, Ticket, TicketReply}
  alias ThreadlinePhoenix.Repo

  @leaving_agent_tx_count 12

  @doc false
  @spec run(map()) :: map()
  def run(ctx) do
    ctx
    |> seed_acme_close()
    |> seed_acme_delete()
    |> seed_leaving_agent_window()
    |> seed_active_agent_window()
    |> seed_globex_close_sample()
    |> seed_variety_pack()
  end

  # D3 — a currently-active actor. ActorLive's default window keys off
  # `DateTime.utc_now()` (not the demo epoch), so epoch-anchored actors render
  # empty in the default 24h view. These closes are anchored wall-clock-recent
  # so the default Actor view demonstrates a real trajectory. The row count and
  # ops are fixed; only the timestamp base is "now" — deterministic for
  # presence assertions. (Distinct from agent2, whose empty 30d window a
  # screenshot pins — this uses the acme closer and ticket numbers 4700+.)
  defp seed_active_agent_window(ctx) do
    acme = Map.fetch!(ctx.orgs, :acme)
    active_id = to_string(Map.fetch!(ctx.users, :closer).id)
    active_agent = Repo.get_by!(Agent, organization_id: acme.id, user_id: active_id)

    [1, 3, 6]
    |> Enum.with_index()
    |> Enum.reduce(ctx, fn {hours_ago, idx}, acc ->
      ticket_number = 4700 + idx
      ticket = upsert_ticket!(acme, ticket_number, active_agent, "open")

      {:ok, tx_id} =
        Repo.transaction(fn ->
          Support.set_actor_guc!(active_id)

          ticket
          |> Ticket.changeset(%{status: "closed", closed_at: Manifest.epoch()})
          |> Repo.update!()

          Support.stamp_org_meta!(acme)
          Support.current_audit_transaction_id!()
        end)

      ts = DateTime.utc_now() |> DateTime.add(-hours_ago, :hour)
      Support.put_timestamp(acc, tx_id, ts)
    end)
  end

  defp seed_acme_close(ctx) do
    acme = Map.fetch!(ctx.orgs, :acme)
    closer_id = to_string(Map.fetch!(ctx.users, :closer).id)
    closer = Repo.get_by!(Agent, organization_id: acme.id, user_id: closer_id)
    ticket = upsert_ticket!(acme, Manifest.ticket_number(:hero_close), closer, "open")

    ctx_audit =
      Support.audit_context(closer_id,
        correlation_id: Manifest.correlation_id(:acme_4521_close),
        request_id: "demo-seed-4521"
      )

    {:ok, result} =
      HelpDesk.ticket_replied_and_closed(
        ctx_audit,
        acme,
        ticket,
        %{
          body: "Thanks — we're closing this out.",
          internal_note_body: "WALKTHROUGH-INTERNAL-SECRET-4521"
        },
        %{status: "closed", closed_at: Manifest.epoch()},
        []
      )

    Support.put_timestamp(ctx, result.audit_transaction_id, Manifest.last_tuesday())
  end

  defp seed_acme_delete(ctx) do
    acme = Map.fetch!(ctx.orgs, :acme)
    closer_id = to_string(Map.fetch!(ctx.users, :closer).id)
    deleter_id = to_string(Map.fetch!(ctx.users, :deleter).id)
    closer = Repo.get_by!(Agent, organization_id: acme.id, user_id: closer_id)
    ticket = upsert_ticket!(acme, Manifest.ticket_number(:hero_delete), closer, "open")

    closer_ctx = Support.audit_context(closer_id, request_id: "demo-seed-4518-reply")

    {:ok, %{reply: reply}} =
      HelpDesk.ticket_replied_and_closed(
        closer_ctx,
        acme,
        ticket,
        %{body: "Reply slated for deletion demo.", internal_note_body: nil},
        %{status: "open"},
        []
      )

    deleter_ctx = Support.audit_context(deleter_id, request_id: "demo-seed-4518-delete")
    {:ok, :deleted} = HelpDesk.delete_reply(deleter_ctx, acme, reply)

    delete_tx_id =
      Repo.one!(
        from(at in AuditTransaction,
          join: ac in assoc(at, :changes),
          where: ac.table_name == "ticket_replies",
          where: ac.op == "delete",
          where: fragment("?->>'id' = ?", ac.table_pk, ^to_string(reply.id)),
          order_by: [desc: at.occurred_at],
          limit: 1,
          select: at.id
        )
      )

    delete_at =
      Manifest.last_tuesday()
      |> DateTime.add(2, :hour)

    Support.put_timestamp(ctx, delete_tx_id, delete_at)
  end

  defp seed_leaving_agent_window(ctx) do
    acme = Map.fetch!(ctx.orgs, :acme)
    leaving_id = to_string(Map.fetch!(ctx.users, :agent2).id)
    leaving_agent = Repo.get_by!(Agent, organization_id: acme.id, user_id: leaving_id)

    Enum.reduce(1..@leaving_agent_tx_count, ctx, fn n, acc ->
      ticket_number = 4600 + n
      ticket = upsert_ticket!(acme, ticket_number, leaving_agent, "open")

      {:ok, tx_id} =
        Repo.transaction(fn ->
          Support.set_actor_guc!(leaving_id)

          ticket
          |> Ticket.changeset(%{status: "closed", closed_at: Manifest.epoch()})
          |> Repo.update!()

          Support.stamp_org_meta!(acme)
          Support.current_audit_transaction_id!()
        end)

      ts =
        Manifest.last_tuesday()
        |> DateTime.add(n, :minute)

      Support.put_timestamp(acc, tx_id, ts)
    end)
  end

  defp seed_globex_close_sample(ctx) do
    globex = Map.fetch!(ctx.orgs, :globex)
    support_id = to_string(Map.fetch!(ctx.users, :support_globex).id)
    agent = Repo.get_by!(Agent, organization_id: globex.id, user_id: support_id)
    ticket = upsert_ticket!(globex, 2001, agent, "open")

    audit_ctx = Support.audit_context(support_id, request_id: "demo-seed-globex-close")

    {:ok, result} =
      HelpDesk.ticket_replied_and_closed(
        audit_ctx,
        globex,
        ticket,
        %{body: "Globex walkthrough close sample.", internal_note_body: nil},
        %{status: "closed", closed_at: Manifest.epoch()},
        []
      )

    ts = Support.days_ago_timestamp(3)
    Support.put_timestamp(ctx, result.audit_transaction_id, ts)
  end

  defp upsert_ticket!(org, number, %Agent{} = assignee, status) do
    case Repo.get_by(Ticket, organization_id: org.id, number: number) do
      %Ticket{} = ticket ->
        ticket
        |> Ticket.changeset(%{status: status, assignee_id: assignee.id})
        |> Repo.update!()

      nil ->
        %Ticket{organization_id: org.id}
        |> Ticket.changeset(%{number: number, status: status, assignee_id: assignee.id})
        |> Repo.insert!()
    end
  end

  # D-11/D-12 in-window variety pack: ~5 INSERT / 4 UPDATE / 2 DELETE across
  # tickets, ticket_replies, org_memberships. Non-human actor clusters (D-06):
  # - service_account/zendesk-sync    → inbound ticket sync (INSERT + UPDATE)
  # - job/oban-retention-purge        → stale-ticket sweep (UPDATE)
  # - system/trigger-backfill         → backfill correction (UPDATE)
  # - anonymous                       → public form ticket submission (INSERT)
  # All rows use wall-clock-recent timestamps (N ≤ 6h ago) via put_timestamp so
  # they appear in the default 24h Timeline window (D-10, D-13).
  defp seed_variety_pack(ctx) do
    acme = Map.fetch!(ctx.orgs, :acme)
    closer_id = to_string(Map.fetch!(ctx.users, :closer).id)
    closer_agent = Repo.get_by!(Agent, organization_id: acme.id, user_id: closer_id)
    support_id = to_string(Map.fetch!(ctx.users, :support_acme).id)
    support_agent = Repo.get_by!(Agent, organization_id: acme.id, user_id: support_id)

    ctx
    |> seed_variety_reply_edit(acme, closer_agent)
    |> seed_variety_ticket_reopen(acme, support_agent)
    |> seed_variety_membership_role_change(acme, support_agent)
    |> seed_variety_reply_delete(acme, closer_agent)
    |> seed_variety_ticket_delete(acme, support_agent)
    |> seed_variety_zendesk_sync(acme, support_agent)
    |> seed_variety_stale_sweep(acme, closer_agent)
    |> seed_variety_backfill(acme, support_agent)
    |> seed_variety_anon_submission(acme, support_agent)
  end

  # Story 1 (D-12.1/D-14): Reply edited — INSERT then UPDATE with body +
  # internal_note_body → canonical before→after + [REDACTED] diff.
  # Uses service_account/zendesk-sync actor for the INSERT, then
  # a separate user UPDATE (D-06). 1h ago.
  defp seed_variety_reply_edit(ctx, acme, closer_agent) do
    # First insert a reply as zendesk-sync (service_account)
    ticket = upsert_ticket!(acme, 5001, closer_agent, "open")
    zendesk_id = Manifest.actor_id(:zendesk_sync)

    {:ok, {reply, insert_tx_id}} =
      Repo.transaction(fn ->
        Support.set_actor_guc!(zendesk_id, :service_account)

        reply =
          %TicketReply{ticket_id: ticket.id}
          |> TicketReply.changeset(%{
            body: "Original reply from Zendesk sync.",
            internal_note_body: "Internal: route to tier-2"
          })
          |> Repo.insert!()

        Support.stamp_org_meta!(acme)
        tx_id = Support.current_audit_transaction_id!()
        {reply, tx_id}
      end)

    ts_insert = DateTime.utc_now() |> DateTime.add(-1, :hour)
    ctx = Support.put_timestamp(ctx, insert_tx_id, ts_insert)

    # Now update the reply as a human user (closer) — this is the edit that
    # produces the rich before→after diff on ticket_replies.
    closer_id = to_string(closer_agent.user_id)

    {:ok, update_tx_id} =
      Repo.transaction(fn ->
        Support.set_actor_guc!(closer_id)

        reply
        |> TicketReply.changeset(%{
          body: "Updated reply — issue resolved.",
          internal_note_body: "Confirmed tier-2 resolved. Closing."
        })
        |> Repo.update!()

        Support.stamp_org_meta!(acme)
        Support.current_audit_transaction_id!()
      end)

    ts_update = DateTime.utc_now() |> DateTime.add(-1, :hour) |> DateTime.add(5, :minute)
    Support.put_timestamp(ctx, update_tx_id, ts_update)
  end

  # Story 2 (D-12): Ticket reopened/re-triaged — tickets UPDATE status
  # closed→open + cleared closed_at; separate assignee reassignment UPDATE.
  # Uses job/oban-retention-purge actor (stale-ticket sweep). 2h ago.
  defp seed_variety_ticket_reopen(ctx, acme, support_agent) do
    ticket = upsert_ticket!(acme, 5002, support_agent, "closed")
    job_id = Manifest.actor_id(:oban_retention_purge)
    support_agent_id = to_string(support_agent.user_id)

    # Reopen the ticket (status closed→open)
    {:ok, reopen_tx_id} =
      Repo.transaction(fn ->
        Support.set_actor_guc!(job_id, :job)

        ticket
        |> Ticket.changeset(%{status: "open", closed_at: nil})
        |> Repo.update!()

        Support.stamp_org_meta!(acme)
        Support.current_audit_transaction_id!()
      end)

    ts_reopen = DateTime.utc_now() |> DateTime.add(-2, :hour)
    ctx = Support.put_timestamp(ctx, reopen_tx_id, ts_reopen)

    # Reassign the ticket (separate UPDATE)
    {:ok, reassign_tx_id} =
      Repo.transaction(fn ->
        Support.set_actor_guc!(support_agent_id)

        Repo.get!(Ticket, ticket.id)
        |> Ticket.changeset(%{assignee_id: support_agent.id, status: "in_progress"})
        |> Repo.update!()

        Support.stamp_org_meta!(acme)
        Support.current_audit_transaction_id!()
      end)

    ts_reassign = DateTime.utc_now() |> DateTime.add(-2, :hour) |> DateTime.add(10, :minute)
    Support.put_timestamp(ctx, reassign_tx_id, ts_reassign)
  end

  # Story 3 (D-12): Membership role change — org_memberships UPDATE role
  # agent→support. Uses system/trigger-backfill actor. Intentionally EPOCH-relative
  # (backdated 7 days past epoch) so it does NOT appear in the 24h window — the
  # D-05 test asserts no org_memberships appear in-window. D-13's ≥1 UPDATE is
  # satisfied by ticket/ticket_replies in-window updates from stories 1 and 2.
  # Note: org_memberships uses default trigger (after-only, no changed_from) — honest D-09.
  # Uses agent2 who has "agent" role, flipping them to "support" (guaranteed change).
  defp seed_variety_membership_role_change(ctx, acme, _support_agent) do
    backfill_id = Manifest.actor_id(:trigger_backfill)
    agent2_id = to_string(Map.fetch!(ctx.users, :agent2).id)

    # Find agent2's membership in acme (role = "agent" by default)
    membership = Repo.get_by(OrgMembership, organization_id: acme.id, user_id: agent2_id)

    if membership do
      {:ok, tx_id} =
        Repo.transaction(fn ->
          Support.set_actor_guc!(backfill_id, :system)

          # Flip to "support" — guaranteed different from "agent" so Ecto sends SQL UPDATE
          membership
          |> OrgMembership.changeset(%{role: "support"})
          |> Repo.update!()

          Support.stamp_org_meta!(acme)
          Support.current_audit_transaction_id!()
        end)

      # Backdated past epoch — outside 24h window (D-05 constraint)
      ts = DateTime.add(Manifest.epoch(), -7, :day)
      Support.put_timestamp(ctx, tx_id, ts)
    else
      ctx
    end
  end

  # Story 4 (D-12): Reply hard-delete — Repo.delete! a ticket_replies row
  # in-window. Uses anonymous actor (public form). 4h ago.
  defp seed_variety_reply_delete(ctx, acme, closer_agent) do
    # Insert a reply to delete
    ticket = upsert_ticket!(acme, 5003, closer_agent, "open")

    {:ok, {reply, insert_tx_id}} =
      Repo.transaction(fn ->
        Support.set_anonymous_actor_guc!()

        reply =
          %TicketReply{ticket_id: ticket.id}
          |> TicketReply.changeset(%{body: "Spam reply to be removed."})
          |> Repo.insert!()

        Support.stamp_org_meta!(acme)
        tx_id = Support.current_audit_transaction_id!()
        {reply, tx_id}
      end)

    ts_insert = DateTime.utc_now() |> DateTime.add(-4, :hour)
    ctx = Support.put_timestamp(ctx, insert_tx_id, ts_insert)

    # Now delete the reply (DELETE audit_change)
    closer_id = to_string(closer_agent.user_id)

    {:ok, delete_tx_id} =
      Repo.transaction(fn ->
        Support.set_actor_guc!(closer_id)
        Repo.delete!(reply)
        Support.stamp_org_meta!(acme)
        Support.current_audit_transaction_id!()
      end)

    ts_delete = DateTime.utc_now() |> DateTime.add(-4, :hour) |> DateTime.add(15, :minute)
    Support.put_timestamp(ctx, delete_tx_id, ts_delete)
  end

  # Story 5 (D-12): Ticket delete — Repo.delete! a duplicate/spam ticket.
  # Uses system/trigger-backfill actor. 5h ago.
  defp seed_variety_ticket_delete(ctx, acme, support_agent) do
    ticket = upsert_ticket!(acme, 5004, support_agent, "open")
    backfill_id = Manifest.actor_id(:trigger_backfill)

    {:ok, delete_tx_id} =
      Repo.transaction(fn ->
        Support.set_actor_guc!(backfill_id, :system)
        Repo.delete!(ticket)
        Support.stamp_org_meta!(acme)
        Support.current_audit_transaction_id!()
      end)

    ts = DateTime.utc_now() |> DateTime.add(-5, :hour)
    Support.put_timestamp(ctx, delete_tx_id, ts)
  end

  # Story 6 (D-06/D-12): Inbound ticket sync cluster — INSERTs by
  # service_account/zendesk-sync. 6h ago.
  defp seed_variety_zendesk_sync(ctx, acme, support_agent) do
    zendesk_id = Manifest.actor_id(:zendesk_sync)

    {:ok, tx_id} =
      Repo.transaction(fn ->
        Support.set_actor_guc!(zendesk_id, :service_account)

        %Ticket{organization_id: acme.id}
        |> Ticket.changeset(%{
          number: 5005,
          status: "open",
          assignee_id: support_agent.id
        })
        |> Repo.insert!(on_conflict: :nothing, conflict_target: [:organization_id, :number])

        Support.stamp_org_meta!(acme)
        Support.current_audit_transaction_id!()
      end)

    ts = DateTime.utc_now() |> DateTime.add(-6, :hour)
    Support.put_timestamp(ctx, tx_id, ts)
  end

  # Story 7 (D-06): Stale-ticket sweep by job/oban-retention-purge. 3h+30m ago.
  defp seed_variety_stale_sweep(ctx, acme, closer_agent) do
    job_id = Manifest.actor_id(:oban_retention_purge)
    ticket = upsert_ticket!(acme, 5006, closer_agent, "open")

    {:ok, tx_id} =
      Repo.transaction(fn ->
        Support.set_actor_guc!(job_id, :job)

        ticket
        |> Ticket.changeset(%{status: "closed", closed_at: Manifest.epoch()})
        |> Repo.update!()

        Support.stamp_org_meta!(acme)
        Support.current_audit_transaction_id!()
      end)

    ts = DateTime.utc_now() |> DateTime.add(-3, :hour) |> DateTime.add(-30, :minute)
    Support.put_timestamp(ctx, tx_id, ts)
  end

  # Story 8 (D-06): Backfill/correction by system/trigger-backfill. 2h+45m ago.
  defp seed_variety_backfill(ctx, acme, support_agent) do
    backfill_id = Manifest.actor_id(:trigger_backfill)
    ticket = upsert_ticket!(acme, 5007, support_agent, "open")

    {:ok, tx_id} =
      Repo.transaction(fn ->
        Support.set_actor_guc!(backfill_id, :system)

        ticket
        |> Ticket.changeset(%{status: "in_progress"})
        |> Repo.update!()

        Support.stamp_org_meta!(acme)
        Support.current_audit_transaction_id!()
      end)

    ts = DateTime.utc_now() |> DateTime.add(-2, :hour) |> DateTime.add(-45, :minute)
    Support.put_timestamp(ctx, tx_id, ts)
  end

  # Story 9 (D-06): Public form ticket submission — anonymous actor. 5h+30m ago.
  defp seed_variety_anon_submission(ctx, acme, support_agent) do
    {:ok, tx_id} =
      Repo.transaction(fn ->
        Support.set_anonymous_actor_guc!()

        %Ticket{organization_id: acme.id}
        |> Ticket.changeset(%{
          number: 5008,
          status: "open",
          assignee_id: support_agent.id
        })
        |> Repo.insert!(on_conflict: :nothing, conflict_target: [:organization_id, :number])

        Support.stamp_org_meta!(acme)
        Support.current_audit_transaction_id!()
      end)

    ts = DateTime.utc_now() |> DateTime.add(-5, :hour) |> DateTime.add(-30, :minute)
    Support.put_timestamp(ctx, tx_id, ts)
  end
end
