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

  test "README declares the public API surface" do
    readme = File.read!("README.md")
    assert String.contains?(readme, "Threadline.Plug")
    assert String.contains?(readme, "Threadline.record_action/2")
    assert String.contains?(readme, "Threadline.history/3")
    assert String.contains?(readme, "Threadline.timeline/2")
    assert String.contains?(readme, "Threadline.export_json/2")
    assert String.contains?(readme, "Threadline.as_of/4")
  end

  test "README links domain reference guide" do
    readme = File.read!("README.md")
    assert String.contains?(readme, "guides/domain-reference.md")
  end

  test "README links production checklist guide" do
    readme = File.read!("README.md")
    assert String.contains?(readme, "guides/production-checklist.md")
  end

  test "README links adoption pilot backlog guide" do
    readme = File.read!("README.md")
    assert String.contains?(readme, "guides/adoption-pilot-backlog.md")
  end

  test "examples README indexes Phoenix reference app" do
    doc = File.read!("examples/README.md")
    assert String.contains?(doc, "threadline_phoenix")
    assert String.contains?(doc, "threadline_phoenix/README.md")
  end

  test "example README carries runbook literals for REF-01" do
    doc = File.read!("examples/threadline_phoenix/README.md")

    assert String.contains?(doc, "mix phx.server") or
             String.contains?(doc, "iex -S mix phx.server")

    assert String.contains?(doc, "mix test")
    assert String.contains?(doc, "ecto.migrate")
  end

  test "example README carries historical reconstruction walkthrough literals" do
    doc = File.read!("examples/threadline_phoenix/README.md")

    assert String.contains?(doc, "Historical reconstruction walkthrough")
    assert String.contains?(doc, "ThreadlinePhoenix.Post")
    assert String.contains?(doc, "as_of/4")
    assert String.contains?(doc, "cast: true")
    assert String.contains?(doc, ":deleted_record")
    assert String.contains?(doc, ":before_audit_horizon")
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
