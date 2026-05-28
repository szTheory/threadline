defmodule Threadline.SemverAdopterDocContractTest do
  use ExUnit.Case, async: true

  @adopter_paths [
    "README.md",
    "guides/getting-started-saas.md",
    "guides/how-threadline-works.md",
    "guides/upgrade-path.md",
    "guides/adoption-pilot-backlog.md"
  ]

  @milestone_pattern ~r/v1\.2[0-9]/

  test "adopter-band docs avoid internal v1.2x milestone labels" do
    for path <- @adopter_paths do
      doc = File.read!(path)
      refute Regex.match?(@milestone_pattern, doc), "expected no v1.2x in #{path}"

      refute String.contains?(doc, "guides/evidence-plane.md"),
             "expected no phantom evidence-plane hub in #{path}"
    end
  end
end
