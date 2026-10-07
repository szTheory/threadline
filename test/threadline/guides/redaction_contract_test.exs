defmodule Threadline.Guides.RedactionContractTest do
  use ExUnit.Case, async: true

  @guide "guides/redaction.md"

  @required_evidence [
    "test/threadline/capture/redaction_leak_property_test.exs",
    "test/threadline/capture/redaction_policy_property_test.exs",
    "test/threadline/capture/trigger_migrate_time_errors_test.exs",
    "test/threadline/policy/redaction_presenter_test.exs",
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

  @claim_evidence [
    {"A generated per-table trigger omits excluded values and masks configured values",
     ["test/threadline/capture/redaction_leak_property_test.exs"], []},
    {"Redaction policy shape is validated, including overlap rules",
     ["test/threadline/capture/redaction_policy_property_test.exs"], []},
    {"A generated host migration rejects an absent configured `mask:` or `exclude:` column",
     ["test/threadline/capture/trigger_migrate_time_errors_test.exs"], []},
    {"The configured/deployed policy view compares policy descriptions",
     ["test/threadline/policy/redaction_presenter_test.exs"], ["mix threadline.policy.show"]}
  ]

  @absolute_claim ~r/(?:\b(?:all|every|always|never|no|none|nothing|zero|not\s+(?:a\s+)?single|not\s+one|fully|completely|impossible|can(?:not|'t|’t|\s+not)|will\s+not|must\s+not|shall\s+not|won['’]t|without\s+(?:(?:any|a\s+single)\s+)?exceptions?|without\s+(?:ever\s+)?fail|free\s+(?:of|from)|foolproof|\w+-proof|\w+-free|prevent\w*|eliminat\w*|ensur\w*|guarante\w*|saf\w*|secur\w*|protect\w*|immune|risk[\s-]?free|(?:do(?:es)?|did)\s+not\s+(?:leak|expos|stor|writ|record|persist|retain|sav|emit|export|log|output|return|includ|contain|captur|disclos|send|transmit|share|forward|deliver|publish|distribut|transfer)\w*|(?:do|does|did)n['’]t\s+(?:leak|expos|stor|writ|record|persist|retain|sav|emit|export|log|output|return|includ|contain|captur|disclos|send|transmit|share|forward|deliver|publish|distribut|transfer)\w*)\b|\b0(?:\.0+)?\s*%(?!\w)|\b0(?:\.0+)?\s+percent(?:age)?\b|\b100(?:\.0+)?\s*%(?!\w)|\b100(?:\.0+)?\s+percent(?:age)?\b|\bone\s+hundred\s+percent\b)/iu
  @bounded_claims [
    "The evidence below describes the paths each test exercises; it does not establish that every copy of a value is redacted.",
    "The generated per-table trigger never stores the masked value in tested exports.",
    "Threadline cannot control every copy around PostgreSQL and the host application.",
    "Threadline cannot control copies made after an export leaves the process that produced it.",
    "They do not establish equivalent behavior for the global redacted `TriggerSQL.install_function/1` path, which generated migrations do not emit, or for a direct `TriggerSQL.create_trigger/3` call that omits the redaction options."
  ]

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

    for {claim, evidence_paths, evidence_text} <- @claim_evidence do
      row = evidence_row(guide, claim)
      assert row, "redaction guide is missing claim/evidence row for #{claim}"
      linked_paths = repository_test_paths(row)

      for path <- evidence_paths do
        assert path in linked_paths,
               "redaction guide's row for #{claim} must link to #{path}, got #{inspect(linked_paths)}"

        assert File.regular?(path),
               "redaction guide links to missing local evidence file #{path}"
      end

      for item <- evidence_text do
        assert row =~ item,
               "redaction guide's row for #{claim} is missing evidence #{item}"
      end
    end

    assert unscoped_absolute_claims(guide) == []
  end

  test "claim removal mutation is detected" do
    guide = File.read!(@guide)

    mutated =
      String.replace(guide, "redaction_leak_property_test.exs", "removed-proof.exs")

    assert "test/threadline/capture/redaction_leak_property_test.exs" in missing_evidence(mutated)
  end

  test "absolute wording must match a reviewed bounded sentence exactly" do
    assert unscoped_absolute_claims("All data is plaintext-safe.") == [
             "All data is plaintext-safe."
           ]

    assert unscoped_absolute_claims("Threadline redaction never stores plaintext.") == [
             "Threadline redaction never stores plaintext."
           ]

    assert unscoped_absolute_claims("This prevents plaintext exposure.") == [
             "This prevents plaintext exposure."
           ]

    assert unscoped_absolute_claims("The generated trigger eliminates plaintext exposure.") == [
             "The generated trigger eliminates plaintext exposure."
           ]

    assert unscoped_absolute_claims("No plaintext can escape the generated trigger.") == [
             "No plaintext can escape the generated trigger."
           ]

    assert unscoped_absolute_claims("Generated triggers leave zero plaintext copies.") == [
             "Generated triggers leave zero plaintext copies."
           ]

    assert unscoped_absolute_claims("Nothing can escape the generated trigger.") == [
             "Nothing can escape the generated trigger."
           ]

    assert unscoped_absolute_claims("The generated trigger keeps plaintext values safe.") == [
             "The generated trigger keeps plaintext values safe."
           ]

    assert unscoped_absolute_claims("The generated trigger securely removes plaintext.") == [
             "The generated trigger securely removes plaintext."
           ]

    assert unscoped_absolute_claims("The data is protected from plaintext exposure.") == [
             "The data is protected from plaintext exposure."
           ]

    assert unscoped_absolute_claims("This approach is immune to value leaks.") == [
             "This approach is immune to value leaks."
           ]

    assert unscoped_absolute_claims("The generated trigger is risk-free.") == [
             "The generated trigger is risk-free."
           ]

    assert unscoped_absolute_claims(
             "The generated trigger masks configured fields without exception."
           ) == ["The generated trigger masks configured fields without exception."]

    assert unscoped_absolute_claims(
             "The generated trigger masks configured fields without exceptions."
           ) == ["The generated trigger masks configured fields without exceptions."]

    assert unscoped_absolute_claims(
             "The generated trigger masks configured fields without a single exception."
           ) == ["The generated trigger masks configured fields without a single exception."]

    assert unscoped_absolute_claims("The generated trigger masks fields without fail.") == [
             "The generated trigger masks fields without fail."
           ]

    assert unscoped_absolute_claims("The generated trigger is leak-proof.") == [
             "The generated trigger is leak-proof."
           ]

    assert unscoped_absolute_claims("The redaction is foolproof.") == [
             "The redaction is foolproof."
           ]

    assert unscoped_absolute_claims("The generated capture is leak-free.") == [
             "The generated capture is leak-free."
           ]

    assert unscoped_absolute_claims("The generated trigger is free of plaintext leaks.") == [
             "The generated trigger is free of plaintext leaks."
           ]

    assert unscoped_absolute_claims("The generated trigger is free from plaintext leaks.") == [
             "The generated trigger is free from plaintext leaks."
           ]

    assert unscoped_absolute_claims("The generated trigger shall not persist plaintext.") == [
             "The generated trigger shall not persist plaintext."
           ]

    assert unscoped_absolute_claims("The generated trigger must not leak plaintext.") == [
             "The generated trigger must not leak plaintext."
           ]

    assert unscoped_absolute_claims("Generated triggers achieve 100% redaction coverage.") == [
             "Generated triggers achieve 100% redaction coverage."
           ]

    assert unscoped_absolute_claims("Generated triggers produce 0% plaintext leakage.") == [
             "Generated triggers produce 0% plaintext leakage."
           ]

    assert unscoped_absolute_claims("Generated triggers produce 0.0% plaintext leakage.") == [
             "Generated triggers produce 0.0% plaintext leakage."
           ]

    assert unscoped_absolute_claims("Generated triggers achieve 100.0% redaction coverage.") == [
             "Generated triggers achieve 100.0% redaction coverage."
           ]

    assert unscoped_absolute_claims("Generated triggers achieve 100 percent redaction coverage.") ==
             [
               "Generated triggers achieve 100 percent redaction coverage."
             ]

    assert unscoped_absolute_claims("Generated triggers achieve one hundred percent coverage.") ==
             [
               "Generated triggers achieve one hundred percent coverage."
             ]

    assert unscoped_absolute_claims("Plaintext leakage is impossible with the generated trigger.") ==
             [
               "Plaintext leakage is impossible with the generated trigger."
             ]

    assert unscoped_absolute_claims("The generated trigger cannot leak plaintext.") == [
             "The generated trigger cannot leak plaintext."
           ]

    assert unscoped_absolute_claims("The generated trigger does not leak plaintext.") == [
             "The generated trigger does not leak plaintext."
           ]

    assert unscoped_absolute_claims("The generated trigger doesn't leak plaintext.") == [
             "The generated trigger doesn't leak plaintext."
           ]

    assert unscoped_absolute_claims("The generated trigger doesn’t leak plaintext.") == [
             "The generated trigger doesn’t leak plaintext."
           ]

    assert unscoped_absolute_claims(
             "The generated trigger does not write plaintext to audit rows."
           ) == [
             "The generated trigger does not write plaintext to audit rows."
           ]

    assert unscoped_absolute_claims("The generated trigger doesn't record plaintext.") == [
             "The generated trigger doesn't record plaintext."
           ]

    assert unscoped_absolute_claims("The generated trigger does not export plaintext.") == [
             "The generated trigger does not export plaintext."
           ]

    assert unscoped_absolute_claims("The generated trigger doesn't log plaintext.") == [
             "The generated trigger doesn't log plaintext."
           ]

    assert unscoped_absolute_claims("The generated trigger does not send plaintext externally.") ==
             [
               "The generated trigger does not send plaintext externally."
             ]

    assert unscoped_absolute_claims(
             "The generated trigger does not transmit plaintext externally."
           ) == [
             "The generated trigger does not transmit plaintext externally."
           ]

    assert unscoped_absolute_claims("Plaintext exposure is prevented by generated triggers.") == [
             "Plaintext exposure is prevented by generated triggers."
           ]

    assert unscoped_absolute_claims("The trigger has eliminated plaintext exposure.") == [
             "The trigger has eliminated plaintext exposure."
           ]

    assert unscoped_absolute_claims("Generated triggers ensure plaintext safety.") == [
             "Generated triggers ensure plaintext safety."
           ]

    assert unscoped_absolute_claims("These triggers guarantee plaintext safety.") == [
             "These triggers guarantee plaintext safety."
           ]

    assert unscoped_absolute_claims("The generated trigger won't leak plaintext.") == [
             "The generated trigger won't leak plaintext."
           ]

    assert unscoped_absolute_claims("The generated trigger won’t leak plaintext.") == [
             "The generated trigger won’t leak plaintext."
           ]

    assert unscoped_absolute_claims("The generated trigger exposes none of the masked data.") == [
             "The generated trigger exposes none of the masked data."
           ]

    assert unscoped_absolute_claims("The generated trigger exposes not a single plaintext value.") ==
             ["The generated trigger exposes not a single plaintext value."]

    assert unscoped_absolute_claims("The generated trigger returns not one plaintext value.") == [
             "The generated trigger returns not one plaintext value."
           ]

    assert unscoped_absolute_claims(
             "The generated per-table trigger prevents every plaintext exposure."
           ) == ["The generated per-table trigger prevents every plaintext exposure."]

    assert unscoped_absolute_claims(
             "The generated trigger prevents every exposure in tested exports and always prevents exposure in backups."
           ) == [
             "The generated trigger prevents every exposure in tested exports and always prevents exposure in backups."
           ]

    assert unscoped_absolute_claims(
             "The evidence does not establish every output is safe and always prevents exposure in backups."
           ) == [
             "The evidence does not establish every output is safe and always prevents exposure in backups."
           ]

    assert unscoped_absolute_claims(
             "The generated trigger always prevents plaintext exposure in tested exports; it always prevents plaintext exposure in backups."
           ) == [
             "The generated trigger always prevents plaintext exposure in tested exports; it always prevents plaintext exposure in backups."
           ]

    assert unscoped_absolute_claims(
             "The generated trigger never stores plaintext in tested exports, backups, or WAL."
           ) == [
             "The generated trigger never stores plaintext in tested exports, backups, or WAL."
           ]

    for bounded <- @bounded_claims do
      assert unscoped_absolute_claims(bounded) == []
    end

    assert unscoped_absolute_claims(
             "The generated per-table trigger never stores the masked value in tested exports as well as every backup."
           ) == [
             "The generated per-table trigger never stores the masked value in tested exports as well as every backup."
           ]

    assert repository_test_path(
             "https://evil.example/other/repo/blob/main/test/threadline/capture/redaction_leak_property_test.exs"
           ) == nil

    assert repository_test_path(
             "https://github.com/other/threadline/blob/main/test/threadline/capture/redaction_leak_property_test.exs"
           ) == nil
  end

  defp missing_evidence(guide) do
    Enum.reject(@required_evidence, &String.contains?(guide, &1))
  end

  defp evidence_row(guide, claim) do
    guide
    |> String.split("\n")
    |> Enum.find(&String.contains?(&1, claim))
  end

  defp repository_test_paths(row) do
    Regex.scan(~r/\[[^\]]+\]\(([^)]+)\)/, row, capture: :all_but_first)
    |> List.flatten()
    |> Enum.map(&repository_test_path/1)
    |> Enum.reject(&is_nil/1)
  end

  defp repository_test_path(target) do
    with %URI{scheme: "https", host: "github.com", path: path} when is_binary(path) <-
           URI.parse(target),
         true <- String.starts_with?(path, "/szTheory/threadline/blob/main/") do
      String.replace_prefix(path, "/szTheory/threadline/blob/main/", "")
    else
      _other -> nil
    end
  end

  defp unscoped_absolute_claims(guide) do
    guide
    |> String.split(~r/(?<=[.!?])\s+/, trim: true)
    |> Enum.map(&normalize_sentence/1)
    |> Enum.filter(fn sentence ->
      Regex.match?(@absolute_claim, sentence) and sentence not in @bounded_claims
    end)
  end

  defp normalize_sentence(sentence) do
    sentence
    |> String.trim()
    |> String.replace(~r/\s+/, " ")
  end
end
