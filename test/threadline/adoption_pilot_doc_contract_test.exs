defmodule Threadline.AdoptionPilotDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @guide "guides/adoption-pilot-backlog.md"
  @version Threadline.MixProject.project()[:version]

  test "adoption-pilot distribution preflight matches mix.exs version and ~> 0.6 constraint" do
    guide = File.read!(@guide)

    assert String.contains?(guide, @version)
    assert String.contains?(guide, "~> 0.6")
    refute String.contains?(guide, "~> 0.5")
    refute String.contains?(guide, "0.2.0")
    refute String.contains?(guide, "~> 0.2")
  end

  test "adoption-pilot links upgrade-path for lane story" do
    guide = File.read!(@guide)
    assert String.contains?(guide, "guides/upgrade-path.md")
  end
end
