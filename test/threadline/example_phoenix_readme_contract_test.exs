defmodule Threadline.ExamplePhoenixReadmeContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()
  @readme_path ["examples", "threadline_phoenix", "README.md"]

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  test "example README locks the direct Sigra callback pair" do
    doc = read_rel!(@readme_path)

    assert String.contains?(doc, "Threadline.Integrations.Sigra.actor_ref_from_conn/1")

    assert String.contains?(
             doc,
             "Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1"
           )

    assert String.contains?(doc, "wired directly into `Threadline.Plug`")
  end

  test "example README does not teach an app-local delegate seam" do
    doc = read_rel!(@readme_path)

    refute String.contains?(doc, "delegates to")
    refute String.contains?(doc, "ThreadlinePhoenix.AuditActor")
  end

  test "example README locks the incident drill-down auth boundary" do
    doc = read_rel!(@readme_path)

    assert String.contains?(doc, "Threadline.incident_bundle/2")
    assert String.contains?(doc, "COMP-EXAMPLE-INCIDENT-JSON")
    assert String.contains?(doc, "requires an authenticated actor before it serves the")
    assert String.contains?(doc, "drill-down endpoint")
    assert String.contains?(doc, "Hosts still need their own tenancy and policy checks")
  end
end
