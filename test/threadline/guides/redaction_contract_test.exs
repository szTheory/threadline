defmodule Threadline.Guides.RedactionContractTest do
  use ExUnit.Case, async: true

  @guide "guides/redaction.md"

  @required_evidence [
    "Threadline.Capture.RedactionLeakPropertyTest",
    "Threadline.Capture.RedactionPolicyPropertyTest",
    "Threadline.Capture.TriggerMigrateTimeErrorsTest",
    "Threadline.Policy.RedactionPresenterTest",
    "mix threadline.policy.show"
  ]

  @required_residuals [
    "host source tables",
    "PostgreSQL WAL",
    "logical decoding output",
    "replication slots",
    "backups",
    "PostgreSQL superusers",
    "before a redaction rule was corrected or introduced",
    "host application logs",
    "downstream copies made from exported data"
  ]

  @required_claims [
    "stored `audit_changes` and `audit_transactions`",
    "`ChangeDiff`",
    "CSV, JSON, and NDJSON exports",
    "do not validate column existence",
    "do not create a column-existence health finding",
    "`changed_fields`",
    "regenerate the trigger",
    "do not rewrite",
    "does not redact or repair",
    "`TriggerSQL.install_function/1`",
    "`TriggerSQL.create_trigger/3`"
  ]

  @absolute_claim ~r/\b(?:always|never|fully|completely|guarantees?|guaranteed)\b/i
  @scope_qualifier ~r/\b(?:generated per-table|tested path|evidence above|specific path)\b/i
  @explicit_limit ~r/\b(?:does not establish|does not prove|may remain|cannot control)\b/i

  test "redaction claims name the evidence, scope, timing, and residual plaintext locations" do
    guide = File.read!(@guide)

    for evidence <- @required_evidence do
      assert guide =~ evidence, "redaction guide is missing #{evidence}"
    end

    for residual <- @required_residuals do
      assert guide =~ residual, "redaction guide is missing residual location #{residual}"
    end

    for claim <- @required_claims do
      assert guide =~ claim, "redaction guide is missing boundary claim #{claim}"
    end

    assert unscoped_absolute_claims(guide) == []
  end

  test "claim removal mutation is detected" do
    guide = File.read!(@guide)

    mutated =
      String.replace(guide, "Threadline.Capture.RedactionLeakPropertyTest", "RemovedProof")

    assert "Threadline.Capture.RedactionLeakPropertyTest" in missing_evidence(mutated)
  end

  test "absolute wording needs a tested-path qualifier or an explicit limit" do
    assert unscoped_absolute_claims("Threadline redaction never stores plaintext.") == [
             "Threadline redaction never stores plaintext."
           ]

    assert unscoped_absolute_claims(
             "The generated per-table trigger never stores the masked value in tested exports."
           ) == []

    assert unscoped_absolute_claims("Threadline cannot control downstream export copies.") == []
  end

  defp missing_evidence(guide) do
    Enum.reject(@required_evidence, &String.contains?(guide, &1))
  end

  defp unscoped_absolute_claims(guide) do
    guide
    |> String.split(~r/(?<=[.!?])\s+/, trim: true)
    |> Enum.filter(fn sentence ->
      Regex.match?(@absolute_claim, sentence) and
        not Regex.match?(@scope_qualifier, sentence) and
        not Regex.match?(@explicit_limit, sentence)
    end)
  end
end
