defmodule Threadline.OperatorSurface.MechanicalChecker.RatchetMetrics do
  @moduledoc false

  alias Threadline.OperatorSurface.MechanicalChecker.Parsing

  # MODE-B ratchet floors and far ceilings for one scorecard.
  #
  # The parent module measures the metrics and declares the pinned ceilings; they
  # arrive here in the `limits` map:
  #
  #   * `:metrics` — metric names, in the order violations are reported
  #   * `:measured` — the measured value per metric name
  #   * `:ceilings` — the far ceiling per metric name (absent means no ceiling)

  def check(scorecard, floors, limits) do
    cell_id = scorecard["cell_id"]
    ledger_id = scorecard["ledger_id"]
    theme_bp = "#{scorecard["theme"]}_#{scorecard["breakpoint"]}"

    Enum.flat_map(limits.metrics, fn metric ->
      current = Map.fetch!(limits.measured, metric)
      floor = get_in(floors, [ledger_id, metric, theme_bp])
      ceiling = Map.get(limits.ceilings, metric)
      mode_b_metric_violations(metric, current, floor, ceiling, cell_id, theme_bp)
    end)
  end

  # Absent floor + a real far ceiling -> absolute blocker. A recorded floor grandfathers
  # any pre-existing >ceiling value; only worsening past that floor then fails.
  defp mode_b_metric_violations(metric, current, floor, ceiling, cell_id, theme_bp) do
    cond do
      is_nil(floor) and not is_nil(ceiling) and current > ceiling ->
        [ceiling_violation(metric, current, ceiling, cell_id, theme_bp)]

      not is_nil(floor) and current > floor ->
        [ratchet_violation(metric, current, floor, cell_id, theme_bp)]

      true ->
        []
    end
  end

  defp ceiling_violation(metric, current, ceiling, cell_id, theme_bp) do
    %{
      cell_id: cell_id,
      metric: metric,
      mode: "B",
      selector: "##{theme_bp}",
      observed: Parsing.fmt(current),
      expected: "<= #{ceiling}",
      fix: "reduce #{metric} to <= #{ceiling} (structural correction + human review required)"
    }
  end

  defp ratchet_violation(metric, current, floor, cell_id, theme_bp) do
    %{
      cell_id: cell_id,
      metric: metric,
      mode: "B",
      selector: "##{theme_bp}",
      observed: Parsing.fmt(current),
      expected: "<= floor #{Parsing.fmt(floor)}",
      fix:
        "#{metric} regressed past its ratchet floor (#{Parsing.fmt(current)} > #{Parsing.fmt(floor)}) — " <>
          "revert the regression or record a ratchet reset with rationale"
    }
  end
end
