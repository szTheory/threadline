defmodule Threadline.ReadmeDocContractTest do
  @moduledoc false
  use Threadline.DataCase

  alias Threadline.Test.Repo

  test "readme quickstart fixtures module is loadable" do
    assert Code.ensure_loaded?(Threadline.ReadmeQuickstartFixtures)
  end

  test "readme doc contract router compiles with Threadline.Plug" do
    assert Code.ensure_loaded?(Threadline.ReadmeDocContractRouter)
  end

  test "README mentions export and timeline together" do
    readme = File.read!("README.md")
    assert String.contains?(readme, "export")
    assert String.contains?(readme, "timeline")
  end

  test "README links production checklist guide" do
    readme = File.read!("README.md")
    assert String.contains?(readme, "guides/production-checklist.md")
  end

  test "README links adoption pilot backlog guide" do
    readme = File.read!("README.md")
    assert String.contains?(readme, "guides/adoption-pilot-backlog.md")
  end

  test "fixture calls match public README API shapes" do
    map = Threadline.ReadmeQuickstartFixtures.actor_ref_map_examples()
    assert map.anonymous["type"] == "anonymous"
    assert is_binary(Threadline.ReadmeQuickstartFixtures.jason_encode_actor_example())

    assert {:ok, _} = Threadline.ReadmeQuickstartFixtures.record_action_call(Repo)

    cov = Threadline.ReadmeQuickstartFixtures.trigger_coverage_call()
    assert is_list(cov)
    assert Enum.all?(cov, &match?({tag, _} when tag in [:covered, :uncovered], &1))
  end
end
