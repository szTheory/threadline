defmodule Threadline.Query.LegacyOpts do
  @moduledoc false

  # D-11: the 0.12 `*_page` helpers treated an absent or `nil` `:cursor` as
  # "first page". The new always-paged functions raise on `cursor: nil`
  # (D-07) — this maps the old first-page call onto the new `:start` so the
  # soon-retired `*_page` helpers keep working unchanged while every other
  # paged read enforces the stricter rule.
  @doc """
  Maps an absent or `nil` `:cursor` option to `:start`. Any other value
  passes through unchanged.
  """
  @spec cursor(keyword()) :: keyword()
  def cursor(opts) when is_list(opts) do
    case Keyword.get(opts, :cursor) do
      nil -> Keyword.put(opts, :cursor, :start)
      _ -> opts
    end
  end
end
