defmodule ThreadlinePhoenixWeb.PostController do
  use ThreadlinePhoenixWeb, :controller

  alias Threadline.Semantics.AuditContext
  alias ThreadlinePhoenix.Blog

  def create(conn, params) do
    audit_context = conn.assigns[:audit_context]
    organization_id = active_organization_id(conn.assigns[:current_scope])

    attrs =
      case params["post"] do
        nil -> %{}
        post_params when is_map(post_params) -> Map.take(post_params, ["title", "slug"])
      end

    cond do
      not match?(%AuditContext{}, audit_context) ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{errors: %{detail: "audit context unavailable"}})

      true ->
        case Blog.create_post(audit_context, attrs, organization_id: organization_id) do
          {:error, :missing_actor} ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{errors: %{detail: "missing actor"}})

          {:error, %Ecto.Changeset{} = changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: ThreadlinePhoenixWeb.ErrorJSON.translate_changeset(changeset)})

          {:ok, %{post: post, audit_transaction_id: audit_transaction_id}} ->
            conn
            |> put_status(:created)
            |> render(:post, post: post, audit_transaction_id: audit_transaction_id)
        end
    end
  end

  defp active_organization_id(%{active_organization_id: org_id})
       when is_binary(org_id) and org_id != "" do
    org_id
  end

  defp active_organization_id(_scope), do: nil
end
