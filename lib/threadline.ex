defmodule Threadline do
  @moduledoc """
  Audit platform for Elixir teams using Phoenix, Ecto, and PostgreSQL.

  Threadline combines trigger-backed row-change capture, rich action semantics
  (actor/intent/context), and operator-grade exploration.
  """

  alias Threadline.Semantics.ActorRef
  alias Threadline.Semantics.AuditAction

  @doc """
  Records a semantic audit action.

  ## Required options

  - `:actor` or `:actor_ref` — `%ActorRef{}` identifying who performed the action
  - `:repo` — the `Ecto.Repo` module to use for insertion

  ## Optional options

  - `:status` — `:ok` or `:error` (default: `:ok`)
  - `:verb` — string or atom (e.g., `"update"`)
  - `:category` — string or atom (e.g., `"membership"`)
  - `:reason` — atom (e.g., `:insufficient_permissions`)
  - `:comment` — free-text string explanation
  - `:correlation_id` — cross-boundary correlation ID string
  - `:request_id` — request ID string (from `Plug.RequestId` / `x-request-id`)
  - `:job_id` — Oban job ID string

  ## Returns

  - `{:ok, %AuditAction{}}` on success
  - `{:error, %Ecto.Changeset{}}` if changeset validation fails
  - `{:error, :missing_actor}` if no actor was provided
  - `{:error, :invalid_actor_ref}` if the actor fails ActorRef validation
  - `{:error, :missing_repo}` if `:repo` is not provided
  """
  def record_action(name, opts \\ []) when is_atom(name) do
    repo = Keyword.get(opts, :repo)
    actor_ref = Keyword.get(opts, :actor) || Keyword.get(opts, :actor_ref)

    result =
      with :ok <- validate_repo(repo),
           {:ok, validated_ref} <- validate_actor(actor_ref) do
        attrs = build_attrs(name, validated_ref, opts)
        changeset = AuditAction.changeset(attrs)
        repo.insert(changeset)
      end

    case result do
      {:ok, _action} ->
        Threadline.Telemetry.emit_action_recorded(:ok)
        Threadline.Telemetry.emit_transaction_committed_proxy()

      {:error, _} ->
        Threadline.Telemetry.emit_action_recorded(:error)
    end

    result
  end

  @doc """
  Returns `AuditChange` records for a given schema record, ordered by
  `captured_at` descending.

  ## Options

  - `:repo` — required `Ecto.Repo` module
  """
  def history(schema_module, id, opts), do: Threadline.Query.history(schema_module, id, opts)

  @doc """
  Returns `AuditTransaction` records for a given actor, ordered by
  `occurred_at` descending.

  ## Options

  - `:repo` — required `Ecto.Repo` module
  """
  def actor_history(actor_ref, opts), do: Threadline.Query.actor_history(actor_ref, opts)

  @doc """
  Returns `AuditChange` records across tables, filtered by the given options,
  ordered by `captured_at` descending.

  ## Options

  - `:table` — string or atom; filters by `table_name`
  - `:actor_ref` — `%ActorRef{}`; filters by actor via a JOIN to `audit_transactions`
  - `:from` — `DateTime`; inclusive lower bound on `captured_at`
  - `:to` — `DateTime`; inclusive upper bound on `captured_at`
  - `:repo` — required `Ecto.Repo` module
  """
  def timeline(filters \\ [], opts \\ []), do: Threadline.Query.timeline(filters, opts)

  defp validate_repo(nil), do: {:error, :missing_repo}
  defp validate_repo(_repo), do: :ok

  defp validate_actor(nil), do: {:error, :missing_actor}
  defp validate_actor(%ActorRef{} = ref), do: {:ok, ref}
  defp validate_actor(_), do: {:error, :invalid_actor_ref}

  defp build_attrs(name, actor_ref, opts) do
    %{
      name: Atom.to_string(name),
      actor_ref: actor_ref,
      status: Keyword.get(opts, :status, :ok),
      verb: stringify_opt(Keyword.get(opts, :verb)),
      category: stringify_opt(Keyword.get(opts, :category)),
      reason: stringify_opt(Keyword.get(opts, :reason)),
      comment: Keyword.get(opts, :comment),
      correlation_id: Keyword.get(opts, :correlation_id),
      request_id: Keyword.get(opts, :request_id),
      job_id: Keyword.get(opts, :job_id)
    }
  end

  defp stringify_opt(nil), do: nil
  defp stringify_opt(v) when is_atom(v), do: Atom.to_string(v)
  defp stringify_opt(v) when is_binary(v), do: v
end
