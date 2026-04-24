defmodule ThreadlinePhoenixWeb.PostController do
  use ThreadlinePhoenixWeb, :controller

  alias Threadline.Semantics.AuditContext
  alias ThreadlinePhoenix.Blog

  def create(conn, params) do
    audit_context = conn.assigns[:audit_context]

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
        case Blog.create_post(audit_context, attrs) do
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
end
