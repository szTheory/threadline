defmodule Threadline.IaLockDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @personas_ia Path.expand("../../.planning/milestones/v1.31-PERSONAS-IA.md", __DIR__)
  @ui_audit Path.expand("../../.planning/milestones/v1.31-UI-AUDIT.md", __DIR__)

  test "PERSONAS-IA.md contains all persona IDs P1–P5" do
    doc = File.read!(@personas_ia)

    for id <- ~w(P1 P2 P3 P4 P5) do
      assert String.contains?(doc, id),
             "expected v1.31-PERSONAS-IA.md to contain #{inspect(id)}"
    end
  end

  test "PERSONAS-IA.md contains all JTBD IDs J1–J11" do
    doc = File.read!(@personas_ia)

    for id <- ~w(J1 J2 J3 J4 J5 J6 J7 J8 J9 J10 J11) do
      assert String.contains?(doc, id),
             "expected v1.31-PERSONAS-IA.md to contain #{inspect(id)}"
    end
  end

  test "PERSONAS-IA.md contains all earned flow IDs EF1–EF5" do
    doc = File.read!(@personas_ia)

    for id <- ~w(EF1 EF2 EF3 EF4 EF5) do
      assert String.contains?(doc, id),
             "expected v1.31-PERSONAS-IA.md to contain #{inspect(id)}"
    end
  end

  test "PERSONAS-IA.md contains the Find/Verify/Prove triad" do
    doc = File.read!(@personas_ia)

    assert String.contains?(doc, "Find/Verify/Prove") or
             String.contains?(doc, "Find / Verify / Prove"),
           "expected v1.31-PERSONAS-IA.md to contain Find/Verify/Prove triad"
  end

  test "PERSONAS-IA.md carries the Phase 135 lock status header" do
    doc = File.read!(@personas_ia)

    assert String.contains?(doc, "Locked by Phase 135"),
           "expected v1.31-PERSONAS-IA.md to contain 'Locked by Phase 135'"
  end

  test "v1.31-UI-AUDIT.md contains the D-17 IA pointer line" do
    doc = File.read!(@ui_audit)

    assert String.contains?(doc, "v1.31-PERSONAS-IA.md"),
           "expected v1.31-UI-AUDIT.md to reference v1.31-PERSONAS-IA.md"

    assert String.contains?(doc, "P1–P5"),
           "expected v1.31-UI-AUDIT.md pointer to mention P1–P5"

    assert String.contains?(doc, "EF1–EF5"),
           "expected v1.31-UI-AUDIT.md pointer to mention EF1–EF5"
  end
end
