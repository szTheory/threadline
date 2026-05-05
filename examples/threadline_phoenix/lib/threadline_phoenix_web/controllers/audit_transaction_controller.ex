defmodule ThreadlinePhoenixWeb.AuditTransactionController do
  @moduledoc false

  use ThreadlinePhoenixWeb, :controller

  alias ThreadlinePhoenix.Repo

  @doc """
  Returns all captured changes for one `audit_transactions.id`, each with a
  `Threadline.change_diff/2` map suitable for JSON APIs.

  **Reference-app contract:** requests must arrive with an authenticated actor.
  Real hosts still own their tenancy and policy rules.
  """
  def changes(conn, %{"id" => id}) do
    case authenticated_actor(conn) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{errors: %{detail: "authentication required for incident drill-down"}})

      _actor_ref ->
        case Ecto.UUID.cast(id) do
          :error ->
            conn
            |> put_status(:bad_request)
            |> json(%{errors: %{detail: "invalid audit transaction id"}})

          {:ok, uuid} ->
            changes = Threadline.audit_changes_for_transaction(uuid, repo: Repo)

            json(conn, %{
              audit_transaction_id: uuid,
              changes:
                Enum.map(changes, fn ac ->
                  %{
                    audit_change_id: to_string(ac.id),
                    change_diff: Threadline.change_diff(ac, [])
                  }
                end)
            })
        end
    end
  end

  defp authenticated_actor(conn) do
    conn.assigns
    |> Map.get(:audit_context)
    |> case do
      %{actor_ref: actor_ref} -> actor_ref
      _ -> nil
    end
  end
end
