defmodule Threadline.Query.TransactionLookup do
  @moduledoc false

  # Hidden shared existence check behind the facade's single-subject
  # transaction lookups (`Threadline.audit_transaction/2`, and the hidden
  # fetches `transaction_context/2` and `incident_bundle/2` build on in later
  # plans of this phase). A transaction "exists" when its `audit_transactions`
  # row passes the scope — this module decides that, and only that.

  import Ecto.Query

  alias Threadline.Capture.AuditTransaction
  alias Threadline.Query

  @lookup_opt_keys [:repo, :storage_schema, :scope, :scope_query_fn]

  @doc false
  # Shared option allowlist for every facade lookup built on `fetch_row/2`.
  # `function_name` names the caller in the error message (each caller
  # validates with its own name; this function does not call itself).
  @spec validate_opts!(keyword(), String.t()) :: :ok
  def validate_opts!(opts, function_name) when is_list(opts) and is_binary(function_name) do
    Enum.each(opts, fn
      {key, _value} ->
        if key not in @lookup_opt_keys do
          allowed = Enum.map_join(@lookup_opt_keys, ", ", &inspect/1)

          raise ArgumentError,
                "unknown #{function_name} option key #{inspect(key)}. Allowed: #{allowed}"
        end

      other ->
        raise ArgumentError,
              "#{function_name} options must be a keyword list, got entry: #{inspect(other)}"
    end)

    :ok
  end

  def validate_opts!(opts, function_name) when is_binary(function_name) do
    raise ArgumentError,
          "#{function_name} options must be a keyword list, got: #{inspect(opts)}"
  end

  @doc false
  # Non-binary ids are a programmer error (ArgumentError). A binary that is
  # not a valid UUID cannot name an existing row, so it resolves to
  # `:not_found` rather than raising — no third return shape is introduced.
  @spec resolve_id(term()) :: {:ok, Ecto.UUID.t()} | :not_found
  def resolve_id(id) when is_binary(id) do
    case Ecto.UUID.cast(id) do
      {:ok, canonical} -> {:ok, canonical}
      :error -> :not_found
    end
  end

  def resolve_id(id) do
    raise ArgumentError, "invalid audit transaction id: #{inspect(id)}"
  end

  @doc false
  # The one hidden existence fetch every single-subject transaction lookup
  # shares: the row first. Scoped with a hardcoded `surface: :transaction_header`
  # (single `[at]` binding) and `params: %{transaction_id: id}` — never read
  # from `opts`, so a caller cannot relabel the binding shape. A scope
  # rejection of the row and a missing row both resolve to `:not_found`, so
  # existence never leaks across tenants. Always hydrates `.action`: 0
  # extra queries when `action_id` is nil, 1 otherwise. No `rescue` around the
  # repo call — a misconfigured `:storage_schema` stays loud rather than being
  # mistaken for absence. No telemetry on a miss; callers instrument their own
  # lookups. Does NOT call `validate_opts!/2` itself — callers validate with
  # their own function name before calling this.
  @spec fetch_row(term(), keyword()) :: {:ok, AuditTransaction.t()} | :not_found
  def fetch_row(id, opts) when is_list(opts) do
    case resolve_id(id) do
      :not_found ->
        :not_found

      {:ok, uuid} ->
        repo = Keyword.fetch!(opts, :repo)

        row =
          AuditTransaction
          |> where([at], at.id == ^uuid)
          |> Query.maybe_apply_scope(
            scope: Keyword.get(opts, :scope),
            scope_query_fn: Keyword.get(opts, :scope_query_fn),
            surface: :transaction_header,
            params: %{transaction_id: id}
          )
          |> repo.one(Query.storage_opts([], opts))

        case row do
          nil -> :not_found
          %AuditTransaction{} = row -> {:ok, Query.hydrate_actions(row, repo, opts)}
        end
    end
  end
end
