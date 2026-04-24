defmodule ThreadlinePhoenixWeb.PostJSON do
  @moduledoc false

  def post(%{post: post}) do
    %{
      id: post.id,
      title: post.title,
      slug: post.slug,
      inserted_at: post.inserted_at
    }
  end
end
