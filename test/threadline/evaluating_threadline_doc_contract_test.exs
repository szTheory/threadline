defmodule Threadline.EvaluatingThreadlineDocContractTest do
  use ExUnit.Case, async: true

  @guide "guides/evaluating-threadline.md"
  @backlog "guides/adoption-pilot-backlog.md"

  defp adoption_pilot_hex_ok? do
    backlog = File.read!(@backlog)

    backlog
    |> String.split("\n")
    |> Enum.find(fn line ->
      String.contains?(line, "threadline") and String.contains?(line, "Hex")
    end)
    |> case do
      nil -> false
      row -> String.contains?(row, "| OK |")
    end
  end

  test "when adoption-pilot Hex row is OK, refutes hex still 0.5.0 caveat" do
    guide = File.read!(@guide)

    if adoption_pilot_hex_ok?() do
      refute String.contains?(guide, "may still list **0.5.0** as latest")
    end
  end

  test "evaluating guide exists with 0.6.0 packaging anchor (PILOT-02)" do
    guide = File.read!(@guide)

    assert String.contains?(guide, "0.6.0")
    assert String.contains?(guide, "Audit.transaction/3")
    assert String.contains?(guide, "0.5.0")
    assert String.contains?(guide, "0.6.0 packages Evidence")
  end

  test "evaluating guide locks verify ladder entrypoints (PILOT-02)" do
    guide = File.read!(@guide)

    assert String.contains?(guide, "mix ci.all")
    assert String.contains?(guide, "mix verify.doc_contract")
    assert String.contains?(guide, "mix verify.example")
    assert String.contains?(guide, "mix verify.hex_evaluator")
    assert String.contains?(guide, "adoption-evidence-playbook.md")
  end

  test "evaluating guide states host-owned boundaries and STG template pointers (PILOT-02)" do
    guide = File.read!(@guide)

    assert String.match?(guide, ~r/host-owned/i)
    assert String.contains?(guide, "STG-HOST-TOPOLOGY-TEMPLATE")
    assert String.contains?(guide, "STG-AUDITED-PATH-RUBRIC")
    assert String.contains?(guide, "adoption-pilot-backlog.md")
  end

  test "evaluating guide links outward to mental model and ops docs (PILOT-02)" do
    guide = File.read!(@guide)

    assert String.contains?(guide, "how-threadline-works.md")
    assert String.contains?(guide, "upgrade-path.md")
    assert String.contains?(guide, "production-checklist.md")
  end

  test "evaluating guide refutes maintainer STG attestation phrasing (PILOT-02)" do
    guide = File.read!(@guide)
    refute Regex.match?(~r/maintainer.*STG.*(attest|certif)/i, guide)
  end

  test "evaluating guide links phx-gen-auth reference lane and neutrality (ADOPT-AUTH-02)" do
    guide = File.read!(@guide)

    assert String.contains?(guide, "guides/integrations/phx-gen-auth.md")
    assert String.contains?(guide, "`phx-gen-auth-reference`")
    assert String.contains?(guide, "sigra-reference")
    assert String.contains?(guide, "mix verify.example")
    assert String.contains?(guide, "root integration tests")
    assert String.contains?(guide, "prove auth and tenancy in staging")
  end
end
