defmodule Threadline.PhxGenAuthDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  test "phx-gen-auth guide retains its marker and section order" do
    doc = read_rel!(["guides", "integrations", "phx-gen-auth.md"])

    assert String.contains?(doc, "<!-- PHX-GEN-AUTH-03-INTEGRATION-GUIDE -->")
    assert String.contains?(doc, "# Threadline ↔ phx.gen.auth integration")
    assert String.contains?(doc, "phx-gen-auth-reference")
    assert String.contains?(doc, "reference claim")

    for heading <- [
          "## Prerequisites",
          "## Plug callback wire-up",
          "## Surface and export auth stay host-owned",
          "## Reference semantics",
          "## Non-goals",
          "## Lane and proof"
        ] do
      assert String.contains?(doc, heading)
    end

    {idx_prereq, _} = :binary.match(doc, "## Prerequisites")
    {idx_plug, _} = :binary.match(doc, "## Plug callback wire-up")
    {idx_surface, _} = :binary.match(doc, "## Surface and export auth stay host-owned")
    {idx_semantics, _} = :binary.match(doc, "## Reference semantics")
    {idx_nongoals, _} = :binary.match(doc, "## Non-goals")
    {idx_lane, _} = :binary.match(doc, "## Lane and proof")

    assert idx_prereq < idx_plug
    assert idx_plug < idx_surface
    assert idx_surface < idx_semantics
    assert idx_semantics < idx_nongoals
    assert idx_nongoals < idx_lane
  end

  test "phx-gen-auth guide locks host-owned plug and authorize literals" do
    doc = read_rel!(["guides", "integrations", "phx-gen-auth.md"])

    assert String.contains?(doc, "MyApp.AuditActor")
    assert String.contains?(doc, "conn.assigns[:current_scope]")
    assert String.contains?(doc, "plug Threadline.Plug,")
    assert String.contains?(doc, "actor_fn: &MyApp.AuditActor.actor_ref_from_conn/1")

    surface_start = "## Surface and export auth stay host-owned"
    surface_end = "## Reference semantics"
    {surface_idx, _} = :binary.match(doc, surface_start)
    {semantics_idx, _} = :binary.match(doc, surface_end)
    surface = binary_part(doc, surface_idx, semantics_idx - surface_idx)

    assert String.contains?(surface, "authorize_fn:")
    assert String.contains?(surface, "&MyApp.Audit.authorize_operator/1")
    assert String.contains?(surface, "defmodule MyApp.Audit")
    assert String.contains?(surface, "%{assigns: assigns}")
    assert String.contains?(surface, "assigns[:current_scope]")
    assert String.contains?(surface, "is_admin: true")
    assert String.contains?(surface, "{:error, :unauthorized}")

    refute String.contains?(
             surface,
             "%{assigns: %{current_user: %{role: \"admin\"}}}"
           )

    refute String.contains?(doc, "_, _ ->")
  end

  test "phx-gen-auth guide locks proof paths and refutes adapter drift" do
    doc = read_rel!(["guides", "integrations", "phx-gen-auth.md"])

    assert String.contains?(
             doc,
             "test/threadline/integrations/phx_gen_auth_integration_test.exs"
           )

    assert String.contains?(doc, "mix verify.test")
    refute String.contains?(doc, "forthcoming")
    refute String.contains?(doc, "Threadline.Integrations.Sigra")
  end
end
