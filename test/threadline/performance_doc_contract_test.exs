defmodule Threadline.PerformanceDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  test "performance guide retains PERF markers and BENCHMARK-ENV block" do
    doc = read_rel!(["guides", "performance.md"])

    assert String.contains?(doc, "<!-- PERF-01 -->")
    assert String.contains?(doc, "<!-- PERF-02 -->")
    assert String.contains?(doc, "<!-- PERF-03 -->")
    assert String.contains?(doc, "```yaml BENCHMARK-ENV")
  end

  test "performance guide retains required headings" do
    doc = read_rel!(["guides", "performance.md"])

    for heading <- [
          "## Workload Presets",
          "## Throughput Baselines",
          "## Impact on Primary Transactions",
          "## Capture-time cost knobs"
        ] do
      assert String.contains?(doc, heading)
    end
  end
end
