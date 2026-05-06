defmodule ThreadlinePhoenixWeb.AuditTransactionJSON do
  @moduledoc false

  alias Threadline.Investigation.{IncidentBundle, IncidentChange, LinkedChange}
  alias Threadline.Capture.AuditTransaction
  alias Threadline.Semantics.ActorRef
  alias Threadline.Semantics.AuditAction

  def show(%{bundle: %IncidentBundle{} = bundle}) do
    %{
      audit_transaction_id: bundle.transaction.id,
      transaction: transaction_json(bundle.transaction),
      action: action_json(bundle.action),
      changes: Enum.map(bundle.changes, &change_json/1)
    }
  end

  defp transaction_json(%AuditTransaction{} = transaction) do
    %{
      occurred_at: transaction.occurred_at,
      actor_ref: actor_ref_json(transaction.actor_ref),
      source: transaction.source
    }
  end

  defp action_json(nil), do: nil

  defp action_json(%AuditAction{} = action) do
    %{
      id: action.id,
      name: action.name,
      status: action.status,
      correlation_id: action.correlation_id,
      request_id: action.request_id
    }
  end

  defp change_json(%IncidentChange{
         linked_change: %LinkedChange{} = linked_change,
         change_diff: change_diff
       }) do
    audit_change = linked_change.audit_change

    %{
      audit_change_id: audit_change.id,
      table_schema: audit_change.table_schema,
      table_name: audit_change.table_name,
      table_pk: audit_change.table_pk,
      op: audit_change.op,
      captured_at: audit_change.captured_at,
      change_diff: change_diff
    }
  end

  defp actor_ref_json(nil), do: nil
  defp actor_ref_json(%ActorRef{} = actor_ref), do: ActorRef.to_map(actor_ref)
end
