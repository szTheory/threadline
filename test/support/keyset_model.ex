defmodule Threadline.Test.KeysetModel do
  @moduledoc """
  An in-memory model of the keyset SQL: `Threadline.Test.KeysetModel` compares
  `{usec_integer, lowercase uuid string}` keys (as 16-byte dumped `Ecto.UUID`
  binaries, Postgres's own `uuid` byte order), independently of the real
  `Cursors`/`Query` ordering code. It must never share a comparator or
  ordering constant with `lib/` — if both sides read the same constant,
  flipping it would flip both, and a SQL mutation control could never go red.

  `expected_order/1` is the test oracle. `actor_history_fetch/4` and
  `timeline_fetch/3` model the DB-side window/order/limit for each cursor;
  `walk_actor_history/2` and `walk_timeline/2` drive the real
  `Threadline.Query.Cursors` paging functions (`actor_history_page/3`,
  `change_page/2`) against this in-memory fetch, so the walk exercises the
  real post-fetch code, not a copy of it.
  """

  alias Threadline.Query.Cursors

  @type entry :: %{ts_usec: integer(), id: String.t()}

  @doc """
  The independent oracle: every entry's id, ordered by `(ts_usec, id)`
  descending, where `id` compares by its raw 16-byte UUID encoding (the same
  byte order Postgres uses for its `uuid` type).
  """
  @spec expected_order([entry()]) :: [String.t()]
  def expected_order(entries) do
    entries
    |> Enum.sort_by(&key/1, :desc)
    |> Enum.map(& &1.id)
  end

  @doc """
  Models the actor-history window + `limit(limit + 1)` fetch. A `before`
  cursor wins over an `after` cursor. Returns `{rows, reverse?}`, mirroring
  `Cursors.actor_history_window/3`'s own return shape.
  """
  @spec actor_history_fetch([entry()], pos_integer(), map() | nil, map() | nil) ::
          {[%{occurred_at: DateTime.t(), id: String.t()}], boolean()}
  def actor_history_fetch(entries, limit, before, after_cursor) do
    cond do
      before != nil ->
        ck = cursor_key(before)

        rows =
          entries
          |> Enum.filter(&(key(&1) > ck))
          |> Enum.sort_by(&key/1, :asc)
          |> Enum.take(limit + 1)
          |> Enum.map(&actor_row/1)

        {rows, true}

      after_cursor != nil ->
        ck = cursor_key(after_cursor)

        rows =
          entries
          |> Enum.filter(&(key(&1) < ck))
          |> Enum.sort_by(&key/1, :desc)
          |> Enum.take(limit + 1)
          |> Enum.map(&actor_row/1)

        {rows, false}

      true ->
        rows =
          entries
          |> Enum.sort_by(&key/1, :desc)
          |> Enum.take(limit + 1)
          |> Enum.map(&actor_row/1)

        {rows, false}
    end
  end

  @doc """
  Models `maybe_after_timeline_cursor/2` + `timeline_order/1` +
  `limit(page_size + 1)` — the D-08 extra-row fetch `Cursors.change_page/2`
  trims.
  """
  @spec timeline_fetch([entry()], pos_integer(), map() | nil) ::
          [%{captured_at: DateTime.t(), id: String.t()}]
  def timeline_fetch(entries, page_size, cursor) do
    entries
    |> maybe_filter_after(cursor)
    |> Enum.sort_by(&key/1, :desc)
    |> Enum.take(page_size + 1)
    |> Enum.map(&timeline_row/1)
  end

  @doc """
  Walks the actor-history cursor forward to exhaustion against the real
  `Cursors.actor_history_page/3`, then walks backward via `{:before, map}`
  starting from the first entry of the last forward page. Returns `{:ok,
  forward_pages, backward_pages}`, each page a list of ids, or `{:error,
  "cursor did not advance"}` if a walk exceeds `length(entries) + 2` steps
  without reaching a `nil` continuation cursor.
  """
  @spec walk_actor_history([entry()], pos_integer()) ::
          {:ok, [[String.t()]], [[String.t()]]} | {:error, String.t()}
  def walk_actor_history(entries, limit) do
    bound = length(entries) + 2

    forward_fetch = fn cursor ->
      page = actor_history_page(entries, limit, :forward, nil, cursor)

      {%{ids: Enum.map(page.entries, & &1.id), first_entry: List.first(page.entries)},
       page.cursor}
    end

    with {:ok, forward_pages} <- step(bound, nil, forward_fetch) do
      # Walking backward from the very first (and, here, only) forward page
      # would re-fetch nothing older than itself — there is no earlier page
      # to reproduce. Only start the backward leg when a second forward page
      # proves an earlier boundary exists.
      backward_start =
        case forward_pages do
          [_single] ->
            nil

          _multiple ->
            case List.last(forward_pages) do
              %{first_entry: %{occurred_at: occurred_at, id: id}} ->
                {:before, %{occurred_at: occurred_at, id: id}}

              _ ->
                nil
            end
        end

      backward_fetch = fn {:before, cursor_map} ->
        page = actor_history_page(entries, limit, :backward, cursor_map, nil)
        {Enum.map(page.entries, & &1.id), page.cursor}
      end

      case walk_backward(bound, backward_start, backward_fetch) do
        {:ok, backward_pages} -> {:ok, Enum.map(forward_pages, & &1.ids), backward_pages}
        {:error, _} = err -> err
      end
    end
  end

  # The one call site exercising the real `Cursors.actor_history_page/3`,
  # shared by both the forward and backward legs of `walk_actor_history/2`.
  defp actor_history_page(entries, limit, direction, before, after_cursor) do
    {raw, _reverse?} = actor_history_fetch(entries, limit, before, after_cursor)
    Cursors.actor_history_page(raw, limit, direction)
  end

  @doc """
  Walks the timeline cursor forward via `Cursors.change_page/2` to
  exhaustion. Returns `{:ok, pages}`, each page a list of ids, or
  `{:error, "cursor did not advance"}` past `length(entries) + 2` steps.
  """
  @spec walk_timeline([entry()], pos_integer()) :: {:ok, [[String.t()]]} | {:error, String.t()}
  def walk_timeline(entries, page_size) do
    bound = length(entries) + 2

    fetch = fn cursor ->
      raw = timeline_fetch(entries, page_size, cursor)
      page = Cursors.change_page(raw, page_size)
      {Enum.map(page.entries, & &1.id), page.cursor}
    end

    step(bound, nil, fetch)
  end

  # ── internals ──────────────────────────────────────────────────────────

  defp key(%{ts_usec: ts_usec, id: id}), do: {ts_usec, Ecto.UUID.dump!(id)}

  defp cursor_key(%{occurred_at: %DateTime{} = dt, id: id}), do: do_cursor_key(dt, id)
  defp cursor_key(%{captured_at: %DateTime{} = dt, id: id}), do: do_cursor_key(dt, id)

  defp do_cursor_key(dt, id) do
    {DateTime.to_unix(dt, :microsecond), Ecto.UUID.dump!(String.downcase(id))}
  end

  defp maybe_filter_after(entries, nil), do: entries

  defp maybe_filter_after(entries, cursor) do
    ck = cursor_key(cursor)
    Enum.filter(entries, &(key(&1) < ck))
  end

  defp actor_row(entry),
    do: %{occurred_at: DateTime.from_unix!(entry.ts_usec, :microsecond), id: entry.id}

  defp timeline_row(entry),
    do: %{captured_at: DateTime.from_unix!(entry.ts_usec, :microsecond), id: entry.id}

  # Generic bounded walker: calls `fetch_fun.(cursor)` repeatedly, collecting
  # whatever item it returns per step, following its returned continuation
  # cursor until that cursor is `nil` (natural end) or stalls (fails with
  # "cursor did not advance" instead of looping past `bound` steps).
  defp step(bound, cursor0, fetch_fun) do
    Enum.reduce_while(0..bound, {[], cursor0}, fn _i, {pages, cursor} ->
      {item, continue_cursor} = fetch_fun.(cursor)
      new_pages = pages ++ [item]

      cond do
        continue_cursor == nil -> {:halt, {:ok, new_pages}}
        continue_cursor == cursor -> {:halt, {:error, "cursor did not advance"}}
        true -> {:cont, {new_pages, continue_cursor}}
      end
    end)
    |> case do
      {:ok, pages} -> {:ok, pages}
      {:error, reason} -> {:error, reason}
      {_pages, _cursor} -> {:error, "cursor did not advance"}
    end
  end

  defp walk_backward(_bound, nil, _fetch_fun), do: {:ok, []}
  defp walk_backward(bound, cursor0, fetch_fun), do: step(bound, cursor0, fetch_fun)
end
