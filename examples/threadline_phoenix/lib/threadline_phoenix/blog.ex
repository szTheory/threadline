defmodule ThreadlinePhoenix.Blog do
  @moduledoc false

  alias Threadline.Semantics.AuditContext
  alias ThreadlinePhoenix.{Post, Repo}

  alias Threadline.Job

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

  @doc """
  Updates a post title from a background job inside one transaction: session GUC,
  row update, then `Threadline.record_action/2` for operator intent.

  `args` is the Oban job args map (including optional `"job_id"` and
  `"correlation_id"`). `attrs` must include `"post_id"` and `"title"`.
  """
  def touch_post_for_job(args, attrs) when is_map(args) and is_map(attrs) do
    case Job.actor_ref_from_args(args) do
      {:error, _} = err ->
        err

      {:ok, actor_ref} ->
        post_id = attrs["post_id"] || attrs[:post_id]
        title = attrs["title"] || attrs[:title]

        if is_nil(post_id) or is_nil(title) do
          {:error, :missing_post_attrs}
        else
          json =
            actor_ref
            |> Threadline.Semantics.ActorRef.to_map()
            |> Jason.encode!()

          Repo.transaction(fn ->
            Repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])

            post = Repo.get!(Post, post_id)

            case Repo.update(Post.changeset(post, %{title: title})) do
              {:error, changeset} ->
                Repo.rollback(changeset)

              {:ok, updated} ->
                opts =
                  [repo: Repo, actor: actor_ref] ++ Job.context_opts(args)

                case Threadline.record_action(:post_title_refreshed_from_queue, opts) do
                  {:ok, _} -> updated
                  {:error, cs} -> Repo.rollback(cs)
                end
            end
          end)
        end
    end
  end
end
