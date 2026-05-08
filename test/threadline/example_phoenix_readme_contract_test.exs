defmodule Threadline.ExamplePhoenixReadmeContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Threadline.GettingStartedFixtures

  @repo_root File.cwd!()
  @readme_path ["examples", "threadline_phoenix", "README.md"]

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  test "example README locks the direct Sigra callback pair" do
    doc = read_rel!(@readme_path)

    assert String.contains?(doc, "This app is the current `sigra-reference` lane")
    assert String.contains?(doc, "maintained first-party")
    assert String.contains?(doc, "It does not claim that arbitrary Sigra versions")
    assert String.contains?(doc, "Threadline.Integrations.Sigra.actor_ref_from_conn/1")

    assert String.contains?(
             doc,
             "Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1"
           )

    assert String.contains?(doc, "wired directly into `Threadline.Plug`")
    assert String.contains?(doc, "soft-loaded, host-owned")
    assert String.contains?(doc, "runnable proof artifact behind that path")
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
    assert String.contains?(doc, "mix threadline.incident <audit_transaction_id>")
  end

  test "example README locks the mounted operator-surface story to the router source" do
    doc = read_rel!(@readme_path)

    assert String.contains?(doc, "secured `/audit` path")
    assert String.contains?(doc, "treat this as a `sigra-reference` example layered on top")
    assert String.contains?(doc, "root library's broader `phoenix-surface` lane")
    assert String.contains?(doc, "Sigra `0.2.5`, Phoenix `1.8.5`")
    assert String.contains?(doc, "scope and pipeline")
    assert contains_normalized?(doc, router_mount_block())
    assert String.contains?(doc, "pipeline :admin_auth")
    assert String.contains?(doc, "authenticated administrative user")
    assert String.contains?(doc, "`phx.gen.auth`-style posture")
    assert String.contains?(doc, "shared `%{assigns: assigns}`")
    assert String.contains?(doc, "support-read-only variation")
    assert String.contains?(doc, "`exports: false`")
    assert String.contains?(doc, "HTTP-native `403`")
    assert String.contains?(doc, "http://localhost:4000/audit")
    assert String.contains?(doc, "../../guides/getting-started-saas.md")
    assert String.contains?(doc, "without becoming the primary onboarding narrative")
    assert String.contains?(doc, "mix threadline.health.coverage")
    assert String.contains?(doc, "mix threadline.policy.show")
    assert String.contains?(doc, "mix threadline.incident <audit_transaction_id>")
  end

  test "example router uses one shared assigns-shaped authorizer" do
    router =
      read_rel!(["examples", "threadline_phoenix", "lib", "threadline_phoenix_web", "router.ex"])

    assert String.contains?(router, "def my_authorize_fn(%{assigns: assigns}) do")
    assert String.contains?(router, "scope_query_fn: &MyApp.Audit.scope_operator_query/3")
    assert String.contains?(router, "exports: false")
    refute String.contains?(router, "def my_authorize_fn(%Plug.Conn{}")
    refute String.contains?(router, "def my_authorize_fn(%Phoenix.LiveView.Socket{}")
    refute String.contains?(router, "match?(%Phoenix.LiveView.Socket{}, transport)")
  end

  defp router_mount_block do
    GettingStartedFixtures.extract!(
      "examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex",
      "operator-surface-mount"
    )
  end

  defp contains_normalized?(doc, snippet) do
    String.contains?(normalize(doc), normalize(snippet))
  end

  defp normalize(value) do
    value
    |> String.trim()
    |> String.replace(~r/\s+/, " ")
  end
end
