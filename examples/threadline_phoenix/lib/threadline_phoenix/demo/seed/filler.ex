defmodule ThreadlinePhoenix.Demo.Seed.Filler do
  @moduledoc false

  import Ecto.Query

  alias ThreadlinePhoenix.Demo.Seed.Support
  alias ThreadlinePhoenix.HelpDesk.{Agent, Organization, Ticket}
  alias ThreadlinePhoenix.Repo

  @tickets_per_org 50
  @hero_numbers MapSet.new([4521, 4518])

  @org_slugs [:acme, :globex, :offboarded_co]

  @doc false
  @spec run(map()) :: map()
  def run(ctx) do
    Enum.reduce(@org_slugs, ctx, fn slug, acc ->
      org = Map.fetch!(acc.orgs, slug)
      agent_user_ids = agent_user_ids_for_org(acc, slug)
      seed_org_filler(acc, org, agent_user_ids)
    end)
  end

  defp agent_user_ids_for_org(ctx, :acme) do
    [:closer, :deleter, :support_acme, :agent2, :agent3]
    |> Enum.map(fn key -> to_string(Map.fetch!(ctx.users, key).id) end)
  end

  defp agent_user_ids_for_org(ctx, :globex) do
    [:support_globex, :agent4, :agent5]
    |> Enum.map(fn key -> to_string(Map.fetch!(ctx.users, key).id) end)
  end

  defp agent_user_ids_for_org(ctx, :offboarded_co) do
    [:support_offboarded, :agent6, :agent7]
    |> Enum.map(fn key -> to_string(Map.fetch!(ctx.users, key).id) end)
  end

  defp seed_org_filler(ctx, %Organization{} = org, agent_user_ids) do
    count =
      Repo.aggregate(from(t in Ticket, where: t.organization_id == ^org.id), :count)

    needed = max(0, @tickets_per_org - count)

    Stream.iterate(next_ticket_number(org), &(&1 + 1))
    |> Stream.reject(&MapSet.member?(@hero_numbers, &1))
    |> Enum.take(needed)
    |> Enum.reduce(ctx, fn number, acc ->
      insert_filler_ticket(acc, org, number, agent_user_ids)
    end)
  end

  defp next_ticket_number(%Organization{id: org_id}) do
    max =
      Repo.one(
        from(t in Ticket,
          where: t.organization_id == ^org_id,
          select: max(t.number)
        )
      )

    (max || 0) + 1
  end

  defp insert_filler_ticket(ctx, %Organization{} = org, number, agent_user_ids) do
    user_id = Enum.at(agent_user_ids, :rand.uniform(length(agent_user_ids)) - 1)
    agent = Repo.get_by!(Agent, organization_id: org.id, user_id: user_id)
    status = if rem(number, 3) == 0, do: "closed", else: "open"

    {:ok, tx_id} =
      Repo.transaction(fn ->
        Support.set_actor_guc!(user_id)

        ticket =
          %Ticket{organization_id: org.id}
          |> Ticket.changeset(%{
            number: number,
            status: "open",
            assignee_id: agent.id
          })
          |> Repo.insert!()

        if status == "closed" do
          ticket
          |> Ticket.changeset(%{
            status: "closed",
            closed_at: ThreadlinePhoenix.Demo.Manifest.epoch()
          })
          |> Repo.update!()
        else
          ticket
          |> Ticket.changeset(%{status: "in_progress"})
          |> Repo.update!()
        end

        Support.stamp_org_meta!(org)
        Support.current_audit_transaction_id!()
      end)

    ts = Support.random_days_ago_timestamp()
    Support.put_timestamp(ctx, tx_id, ts)
  end
end
