defmodule Threadline.Query.LegacyOpts do
  @moduledoc false

  alias Threadline.Query

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
    flags = actor_history_flags(opts)

    actor_history_check_conflicts!(flags)
    actor_history_warn_legacy(flags)

    {actor_history_cursor(opts, flags), actor_history_page_size(opts, flags)}
  end

  defp actor_history_flags(opts) do
    %{
      cursor: Keyword.has_key?(opts, :cursor),
      after: Keyword.has_key?(opts, :after),
      before: Keyword.has_key?(opts, :before),
      page_size: Keyword.has_key?(opts, :page_size),
      limit: Keyword.has_key?(opts, :limit)
    }
  end

  defp actor_history_check_conflicts!(%{cursor: true, after: has_after?, before: has_before?})
       when has_after? or has_before? do
    raise ArgumentError,
          "actor_history/2 cannot combine :cursor with :after or :before — pass the cursor " <>
            "as cursor: alone."
  end

  defp actor_history_check_conflicts!(%{page_size: true, limit: true}) do
    raise ArgumentError,
          "actor_history/2 cannot combine :page_size with :limit — pass the page size as " <>
            "page_size: alone."
  end

  defp actor_history_check_conflicts!(_flags), do: :ok

  defp actor_history_warn_legacy(flags) do
    if flags.after, do: warn_legacy_actor_history_option(:after, "cursor:")
    if flags.before, do: warn_legacy_actor_history_option(:before, "cursor:")
    if flags.limit, do: warn_legacy_actor_history_option(:limit, "page_size:")
  end

  defp actor_history_cursor(opts, %{cursor: true}), do: Keyword.get(opts, :cursor, :start)
  defp actor_history_cursor(opts, %{before: true}), do: {:before, Keyword.get(opts, :before)}
  defp actor_history_cursor(opts, %{after: true}), do: Keyword.get(opts, :after)
  defp actor_history_cursor(_opts, _flags), do: :start

  defp actor_history_page_size(opts, %{page_size: true}), do: Keyword.get(opts, :page_size)
  defp actor_history_page_size(opts, %{limit: true}), do: Keyword.get(opts, :limit)
  defp actor_history_page_size(_opts, _flags), do: 50

  defp warn_legacy_actor_history_option(option, replacement) do
    IO.warn(
      "Threadline: actor_history/2's :#{option} option is deprecated and will be removed " <>
        "no earlier than Threadline 2.0. Pass it as #{replacement} instead."
    )
  end

  # The retired `row_history/4` shape (filters, opts) keeps its 0.12 unbounded
  # default: validate the old filter-key vocabulary, then merge filters into
  # opts and default :limit to :infinity unless the caller already supplied
  # one, so a 0.12 caller never notices the newer bounded default.
  @doc """
  Validates `filters` against the retired `row_history/4` filter-key
  vocabulary, then merges `filters` into `opts` and defaults `:limit` to
  `:infinity` unless `opts` already supplies one.
  """
  @spec row_history(keyword(), keyword()) :: keyword()
  def row_history(filters, opts) when is_list(filters) and is_list(opts) do
    Query.validate_row_history_filters!(filters)
    Keyword.put_new(filters ++ opts, :limit, :infinity)
  end
end
