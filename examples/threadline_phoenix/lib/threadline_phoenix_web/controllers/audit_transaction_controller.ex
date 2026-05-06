defmodule ThreadlinePhoenixWeb.AuditTransactionController do
  @moduledoc false

  use ThreadlinePhoenixWeb, :controller

  alias ThreadlinePhoenix.Repo

  @doc """
  Returns one bundled incident drill-down for a single `audit_transactions.id`.

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
            case Threadline.incident_bundle(uuid, repo: Repo) do
              {:ok, bundle} ->
                render(conn, :show, bundle: bundle)

              {:error, :not_found} ->
                conn
                |> put_status(:not_found)
                |> json(%{errors: %{detail: "audit transaction not found"}})
            end
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
