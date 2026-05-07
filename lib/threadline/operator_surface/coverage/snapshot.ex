defmodule Threadline.OperatorSurface.Coverage.Snapshot do
  @moduledoc """
  Snapshot of `Threadline.Health.trigger_coverage/1` results for the operator
  surface coverage dashboard and surface-header pill.

  Held on `socket.assigns.:threadline_coverage` and refreshed by
  `Threadline.OperatorSurface.Coverage.OnMount` on a 30-second interval
  (configurable; floor 5_000 ms — see D-30a).

  This module is pure stdlib — NO `Code.ensure_loaded?(Phoenix.LiveView)`
  file-scope gate (D-36). The struct is consumed by the LV-gated dashboard
  AND will be consumed by future Mix-task surfaces (`mix threadline.health.coverage`).
  """

  defstruct covered_count: 0,
            uncovered_count: 0,
            expected_uncovered_count: 0,
            last_checked_at: nil,
            error: nil,
            tables: [covered: [], uncovered: [], expected_uncovered: []]

  @type bucket :: :covered | :uncovered | :expected_uncovered
  @type t :: %__MODULE__{
          covered_count: non_neg_integer(),
          uncovered_count: non_neg_integer(),
          expected_uncovered_count: non_neg_integer(),
          last_checked_at: DateTime.t() | nil,
          error: String.t() | nil,
          tables: [{bucket(), [String.t()]}]
        }

  @doc """
  `from_coverage/2` — builds a Snapshot from a `Threadline.Health.trigger_coverage/1`
  result list.

  `:last_checked_at` is read from `opts` (defaults to `DateTime.utc_now/0`).
  """
  def from_coverage(coverage, opts \\ []) when is_list(coverage) do
    last_checked_at = Keyword.get(opts, :last_checked_at, DateTime.utc_now())

    grouped =
      Enum.reduce(coverage, %{covered: [], uncovered: [], expected_uncovered: []}, fn
        {:covered, name}, acc -> Map.update!(acc, :covered, &[name | &1])
        {:uncovered, name}, acc -> Map.update!(acc, :uncovered, &[name | &1])
        {:expected_uncovered, name}, acc -> Map.update!(acc, :expected_uncovered, &[name | &1])
      end)

    tables = [
      covered: Enum.sort(grouped.covered),
      uncovered: Enum.sort(grouped.uncovered),
      expected_uncovered: Enum.sort(grouped.expected_uncovered)
    ]

    %__MODULE__{
      covered_count: length(grouped.covered),
      uncovered_count: length(grouped.uncovered),
      expected_uncovered_count: length(grouped.expected_uncovered),
      last_checked_at: last_checked_at,
      error: nil,
      tables: tables
    }
  end

  @doc """
  Empty snapshot — used when on_mount cannot fetch initial coverage and there
  is no previous Snapshot to fall back on (e.g. very first render under error).
  """
  def empty(last_checked_at \\ nil) do
    %__MODULE__{
      covered_count: 0,
      uncovered_count: 0,
      expected_uncovered_count: 0,
      last_checked_at: last_checked_at,
      error: nil,
      tables: [covered: [], uncovered: [], expected_uncovered: []]
    }
  end
end
