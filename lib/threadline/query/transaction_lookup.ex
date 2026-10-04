defmodule Threadline.Query.TransactionLookup do
  @moduledoc false

  # Hidden shared existence check behind the facade's single-subject
  # transaction lookups (`Threadline.audit_transaction/2`, and the hidden
  # fetches `transaction_context/2` and `incident_bundle/2` build on in later
  # plans of this phase). A transaction "exists" when its `audit_transactions`
  # row passes the scope — this module decides that, and only that.

  import Ecto.Query

  alias Threadline.Capture.{AuditChange, AuditTransaction}
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
  # The shared scoped row read behind every lookup that needs the bare
  # `audit_transactions` row under a caller-chosen `surface`. `fetch_row/2`
  # below always calls this with the hardcoded `:transaction_header` surface
  # (single `[at]` binding); the deprecated `Threadline.Query.audit_transaction/2`
  # delegate calls it with its own 0.12 surface default/override instead, so an
  # adopter scope fn written against 0.12 keeps seeing exactly what it saw
  # before. `raw_id` (not the resolved `uuid`) is threaded into `params` so a
  # scope fn sees the same value a caller passed in. No `rescue` around the
  # repo call — a misconfigured `:storage_schema` stays loud rather than being
  # mistaken for absence.
  @spec scoped_row(Ecto.UUID.t(), term(), atom(), keyword()) :: AuditTransaction.t() | nil
  def scoped_row(uuid, raw_id, surface, opts) when is_list(opts) do
    repo = Keyword.fetch!(opts, :repo)

    AuditTransaction
    |> where([at], at.id == ^uuid)
    |> Query.maybe_apply_scope(
      scope: Keyword.get(opts, :scope),
      scope_query_fn: Keyword.get(opts, :scope_query_fn),
      surface: surface,
      params: %{transaction_id: raw_id}
    )
    |> repo.one(Query.storage_opts([], opts))
  end

  @doc false
  # The one hidden existence fetch every single-subject transaction lookup
  # shares: the row first, read via `scoped_row/4` with a hardcoded
  # `surface: :transaction_header` — never read from `opts`, so a caller
  # cannot relabel the binding shape. A scope rejection of the row and a
  # missing row both resolve to `:not_found`, so existence never leaks across
  # tenants. Always hydrates `.action`: 0 extra queries when `action_id` is
  # nil, 1 otherwise. No telemetry on a miss; callers instrument their own
  # lookups. Does NOT call `validate_opts!/2` itself — callers validate with
  # their own function name before calling this.
  @spec fetch_row(term(), keyword()) :: {:ok, AuditTransaction.t()} | :not_found
  def fetch_row(id, opts) when is_list(opts) do
    case resolve_id(id) do
      :not_found ->
        :not_found

      {:ok, uuid} ->
        repo = Keyword.fetch!(opts, :repo)

        case scoped_row(uuid, id, :transaction_header, opts) do
          nil -> :not_found
          %AuditTransaction{} = row -> {:ok, Query.hydrate_actions(row, repo, opts)}
        end
    end
  end

  @doc false
  # The shared row-first fetch behind `transaction_context/2` and
  # `incident_bundle/2`. Existence is decided once by `fetch_row/2` (hardcoded
  # `surface: :transaction_header`); the changes read is a second, independent
  # query scoped with a hardcoded `surface: :transaction` ([ac, at] binding)
  # that reuses the already-hydrated row rather than preloading or hydrating
  # actions a second time. Two independent READ COMMITTED reads, not wrapped
  # in a transaction — a retention delete racing between them still yields a
  # valid result: the row plus fewer (or zero) changes.
  @spec fetch(term(), keyword()) ::
          {:ok, AuditTransaction.t(), [AuditChange.t()]} | :not_found
  def fetch(id, opts) when is_list(opts) do
    case fetch_row(id, opts) do
      :not_found ->
        :not_found

      {:ok, row} ->
        repo = Keyword.fetch!(opts, :repo)

        changes =
          AuditChange
          |> where([ac], ac.transaction_id == ^row.id)
          |> join(:inner, [ac], at in AuditTransaction, on: ac.transaction_id == at.id)
          |> Query.maybe_apply_scope(
            scope: Keyword.get(opts, :scope),
            scope_query_fn: Keyword.get(opts, :scope_query_fn),
            surface: :transaction,
            params: %{transaction_id: id}
          )
          |> order_by([ac], desc: ac.captured_at)
          |> order_by([ac], desc: ac.id)
          |> select([ac, _at], ac)
          |> repo.all(Query.storage_opts([], opts))
          |> Enum.map(&%{&1 | transaction: row})

        {:ok, row, changes}
    end
  end
end
