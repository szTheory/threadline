defmodule ThreadlinePhoenix.HelpDeskFixtures do
  @moduledoc false

  import Ecto.Query

  alias Threadline.Semantics.{ActorRef, AuditContext}
  alias ThreadlinePhoenix.HelpDesk.{Agent, OrgMembership, Organization, Ticket}
  alias ThreadlinePhoenix.Repo

  def organization_fixture(attrs \\ %{}) do
    n = System.unique_integer([:positive])

    attrs =
      Map.merge(
        %{slug: "org-#{n}", name: "Organization #{n}"},
        Map.new(attrs)
      )

    %Organization{}
    |> Organization.changeset(attrs)
    |> Repo.insert!()
  end

  def membership_fixture(%Organization{} = org, attrs \\ %{}) do
    n = System.unique_integer([:positive])

    attrs =
      Map.merge(
        %{user_id: "user-#{n}", role: "support"},
        Map.new(attrs)
      )

    %OrgMembership{organization_id: org.id, user_id: attrs.user_id}
    |> OrgMembership.changeset(%{role: attrs.role})
    |> Repo.insert!()
  end

  def agent_fixture(%Organization{} = org, attrs \\ %{}) do
    n = System.unique_integer([:positive])

    attrs =
      Map.merge(
        %{user_id: "agent-#{n}", display_name: "Agent #{n}"},
        Map.new(attrs)
      )

    %Agent{organization_id: org.id, user_id: attrs.user_id}
    |> Agent.changeset(%{display_name: attrs.display_name})
    |> Repo.insert!()
  end

  def ticket_fixture(%Organization{} = org, %Agent{} = agent, attrs \\ %{}) do
    number =
      Map.get_lazy(attrs, :number, fn ->
        from(t in Ticket,
          where: t.organization_id == ^org.id,
          select: max(t.number)
        )
        |> Repo.one()
        |> case do
          nil -> 1
          max -> max + 1
        end
      end)

    attrs =
      attrs
      |> Map.new()
      |> Map.merge(%{number: number, status: "open", assignee_id: agent.id})

    %Ticket{organization_id: org.id}
    |> Ticket.changeset(attrs)
    |> Repo.insert!()
  end

  def audit_context_for_user(user_id) when is_binary(user_id) do
    {:ok, actor_ref} = ActorRef.new(:user, user_id)

    %AuditContext{
      actor_ref: actor_ref,
      correlation_id: "test-corr",
      request_id: "test-req"
    }
  end
end
