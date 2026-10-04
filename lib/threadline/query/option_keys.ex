defmodule Threadline.Query.OptionKeys do
  @moduledoc false

  @option_keys %{
    row_history: [
      :repo,
      :from,
      :to,
      :limit,
      :cursor,
      :page_size,
      :scope,
      :scope_query_fn,
      :storage_schema
    ]
  }

  @filter_keys %{}

  @spec allowed(atom()) :: [atom()] | :not_closed
  def allowed(name), do: Map.get(@option_keys, name, :not_closed)

  @spec filters(atom()) :: [atom()] | :not_closed
  def filters(name), do: Map.get(@filter_keys, name, :not_closed)

  @spec validate!([tuple()], atom()) :: :ok
  def validate!(opts, name) when is_list(opts) and is_atom(name) do
    validate_keys!(opts, allowed(name), name, "option")
  end

  @spec validate_filters!([tuple()], atom()) :: :ok
  def validate_filters!(entries, name) when is_list(entries) and is_atom(name) do
    validate_keys!(entries, filters(name), name, "filter")
  end

  @spec validate_keys!([tuple()], [atom()] | :not_closed, atom(), String.t()) :: :ok
  defp validate_keys!(_entries, :not_closed, _name, _kind), do: :ok

  defp validate_keys!(entries, allowed, name, kind) do
    Enum.each(entries, fn {key, _value} ->
      if key not in allowed do
        allowed_keys = Enum.map_join(allowed, ", ", &inspect/1)

        raise ArgumentError,
              "unknown #{name} #{kind} key #{inspect(key)}. Allowed: #{allowed_keys}"
      end
    end)

    :ok
  end
end
