defmodule Threadline.Investigation do
  @moduledoc """
  Higher-level investigation helpers layered on top of Threadline query primitives.

  Use these helpers when you want the canonical operator questions as one public
  entrypoint instead of assembling low-level filter lists manually.
  """

  alias Threadline.Query
  alias Threadline.Query.TimelinePage

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

  @doc """
  Returns change history for one schema row, ordered by `captured_at` descending,
  then `id` descending.

  `filters` accepts only `:from`, `:to`, and optional `:repo` parity with the
  lower-level timeline APIs. Pass paging controls in `opts` only when using
  `row_history_page/4`.
  """
  def row_history(schema_module, id, filters \\ [], opts \\ []) do
    filters = validate_helper_filters!(filters, @allowed_row_history_filter_keys, :row_history)

    schema_module
    |> Query.row_history(id, filters, opts)
    |> linked_changes(opts)
  end

  @doc """
  Returns one keyset page of row history for a single schema row.

  Uses the same `(captured_at, id)` keyset rules as `Threadline.timeline_page/2`.
  """
  def row_history_page(schema_module, id, filters \\ [], opts \\ []) do
    filters =
      validate_helper_filters!(filters, @allowed_row_history_filter_keys, :row_history_page)

    schema_module
    |> Query.row_history_page(id, filters, opts)
    |> linked_page(opts)
  end

  @doc """
  Returns change rows across tables for one actor, ordered by `captured_at`
  descending, then `id` descending.

  `filters` accepts timeline filters except `:actor_ref`, which is fixed by the
  helper argument.
  """
  def actor_window(%ActorRef{} = actor_ref, filters \\ [], opts \\ []) do
    filters =
      filters
      |> validate_helper_filters!(@allowed_actor_window_filter_keys, :actor_window)
      |> Keyword.put(:actor_ref, actor_ref)

    filters
    |> Query.timeline(opts)
    |> linked_changes(opts)
  end

  @doc """
  Returns one keyset page of change rows across tables for one actor.
  """
  def actor_window_page(%ActorRef{} = actor_ref, filters \\ [], opts \\ []) do
    filters =
      filters
      |> validate_helper_filters!(@allowed_actor_window_filter_keys, :actor_window_page)
      |> Keyword.put(:actor_ref, actor_ref)

    filters
    |> Query.timeline_page(opts)
    |> linked_page(opts)
  end

  @doc """
  Returns change rows linked to one `correlation_id` with strict inner-join semantics.

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

    filters
    |> Query.timeline(opts)
    |> linked_changes(opts)
  end

  @doc """
  Returns one keyset page of changes linked to one `correlation_id`.
  """
  def correlation_bundle_page(correlation_id, filters \\ [], opts \\ [])
      when is_binary(correlation_id) do
    filters =
      filters
      |> validate_helper_filters!(
        @allowed_correlation_bundle_filter_keys,
        :correlation_bundle_page
      )
      |> Keyword.put(:correlation_id, correlation_id)

    filters
    |> Query.timeline_page(opts)
    |> linked_page(opts)
  end

  @doc """
  Returns one transaction-oriented investigation slice with linked transaction
  and optional action metadata.
  """
  def transaction_context(transaction_id, opts \\ []) do
    changes =
      Query.audit_changes_for_transaction(
        transaction_id,
        Keyword.put(opts, :preload, transaction: :action)
      )

    linked_changes = to_linked_changes(changes)
    transaction = linked_transaction(linked_changes)

    %LinkedTransaction{
      transaction: transaction,
      action: linked_action(transaction),
      changes: linked_changes
    }
  end

  @doc """
  Returns one transaction-focused incident bundle with linked context and
  packaged diffs.
  """
  def incident_bundle(transaction_id, opts \\ []) do
    transaction_opts =
      opts
      |> Keyword.put(:preload, :action)
      |> Keyword.put(:surface, :transaction_header)
      |> Keyword.put(:params, %{transaction_id: transaction_id})

    case Query.audit_transaction(transaction_id, transaction_opts) do
      nil ->
        {:error, :not_found}

      transaction ->
        changes =
          Query.audit_changes_for_transaction(
            transaction_id,
            opts
            |> Keyword.put(:preload, transaction: :action)
            |> Keyword.put(:surface, :transaction)
            |> Keyword.put(:params, %{transaction_id: transaction_id})
          )

        linked_changes = to_linked_changes(changes)

        {:ok,
         %IncidentBundle{
           transaction: transaction,
           action: linked_action(transaction),
           changes: Enum.map(linked_changes, &to_incident_change/1)
         }}
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

  defp linked_page(%TimelinePage{} = page, opts) do
    %TimelinePage{page | entries: linked_changes(page.entries, opts)}
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

  defp linked_transaction([%LinkedChange{transaction: transaction} | _]), do: transaction
  defp linked_transaction([]), do: nil

  defp linked_action(nil), do: nil
  defp linked_action(transaction), do: Map.get(transaction, :action)
end
