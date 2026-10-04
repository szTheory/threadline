defmodule Threadline.Investigation do
  @moduledoc false

  alias Threadline.Query
  alias Threadline.Query.LegacyOpts
  alias Threadline.Query.RowReads
  alias Threadline.Query.TransactionLookup

  alias Threadline.Investigation.{
    IncidentBundle,
    IncidentChange,
    LinkedChange,
    LinkedTransaction
  }

  alias Threadline.Semantics.ActorRef

  @allowed_row_history_filter_keys ~w(from to repo)a
  @allowed_actor_window_filter_keys ~w(table from to correlation_id repo)a
  @allowed_correlation_bundle_filter_keys ~w(table actor_ref from to repo)a
  @row_history_opt_keys ~w(repo from to limit cursor page_size scope scope_query_fn surface storage_schema)a

  @doc """
  Returns row history for one schema row, ordered by `captured_at`
  descending, then `id` descending.

  Returns a bare list of `LinkedChange`, capped at 200 entries by default.
  Pass `limit: n` or `limit: :infinity` to override the cap, or `cursor:` to
  page through the full history as a `%Threadline.Page{}`.
  """
  def row_history(schema_module, id, opts \\ []) when is_list(opts) do
    validate_row_history_opts!(opts)
    validate_row_history_mode!(opts)

    if Keyword.has_key?(opts, :cursor) do
      schema_module
      |> RowReads.page(id, opts)
      |> linked_page(opts)
    else
      schema_module
      |> RowReads.list(id, opts)
      |> linked_changes(opts)
    end
  end

  @deprecated "Use Threadline.row_history/3 instead."
  @doc """
  Returns row history for one schema row using the retired `(filters, opts)`
  shape, with 0.12's unbounded default.
  """
  @spec row_history(module(), term(), keyword(), keyword()) :: [LinkedChange.t()]
  def row_history(schema_module, id, filters, opts)
      when is_list(filters) and is_list(opts) do
    row_history(schema_module, id, LegacyOpts.row_history(filters, opts))
  end

  @deprecated "Use Threadline.row_history/3 instead."
  @doc """
  Returns one keyset page of row history for a single schema row.

  Uses the same `(captured_at, id)` keyset rules as `Threadline.timeline_page/2`.
  """
  @spec row_history_page(module(), term()) :: Threadline.Page.t(LinkedChange.t())
  @spec row_history_page(module(), term(), keyword()) :: Threadline.Page.t(LinkedChange.t())
  @spec row_history_page(module(), term(), keyword(), keyword()) ::
          Threadline.Page.t(LinkedChange.t())
  def row_history_page(schema_module, id, filters \\ [], opts \\ []) do
    filters =
      validate_helper_filters!(filters, @allowed_row_history_filter_keys, :row_history_page)

    row_history(schema_module, id, LegacyOpts.cursor(filters ++ opts))
  end

  @doc """
  Returns change rows across tables for one actor, ordered by `captured_at`
  descending, then `id` descending.

  Returns a bare list of `LinkedChange` by default. Pass `cursor:` (with
  optional `page_size:`) to page through the results as a
  `%Threadline.Page{}` instead.

  `filters` accepts timeline filters except `:actor_ref`, which is fixed by the
  helper argument.
  """
  def actor_window(%ActorRef{} = actor_ref, filters \\ [], opts \\ []) do
    filters =
      filters
      |> validate_helper_filters!(@allowed_actor_window_filter_keys, :actor_window)
      |> Keyword.put(:actor_ref, actor_ref)

    if Keyword.has_key?(opts, :cursor) do
      filters
      |> Query.timeline_page(opts)
      |> linked_page(opts)
    else
      filters
      |> Query.timeline(opts)
      |> linked_changes(opts)
    end
  end

  @deprecated "Use Threadline.actor_window/3 instead."
  @doc """
  Returns one keyset page of change rows across tables for one actor.
  """
  @spec actor_window_page(ActorRef.t()) :: Threadline.Page.t(LinkedChange.t())
  @spec actor_window_page(ActorRef.t(), keyword()) :: Threadline.Page.t(LinkedChange.t())
  @spec actor_window_page(ActorRef.t(), keyword(), keyword()) ::
          Threadline.Page.t(LinkedChange.t())
  def actor_window_page(%ActorRef{} = actor_ref, filters \\ [], opts \\ []) do
    actor_window(actor_ref, filters, LegacyOpts.cursor(opts))
  end

  @doc """
  Returns change rows linked to one `correlation_id` with strict inner-join semantics.

  Returns a bare list of `LinkedChange` by default. Pass `cursor:` (with
  optional `page_size:`) to page through the results as a
  `%Threadline.Page{}` instead.

  `filters` accepts timeline filters except `:correlation_id`, which is fixed by
  the helper argument.
  """
  def correlation_bundle(correlation_id, filters \\ [], opts \\ [])
      when is_binary(correlation_id) do
    filters =
      filters
      |> validate_helper_filters!(
        @allowed_correlation_bundle_filter_keys,
        :correlation_bundle
      )
      |> Keyword.put(:correlation_id, correlation_id)

    if Keyword.has_key?(opts, :cursor) do
      filters
      |> Query.timeline_page(opts)
      |> linked_page(opts)
    else
      filters
      |> Query.timeline(opts)
      |> linked_changes(opts)
    end
  end

  @deprecated "Use Threadline.correlation_bundle/3 instead."
  @doc """
  Returns one keyset page of changes linked to one `correlation_id`.
  """
  @spec correlation_bundle_page(String.t()) :: Threadline.Page.t(LinkedChange.t())
  @spec correlation_bundle_page(String.t(), keyword()) :: Threadline.Page.t(LinkedChange.t())
  @spec correlation_bundle_page(String.t(), keyword(), keyword()) ::
          Threadline.Page.t(LinkedChange.t())
  def correlation_bundle_page(correlation_id, filters \\ [], opts \\ [])
      when is_binary(correlation_id) do
    correlation_bundle(correlation_id, filters, LegacyOpts.cursor(opts))
  end

  @doc """
  Returns one transaction-oriented investigation slice with linked transaction
  and optional action metadata.
  """
  @spec transaction_context(Ecto.UUID.t(), keyword()) ::
          {:ok, LinkedTransaction.t()} | {:error, :not_found}
  def transaction_context(transaction_id, opts \\ []) do
    TransactionLookup.validate_opts!(opts, "transaction_context")

    case TransactionLookup.fetch(transaction_id, opts) do
      :not_found ->
        {:error, :not_found}

      {:ok, row, changes} ->
        {:ok,
         %LinkedTransaction{
           transaction: row,
           action: linked_action(row),
           changes: to_linked_changes(changes)
         }}
    end
  end

  @doc """
  Returns one transaction-focused incident bundle with linked context and
  packaged diffs.
  """
  @spec incident_bundle(Ecto.UUID.t(), keyword()) ::
          {:ok, IncidentBundle.t()} | {:error, :not_found}
  def incident_bundle(transaction_id, opts \\ []) do
    TransactionLookup.validate_opts!(opts, "incident_bundle")

    case TransactionLookup.fetch(transaction_id, opts) do
      :not_found ->
        {:error, :not_found}

      {:ok, row, changes} ->
        {:ok,
         %IncidentBundle{
           transaction: row,
           action: linked_action(row),
           changes: changes |> to_linked_changes() |> Enum.map(&to_incident_change/1)
         }}
    end
  end

  defp validate_row_history_opts!(opts) do
    Enum.each(opts, fn {key, _value} ->
      if key not in @row_history_opt_keys do
        allowed = Enum.map_join(@row_history_opt_keys, ", ", &inspect/1)

        raise ArgumentError,
              "unknown row_history option key #{inspect(key)}. Allowed: #{allowed}"
      end
    end)
  end

  defp validate_row_history_mode!(opts) do
    cond do
      Keyword.has_key?(opts, :limit) and Keyword.has_key?(opts, :cursor) ->
        raise ArgumentError,
              "row_history/3 cannot combine :limit with :cursor — pass either :limit " <>
                "(bare list) or :cursor (Page), not both"

      Keyword.has_key?(opts, :page_size) and not Keyword.has_key?(opts, :cursor) ->
        raise ArgumentError,
              "row_history/3's :page_size only applies with :cursor — pass cursor: :start " <>
                "to page"

      true ->
        :ok
    end
  end

  defp validate_helper_filters!(filters, allowed_keys, helper_name) when is_list(filters) do
    Enum.each(filters, fn {key, _value} ->
      if key not in allowed_keys do
        allowed = Enum.map_join(allowed_keys, ", ", &inspect/1)

        raise ArgumentError,
              "unknown #{helper_name} filter key #{inspect(key)}. Allowed: #{allowed}"
      end
    end)

    filters
  end

  defp linked_page(%Threadline.Page{} = page, opts) do
    %Threadline.Page{page | entries: linked_changes(page.entries, opts)}
  end

  defp linked_changes(changes, opts) when is_list(changes) do
    repo = Query.timeline_repo!([], opts)

    changes
    |> Query.preload_investigation_context(repo, opts)
    |> to_linked_changes()
  end

  defp to_linked_changes(changes) do
    Enum.map(changes, fn audit_change ->
      transaction = audit_change.transaction

      %LinkedChange{
        audit_change: audit_change,
        transaction: transaction,
        action: linked_action(transaction)
      }
    end)
  end

  defp to_incident_change(%LinkedChange{} = linked_change) do
    %IncidentChange{
      linked_change: linked_change,
      change_diff: Threadline.change_diff(linked_change.audit_change)
    }
  end

  defp linked_action(nil), do: nil
  defp linked_action(transaction), do: Map.get(transaction, :action)
end
