defmodule ThreadlinePhoenixWeb.HelpDeskDevController do
  @moduledoc false
  use ThreadlinePhoenixWeb, :controller

  alias Threadline.Integrations.Sigra
  alias Threadline.Semantics.{ActorRef, AuditContext}
  alias ThreadlinePhoenix.HelpDesk
  alias ThreadlinePhoenix.HelpDesk.{Agent, Organization, Ticket}
  alias ThreadlinePhoenix.Repo

  def ticket_reply(conn, params) do
    with %{"organization_id" => org_id, "ticket_id" => ticket_id} <- params,
         %Organization{} = org <- Repo.get(Organization, org_id),
         %Ticket{} = ticket <- Repo.get_by(Ticket, id: ticket_id, organization_id: org.id),
         user_id when is_binary(user_id) <- current_user_id(conn),
         %Agent{} <- Repo.get_by(Agent, organization_id: org.id, user_id: user_id),
         %AuditContext{} = audit_context <- audit_context_from_conn(conn),
         {:ok, result} <-
           HelpDesk.ticket_replied_and_closed(
             audit_context,
             org,
             ticket,
             %{
               body: Map.get(params, "body", "reply"),
               internal_note_body: Map.get(params, "internal_note_body")
             },
             %{status: "closed", closed_at: DateTime.utc_now(:second)},
             []
           ) do
      json(conn, %{audit_transaction_id: result.audit_transaction_id})
    else
      nil -> send_error(conn, :not_found)
      {:error, :missing_actor} -> send_error(conn, :missing_actor)
      {:error, reason} -> send_error(conn, reason)
      _ -> send_error(conn, :invalid_request)
    end
  end

  defp audit_context_from_conn(conn) do
    case actor_ref_from_conn(conn) do
      nil ->
        nil

      actor_ref ->
        overrides = Sigra.audit_context_overrides_from_conn(conn)

        %AuditContext{
          actor_ref: actor_ref,
          correlation_id: Map.get(overrides, :correlation_id, "dev-help-desk"),
          request_id: "dev-help-desk"
        }
    end
  end

  defp actor_ref_from_conn(conn) do
    Sigra.actor_ref_from_conn(conn) || actor_ref_from_current_user(conn)
  end

  defp actor_ref_from_current_user(conn) do
    case conn.assigns[:current_user] do
      %{id: id} ->
        case ActorRef.new(:user, to_string(id)) do
          {:ok, ref} -> ref
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp current_user_id(conn) do
    case conn.assigns[:current_user] do
      %{id: id} -> to_string(id)
      _ -> nil
    end
  end

  defp send_error(conn, reason) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: to_string(reason)})
  end
end
