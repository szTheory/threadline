defmodule Threadline.Test.RowHistoryGenerators do
  @moduledoc """
  StreamData generator for PROP-06 (D-15): real row histories applied as
  parameterised SQL against the `asof_prop_rows` fixture table.

  `history_gen/0` yields a list of batches. Each batch is a non-empty list
  of steps, applied totally, inside one `Repo.transaction`:

    * `{:write, full_row, subset}` — when the row is currently absent (the
      first step, or the step right after a delete), this is a full INSERT
      of `full_row`. When the row is present, only the columns named in
      `subset` are changed; every other column is resent with its current
      value, so every UPDATE statement is syntactically complete. An empty
      `subset` is therefore a genuine no-op UPDATE (same values resent),
      and the trigger still fires because the capture trigger carries no
      `WHEN` clause.
    * `:delete` — deletes the row. A `:delete` step when the row is
      already absent is dropped by the property body (nothing to delete),
      so re-inserting the same primary key after a real delete happens
      naturally whenever a later batch starts with a `:write`.

  Per D-04, this generator must not depend on StreamData's run size: every
  shape below is `member_of`/`frequency`/bounded `list_of(max_length:)`, so
  growing the generation size at `THREADLINE_PROPERTY_SCALE` never grows
  the row/step count along with the run count (226 measured that coupling
  at 1.6s unscaled vs 96.6s scaled for a size-dependent DB generator).

  Column values are exact, with no normaliser: `name`/`note` cover plain
  text, a literal single quote, a double quote, CRLF, and multibyte/emoji
  text (escape-proof shapes that survive SQL parameterisation, jsonb, and
  cast: true identically); `n` covers zero, negative, a bigint above
  2^53, and the signed 64-bit extremes; `flag` covers true/false/nil;
  `doc` covers nil and a small nested map of strings/ints/bools/nil, with
  fixed shapes via `member_of`/`fixed_map` (never a recursive generator,
  which would reintroduce the size dependency this module avoids).
  `numeric` and `timestamptz` column types are never generated here: a
  `numeric` value round-trips lossy through Jason (`1.10` -> `1.1`), and a
  `timestamptz` column renders in the session timezone, either of which
  would fail the property on capture fidelity rather than on `as_of`
  itself (CONTEXT.md D-14, Deferred).

  Delete/re-insert bias (D-26): batches are biased so that at least a
  fifth of generated histories contain a delete step, and a write
  following a delete (a re-insert of the same primary key) is reachable
  within the sampled floor in `property_generator_coverage_test.exs`.
  """

  use ExUnitProperties

  @columns [:name, :note, :n, :flag, :doc]

  # Plain, quote, CRLF and multibyte/emoji text shapes a `name`/`note`
  # value is drawn from. All are escape-proof through SQL parameters,
  # jsonb round trips, and `Ecto.embedded_load/3` identically.
  @text_pool [
    "plain",
    "O'Brien",
    "\"quoted\"",
    "line1\r\nline2",
    "café",
    "😀row",
    String.duplicate("x", 200)
  ]

  @n_pool [0, -1, 9_007_199_254_740_993, -9_223_372_036_854_775_808, 9_223_372_036_854_775_807]

  @doc "A full generated row: a string-keyed map of all five columns (never `id`)."
  def full_row_gen do
    gen all(
          name <- member_of(@text_pool),
          note <- one_of([constant(nil), member_of(@text_pool)]),
          n <- one_of([constant(nil), member_of(@n_pool)]),
          flag <- member_of([true, false, nil]),
          doc <- doc_gen()
        ) do
      %{"name" => name, "note" => note, "n" => n, "flag" => flag, "doc" => doc}
    end
  end

  defp doc_gen do
    one_of([
      constant(nil),
      fixed_map(%{
        "a" => member_of(["s", "", "é", nil]),
        "b" => member_of([1, -1, 0, nil]),
        "c" => member_of([true, false, nil])
      })
    ])
  end

  @doc "A possibly-empty, uniq subset of the five fixture columns."
  def subset_gen do
    map(list_of(member_of(@columns), max_length: 5), &Enum.uniq/1)
  end

  defp step_gen do
    frequency([
      {3, write_step_gen()},
      {1, constant(:delete)}
    ])
  end

  defp write_step_gen do
    gen all(full_row <- full_row_gen(), subset <- subset_gen()) do
      {:write, full_row, subset}
    end
  end

  @doc """
  A list of batches, each a non-empty list of 1-3 steps, 1-4 batches,
  capped at 8 steps overall (D-15). Always applied after the property
  body's own leading full INSERT.
  """
  def history_gen do
    gen all(
          batches <-
            list_of(list_of(step_gen(), min_length: 1, max_length: 3),
              min_length: 1,
              max_length: 4
            )
        ) do
      batches
      |> List.flatten()
      |> Enum.take(8)
      |> rebatch(batches)
    end
  end

  # Caps the flattened step count at 8 while preserving batch boundaries
  # (each generated batch still runs inside one Repo.transaction).
  defp rebatch(capped_steps, original_batches) do
    {result, _rest} =
      Enum.reduce(original_batches, {[], capped_steps}, fn batch, {acc, remaining} ->
        take = min(length(batch), length(remaining))
        {taken, rest} = Enum.split(remaining, take)

        case taken do
          [] -> {acc, rest}
          _ -> {[taken | acc], rest}
        end
      end)

    Enum.reverse(result)
  end
end
