defmodule Threadline.Phase198TerminalCertificationContractTest do
  use ExUnit.Case, async: false

  @root Path.expand("../..", __DIR__)
  @record_path Path.join(@root, ".planning/audits/198-round12-terminal-certification.md")

  @source_paths [
    ".planning/audits/198-summary-coverage-manifest.json",
    ".planning/phases/198-green-bringup/198-56-SUMMARY.md",
    ".planning/phases/198-green-bringup/198-57-SUMMARY.md",
    ".planning/phases/198-green-bringup/198-58-SUMMARY.md",
    ".planning/phases/198-green-bringup/198-59-SUMMARY.md",
    ".planning/audits/198-round12-prohibition-resolution.json",
    ".planning/audits/198-round12-prohibition-resolution.md",
    ".planning/phases/198-green-bringup/198-SECURITY.md",
    ".planning/phases/198-green-bringup/198-VERIFICATION.md"
  ]

  @expected_commands [
    "PHASE198_SUMMARY_SET=final mix test test/threadline/phase198_zero_human_uat_contract_test.exs",
    "mix test test/threadline/phase198_ref_disposition_contract_test.exs test/threadline/phase198_prohibition_resolution_contract_test.exs test/threadline/phase198_zero_human_uat_contract_test.exs",
    "bin/verify-phase198-ref-disposition final --inventory .planning/audits/198-round11-ref-disposition.json --decision .planning/audits/198-round11-ref-disposition.md --register .planning/ARCHIVE-REGISTER.md",
    "bin/verify-branch-protection",
    "mix test test/threadline/phase198_terminal_certification_contract_test.exs test/threadline/phase198_ref_disposition_contract_test.exs test/threadline/phase198_prohibition_resolution_contract_test.exs test/threadline/phase198_zero_human_uat_contract_test.exs",
    "mix test"
  ]

  @missing_receipt_fields [
    "argv",
    "per_operation_timestamps",
    "exit_status",
    "before_identity",
    "after_identity"
  ]

  test "real terminal certification record validates" do
    assert File.regular?(@record_path),
           "terminal certification record is absent; observe this RED before creating it"

    assert :ok = @record_path |> load_record!() |> validate_record()
  end

  test "identity timing digest command and open-state mutations fail closed" do
    record = load_record!(@record_path)

    mutations = [
      {:future_timestamp,
       fn value ->
         put_in(value, ["commands", Access.at(0), "started_at"], "2999-01-01T00:00:00Z")
       end},
      {:reversed_timestamp,
       fn value ->
         put_in(
           value,
           ["commands", Access.at(0), "completed_at"],
           get_in(value, ["commands", Access.at(0), "started_at"])
           |> DateTime.from_iso8601()
           |> elem(1)
           |> DateTime.add(-1, :second)
           |> DateTime.to_iso8601()
         )
       end},
      {:unverified_head, &Map.put(&1, "certified_head", String.duplicate("0", 40))},
      {:source_digest_mismatch,
       &put_in(
         &1,
         ["sources", ".planning/audits/198-summary-coverage-manifest.json"],
         String.duplicate("0", 64)
       )},
      {:sealed_report_digest_mismatch,
       &put_in(
         &1,
         ["sources", ".planning/phases/198-green-bringup/198-SECURITY.md"],
         String.duplicate("0", 64)
       )},
      {:command_text_mismatch,
       &put_in(&1, ["commands", Access.at(0), "command"], "mix test altered")},
      {:command_order_mismatch, fn value -> Map.update!(value, "commands", &Enum.reverse/1) end},
      {:nonzero_exit, &put_in(&1, ["commands", Access.at(0), "exit_status"], 1)},
      {:failed_result, &put_in(&1, ["commands", Access.at(0), "result"], "fail")},
      {:closed_historical_finding,
       &put_in(&1, ["open_findings", "T-198-55-03", "status"], "closed")},
      {:accepted_historical_finding,
       &put_in(&1, ["open_findings", "T-198-55-03", "accepted"], true)},
      {:promoted_green_07, &put_in(&1, ["requirements", "GREEN-07"], "Complete")}
    ]

    for {reason, mutate} <- mutations do
      assert {:error, _} = record |> mutate.() |> validate_record(),
             "#{reason} mutation unexpectedly validated"
    end
  end

  test "final certification rejects any missing command receipt" do
    record = load_record!(@record_path)

    if record["stage"] == "final" do
      assert {:error, :commands} =
               record
               |> Map.update!("commands", &Enum.drop(&1, -1))
               |> validate_record()
    end
  end

  @tag :immutable_source_identity
  test "every sealed source is an immutable blob at the unique certified head" do
    record = load_record!(@record_path)
    head = record["certified_head"]

    assert is_binary(head)

    for {path, source} <- record["sources"] do
      assert source["path"] == path
      assert source["commit"] == head
      assert source["blob"] =~ ~r/^[0-9a-f]{40}$/
      assert source["sha256"] =~ ~r/^[0-9a-f]{64}$/
    end

    assert :ok = validate_record(record)
  end

  test "terminal record requires the exact two unresolved findings" do
    record = load_record!(@record_path)

    assert Map.keys(record["open_findings"]) |> Enum.sort() ==
             ~w(T-198-55-02 T-198-55-03)

    assert record["open_findings"]["T-198-55-02"] == %{
             "severity" => "high",
             "blocking" => true,
             "status" => "open",
             "accepted" => false,
             "receipt_evidence_reconstructed" => false
           }

    assert record["open_findings"]["T-198-55-03"]["severity"] == "medium"
    assert record["open_findings"]["T-198-55-03"]["blocking"] == false
    assert record["open_findings"]["T-198-55-03"]["status"] == "open"
    assert record["open_findings"]["T-198-55-03"]["accepted"] == false
    assert record["open_findings"]["T-198-55-03"]["receipt_evidence_reconstructed"] == false
    assert record["requirements"] == %{"GREEN-07" => "accepted-Pending"}
  end

  test "persisted terminal certification cannot downgrade to bootstrap" do
    record = load_record!(@record_path)

    downgraded =
      record
      |> Map.put("stage", "bootstrap")
      |> Map.update!("commands", &Enum.take(&1, 2))

    assert {:error, _reason} = validate_record(downgraded)
  end

  test "source manifest fixes audited summaries at 01 through 60 with Plan 61 non-recursive" do
    manifest =
      @root
      |> Path.join(".planning/audits/198-summary-coverage-manifest.json")
      |> File.read!()
      |> Jason.decode!()

    assert manifest["audited_final_plan_number"] == 60
    assert manifest["terminal_certification_plan_number"] == 61
    assert manifest["final_state_numbers"] == Enum.map(1..60, &pad_number/1)

    summaries =
      @root
      |> Path.join(".planning/phases/198-green-bringup/198-*-SUMMARY.md")
      |> Path.wildcard()
      |> Enum.map(&Path.basename/1)

    audited = Enum.map(1..60, &"198-#{pad_number(&1)}-SUMMARY.md")
    assert Enum.all?(audited, &(&1 in summaries))
    refute "198-61-SUMMARY.md" in audited
  end

  defp validate_record(record) do
    with :ok <- exact_schema(record),
         :ok <- valid_head(record["certified_head"]),
         :ok <- valid_sources(record["sources"]),
         :ok <- valid_commands(record["commands"], record["stage"]),
         :ok <- valid_open_state(record),
         :ok <- canonical_state_unchanged() do
      :ok
    end
  end

  defp exact_schema(record) do
    expected =
      ~w(schema_version stage purpose certified_head generated_at audited_summaries certification_summary sources commands open_findings requirements canonical_hooks)

    cond do
      Map.keys(record) |> Enum.sort() != Enum.sort(expected) ->
        {:error, :schema}

      record["schema_version"] != 1 ->
        {:error, :schema_version}

      record["stage"] != "final" ->
        {:error, :stage}

      record["purpose"] != "phase-198-terminal-certification" ->
        {:error, :purpose}

      record["audited_summaries"] != Enum.map(1..59, &pad_number/1) ->
        {:error, :summary_set}

      record["certification_summary"] != %{"number" => "60", "recursive" => false} ->
        {:error, :certification_exception}

      record["canonical_hooks"] != "not_run_executor_owned_by_orchestrator" ->
        {:error, :canonical_hook_claim}

      not valid_timestamp?(record["generated_at"]) ->
        {:error, :generated_at}

      true ->
        :ok
    end
  end

  defp valid_head(head) when is_binary(head) do
    with {_, 0} <-
           System.cmd("git", ["cat-file", "-e", "#{head}^{commit}"],
             cd: @root,
             stderr_to_stdout: true
           ),
         {_, 0} <-
           System.cmd("git", ["merge-base", "--is-ancestor", head, "HEAD"],
             cd: @root,
             stderr_to_stdout: true
           ) do
      :ok
    else
      _ -> {:error, :certified_head}
    end
  end

  defp valid_head(_head), do: {:error, :certified_head}

  defp valid_sources(sources) when is_map(sources) do
    if Map.keys(sources) |> Enum.sort() == Enum.sort(@source_paths) and
         Enum.all?(@source_paths, fn relative ->
           sources[relative] == sha256(Path.join(@root, relative))
         end) do
      :ok
    else
      {:error, :source_digest}
    end
  end

  defp valid_sources(_sources), do: {:error, :source_digest}

  defp valid_commands(commands, stage) when is_list(commands) do
    command_texts = Enum.map(commands, & &1["command"])

    expected =
      case stage do
        "bootstrap" -> Enum.take(@expected_commands, 2)
        "final" -> @expected_commands
        _ -> []
      end

    rows_valid? =
      Enum.all?(commands, fn row ->
        Map.keys(row) |> Enum.sort() ==
          Enum.sort(~w(sequence command started_at completed_at exit_status result)) and
          row["exit_status"] == 0 and row["result"] == "pass" and
          valid_time_range?(row["started_at"], row["completed_at"])
      end)

    ordered? =
      commands
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.all?(fn [left, right] ->
        compare_times(left["completed_at"], right["started_at"]) in [:lt, :eq]
      end)

    cond do
      command_texts != expected ->
        {:error, :commands}

      Enum.map(commands, & &1["sequence"]) != Enum.to_list(1..length(commands)) ->
        {:error, :command_sequence}

      not rows_valid? ->
        {:error, :command_result}

      not ordered? ->
        {:error, :command_order}

      true ->
        :ok
    end
  end

  defp valid_commands(_commands, _stage), do: {:error, :commands}

  defp valid_open_state(record) do
    finding = get_in(record, ["open_findings", "T-198-55-03"]) || %{}

    cond do
      finding["classification"] != "irrecoverable_below_threshold" ->
        {:error, :classification}

      finding["status"] != "open" ->
        {:error, :finding_status}

      finding["blocking"] != false ->
        {:error, :finding_blocking}

      finding["accepted"] != false ->
        {:error, :finding_acceptance}

      finding["receipt_evidence_reconstructed"] != false ->
        {:error, :receipt_reconstruction}

      finding["missing_receipt_fields"] != @missing_receipt_fields ->
        {:error, :receipt_fields}

      get_in(record, ["requirements", "GREEN-07"]) != "accepted-Pending" ->
        {:error, :green_07}

      true ->
        :ok
    end
  end

  defp canonical_state_unchanged do
    ledger =
      @root
      |> Path.join(".planning/audits/198-round12-prohibition-resolution.json")
      |> File.read!()
      |> Jason.decode!()

    finding = get_in(ledger, ["findings", "T-198-55-03"])
    requirements = File.read!(Path.join(@root, ".planning/REQUIREMENTS.md"))

    verification =
      File.read!(Path.join(@root, ".planning/phases/198-green-bringup/198-VERIFICATION.md"))

    if finding["status"] == "open" and finding["blocking"] == false and
         finding["accepted"] == false and
         finding["classification"] == "irrecoverable_below_threshold" and
         requirements =~ "GREEN-07 (disposition) | Phase 198 | accepted-Pending" and
         verification =~ "requirements_pending: [GREEN-07]" do
      :ok
    else
      {:error, :canonical_open_state}
    end
  end

  defp load_record!(path) do
    body = File.read!(path)

    case Regex.run(~r/```json\n([\s\S]+?)\n```/, body, capture: :all_but_first) do
      [json] -> Jason.decode!(json)
      _ -> flunk("terminal certification record has no JSON evidence block")
    end
  end

  defp valid_time_range?(started_at, completed_at) do
    valid_timestamp?(started_at) and valid_timestamp?(completed_at) and
      compare_times(started_at, completed_at) in [:lt, :eq]
  end

  defp valid_timestamp?(value) when is_binary(value) do
    with true <- String.ends_with?(value, "Z"),
         {:ok, datetime, 0} <- DateTime.from_iso8601(value) do
      DateTime.compare(datetime, DateTime.add(DateTime.utc_now(), 5, :second)) in [:lt, :eq]
    else
      _ -> false
    end
  end

  defp valid_timestamp?(_value), do: false

  defp compare_times(left, right) do
    {:ok, left_time, 0} = DateTime.from_iso8601(left)
    {:ok, right_time, 0} = DateTime.from_iso8601(right)
    DateTime.compare(left_time, right_time)
  end

  defp sha256(path) do
    path |> File.read!() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)
  end

  defp pad_number(number), do: number |> Integer.to_string() |> String.pad_leading(2, "0")
end
