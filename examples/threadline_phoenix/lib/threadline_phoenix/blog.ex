defmodule ThreadlinePhoenix.Blog do
  @moduledoc false

  alias Threadline.Semantics.AuditContext
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
  def create_post(%AuditContext{} = audit_context, attrs, opts \\ []) when is_map(attrs) do
    # doc: start: blog-create-post-transaction
    Threadline.Audit.transaction(
      Repo,
      [
        audit_context: audit_context,
        action: :post_created_via_api,
        transaction_meta: audit_transaction_meta(opts)
      ],
      fn ->
        case Repo.insert(Post.changeset(%Post{}, attrs)) do
          {:error, changeset} -> Repo.rollback(changeset)
          {:ok, post} -> %{post: post}
        end
      end
    )

    # doc: end: blog-create-post-transaction
  end

  defp audit_transaction_meta(opts) do
    case Keyword.get(opts, :organization_id) do
      org_id when is_binary(org_id) and org_id != "" ->
        %{"organization_id" => org_id}

      _ ->
        nil
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
          action_opts = Job.context_opts(args)

          Threadline.Audit.transaction(
            Repo,
            Keyword.merge(action_opts, [
              actor_ref: actor_ref,
              action: {:post_title_refreshed_from_queue, action_opts}
            ]),
            fn ->
              post = Repo.get!(Post, post_id)

              case Repo.update(Post.changeset(post, %{title: title})) do
                {:error, cs} -> Repo.rollback(cs)
                {:ok, updated} -> %{post: updated}
              end
            end
          )
        end
    end
  end
end
