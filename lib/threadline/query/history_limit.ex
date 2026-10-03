defmodule Threadline.Query.HistoryLimit do
  @moduledoc false

  import Ecto.Query

  @doc "Validates `history/3`'s `:limit` before any DB access. `nil` is unbounded."
  def validate!(nil), do: :ok
  def validate!(v) when is_integer(v) and v > 0, do: :ok

  def validate!(v),
    do: raise(ArgumentError, ":limit must be a positive integer, got: #{inspect(v)}")

  @doc "Applies the validated `:limit` as the query's final `LIMIT`."
  def apply(query, nil), do: query
  def apply(query, n), do: limit(query, ^n)
end
