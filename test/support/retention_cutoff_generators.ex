defmodule Threadline.Test.RetentionCutoffGenerators do
  @moduledoc """
  StreamData generator for PROP-07 (D-19): fixtures clustered on the
  retention cutoff microsecond, for `test/threadline/retention/cutoff_property_test.exs`.

  `fixture_gen/0` yields `%{cutoff:, transactions:, delete_empty?:, batch_size:}`:

    * `cutoff` — `~U[2001-01-01 00:00:00.000000Z]` plus a `frequency`-picked
      microsecond offset: exactly `0`, exactly `999_999`, or a random offset
      up to `10^12` microseconds. Always precision 6 (`DateTime.add/3` in
      `:microsecond` mode never drops the fixed sub-second field count). The
      year-2001 base is always older than the test suite's `keep_days: 1`
      policy window, so an explicit `cutoff:` passed to `Retention.purge/1`
      never trips `resolve_cutoff/2`'s "stricter than policy only" guard.
    * `transactions` — 1 to 4 lists of per-change microsecond offsets
      (`frequency`-biased toward 0, +-1, +-999_999/1_000_000/1_000, and a
      wide random band), each list 1 to 5 entries. About 1 in 10 lists is
      empty (a pre-existing orphan transaction), and about 3 in 10 are
      entirely negative (a transaction with no surviving change — one the
      purge itself orphans), so the D-20 dry/real agreement on
      `deleted_transactions` is reliably exercised rather than reached only
      by chance within a DB property's low `max_runs` budget.
    * `delete_empty?` — 3:1 biased toward `true`.
    * `batch_size` — one of `1, 2, 3, 500`, exercising the orphan drain
      between small batches at no extra run cost.

  Per D-04, every shape here is `member_of`/`frequency`/bounded
  `list_of(max_length:)` or `integer(a..b)` — none of it depends on
  StreamData's run size, so raising `THREADLINE_PROPERTY_SCALE` never grows
  the row count along with the run count.
  """

  use ExUnitProperties

  @base_cutoff ~U[2001-01-01 00:00:00.000000Z]
  @wide_band 100_000_000_000

  @doc "A single PROP-07 fixture (D-19)."
  def fixture_gen do
    gen all(
          cutoff <- cutoff_gen(),
          transactions <- transactions_gen(),
          delete_empty? <- delete_empty_gen(),
          batch_size <- member_of([1, 2, 3, 500])
        ) do
      %{
        cutoff: cutoff,
        transactions: transactions,
        delete_empty?: delete_empty?,
        batch_size: batch_size
      }
    end
  end

  defp cutoff_gen do
    gen all(
          offset_us <-
            frequency([
              {1, constant(0)},
              {1, constant(999_999)},
              {1, integer(0..1_000_000_000_000)}
            ])
        ) do
      DateTime.add(@base_cutoff, offset_us, :microsecond)
    end
  end

  defp transactions_gen do
    list_of(transaction_offsets_gen(), min_length: 1, max_length: 4)
  end

  # ~10% of transactions is empty (a pre-existing orphan). ~30% is entirely
  # before the cutoff (a transaction the purge itself orphans, with no
  # surviving change) — this branch exists specifically so a fixture
  # reliably exercises "orphaned by the purge" within a DB property's
  # low max_runs budget, which the general mixed offsets below reach only
  # by chance (the D-20 mutation control needs this to be reliable, not
  # incidental).
  defp transaction_offsets_gen do
    frequency([
      {6, list_of(offset_us_gen(), min_length: 1, max_length: 5)},
      {3, list_of(purged_offset_us_gen(), min_length: 1, max_length: 5)},
      {1, constant([])}
    ])
  end

  defp offset_us_gen do
    frequency([
      {4, constant(0)},
      {3, member_of([-1, 1])},
      {2, member_of([-999_999, 999_999, -1_000_000, 1_000_000, -1_000, 1_000])},
      {1, integer(-@wide_band..@wide_band)}
    ])
  end

  # Always strictly before the cutoff, so a transaction built entirely from
  # this generator has no surviving change.
  defp purged_offset_us_gen do
    frequency([
      {3, constant(-1)},
      {2, member_of([-999_999, -1_000_000, -1_000])},
      {1, integer(-@wide_band..-1)}
    ])
  end

  defp delete_empty_gen, do: frequency([{3, constant(true)}, {1, constant(false)}])
end
