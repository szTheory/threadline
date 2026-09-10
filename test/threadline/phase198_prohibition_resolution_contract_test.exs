defmodule Threadline.Phase198ProhibitionResolutionContractTest do
  use ExUnit.Case, async: true

  @root Path.expand("../..", __DIR__)
  @ledger_path Path.join(@root, ".planning/audits/198-round12-prohibition-resolution.json")
  @disposition_path Path.join(@root, ".planning/audits/198-round14-security-disposition.json")
  @plan63_summary_path Path.join(
                         @root,
                         ".planning/phases/198-green-bringup/198-63-SUMMARY.md"
                       )
  @risk_acceptance_verbatim "accept-risk by YOUR_NAME: I accept the residual uncertainty that Plan 198-55’s exact historical argv and non-force method evidence was not retained."
  @risk_acceptance_rationale "I accept the residual uncertainty that Plan 198-55’s exact historical argv and non-force method evidence was not retained."
  @accepted_scope "The residual uncertainty for T-198-55-02 caused solely by the unavailable exact historical argv and non-force method evidence for completed Plan 198-55 mutations."
  @source_paths %{
    "round11_json" => Path.join(@root, ".planning/audits/198-round11-ref-disposition.json"),
    "round11_markdown" => Path.join(@root, ".planning/audits/198-round11-ref-disposition.md")
  }
  @cannot_attest_verbatim "cannot-attest by szTheory"

  @prohibitions [
    {"P-198-53-01", "198-53-PLAN.md",
     "A stale-ref recommendation, historical maintainer response, or complete ancestry proof must never be converted into branch, pull-request, tag, main, ruleset, or protection mutation authority."},
    {"P-198-53-02", "198-53-PLAN.md",
     "No preservation subject may be collapsed merely because its local and remote refs share a branch name."},
    {"P-198-55-01", "198-55-PLAN.md",
     "Do not use wildcard, mirror, all-tags, force, rebase, squash, branch-switch, merge, ruleset, or protection mutations."},
    {"P-198-55-02", "198-55-PLAN.md",
     "Do not retire any handle until every distinct object reachable only through that handle has verified local and remote annotated-tag recovery plus a tracked register row."},
    {"P-198-55-03", "198-55-PLAN.md",
     "Do not relabel GREEN-07 or roadmap criterion 3 as met from repository-hygiene work."}
  ]

  test "round-14 disposition persists the exact narrow T-198-55-02 acceptance" do
    disposition = load_disposition!()

    assert Map.keys(disposition) |> Enum.sort() ==
             Enum.sort([
               "schema_version",
               "phase",
               "threat_id",
               "decision",
               "verbatim",
               "decided_by",
               "decided_at",
               "historical_evidence_reconstructed",
               "rationale",
               "accepted_scope",
               "excluded_threats",
               "green_07"
             ])

    assert disposition["schema_version"] == "threadline.phase198.security-disposition.v1"
    assert disposition["phase"] == "198"
    assert disposition["threat_id"] == "T-198-55-02"
    assert disposition["decision"] == "accept-risk"
    assert disposition["verbatim"] == @risk_acceptance_verbatim
    assert disposition["decided_by"] == "YOUR_NAME"
    assert rfc3339_seconds_utc?(disposition["decided_at"])
    assert disposition["historical_evidence_reconstructed"] == false
    assert disposition["rationale"] == @risk_acceptance_rationale
    assert disposition["accepted_scope"] == @accepted_scope
    assert disposition["excluded_threats"] == ["T-198-55-03", "T-198-62-SC"]
    assert disposition["green_07"] == %{"status" => "accepted-Pending", "changed" => false}

    refute contains_forbidden_disposition_key?(disposition)
  end

  test "round-14 disposition schema fails closed for missing, extra, and mistyped fields" do
    disposition = load_disposition!()
    assert :ok = validate_disposition(disposition)

    for key <- Map.keys(disposition) do
      assert {:error, _reason} = disposition |> Map.delete(key) |> validate_disposition()
    end

    assert {:error, _reason} =
             disposition |> Map.put("unknown", true) |> validate_disposition()

    wrong_types = %{
      "schema_version" => 1,
      "phase" => 198,
      "threat_id" => ["T-198-55-02"],
      "decision" => true,
      "verbatim" => nil,
      "decided_by" => %{},
      "decided_at" => 0,
      "historical_evidence_reconstructed" => "false",
      "rationale" => [],
      "accepted_scope" => %{},
      "excluded_threats" => "T-198-55-03,T-198-62-SC",
      "green_07" => []
    }

    for {key, value} <- wrong_types do
      assert {:error, _reason} = disposition |> Map.put(key, value) |> validate_disposition()
    end

    for key <- Map.keys(disposition["green_07"]) do
      malformed = update_in(disposition["green_07"], &Map.delete(&1, key))
      assert {:error, _reason} = validate_disposition(malformed)
    end

    for green_07 <- [
          %{"status" => "accepted-Pending", "changed" => false, "unknown" => true},
          %{"status" => :pending, "changed" => false},
          %{"status" => "Complete", "changed" => false},
          %{"status" => "accepted-Pending", "changed" => "false"},
          %{"status" => "accepted-Pending", "changed" => true}
        ] do
      assert {:error, _reason} =
               disposition |> Map.put("green_07", green_07) |> validate_disposition()
    end
  end

  test "round-14 disposition rejects timestamp and exclusion mutations" do
    disposition = load_disposition!()

    for invalid <- [
          0,
          "not-a-time",
          "2026-09-10T20:59:16+00:00",
          "2026-09-10T20:59:16.1Z",
          "2026-02-30T20:59:16Z",
          "2026-09-10T24:00:00Z"
        ] do
      assert {:error, _reason} =
               disposition |> Map.put("decided_at", invalid) |> validate_disposition()
    end

    assert :ok =
             disposition
             |> Map.put("decided_at", "2026-09-10T20:59:16Z")
             |> validate_disposition()

    for invalid <- [
          "T-198-55-03,T-198-62-SC",
          [],
          ["T-198-55-03"],
          ["T-198-55-03", "T-198-62-SC", "T-198-64-01"],
          ["T-198-62-SC", "T-198-55-03"],
          ["T-198-55-03", "T-198-55-03"],
          ["T-198-55-03", "T-198-55-02"]
        ] do
      assert {:error, _reason} =
               disposition |> Map.put("excluded_threats", invalid) |> validate_disposition()
    end
  end

  test "round-14 disposition rejects attribution, scope, evidence, and verdict fabrication" do
    disposition = load_disposition!()

    altered_values = [
      {"schema_version", "threadline.phase198.security-disposition.v2"},
      {"phase", "all"},
      {"threat_id", "T-198-55-03"},
      {"decision", "mitigated"},
      {"verbatim", String.replace(@risk_acceptance_verbatim, "198-55’s", "198-55's")},
      {"verbatim", String.replace(@risk_acceptance_verbatim, "accept-risk", "ACCEPT-RISK")},
      {"verbatim", " " <> @risk_acceptance_verbatim},
      {"decided_by", "maintainer"},
      {"historical_evidence_reconstructed", true},
      {"rationale", ""},
      {"rationale", @risk_acceptance_rationale <> " All Phase-198 risk is accepted."},
      {"accepted_scope", "All Phase-198 historical uncertainty."},
      {"accepted_scope", @accepted_scope <> " T-198-55-03 is also accepted."}
    ]

    for {key, value} <- altered_values do
      assert {:error, _reason} = disposition |> Map.put(key, value) |> validate_disposition()
    end

    for key <- ~w(evidence_source argv command refspec force mitigation attestation before after closed evidenced status verdict) do
      assert {:error, _reason} = disposition |> Map.put(key, true) |> validate_disposition()
    end
  end

  test "round-14 acceptance supersedes only the preserved Plan-63 decline" do
    summary = File.read!(@plan63_summary_path)
    disposition = load_disposition!()

    assert summary =~ "status: halted"
    assert summary =~ "coverage: []"
    assert summary =~ "> do-not-accept by SIGNER"
    assert disposition["verbatim"] == @risk_acceptance_verbatim
    assert disposition["threat_id"] == "T-198-55-02"
    assert disposition["excluded_threats"] == ["T-198-55-03", "T-198-62-SC"]
    assert disposition["green_07"] == %{"status" => "accepted-Pending", "changed" => false}
  end

  test "ledger copies exactly five source prohibitions with stable identities" do
    ledger = load_ledger!()

    actual =
      Enum.map(ledger["prohibitions"], fn row ->
        {row["id"], row["source_plan"], row["statement"]}
      end)

    assert actual == @prohibitions

    for {_id, plan, statement} <- @prohibitions do
      source = File.read!(Path.join(@root, ".planning/phases/198-green-bringup/#{plan}"))
      assert source =~ ~s(statement: "#{statement}")
    end
  end

  test "four mechanical prohibitions name passing executable ref-disposition checks" do
    ledger = load_ledger!()
    rows = Map.new(ledger["prohibitions"], &{&1["id"], &1})

    expected_tests = %{
      "P-198-53-01" =>
        "round 11 authority rejects silence, preserve, abort, stale digests, missing subjects, and outsiders",
      "P-198-53-02" =>
        "round 11 keeps divergent local and remote tips as separate preservation subjects",
      "P-198-55-02" =>
        "round 11 refuses delete-before-preserve ordering and incomplete divergent preservation",
      "P-198-55-03" =>
        "round 11 final derives both namespaces and rejects an unremembered live ref or GREEN-07 promotion"
    }

    for {id, test_name} <- expected_tests do
      row = Map.fetch!(rows, id)
      assert row["tier"] == "test"
      assert row["status"] == "pass"
      assert Enum.any?(row["evidence"], &(&1["test"] == test_name and &1["result"] == "pass"))

      assert Enum.any?(row["evidence"], fn evidence ->
               evidence["command"] ==
                 "mix test test/threadline/phase198_ref_disposition_contract_test.exs" and
                 evidence["result"] == "pass"
             end)
    end
  end

  test "historical command-method prohibition records exact cannot-attest response and remains open" do
    ledger = load_ledger!()
    row = Enum.find(ledger["prohibitions"], &(&1["id"] == "P-198-55-01"))

    assert row["tier"] == "judgment"
    assert row["status"] == "pending"

    assert row["resolution"] == %{
             "outcome" => "cannot-attest",
             "verbatim" => @cannot_attest_verbatim,
             "recorded_at" => "2026-09-10T02:37:41Z",
             "signer" => "szTheory"
           }

    assert row["evidence"] == []
    assert row["risk_accepted"] == false
    assert row["historical_limitation"] =~ "cannot establish which command operands were typed"
    refute forbidden_receipt_claim?(row)
    assert :ok = validate_resolution(ledger)
  end

  test "round-11 sources are digest-pinned and the receipt gap stays open below threshold" do
    ledger = load_ledger!()

    for {key, path} <- @source_paths do
      source = Map.fetch!(ledger["immutable_sources"], key)
      assert source["path"] == Path.relative_to(path, @root)
      assert source["sha256"] == sha256(path)
    end

    finding = ledger["findings"]["T-198-55-03"]
    assert finding["severity"] == "medium"
    assert finding["blocking_threshold"] == "high"
    assert finding["classification"] == "irrecoverable_below_threshold"
    assert finding["status"] == "open"
    assert finding["blocking"] == false
    assert finding["accepted"] == false

    assert finding["missing_receipt_fields"] == [
             "argv",
             "per_operation_timestamps",
             "exit_status",
             "before_identity",
             "after_identity"
           ]
  end

  test "every row has a tier, evidence status, and relevant round-11 threat mapping" do
    ledger = load_ledger!()

    for row <- ledger["prohibitions"] do
      assert row["tier"] in ["test", "judgment"]
      assert row["status"] in ["pass", "pending"]
      assert is_list(row["threat_ids"]) and row["threat_ids"] != []
      assert Enum.all?(row["threat_ids"], &String.starts_with?(&1, "T-198-"))
    end
  end

  test "retrospective command fields fail before a signed Plan-59 attestation" do
    ledger = load_ledger!()

    for {field, value} <- [
          {"argv", ["git", "push", "origin", "unknown"]},
          {"refspec", "unknown:unknown"},
          {"force", false},
          {"timestamp", "2026-09-09T22:40:00Z"},
          {"before", %{"ref" => "unknown"}},
          {"after", %{"ref" => nil}}
        ] do
      malformed = update_row(ledger, "P-198-55-01", &Map.put(&1, field, value))
      assert {:error, :fabricated_historical_receipt} = validate_resolution(malformed)
    end
  end

  test "source, digest, tier, result, and threat-map mutations fail closed" do
    ledger = load_ledger!()

    mutations = [
      &update_row(&1, "P-198-53-01", fn row ->
        Map.put(row, "statement", row["statement"] <> " altered")
      end),
      &put_in(&1, ["immutable_sources", "round11_json", "sha256"], String.duplicate("0", 64)),
      &update_row(&1, "P-198-53-02", fn row -> Map.put(row, "tier", "judgment") end),
      &update_row(&1, "P-198-55-02", fn row ->
        update_in(row["evidence"], fn [first | rest] ->
          [Map.put(first, "result", "unknown") | rest]
        end)
      end),
      &update_row(&1, "P-198-55-03", fn row -> Map.put(row, "threat_ids", []) end)
    ]

    for mutate <- mutations do
      assert {:error, _reason} = ledger |> mutate.() |> validate_resolution()
    end
  end

  test "judgment transitions require exact signed attestation semantics" do
    ledger = load_ledger!()

    incomplete =
      update_row(ledger, "P-198-55-01", fn row ->
        row
        |> Map.put("status", "resolved")
        |> Map.put("resolution", %{"outcome" => "attested", "verbatim" => "yes"})
      end)

    assert {:error, :invalid_attestation} = validate_resolution(incomplete)

    cannot_attest_closed =
      update_row(ledger, "P-198-55-01", fn row ->
        row
        |> Map.put("status", "resolved")
        |> Map.put("resolution", valid_attestation("cannot-attest"))
      end)

    assert {:error, :cannot_attest_must_remain_open} = validate_resolution(cannot_attest_closed)

    attested =
      update_row(ledger, "P-198-55-01", fn row ->
        row
        |> Map.put("status", "resolved")
        |> Map.put("resolution", valid_attestation("attested"))
      end)

    assert :ok = validate_resolution(attested)
    assert get_in(attested, ["findings", "T-198-55-03", "status"]) == "open"
    assert get_in(attested, ["findings", "T-198-55-03", "accepted"]) == false
  end

  defp load_ledger! do
    assert File.exists?(@ledger_path),
           "round-12 prohibition ledger is absent; implement it only after observing this RED"

    @ledger_path |> File.read!() |> Jason.decode!()
  end

  defp load_disposition! do
    assert File.exists?(@disposition_path),
           "round-14 security disposition is absent; create it only after observing this RED"

    @disposition_path |> File.read!() |> Jason.decode!()
  end

  defp rfc3339_seconds_utc?(value) when is_binary(value) do
    Regex.match?(~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/, value) and
      match?({:ok, _datetime, 0}, DateTime.from_iso8601(value))
  end

  defp rfc3339_seconds_utc?(_value), do: false

  defp contains_forbidden_disposition_key?(value) when is_map(value) do
    forbidden =
      ~w(evidence_source argv command refspec force mitigation attestation before after closed evidenced)

    Enum.any?(value, fn {key, nested} ->
      key in forbidden or contains_forbidden_disposition_key?(nested)
    end)
  end

  defp contains_forbidden_disposition_key?(value) when is_list(value),
    do: Enum.any?(value, &contains_forbidden_disposition_key?/1)

  defp contains_forbidden_disposition_key?(_value), do: false

  defp validate_resolution(ledger) do
    rows = ledger["prohibitions"] || []
    row = Enum.find(rows, &(&1["id"] == "P-198-55-01")) || %{}

    cond do
      forbidden_receipt_claim?(row) ->
        {:error, :fabricated_historical_receipt}

      source_rows(rows) != @prohibitions ->
        {:error, :source_mutation}

      not immutable_sources_valid?(ledger) ->
        {:error, :source_digest_mutation}

      not tiers_valid?(rows) ->
        {:error, :tier_mutation}

      not evidence_valid?(rows) ->
        {:error, :evidence_mutation}

      not threat_maps_valid?(rows) ->
        {:error, :threat_map_mutation}

      not finding_valid?(ledger) ->
        {:error, :finding_mutation}

      true ->
        validate_judgment(row)
    end
  end

  defp source_rows(rows) do
    Enum.map(rows, &{&1["id"], &1["source_plan"], &1["statement"]})
  end

  defp immutable_sources_valid?(ledger) do
    Enum.all?(@source_paths, fn {key, path} ->
      source = get_in(ledger, ["immutable_sources", key]) || %{}
      source["path"] == Path.relative_to(path, @root) and source["sha256"] == sha256(path)
    end)
  end

  defp tiers_valid?(rows) do
    Enum.all?(rows, fn row ->
      case row["id"] do
        "P-198-55-01" -> row["tier"] == "judgment"
        _ -> row["tier"] == "test" and row["status"] == "pass"
      end
    end)
  end

  defp evidence_valid?(rows) do
    Enum.all?(rows, fn row ->
      case row["id"] do
        "P-198-55-01" ->
          row["evidence"] == []

        _ ->
          row["evidence"] != [] and
            Enum.all?(row["evidence"], fn evidence ->
              evidence["result"] == "pass" and
                evidence["command"] ==
                  "mix test test/threadline/phase198_ref_disposition_contract_test.exs" and
                is_binary(evidence["test"])
            end)
      end
    end)
  end

  defp threat_maps_valid?(rows) do
    expected = %{
      "P-198-53-01" => ["T-198-53-01", "T-198-53-06", "T-198-54-02", "T-198-54-04", "T-198-58-01"],
      "P-198-53-02" => ["T-198-53-02", "T-198-58-01"],
      "P-198-55-01" => ["T-198-55-02", "T-198-55-03", "T-198-58-02", "T-198-58-03"],
      "P-198-55-02" => ["T-198-55-02", "T-198-55-05", "T-198-58-01"],
      "P-198-55-03" => ["T-198-55-06", "T-198-58-01"]
    }

    Enum.all?(rows, &(&1["threat_ids"] == expected[&1["id"]]))
  end

  defp finding_valid?(ledger) do
    finding = get_in(ledger, ["findings", "T-198-55-03"]) || %{}

    finding["severity"] == "medium" and
      finding["blocking_threshold"] == "high" and
      finding["classification"] == "irrecoverable_below_threshold" and
      finding["status"] == "open" and
      finding["blocking"] == false and
      finding["accepted"] == false
  end

  defp validate_judgment(%{"status" => "pending", "resolution" => nil}), do: :ok

  defp validate_judgment(%{"status" => "pending", "resolution" => resolution}) do
    if exact_attestation?(resolution, "cannot-attest"),
      do: :ok,
      else: {:error, :invalid_attestation}
  end

  defp validate_judgment(%{"status" => "resolved", "resolution" => resolution}) do
    cond do
      exact_attestation?(resolution, "cannot-attest") ->
        {:error, :cannot_attest_must_remain_open}

      exact_attestation?(resolution, "attested") ->
        :ok

      true ->
        {:error, :invalid_attestation}
    end
  end

  defp validate_judgment(_row), do: {:error, :invalid_attestation}

  defp exact_attestation?(resolution, expected_outcome) when is_map(resolution) do
    signer = resolution["signer"]

    expected_verbatim =
      case expected_outcome do
        "cannot-attest" ->
          "cannot-attest by #{signer}"

        "attested" ->
          "attest by #{signer}: I confirm every successful Plan 55 mutation targeted one exact object/ref/PR without force and used none of the prohibited wildcard, mirror, all-tags, rebase, squash, branch-switch, merge, ruleset, or protection operations"
      end

    Map.keys(resolution) |> Enum.sort() ==
      Enum.sort(["outcome", "verbatim", "recorded_at", "signer"]) and
      resolution["outcome"] == expected_outcome and is_binary(signer) and
      String.trim(signer) == signer and signer != "" and
      not String.contains?(signer, [":", "\n", "\r"]) and
      resolution["verbatim"] == expected_verbatim and rfc3339_utc?(resolution["recorded_at"])
  end

  defp exact_attestation?(_resolution, _expected_outcome), do: false

  defp update_row(ledger, id, fun) do
    update_in(ledger["prohibitions"], fn rows ->
      Enum.map(rows, fn row -> if row["id"] == id, do: fun.(row), else: row end)
    end)
  end

  defp valid_attestation(outcome) do
    signer = "maintainer"

    verbatim =
      case outcome do
        "cannot-attest" ->
          "cannot-attest by #{signer}"

        "attested" ->
          "attest by #{signer}: I confirm every successful Plan 55 mutation targeted one exact object/ref/PR without force and used none of the prohibited wildcard, mirror, all-tags, rebase, squash, branch-switch, merge, ruleset, or protection operations"
      end

    %{
      "outcome" => outcome,
      "verbatim" => verbatim,
      "recorded_at" => "2026-09-10T02:00:00Z",
      "signer" => signer
    }
  end

  defp rfc3339_utc?(recorded_at) when is_binary(recorded_at) do
    String.ends_with?(recorded_at, "Z") and
      match?({:ok, _datetime, 0}, DateTime.from_iso8601(recorded_at))
  end

  defp rfc3339_utc?(_recorded_at), do: false

  defp forbidden_receipt_claim?(value) when is_map(value) do
    forbidden = ~w(argv refspec force started_at completed_at timestamp exit_status before after)

    Enum.any?(value, fn {key, nested} ->
      key in forbidden or forbidden_receipt_claim?(nested)
    end)
  end

  defp forbidden_receipt_claim?(value) when is_list(value),
    do: Enum.any?(value, &forbidden_receipt_claim?/1)

  defp forbidden_receipt_claim?(_value), do: false

  defp sha256(path) do
    path |> File.read!() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)
  end
end
