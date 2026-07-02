defmodule Threadline.ReleaseArtifactContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  defp project_config, do: Threadline.MixProject.project()

  defp docs_config, do: project_config()[:docs]

  defp package_files, do: MapSet.new(project_config()[:package][:files])

  defp guide_extras do
    docs_config()[:extras]
    |> Enum.filter(&String.starts_with?(&1, "guides/"))
    |> MapSet.new()
  end

  defp guides_on_disk do
    Path.wildcard("guides/**/*.md")
    |> MapSet.new()
  end

  test "guides on disk match the ExDoc guide extras allowlist" do
    assert guide_extras() == guides_on_disk()
  end

  test "release package includes the shipped documentation surfaces" do
    files = package_files()
    extras = docs_config()[:extras]

    assert "guides" in files
    assert "README.md" in files
    assert "CHANGELOG.md" in files
    assert "CONTRIBUTING.md" in files
    assert "README.md" in extras
    assert "CONTRIBUTING.md" in extras
    assert "CHANGELOG.md" in extras
  end

  test "ExDoc extras keep integrations ahead of the verb routing lanes" do
    assert Keyword.keys(docs_config()[:groups_for_extras]) == [
             :Overview,
             :Integrations,
             :Evaluate,
             :Adopt,
             :Operate,
             :Contribute
           ]
  end

  test "ExDoc module groups keep Sigra in a dedicated integrations bucket" do
    groups = docs_config()[:groups_for_modules]

    assert Keyword.fetch!(groups, :Integrations) == [Threadline.Integrations.Sigra]

    assert Keyword.fetch!(groups, :"Operator Surface (Optional In-Tree)") == [
             Threadline.OperatorSurface.Router,
             Threadline.OperatorSurface.Auth
           ]

    assert Keyword.fetch!(groups, :Integration) == [
             Threadline.Plug,
             Threadline.Job,
             Threadline.Health,
             Threadline.Continuity,
             Threadline.Telemetry
           ]
  end

  test "ExDoc module groups include Evidence plane and Core API audit modules" do
    groups = docs_config()[:groups_for_modules]

    assert Keyword.fetch!(groups, :Evidence) == [
             Threadline.Evidence,
             Threadline.Evidence.Proof,
             Threadline.Evidence.Subject
           ]

    core_api = Keyword.fetch!(groups, :"Core API")
    assert Threadline.Audit in core_api

    mix_tasks = Keyword.fetch!(groups, :"Mix Tasks")
    assert Mix.Tasks.Threadline.Evidence.Show in mix_tasks
  end

  test "README carries only the release-scoped installer and routing literals" do
    readme = File.read!("README.md")

    assert String.contains?(readme, "{:threadline, \"~> 0.9.0\"}")
    assert String.contains?(readme, "guides/how-threadline-works.md")
    assert String.contains?(readme, "guides/getting-started-saas.md")
    assert String.contains?(readme, "guides/integrations/sigra.md")
  end

  test "CONTRIBUTING carries the release pre-flight and release workflow literals" do
    doc = File.read!("CONTRIBUTING.md")

    assert String.contains?(doc, "mix verify.release")
    assert String.contains?(doc, ".github/workflows/release.yml")
    assert String.contains?(doc, "workflow_dispatch")
    assert String.contains?(doc, "v0.6.0")
  end
end
