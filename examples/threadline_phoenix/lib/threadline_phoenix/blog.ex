defmodule ThreadlinePhoenix.Blog do
  @moduledoc false

  import Ecto.Query

  alias Threadline.Capture.AuditTransaction
  alias Threadline.Semantics.{AuditAction, AuditContext}
  alias ThreadlinePhoenix.{Post, Repo}

  alias Threadline.Job

  @doc """
  Creates a post inside a single DB transaction after setting the transaction-local
  `threadline.actor_ref` GUC (see `Threadline.Plug` moduledoc).

  On success, `Threadline.record_action/2` runs in the **same** transaction as the
  audited insert so capture and semantics share one `audit_transactions` row; the
  row is then linked via `audit_transactions.action_id` so strict
  `:correlation_id` filters on `Threadline.timeline/2` match.
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
            {:error, changeset} ->
              Repo.rollback(changeset)

            {:ok, post} ->
              opts = [
                repo: Repo,
                actor: actor_ref,
                correlation_id: audit_context.correlation_id,
                request_id: audit_context.request_id
              ]

              case Threadline.record_action(:post_created_via_api, opts) do
                {:error, cs} ->
                  Repo.rollback(cs)

                {:ok, %AuditAction{id: action_id}} ->
                  {count, _} =
                    Repo.update_all(
                      from(at in AuditTransaction,
                        where: at.txid == fragment("txid_current()")
                      ),
                      set: [action_id: action_id]
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

                  %{post: post, audit_transaction_id: audit_transaction_id}
              end
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
