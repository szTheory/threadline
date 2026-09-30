defmodule Threadline.Test.TriggerRunGenerators do
  @moduledoc """
  StreamData generators for ordered rerun sequences used by the DB-backed
  CAPT-02 property test. Each sequence is 1-4 runs applied, in order, to one
  table: a run is either `:default` or `{:per_table, option}`, forcing a
  per-table capture function through one of `:store_changed_from`,
  `:exclude`, or `:mask`. Every generator here is size-independent
  (`member_of`/`constant`/`frequency`/`gen all` over fixed-length pieces), so
  a capped `max_runs` samples every sequence length from the first
  iteration instead of starting with the smallest StreamData size.
  """

  use ExUnitProperties

  @per_table_options [:store_changed_from, :exclude, :mask]

  defp length_gen do
    frequency([
      {1, constant(1)},
      {3, constant(2)},
      {3, constant(3)},
      {3, constant(4)}
    ])
  end

  defp per_table_gen do
    gen all(option <- member_of(@per_table_options)) do
      {:per_table, option}
    end
  end

  # Biased toward default -> per_table (the common first rerun).
  defp first_run_gen do
    frequency([
      {3, constant(:default)},
      {2, per_table_gen()}
    ])
  end

  # Biased toward per_table -> default (the retire path) and
  # per_table -> per_table with a possibly different option.
  defp later_run_gen do
    frequency([
      {3, per_table_gen()},
      {2, constant(:default)}
    ])
  end

  defp fixed_length_list(_gen, 0), do: constant([])

  defp fixed_length_list(gen, n) when n > 0 do
    gen all(head <- gen, tail <- fixed_length_list(gen, n - 1)) do
      [head | tail]
    end
  end

  @doc """
  1-4 ordered runs, each `:default` or `{:per_table, option}`. The first run
  and every later run are drawn from differently-biased generators; the
  sequence length is chosen independently of StreamData's own size hint.
  """
  def run_sequence do
    gen all(
          length <- length_gen(),
          first <- first_run_gen(),
          rest <- fixed_length_list(later_run_gen(), length - 1)
        ) do
      [first | rest]
    end
  end
end
