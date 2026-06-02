defmodule ThreadlinePhoenix.Demo.Seed.Anchors do
  @moduledoc false

  import Ecto.Query

  alias Threadline.Capture.AuditTransaction
  alias ThreadlinePhoenix.Demo.Manifest
  alias ThreadlinePhoenix.Demo.Seed.Support
  alias ThreadlinePhoenix.HelpDesk
  alias ThreadlinePhoenix.HelpDesk.{Agent, Ticket}
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
end
