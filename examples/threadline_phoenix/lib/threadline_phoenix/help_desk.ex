defmodule ThreadlinePhoenix.HelpDesk do
  @moduledoc """
  Help-desk domain writes with Threadline capture and semantics for the example app.
  """

  import Ecto.Query

  alias Threadline.Capture.AuditTransaction
  alias Threadline.Semantics.{AuditAction, AuditContext}
  alias ThreadlinePhoenix.HelpDesk.{Organization, Ticket, TicketReply}
  alias ThreadlinePhoenix.Repo

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
        ) :: {:ok, %{ticket: Ticket.t(), reply: TicketReply.t(), audit_transaction_id: term()}}
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
    case audit_context.actor_ref do
      nil ->
        {:error, :missing_actor}

      actor_ref ->
        json =
          actor_ref
          |> Threadline.Semantics.ActorRef.to_map()
          |> Jason.encode!()

        Repo.transaction(fn ->
          Repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])

          reply_changeset =
            %TicketReply{ticket_id: ticket.id}
            |> TicketReply.changeset(reply_attrs)

          case Repo.insert(reply_changeset) do
            {:error, changeset} ->
              Repo.rollback(changeset)

            {:ok, reply} ->
              ticket_changeset =
                ticket
                |> Ticket.changeset(ticket_attrs)

              case Repo.update(ticket_changeset) do
                {:error, changeset} ->
                  Repo.rollback(changeset)

                {:ok, updated_ticket} ->
                  action_opts = [
                    repo: Repo,
                    actor: actor_ref,
                    correlation_id: audit_context.correlation_id,
                    request_id: audit_context.request_id
                  ]

                  case Threadline.record_action(:ticket_replied_and_closed, action_opts) do
                    {:error, cs} ->
                      Repo.rollback(cs)

                    {:ok, %AuditAction{id: action_id}} ->
                      meta = audit_transaction_meta(organization)

                      {count, _} =
                        Repo.update_all(
                          from(at in AuditTransaction,
                            where: at.txid == fragment("txid_current()")
                          ),
                          set: [action_id: action_id, meta: meta]
                        )

                      if count != 1 do
                        Repo.rollback(:missing_audit_transaction_for_link)
                      end

                      audit_transaction_id =
                        Repo.one!(
                          from(at in AuditTransaction,
                            where: at.txid == fragment("txid_current()"),
                            select: at.id
                          )
                        )

                      %{
                        ticket: updated_ticket,
                        reply: reply,
                        audit_transaction_id: audit_transaction_id
                      }
                  end
              end
          end
        end)
    end
  end

  defp audit_transaction_meta(%Organization{id: org_id}) do
    %{"organization_id" => to_string(org_id)}
  end
end
