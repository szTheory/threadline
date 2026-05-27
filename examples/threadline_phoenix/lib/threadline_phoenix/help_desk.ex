defmodule ThreadlinePhoenix.HelpDesk do
  @moduledoc """
  Help-desk domain writes with Threadline capture and semantics for the example app.
  """

  import Ecto.Query

  alias Threadline.Semantics.AuditContext
  alias ThreadlinePhoenix.HelpDesk.{Agent, OrgMembership, Organization, Ticket, TicketReply}
  alias ThreadlinePhoenix.Repo

  @doc """
  Creates a default help-desk workspace for a Sigra user id (UUID string).

  Idempotent when `(organization_id, user_id)` membership already exists — returns
  the existing organization.
  """
  @spec provision_default_workspace_for_user(String.t(), keyword()) ::
          {:ok, Organization.t()} | {:error, term()}
  def provision_default_workspace_for_user(user_id, opts \\ []) when is_binary(user_id) do
    role = Keyword.get(opts, :role, "agent")

    case existing_membership_org(user_id) do
      %Organization{} = org ->
        {:ok, org}

      nil ->
        slug = Keyword.get(opts, :slug) || unique_org_slug()
        name = Keyword.get(opts, :name) || "Workspace #{slug}"

        Ecto.Multi.new()
        |> Ecto.Multi.insert(
          :organization,
          Organization.changeset(%Organization{}, %{slug: slug, name: name})
        )
        |> Ecto.Multi.insert(:membership, fn %{organization: org} ->
          %OrgMembership{organization_id: org.id, user_id: user_id}
          |> OrgMembership.changeset(%{role: role})
        end)
        |> Ecto.Multi.insert(:agent, fn %{organization: org} ->
          %Agent{organization_id: org.id, user_id: user_id}
          |> Agent.changeset(%{display_name: "Agent"})
        end)
        |> Repo.transaction()
        |> case do
          {:ok, %{organization: org}} -> {:ok, org}
          {:error, _step, reason, _} -> {:error, reason}
        end
    end
  end

  defp existing_membership_org(user_id) do
    from(m in OrgMembership,
      join: o in Organization,
      on: o.id == m.organization_id,
      where: m.user_id == ^user_id,
      select: o,
      limit: 1
    )
    |> Repo.one()
  end

  defp unique_org_slug do
    "org-" <> Base.encode16(:crypto.strong_rand_bytes(4), case: :lower)
  end

  @doc """
  Returns the membership role for a user in an organization, or `nil` if none exists.
  """
  @spec get_membership_role(String.t(), String.t()) :: :agent | :support | nil
  def get_membership_role(user_id, organization_id)
      when is_binary(user_id) and is_binary(organization_id) do
    case Repo.get_by(OrgMembership, user_id: user_id, organization_id: organization_id) do
      %{role: "agent"} -> :agent
      %{role: "support"} -> :support
      _ -> nil
    end
  end

  @doc """
  Returns the user's default help-desk organization.

  When the user has exactly one membership, that organization is returned.
  Otherwise the earliest membership by `inserted_at` is used.
  """
  @spec get_default_organization_for_user(String.t()) :: Organization.t() | nil
  def get_default_organization_for_user(user_id) when is_binary(user_id) do
    memberships =
      from(m in OrgMembership,
        join: o in Organization,
        on: o.id == m.organization_id,
        where: m.user_id == ^user_id,
        order_by: [asc: m.inserted_at],
        select: {m, o}
      )
      |> Repo.all()

    case memberships do
      [] ->
        nil

      [{_membership, org}] ->
        org

      [{_first, first_org} | _rest] ->
        first_org
    end
  end

  @doc """
  Returns `to_string(organization.id)` for the user's default organization, or `nil`.
  """
  @spec get_organization_id_for_user(String.t()) :: String.t() | nil
  def get_organization_id_for_user(user_id) when is_binary(user_id) do
    case get_default_organization_for_user(user_id) do
      %Organization{id: id} -> to_string(id)
      nil -> nil
    end
  end

  @doc """
  Inserts a ticket reply and closes the ticket in one transaction with actor GUC,
  capture, and `:ticket_replied_and_closed` semantics linked to the audit row.
  """
  @spec ticket_replied_and_closed(
          AuditContext.t(),
          Organization.t(),
          Ticket.t(),
          map(),
          map(),
          keyword()
        ) ::
          {:ok, %{ticket: Ticket.t(), reply: TicketReply.t(), audit_transaction_id: term()}}
          | {:error, term()}
  def ticket_replied_and_closed(
        %AuditContext{} = audit_context,
        %Organization{} = organization,
        %Ticket{} = ticket,
        reply_attrs,
        ticket_attrs,
        _opts \\ []
      )
      when is_map(reply_attrs) and is_map(ticket_attrs) do
    Threadline.Audit.transaction(
      Repo,
      [
        audit_context: audit_context,
        action: :ticket_replied_and_closed,
        transaction_meta: audit_transaction_meta(organization)
      ],
      fn ->
        reply_changeset =
          %TicketReply{ticket_id: ticket.id}
          |> TicketReply.changeset(reply_attrs)

        with {:ok, reply} <- Repo.insert(reply_changeset),
             {:ok, updated_ticket} <- Repo.update(ticket |> Ticket.changeset(ticket_attrs)) do
          %{ticket: updated_ticket, reply: reply}
        else
          {:error, cs} -> Repo.rollback(cs)
        end
      end
    )
  end

  @doc """
  Hard-deletes a ticket reply with actor GUC and org scope on the audit transaction.

  Does not record a semantic `:ticket_reply_deleted` action (D-107-05d).
  """
  @spec delete_reply(AuditContext.t(), Organization.t(), TicketReply.t()) ::
          {:ok, :deleted} | {:error, term()}
  def delete_reply(
        %AuditContext{} = audit_context,
        %Organization{} = organization,
        %TicketReply{} = reply
      ) do
    Threadline.Audit.transaction(
      Repo,
      [
        audit_context: audit_context,
        capture_only: true,
        transaction_meta: audit_transaction_meta(organization)
      ],
      fn ->
        Repo.delete!(reply)
        :deleted
      end
    )
    |> case do
      {:ok, %{result: :deleted, audit_transaction_id: _}} -> {:ok, :deleted}
      {:error, reason} -> {:error, reason}
    end
  end

  defp audit_transaction_meta(%Organization{id: org_id}) do
    %{"organization_id" => to_string(org_id)}
  end
end
