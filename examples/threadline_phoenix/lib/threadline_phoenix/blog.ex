defmodule ThreadlinePhoenix.Blog do
  @moduledoc false

  alias Threadline.Semantics.AuditContext
  alias ThreadlinePhoenix.{Post, Repo}

  @doc """
  Creates a post inside a single DB transaction after setting the transaction-local
  `threadline.actor_ref` GUC (see `Threadline.Plug` moduledoc).
  """
  def create_post(%AuditContext{} = audit_context, attrs) when is_map(attrs) do
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

          case Repo.insert(Post.changeset(%Post{}, attrs)) do
            {:ok, post} -> post
            {:error, changeset} -> Repo.rollback(changeset)
          end
        end)
    end
  end
end
