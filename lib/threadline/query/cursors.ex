defmodule Threadline.Query.Cursors do
  @moduledoc false

  import Ecto.Query

  # Keyset cursor and paging helpers behind `Threadline.Query`.
  #
  # Actor history pages over `audit_transactions` by `(occurred_at, id)` and
  # expects the `at` binding. The timeline pages over `audit_changes` by
  # `(captured_at, id)`. The validators raise `ArgumentError` with the messages
  # callers of the public query functions see.

  def actor_history_filter_from(query, nil), do: query

  def actor_history_filter_from(query, %DateTime{} = from) do
    where(query, [at], at.occurred_at >= ^from)
  end

  def actor_history_filter_to(query, nil), do: query

  def actor_history_filter_to(query, %DateTime{} = to) do
    where(query, [at], at.occurred_at <= ^to)
  end

  def actor_history_after_cursor(query, %{occurred_at: %DateTime{} = occurred_at, id: id}) do
    where(
      query,
      [at],
      fragment(
        "(?, ?) < (?, ?)",
        at.occurred_at,
        at.id,
        ^occurred_at,
        type(^id, :binary_id)
      )
    )
  end

  def actor_history_before_cursor(query, %{occurred_at: %DateTime{} = occurred_at, id: id}) do
    where(
      query,
      [at],
      fragment(
        "(?, ?) > (?, ?)",
        at.occurred_at,
        at.id,
        ^occurred_at,
        type(^id, :binary_id)
      )
    )
  end

  # Orders the actor-history query for the requested direction. A `before`
  # cursor pages toward newer records, so it reads ascending and the caller
  # reverses the page; it wins over an `after` cursor when both are given.
  def actor_history_window(query, nil, nil) do
    {order_by(query, [at], desc: at.occurred_at, desc: at.id), false}
  end

  def actor_history_window(query, nil, after_cursor) do
    {query
     |> actor_history_after_cursor(after_cursor)
     |> order_by([at], desc: at.occurred_at, desc: at.id), false}
  end

  def actor_history_window(query, before_cursor, _after_cursor) do
    {query
     |> actor_history_before_cursor(before_cursor)
     |> order_by([at], asc: at.occurred_at, asc: at.id), true}
  end

  # The query fetched `limit + 1` rows; the extra row only signals that more
  # records exist. Returns the page in descending order and that signal.
  def actor_history_trim(entries, limit, reverse?) do
    has_more? = length(entries) > limit
    {trim_actor_history(entries, limit, has_more?, reverse?), has_more?}
  end

  defp trim_actor_history(entries, _limit, true, true),
    do: entries |> Enum.reverse() |> Enum.drop(1)

  defp trim_actor_history(entries, limit, true, false), do: Enum.take(entries, limit)
  defp trim_actor_history(entries, _limit, false, true), do: Enum.reverse(entries)
  defp trim_actor_history(entries, _limit, false, false), do: entries

  # The whole post-fetch step for one actor-history page: trim the
  # `page_size + 1` fetch down to the page and build the one cursor for
  # continuing in the direction walked. Kept separate from the DB fetch so a
  # property test can exercise exactly the code the product runs without a
  # database.
  @doc """
  Builds a `%Threadline.Page{}` from a `page_size + 1` actor-history fetch.
  `direction` is the direction `raw` was fetched and ordered in; `:forward`
  reads newer-to-older, `:backward` reads older-to-newer (and is reversed to
  display order by `actor_history_trim/3`). The returned `cursor` continues
  the walk in the same direction: a bare map for `:forward`, `{:before, map}`
  for `:backward`.
  """
  @spec actor_history_page(
          [Threadline.Capture.AuditTransaction.t()],
          pos_integer(),
          :forward | :backward
        ) :: Threadline.Page.t()
  def actor_history_page(raw, page_size, direction) when direction in [:forward, :backward] do
    reverse? = direction == :backward
    {entries, has_more?} = actor_history_trim(raw, page_size, reverse?)

    cursor =
      case {has_more?, direction} do
        {false, _} -> nil
        {true, :forward} -> actor_history_edge_cursor(List.last(entries))
        {true, :backward} -> {:before, actor_history_edge_cursor(List.first(entries))}
      end

    %Threadline.Page{entries: entries, cursor: cursor, has_more: has_more?}
  end

  defp actor_history_edge_cursor(%{occurred_at: occurred_at, id: id}),
    do: %{occurred_at: occurred_at, id: id}

  @doc """
  Validates the `:cursor` option for `actor_history/2`. `:start` begins a
  forward walk; `nil` raises (naming `:start`); a map continues a forward
  walk after it; `{:before, map}` walks backward from it. Returns
  `{cursor_map_or_nil, direction}`.
  """
  @spec validate_actor_history_page_cursor!(
          :start
          | Threadline.Page.actor_cursor()
          | {:before, Threadline.Page.actor_cursor()}
        ) ::
          {Threadline.Page.actor_cursor() | nil, :forward | :backward}
  def validate_actor_history_page_cursor!(:start), do: {nil, :forward}

  def validate_actor_history_page_cursor!(nil) do
    raise ArgumentError,
          ":cursor must not be nil — pass cursor: :start to begin a walk, or the previous " <>
            "page's cursor to continue; a page with has_more: false has no cursor."
  end

  def validate_actor_history_page_cursor!({:before, %{} = cursor}) do
    {validate_actor_history_cursor!(cursor), :backward}
  end

  def validate_actor_history_page_cursor!(%{} = cursor) do
    {validate_actor_history_cursor!(cursor), :forward}
  end

  def validate_actor_history_page_cursor!(cursor) do
    raise ArgumentError,
          ":cursor must be :start, %{occurred_at: %DateTime{}, id: uuid}, or " <>
            "{:before, %{occurred_at: %DateTime{}, id: uuid}}, got: #{inspect(cursor)}"
  end

  def validate_actor_history_cursor!(nil), do: nil

  def validate_actor_history_cursor!(%{occurred_at: %DateTime{} = occurred_at, id: id})
      when is_binary(id) do
    case Ecto.UUID.cast(id) do
      {:ok, canonical} -> %{occurred_at: occurred_at, id: canonical}
      :error -> raise ArgumentError, "cursor.id must be a UUID binary, got: #{inspect(id)}"
    end
  end

  def validate_actor_history_cursor!(%{} = cursor) do
    has_occurred_at? = Map.has_key?(cursor, :occurred_at)
    has_id? = Map.has_key?(cursor, :id)

    if has_occurred_at? or has_id? do
      raise ArgumentError,
            "cursor must include both :occurred_at and :id or be nil, got: #{inspect(cursor)}"
    else
      raise ArgumentError,
            "cursor must be nil or %{occurred_at: %DateTime{}, id: uuid}, got: #{inspect(cursor)}"
    end
  end

  def validate_actor_history_cursor!(cursor) do
    raise ArgumentError,
          "cursor must be nil or %{occurred_at: %DateTime{}, id: uuid}, got: #{inspect(cursor)}"
  end

  def timeline_page_size!(page_size) when is_integer(page_size) and page_size > 0,
    do: page_size

  def timeline_page_size!(page_size) do
    raise ArgumentError,
          ":page_size must be a positive integer, got: #{inspect(page_size)}"
  end

  def validate_timeline_cursor!(nil), do: nil

  def validate_timeline_cursor!(%{captured_at: %DateTime{} = captured_at, id: id})
      when is_binary(id) do
    case Ecto.UUID.cast(id) do
      {:ok, canonical} -> %{captured_at: captured_at, id: canonical}
      :error -> raise ArgumentError, ":cursor.id must be a UUID binary, got: #{inspect(id)}"
    end
  end

  def validate_timeline_cursor!(%{} = cursor) do
    has_captured_at? = Map.has_key?(cursor, :captured_at)
    has_id? = Map.has_key?(cursor, :id)

    if has_captured_at? or has_id? do
      raise ArgumentError,
            ":cursor must include both :captured_at and :id or be nil, got: #{inspect(cursor)}"
    else
      raise ArgumentError,
            ":cursor must be nil or %{captured_at: %DateTime{}, id: uuid}, got: #{inspect(cursor)}"
    end
  end

  def validate_timeline_cursor!(cursor) do
    raise ArgumentError,
          ":cursor must be nil or %{captured_at: %DateTime{}, id: uuid}, got: #{inspect(cursor)}"
  end

  # `raw` is a fetch of up to `page_size + 1` rows in descending keyset
  # order. The extra row (if present) only signals that more rows exist; it
  # is dropped from `entries`. `has_more` is therefore exact: a page that is
  # exactly full never falsely reports a cursor.
  @doc """
  Builds a `%Threadline.Page{}` from a `page_size + 1` fetch.
  """
  @spec change_page([Threadline.Capture.AuditChange.t()], pos_integer()) :: Threadline.Page.t()
  def change_page(raw, page_size) when is_list(raw) and is_integer(page_size) do
    has_more? = length(raw) > page_size
    entries = Enum.take(raw, page_size)

    cursor =
      case {has_more?, List.last(entries)} do
        {true, %{captured_at: captured_at, id: id}} -> %{captured_at: captured_at, id: id}
        _ -> nil
      end

    %Threadline.Page{entries: entries, cursor: cursor, has_more: has_more?}
  end

  @doc """
  Validates the `:cursor` option for an always-paged read (`timeline_page/2`,
  `actor_history/2`). `:start` (or an absent key, mapped to `:start` by the
  caller) begins a walk; `nil` raises; a cursor map is validated by
  `validate_timeline_cursor!/1`.
  """
  @spec validate_page_cursor!(:start | Threadline.Page.change_cursor() | nil) ::
          Threadline.Page.change_cursor() | nil
  def validate_page_cursor!(:start), do: nil

  def validate_page_cursor!(nil) do
    raise ArgumentError,
          ":cursor must not be nil — pass cursor: :start to begin a walk, or the previous " <>
            "page's cursor to continue; a page with has_more: false has no cursor."
  end

  def validate_page_cursor!(%{} = cursor), do: validate_timeline_cursor!(cursor)
end
