defmodule ThreadlinePhoenixWeb.PostJSON do
  @moduledoc false

  def post(%{post: post} = assigns) do
    base = %{
      id: post.id,
      title: post.title,
      slug: post.slug,
      inserted_at: post.inserted_at
    }

    case Map.get(assigns, :audit_transaction_id) do
      nil -> base
      at_id -> Map.put(base, :audit_transaction_id, at_id)
    end
  end
end
