defmodule Threadline.Test.CursorGenerators do
  @moduledoc """
  StreamData generators for cursor-paging tests, biased toward
  timestamp tie groups interleaved with singletons so most entries share a
  timestamp with at least one neighbour and page cuts often land inside a
  tie group.
  """

  use ExUnitProperties

  @base_ts_usec 1_800_000_000_000_000
  @max_entries 60
  @max_groups 20

  defp group_size_gen do
    frequency([
      {5, constant(1)},
      {3, integer(2..4)},
      {2, integer(5..12)}
    ])
  end

  # Most gaps are 1 microsecond (the off-by-one-µs boundary), with an
  # occasional larger jump.
  defp gap_gen do
    frequency([
      {3, constant(1)},
      {1, integer(2..1_000_000)}
    ])
  end

  defp fixed_length_list(_gen, 0), do: constant([])

  defp fixed_length_list(gen, n) when n > 0 do
    gen all(head <- gen, tail <- fixed_length_list(gen, n - 1)) do
      [head | tail]
    end
  end

  defp ids_gen(n) do
    map(uniq_list_of(binary(length: 16), length: n), fn binaries ->
      Enum.map(binaries, &Ecto.UUID.load!/1)
    end)
  end

  # Distinct, descending group timestamps built from a fixed base.
  defp timestamps_from_gaps(gaps) do
    Enum.scan(gaps, @base_ts_usec, fn gap, prev -> prev - gap end)
  end

  defp build_entries(sizes, timestamps, ids) do
    flattened_ts =
      Enum.zip(timestamps, sizes)
      |> Enum.flat_map(fn {ts, size} -> List.duplicate(ts, size) end)
      |> Enum.take(@max_entries)

    flattened_ts
    |> Enum.zip(ids)
    |> Enum.map(fn {ts, id} -> %{ts_usec: ts, id: id} end)
    |> Enum.shuffle()
  end

  @doc """
  0..60 entries `%{ts_usec: integer, id: uuid_string}`, built as a list of
  tie groups (group size from `frequency([{5, 1}, {3, 2..4}, {2, 5..12}])`,
  so about 60-70% of entries share a timestamp with a neighbour). Ids are
  unique by construction. The output order is shuffled, so input order says
  nothing about timestamp order.
  """
  def entries_gen do
    gen all(
          count <- integer(0..@max_groups),
          sizes <- fixed_length_list(group_size_gen(), count),
          gaps <- fixed_length_list(gap_gen(), count),
          total = sizes |> Enum.sum() |> min(@max_entries),
          ids <- ids_gen(total)
        ) do
      build_entries(sizes, timestamps_from_gaps(gaps), ids)
    end
  end

  @doc """
  `{entries, page_size}` — page size weighted toward 1-3 (so cuts land
  inside tie groups), with sizes equal to and larger than the entry count
  also drawn.
  """
  def paging_gen do
    gen all(
          entries <- entries_gen(),
          n = length(entries),
          k <-
            frequency([
              {6, integer(1..3)},
              {3, integer(4..8)},
              {1, constant(max(n, 1))},
              {1, constant(n + 1)}
            ])
        ) do
      {entries, k}
    end
  end
end
