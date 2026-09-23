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

  def timeline_page_next_cursor(entries, page_size) when length(entries) < page_size, do: nil

  def timeline_page_next_cursor(entries, _page_size) do
    last = List.last(entries)
    %{captured_at: last.captured_at, id: last.id}
  end
end
