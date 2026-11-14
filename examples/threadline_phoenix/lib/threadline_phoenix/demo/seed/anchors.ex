defmodule ThreadlinePhoenix.Demo.Seed.Anchors do
  @moduledoc false

  import Ecto.Query

  alias Threadline.Capture.AuditTransaction
  alias Threadline.StorageSchema
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

  # D3 — a currently-active actor. ActorLive's default window keys off real
  # current time (not the demo epoch), so epoch-anchored actors render empty in
  # the default 24h view. These closes use the single seed-run clock so the
  # default Actor view demonstrates a real trajectory. The row count and ops
  # are fixed; only the run clock changes. (Distinct from agent2, whose empty 30d window a
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
      event_at = DateTime.add(ctx.run_now, -hours_ago, :hour)

      {:ok, tx_id} =
        Repo.transaction(fn ->
          Support.set_actor_guc!(active_id)

          ticket
          |> Ticket.changeset(%{status: "closed", closed_at: event_at})
          |> Support.stamp_update(event_at)
          |> Repo.update!()

          Support.stamp_org_meta!(acme)
          Support.current_audit_transaction_id!()
        end)

      Support.put_timestamp(acc, tx_id, event_at)
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
      Support.reply_and_close(
        ctx_audit,
        acme,
        ticket,
        %{
          body: "Thanks — we're closing this out.",
          # The operator evidence lane scans rendered output for this sentinel.
          # The configured trigger mask must keep it out of persisted audit data.
          internal_note_body: "synthetic-secret-canary-239-6f71"
        },
        %{status: "closed", closed_at: Manifest.last_tuesday()},
        Manifest.last_tuesday()
      )

    Support.put_timestamp(ctx, result.audit_transaction_id, Manifest.last_tuesday())
  end

  defp seed_acme_delete(ctx) do
    acme = Map.fetch!(ctx.orgs, :acme)
    closer_id = to_string(Map.fetch!(ctx.users, :closer).id)
    deleter_id = to_string(Map.fetch!(ctx.users, :deleter).id)
    closer = Repo.get_by!(Agent, organization_id: acme.id, user_id: closer_id)
    ticket = upsert_ticket!(acme, Manifest.ticket_number(:hero_delete), closer, "open")

    close_at = DateTime.add(Manifest.last_tuesday(), 1, :hour)
    closer_ctx = Support.audit_context(closer_id, request_id: "demo-seed-4518-reply")

    {:ok, result} =
      Support.reply_and_close(
        closer_ctx,
        acme,
        ticket,
        %{body: "Reply slated for deletion demo.", internal_note_body: nil},
        %{status: "closed", closed_at: close_at},
        close_at
      )

    ctx = Support.put_timestamp(ctx, result.audit_transaction_id, close_at)
    deleter_ctx = Support.audit_context(deleter_id, request_id: "demo-seed-4518-delete")
    {:ok, :deleted} = HelpDesk.delete_reply(deleter_ctx, acme, result.reply)

    delete_tx_id =
      Repo.one!(
        from(at in AuditTransaction,
          join: ac in assoc(at, :changes),
          where: ac.table_name == "ticket_replies",
          where: ac.op == "delete",
          where: fragment("?->>'id' = ?", ac.table_pk, ^to_string(result.reply.id)),
          order_by: [desc: at.occurred_at],
          limit: 1,
          select: at.id
        ),
        StorageSchema.repo_opts()
      )

    delete_at = DateTime.add(Manifest.last_tuesday(), 2, :hour)

    Support.put_timestamp(ctx, delete_tx_id, delete_at)
  end

  defp seed_leaving_agent_window(ctx) do
    acme = Map.fetch!(ctx.orgs, :acme)
    leaving_id = to_string(Map.fetch!(ctx.users, :agent2).id)
    leaving_agent = Repo.get_by!(Agent, organization_id: acme.id, user_id: leaving_id)

    Enum.reduce(1..@leaving_agent_tx_count, ctx, fn n, acc ->
      ticket_number = 4600 + n
      ticket = upsert_ticket!(acme, ticket_number, leaving_agent, "open")
      event_at = DateTime.add(Manifest.last_tuesday(), n, :minute)

      {:ok, tx_id} =
        Repo.transaction(fn ->
          Support.set_actor_guc!(leaving_id)

          ticket
          |> Ticket.changeset(%{status: "closed", closed_at: event_at})
          |> Support.stamp_update(event_at)
          |> Repo.update!()

          Support.stamp_org_meta!(acme)
          Support.current_audit_transaction_id!()
        end)

      Support.put_timestamp(acc, tx_id, event_at)
    end)
  end

  defp seed_globex_close_sample(ctx) do
    globex = Map.fetch!(ctx.orgs, :globex)
    support_id = to_string(Map.fetch!(ctx.users, :support_globex).id)
    agent = Repo.get_by!(Agent, organization_id: globex.id, user_id: support_id)
    ticket = upsert_ticket!(globex, 2001, agent, "open")
    event_at = Support.days_ago_timestamp(3)

    audit_ctx = Support.audit_context(support_id, request_id: "demo-seed-globex-close")

    {:ok, result} =
      Support.reply_and_close(
        audit_ctx,
        globex,
        ticket,
        %{body: "Globex walkthrough close sample.", internal_note_body: nil},
        %{status: "closed", closed_at: event_at},
        event_at
      )

    Support.put_timestamp(ctx, result.audit_transaction_id, event_at)
  end

  defp upsert_ticket!(org, number, %Agent{} = assignee, status) do
    setup_at = DateTime.add(Manifest.epoch(), -21, :day)

    case Repo.get_by(Ticket, organization_id: org.id, number: number) do
      %Ticket{} = ticket ->
        ticket
        |> Ticket.changeset(%{status: status, assignee_id: assignee.id})
        |> Ecto.Changeset.put_change(:assignee_id, assignee.id)
        |> Support.stamp_update(setup_at)
        |> Repo.update!()

      nil ->
        %Ticket{organization_id: org.id}
        |> Ticket.changeset(%{number: number, status: status, assignee_id: assignee.id})
        |> Ecto.Changeset.put_change(:assignee_id, assignee.id)
        |> Support.stamp_insert(setup_at)
        |> Repo.insert!()
    end
  end

  # D-11/D-12 in-window variety pack: ~5 INSERT / 4 UPDATE / 2 DELETE across
  # tickets, ticket_replies, org_memberships. Non-human actor clusters (D-06):
  # - service_account/zendesk-sync    → inbound ticket sync (INSERT + UPDATE)
  # - job/oban-retention-purge        → stale-ticket sweep (UPDATE)
  # - system/trigger-backfill         → backfill correction (UPDATE)
  # - anonymous                       → public form ticket submission (INSERT)
  # All current-window event offsets derive from the single run clock so they
  # appear in the default 24h Timeline window (D-10, D-13).
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
    insert_at = DateTime.add(ctx.run_now, -1, :hour)

    {:ok, {reply, insert_tx_id}} =
      Repo.transaction(fn ->
        Support.set_actor_guc!(zendesk_id, :service_account)

        reply =
          %TicketReply{ticket_id: ticket.id}
          |> TicketReply.changeset(%{
            body: "Original reply from Zendesk sync.",
            internal_note_body: "Internal: route to tier-2"
          })
          |> Support.stamp_insert(insert_at)
          |> Repo.insert!()

        Support.stamp_org_meta!(acme)
        tx_id = Support.current_audit_transaction_id!()
        {reply, tx_id}
      end)

    ctx = Support.put_timestamp(ctx, insert_tx_id, insert_at)

    # Now update the reply as a human user (closer) — this is the edit that
    # produces the rich before→after diff on ticket_replies.
    closer_id = to_string(closer_agent.user_id)
    update_at = DateTime.add(ctx.run_now, -55, :minute)

    {:ok, update_tx_id} =
      Repo.transaction(fn ->
        Support.set_actor_guc!(closer_id)

        reply
        |> TicketReply.changeset(%{
          body: "Updated reply — issue resolved.",
          internal_note_body: "Confirmed tier-2 resolved. Closing."
        })
        |> Support.stamp_update(update_at)
        |> Repo.update!()

        Support.stamp_org_meta!(acme)
        Support.current_audit_transaction_id!()
      end)

    Support.put_timestamp(ctx, update_tx_id, update_at)
  end

  # Story 2 (D-12): Ticket reopened/re-triaged — tickets UPDATE status
  # closed→open + cleared closed_at; separate assignee reassignment UPDATE.
  # Uses job/oban-retention-purge actor (stale-ticket sweep). 2h ago.
  defp seed_variety_ticket_reopen(ctx, acme, support_agent) do
    ticket = upsert_ticket!(acme, 5002, support_agent, "closed")
    job_id = Manifest.actor_id(:oban_retention_purge)
    support_agent_id = to_string(support_agent.user_id)
    reopen_at = DateTime.add(ctx.run_now, -2, :hour)

    # Reopen the ticket (status closed→open)
    {:ok, reopen_tx_id} =
      Repo.transaction(fn ->
        Support.set_actor_guc!(job_id, :job)

        ticket
        |> Ticket.changeset(%{status: "open", closed_at: nil})
        |> Support.stamp_update(reopen_at)
        |> Repo.update!()

        Support.stamp_org_meta!(acme)
        Support.current_audit_transaction_id!()
      end)

    ctx = Support.put_timestamp(ctx, reopen_tx_id, reopen_at)

    # Reassign the ticket (separate UPDATE)
    reassign_at = DateTime.add(ctx.run_now, -110, :minute)

    {:ok, reassign_tx_id} =
      Repo.transaction(fn ->
        Support.set_actor_guc!(support_agent_id)

        Repo.get!(Ticket, ticket.id)
        |> Ticket.changeset(%{assignee_id: support_agent.id, status: "in_progress"})
        |> Ecto.Changeset.put_change(:assignee_id, support_agent.id)
        |> Support.stamp_update(reassign_at)
        |> Repo.update!()

        Support.stamp_org_meta!(acme)
        Support.current_audit_transaction_id!()
      end)

    Support.put_timestamp(ctx, reassign_tx_id, reassign_at)
  end

  # Story 3 (D-12): Membership role change — org_memberships UPDATE role
  # agent→support. Uses system/trigger-backfill actor. Intentionally EPOCH-relative
  # (backdated 7 days past epoch) so it does NOT appear in the 24h window — the
  # D-05 test asserts no org_memberships appear in-window. D-13's ≥1 UPDATE is
  # satisfied by ticket/ticket_replies in-window updates from stories 1 and 2.
  # Note: org_memberships uses default trigger (after-only, no changed_from) — honest D-09.
  # Uses agent3 who has "agent" role, flipping them to "support" (guaranteed change).
  defp seed_variety_membership_role_change(ctx, acme, _support_agent) do
    backfill_id = Manifest.actor_id(:trigger_backfill)
    agent3_id = to_string(Map.fetch!(ctx.users, :agent3).id)

    # Find agent3's membership in acme (role = "agent" by default)
    membership = Repo.get_by(OrgMembership, organization_id: acme.id, user_id: agent3_id)

    # Only attempt if membership exists and role is still "agent" — idempotent on re-seed
    if membership && membership.role != "support" do
      role_change_at = DateTime.add(Manifest.epoch(), -7, :day)

      {:ok, tx_id} =
        Repo.transaction(fn ->
          Support.set_actor_guc!(backfill_id, :system)

          # Flip to "support" — guaranteed different from "agent" so Ecto sends SQL UPDATE
          membership
          |> OrgMembership.changeset(%{role: "support"})
          |> Support.stamp_update(role_change_at)
          |> Repo.update!()

          Support.stamp_org_meta!(acme)
          Support.current_audit_transaction_id!()
        end)

      # Backdated past epoch — outside 24h window (D-05 constraint)
      Support.put_timestamp(ctx, tx_id, role_change_at)
    else
      ctx
    end
  end

  # Story 4 (D-12): Reply hard-delete — Repo.delete! a ticket_replies row
  # in-window. Uses anonymous actor (public form). 4h ago.
  defp seed_variety_reply_delete(ctx, acme, closer_agent) do
    # Insert a reply to delete
    ticket = upsert_ticket!(acme, 5003, closer_agent, "open")
    insert_at = DateTime.add(ctx.run_now, -4, :hour)

    {:ok, {reply, insert_tx_id}} =
      Repo.transaction(fn ->
        Support.set_anonymous_actor_guc!()

        reply =
          %TicketReply{ticket_id: ticket.id}
          |> TicketReply.changeset(%{body: "Spam reply to be removed."})
          |> Support.stamp_insert(insert_at)
          |> Repo.insert!()

        Support.stamp_org_meta!(acme)
        tx_id = Support.current_audit_transaction_id!()
        {reply, tx_id}
      end)

    ctx = Support.put_timestamp(ctx, insert_tx_id, insert_at)

    # Now delete the reply (DELETE audit_change)
    closer_id = to_string(closer_agent.user_id)
    delete_at = DateTime.add(ctx.run_now, -225, :minute)

    {:ok, delete_tx_id} =
      Repo.transaction(fn ->
        Support.set_actor_guc!(closer_id)
        Repo.delete!(reply)
        Support.stamp_org_meta!(acme)
        Support.current_audit_transaction_id!()
      end)

    Support.put_timestamp(ctx, delete_tx_id, delete_at)
  end

  # Story 5 (D-12): Ticket delete — Repo.delete! a duplicate/spam ticket.
  # Uses system/trigger-backfill actor. 5h ago.
  defp seed_variety_ticket_delete(ctx, acme, support_agent) do
    ticket = upsert_ticket!(acme, 5004, support_agent, "open")
    backfill_id = Manifest.actor_id(:trigger_backfill)
    delete_at = DateTime.add(ctx.run_now, -5, :hour)

    {:ok, delete_tx_id} =
      Repo.transaction(fn ->
        Support.set_actor_guc!(backfill_id, :system)
        Repo.delete!(ticket)
        Support.stamp_org_meta!(acme)
        Support.current_audit_transaction_id!()
      end)

    Support.put_timestamp(ctx, delete_tx_id, delete_at)
  end

  # Story 6 (D-06/D-12): Inbound ticket sync cluster — INSERTs by
  # service_account/zendesk-sync. 6h ago.
  defp seed_variety_zendesk_sync(ctx, acme, support_agent) do
    zendesk_id = Manifest.actor_id(:zendesk_sync)
    event_at = DateTime.add(ctx.run_now, -6, :hour)

    {:ok, tx_id} =
      Repo.transaction(fn ->
        Support.set_actor_guc!(zendesk_id, :service_account)

        %Ticket{organization_id: acme.id}
        |> Ticket.changeset(%{
          number: 5005,
          status: "open",
          assignee_id: support_agent.id
        })
        |> Ecto.Changeset.put_change(:assignee_id, support_agent.id)
        |> Support.stamp_insert(event_at)
        |> Repo.insert!(on_conflict: :nothing, conflict_target: [:organization_id, :number])

        Support.stamp_org_meta(acme)
        Support.current_audit_transaction_id()
      end)

    if tx_id, do: Support.put_timestamp(ctx, tx_id, event_at), else: ctx
  end

  # Story 7 (D-06): Stale-ticket sweep by job/oban-retention-purge. 3h+30m ago.
  defp seed_variety_stale_sweep(ctx, acme, closer_agent) do
    job_id = Manifest.actor_id(:oban_retention_purge)
    ticket = upsert_ticket!(acme, 5006, closer_agent, "open")
    event_at = DateTime.add(ctx.run_now, -210, :minute)

    {:ok, tx_id} =
      Repo.transaction(fn ->
        Support.set_actor_guc!(job_id, :job)

        ticket
        |> Ticket.changeset(%{status: "closed", closed_at: event_at})
        |> Support.stamp_update(event_at)
        |> Repo.update!()

        Support.stamp_org_meta!(acme)
        Support.current_audit_transaction_id!()
      end)

    Support.put_timestamp(ctx, tx_id, event_at)
  end

  # Story 8 (D-06): Backfill/correction by system/trigger-backfill. 2h+45m ago.
  defp seed_variety_backfill(ctx, acme, support_agent) do
    backfill_id = Manifest.actor_id(:trigger_backfill)
    ticket = upsert_ticket!(acme, 5007, support_agent, "open")
    event_at = DateTime.add(ctx.run_now, -165, :minute)

    {:ok, tx_id} =
      Repo.transaction(fn ->
        Support.set_actor_guc!(backfill_id, :system)

        ticket
        |> Ticket.changeset(%{status: "in_progress"})
        |> Support.stamp_update(event_at)
        |> Repo.update!()

        Support.stamp_org_meta!(acme)
        Support.current_audit_transaction_id!()
      end)

    Support.put_timestamp(ctx, tx_id, event_at)
  end

  # Story 9 (D-06): Public form ticket submission — anonymous actor. 5h+30m ago.
  defp seed_variety_anon_submission(ctx, acme, support_agent) do
    event_at = DateTime.add(ctx.run_now, -330, :minute)

    {:ok, tx_id} =
      Repo.transaction(fn ->
        Support.set_anonymous_actor_guc!()

        %Ticket{organization_id: acme.id}
        |> Ticket.changeset(%{
          number: 5008,
          status: "open",
          assignee_id: support_agent.id
        })
        |> Ecto.Changeset.put_change(:assignee_id, support_agent.id)
        |> Support.stamp_insert(event_at)
        |> Repo.insert!(on_conflict: :nothing, conflict_target: [:organization_id, :number])

        Support.stamp_org_meta(acme)
        Support.current_audit_transaction_id()
      end)

    if tx_id, do: Support.put_timestamp(ctx, tx_id, event_at), else: ctx
  end
end
