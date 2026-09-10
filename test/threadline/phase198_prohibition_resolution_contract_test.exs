defmodule Threadline.Phase198ProhibitionResolutionContractTest do
  use ExUnit.Case, async: true

  @root Path.expand("../..", __DIR__)
  @ledger_path Path.join(@root, ".planning/audits/198-round12-prohibition-resolution.json")
  @source_paths %{
    "round11_json" => Path.join(@root, ".planning/audits/198-round11-ref-disposition.json"),
    "round11_markdown" => Path.join(@root, ".planning/audits/198-round11-ref-disposition.md")
  }

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

  test "historical command-method prohibition remains pending judgment without fabricated receipts" do
    ledger = load_ledger!()
    row = Enum.find(ledger["prohibitions"], &(&1["id"] == "P-198-55-01"))

    assert row["tier"] == "judgment"
    assert row["status"] == "pending"
    assert row["resolution"] == nil
    assert row["evidence"] == []
    assert row["risk_accepted"] == false
    assert row["historical_limitation"] =~ "cannot establish which command operands were typed"
    refute forbidden_receipt_claim?(row)
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

  defp load_ledger! do
    assert File.exists?(@ledger_path),
           "round-12 prohibition ledger is absent; implement it only after observing this RED"

    @ledger_path |> File.read!() |> Jason.decode!()
  end

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
