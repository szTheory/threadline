defmodule Threadline.Query.LegacyOpts do
  @moduledoc false

  # The 0.12 `*_page` helpers treated an absent or `nil` `:cursor` as "first
  # page". The newer always-paged functions raise on `cursor: nil` instead —
  # this maps the old first-page call onto the new `:start` so the
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

  # actor_history/2's old `:after`/`:before`/`:limit` options keep working:
  # each still returns the equivalent page and emits one runtime warning per
  # call naming its canonical replacement. Combining a legacy option with its
  # canonical replacement raises instead of silently picking one.
  @doc """
  Normalizes `actor_history/2`'s options to the canonical `{cursor, page_size}`
  pair, warning once per legacy option present (`:after`, `:before`,
  `:limit`). Raises `ArgumentError` when `:cursor` is combined with `:after`
  or `:before`, or when `:page_size` is combined with `:limit`.
  """
  @spec actor_history(keyword()) :: {:start | map() | {:before, map()}, pos_integer()}
  def actor_history(opts) when is_list(opts) do
    has_cursor? = Keyword.has_key?(opts, :cursor)
    has_after? = Keyword.has_key?(opts, :after)
    has_before? = Keyword.has_key?(opts, :before)
    has_page_size? = Keyword.has_key?(opts, :page_size)
    has_limit? = Keyword.has_key?(opts, :limit)

    if has_cursor? and (has_after? or has_before?) do
      raise ArgumentError,
            "actor_history/2 cannot combine :cursor with :after or :before — pass the cursor " <>
              "as cursor: alone."
    end

    if has_page_size? and has_limit? do
      raise ArgumentError,
            "actor_history/2 cannot combine :page_size with :limit — pass the page size as " <>
              "page_size: alone."
    end

    if has_after?, do: warn_legacy_actor_history_option(:after, "cursor:")
    if has_before?, do: warn_legacy_actor_history_option(:before, "cursor:")
    if has_limit?, do: warn_legacy_actor_history_option(:limit, "page_size:")

    cursor =
      cond do
        has_cursor? -> Keyword.get(opts, :cursor, :start)
        has_before? -> {:before, Keyword.get(opts, :before)}
        has_after? -> Keyword.get(opts, :after)
        true -> :start
      end

    page_size =
      cond do
        has_page_size? -> Keyword.get(opts, :page_size)
        has_limit? -> Keyword.get(opts, :limit)
        true -> 50
      end

    {cursor, page_size}
  end

  defp warn_legacy_actor_history_option(option, replacement) do
    IO.warn(
      "Threadline: actor_history/2's :#{option} option is deprecated and will be removed " <>
        "no earlier than Threadline 2.0. Pass it as #{replacement} instead."
    )
  end
end
