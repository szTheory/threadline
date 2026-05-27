defmodule Threadline.Audit do
  @moduledoc """
  Audited write-path helper — one call for transaction-local actor GUC, domain
  writes, optional semantic action linkage, and `audit_transaction_id` on success.

  Call from Phoenix context modules (or Oban workers) after `Threadline.Plug` /
  `Threadline.Job` have resolved `%Threadline.Semantics.AuditContext{}` and
  `%Threadline.Semantics.ActorRef{}`. The helper does not replace those edge modules.

  ## Options

  - `:actor_ref` — `%Threadline.Semantics.ActorRef{}` (required unless
    `audit_context:` or `allow_missing_actor: true` on capture-only paths)
  - `:audit_context` — `%Threadline.Semantics.AuditContext{}`; supplies
    `actor_ref`, `correlation_id`, and `request_id` (top-level opts override)
  - `:action` — atom or `{:name, action_opts}` for `Threadline.record_action/2`
    after the callback succeeds; links `audit_transactions.action_id` via
    `txid_current()` (correlation-ready path)
  - `:capture_only` — same as omitting `:action` (capture-only path)
  - `:allow_missing_actor` — when true and `:action` is absent, permits nil
    `actor_ref` (non-recommended for multi-tenant SaaS)
  - `:transaction_meta` — map stored on `audit_transactions.meta` when linking
  - `:correlation_id`, `:request_id`, `:job_id` — forwarded to `record_action/2`
    when `:action` is an atom

  ## Capture-only vs correlation-ready

  | `:action` | Strict `:correlation_id` timeline/export |
  |-----------|------------------------------------------|
  | present   | correlation-ready — `action_id` linked   |
  | absent    | capture-only — strict filters won't match |

  See `Threadline.Query.timeline/2` for strict `:correlation_id` semantics.

  ## Callback contract

  Pass `fn -> domain_result end` with `Repo` captured in the closure.

  **Allowed:** domain inserts/updates/deletes; `Repo.rollback/1` on failure.

  **Forbidden inside the callback:** `set_config` for `threadline.actor_ref`,
  `Threadline.record_action/2`, and nested `Repo.transaction/1` (breaks GUC and
  `txid_current()` linkage).

  ## Return shape

  On success, returns `{:ok, result}` where `result` is the callback return with
  `:audit_transaction_id` merged when capture produced an `audit_transactions` row
  (map callback) or wrapped as `%{result: value, audit_transaction_id: id}` for
  non-map returns. On failure, `{:error, reason}` (`:missing_actor`,
  `:missing_audit_transaction_for_link`, changesets, or rollback reasons).

  ## Errors

  - `{:error, :missing_actor}` — nil `actor_ref` when required
  - `{:error, :missing_audit_transaction_for_link}` — linkage `update_all` count != 1
  """

  import Ecto.Query

  alias Threadline.Capture.AuditTransaction
  alias Threadline.Semantics.{ActorRef, AuditAction, AuditContext}

  @type action_opt :: atom() | {atom(), keyword()}

  @doc """
  Runs `fun` inside `repo.transaction/1` after setting the transaction-local
  `threadline.actor_ref` GUC and optionally recording a semantic action.

  See module doc for options, callback rules, and return envelope.
  """
  @spec transaction(module(), keyword(), (-> term())) ::
          {:ok, term()} | {:error, term()}
  def transaction(repo, opts, fun) when is_function(fun, 0) do
    resolved = resolve_opts(opts)

    with :ok <- validate_actor(resolved) do
      repo.transaction(fn ->
        set_actor_guc!(repo, resolved.actor_ref)

        result = fun.()

        case finalize_success(repo, resolved, result) do
          {:error, reason} -> repo.rollback(reason)
          ok -> ok
        end
      end)
      |> normalize_transaction_result()
    end
  end

  # doc: start: audit-transaction-helper
  # Threadline.Audit.transaction(
  #   Repo,
  #   [
  #     audit_context: audit_context,
  #     action: :post_created_via_api,
  #     transaction_meta: %{"organization_id" => org_id}
  #   ],
  #   fn ->
  #     Repo.insert!(Post.changeset(%Post{}, attrs))
  #   end
  # )
  # doc: end: audit-transaction-helper

  defp resolve_opts(opts) do
    ctx = Keyword.get(opts, :audit_context)

    ctx_fields =
      case ctx do
        %AuditContext{} = ac ->
          %{
            actor_ref: ac.actor_ref,
            correlation_id: ac.correlation_id,
            request_id: ac.request_id,
            job_id: nil
          }

        _ ->
          %{actor_ref: nil, correlation_id: nil, request_id: nil, job_id: nil}
      end

    actor_ref = Keyword.get(opts, :actor_ref) || ctx_fields.actor_ref

    {action_name, action_extra_opts} = resolve_action(opts)

    %{
      actor_ref: actor_ref,
      correlation_id: pick_opt(opts, :correlation_id, ctx_fields.correlation_id),
      request_id: pick_opt(opts, :request_id, ctx_fields.request_id),
      job_id: pick_opt(opts, :job_id, ctx_fields.job_id),
      action_name: action_name,
      action_extra_opts: action_extra_opts,
      transaction_meta: Keyword.get(opts, :transaction_meta),
      allow_missing_actor: Keyword.get(opts, :allow_missing_actor, false)
    }
  end

  defp pick_opt(opts, key, ctx_value) do
    case Keyword.fetch(opts, key) do
      {:ok, value} -> value
      :error -> ctx_value
    end
  end

  defp resolve_action(opts) do
    cond do
      Keyword.get(opts, :capture_only, false) ->
        {nil, []}

      match?({name, extra} when is_atom(name) and is_list(extra), Keyword.get(opts, :action)) ->
        {name, extra} = Keyword.get(opts, :action)
        {name, extra}

      is_atom(Keyword.get(opts, :action)) ->
        {Keyword.get(opts, :action), []}

      true ->
        {nil, []}
    end
  end

  defp validate_actor(%{actor_ref: nil, action_name: action})
       when not is_nil(action) do
    {:error, :missing_actor}
  end

  defp validate_actor(%{actor_ref: nil, allow_missing_actor: false}) do
    {:error, :missing_actor}
  end

  defp validate_actor(_resolved), do: :ok

  defp set_actor_guc!(repo, %ActorRef{} = actor_ref) do
    json =
      actor_ref
      |> ActorRef.to_map()
      |> Jason.encode!()

    repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])
  end

  defp set_actor_guc!(_repo, nil), do: :ok

  defp finalize_success(repo, resolved, result) do
    case resolved.action_name do
      nil ->
        attach_audit_transaction_id(repo, result)

      action_name ->
        with {:ok, %AuditAction{id: action_id}} <- record_action(repo, resolved, action_name),
             :ok <- link_action(repo, action_id, resolved.transaction_meta),
             {:ok, audit_transaction_id} <- fetch_audit_transaction_id(repo) do
          envelope(result, audit_transaction_id)
        end
    end
  end

  defp record_action(repo, resolved, action_name) do
    base = [
      repo: repo,
      actor: resolved.actor_ref,
      correlation_id: resolved.correlation_id,
      request_id: resolved.request_id,
      job_id: resolved.job_id
    ]

    opts = base ++ resolved.action_extra_opts

    Threadline.record_action(action_name, opts)
    |> case do
      {:error, %Ecto.Changeset{} = cs} -> {:error, cs}
      other -> other
    end
  end

  defp link_action(repo, action_id, transaction_meta) do
    {count, _} =
      repo.update_all(
        from(at in AuditTransaction, where: at.txid == fragment("txid_current()")),
        set: [action_id: action_id, meta: transaction_meta]
      )

    if count == 1 do
      :ok
    else
      {:error, :missing_audit_transaction_for_link}
    end
  end

  defp fetch_audit_transaction_id(repo) do
    case repo.one(
           from(at in AuditTransaction,
             where: at.txid == fragment("txid_current()"),
             select: at.id
           )
         ) do
      nil -> {:ok, nil}
      id -> {:ok, id}
    end
  end

  defp attach_audit_transaction_id(repo, result) do
    case fetch_audit_transaction_id(repo) do
      {:ok, nil} -> result
      {:ok, id} -> envelope(result, id)
    end
  end

  defp envelope(result, audit_transaction_id) when is_map(result) do
    Map.put(result, :audit_transaction_id, audit_transaction_id)
  end

  defp envelope(result, audit_transaction_id) do
    %{result: result, audit_transaction_id: audit_transaction_id}
  end

  defp normalize_transaction_result({:ok, value}), do: {:ok, value}
  defp normalize_transaction_result({:error, reason}), do: {:error, reason}
  defp normalize_transaction_result(value), do: {:ok, value}
end
