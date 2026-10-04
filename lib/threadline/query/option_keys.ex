defmodule Threadline.Query.OptionKeys do
  @moduledoc false

  @option_keys %{
    :row_history => [
      :repo,
      :from,
      :to,
      :limit,
      :cursor,
      :page_size,
      :scope,
      :scope_query_fn,
      :storage_schema
    ],
    :row_history_page => [
      :repo,
      :from,
      :to,
      :limit,
      :cursor,
      :page_size,
      :scope,
      :scope_query_fn,
      :storage_schema
    ],
    :audit_transaction => [:repo, :storage_schema, :scope, :scope_query_fn],
    :audit_transaction! => [:repo, :storage_schema, :scope, :scope_query_fn],
    :transaction_context => [:repo, :storage_schema, :scope, :scope_query_fn],
    :transaction_context! => [:repo, :storage_schema, :scope, :scope_query_fn],
    :incident_bundle => [:repo, :storage_schema, :scope, :scope_query_fn],
    :incident_bundle! => [:repo, :storage_schema, :scope, :scope_query_fn],
    :timeline => [:repo, :storage_schema, :scope, :scope_query_fn],
    :timeline_page => [:repo, :storage_schema, :scope, :scope_query_fn, :page_size, :cursor],
    :actor_history => [
      :repo,
      :storage_schema,
      :scope,
      :scope_query_fn,
      :from,
      :to,
      :cursor,
      :page_size,
      :after,
      :before,
      :limit
    ],
    :actor_window => [:repo, :storage_schema, :scope, :scope_query_fn, :cursor, :page_size],
    :actor_window_page => [:repo, :storage_schema, :scope, :scope_query_fn, :cursor, :page_size],
    :correlation_bundle => [:repo, :storage_schema, :scope, :scope_query_fn, :cursor, :page_size],
    :correlation_bundle_page => [
      :repo,
      :storage_schema,
      :scope,
      :scope_query_fn,
      :cursor,
      :page_size
    ],
    :export_csv => [
      :repo,
      :storage_schema,
      :scope,
      :scope_query_fn,
      :max_rows,
      :include_action_metadata
    ],
    :export_json => [:repo, :storage_schema, :scope, :scope_query_fn, :max_rows, :json_format]
  }

  @filter_keys %{
    :timeline => [:repo, :table_schema, :table, :actor_ref, :from, :to, :correlation_id],
    :timeline_page => [:repo, :table_schema, :table, :actor_ref, :from, :to, :correlation_id],
    :row_history => [:repo, :from, :to],
    :row_history_page => [:repo, :from, :to],
    :actor_window => [:table, :from, :to, :correlation_id, :repo],
    :actor_window_page => [:table, :from, :to, :correlation_id, :repo],
    :correlation_bundle => [:table, :actor_ref, :from, :to, :repo],
    :correlation_bundle_page => [:table, :actor_ref, :from, :to, :repo],
    :export_csv => [:repo, :table_schema, :table, :actor_ref, :from, :to, :correlation_id],
    :export_json => [:repo, :table_schema, :table, :actor_ref, :from, :to, :correlation_id]
  }

  @spec allowed(atom()) :: [atom()] | :not_closed
  def allowed(name), do: Map.get(@option_keys, name, :not_closed)

  @spec filters(atom()) :: [atom()] | :not_closed
  def filters(name), do: Map.get(@filter_keys, name, :not_closed)

  @spec validate!([tuple()], atom()) :: :ok
  def validate!(opts, name) when is_list(opts) and is_atom(name) do
    validate_keys!(opts, allowed(name), name, "option", "")
  end

  def validate!(opts, name) when is_atom(name) do
    raise ArgumentError,
          "#{name} options must be a keyword list, got: #{inspect(opts)}"
  end

  @spec validate_filters!([tuple()], atom()) :: :ok
  def validate_filters!(entries, name) when is_list(entries) and is_atom(name) do
    validate_keys!(entries, filters(name), name, "filter", filter_suffix(name))
  end

  @spec validate_keys!([tuple()], [atom()] | :not_closed, atom(), String.t(), String.t()) :: :ok
  defp validate_keys!(_entries, :not_closed, _name, _kind, _suffix), do: :ok

  defp validate_keys!(entries, allowed, name, kind, suffix) do
    Enum.each(entries, fn
      {key, _value} ->
        if key not in allowed do
          allowed_keys = Enum.map_join(allowed, ", ", &inspect/1)

          raise ArgumentError,
                "unknown #{name} #{kind} key #{inspect(key)}. Allowed: #{allowed_keys}#{suffix}"
        end

      other ->
        raise ArgumentError,
              "#{name} options must be a keyword list, got entry: #{inspect(other)}"
    end)

    :ok
  end

  defp filter_suffix(name) when name in [:timeline, :timeline_page],
    do: " See `Threadline.Query` and `Threadline.Export`."

  defp filter_suffix(_name), do: ""
end
