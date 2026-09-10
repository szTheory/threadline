defmodule Threadline.Phase198TerminalCertificationContractTest do
  use ExUnit.Case, async: false

  @root Path.expand("../..", __DIR__)
  @record_path Path.join(@root, ".planning/audits/198-round13-terminal-certification.md")

  @source_paths [
    ".planning/audits/198-summary-coverage-manifest.json",
    ".planning/phases/198-green-bringup/198-56-SUMMARY.md",
    ".planning/phases/198-green-bringup/198-57-SUMMARY.md",
    ".planning/phases/198-green-bringup/198-58-SUMMARY.md",
    ".planning/phases/198-green-bringup/198-59-SUMMARY.md",
    ".planning/phases/198-green-bringup/198-60-SUMMARY.md",
    ".planning/phases/198-green-bringup/198-61-SUMMARY.md",
    ".planning/audits/198-round11-ref-disposition.json",
    ".planning/audits/198-round11-ref-disposition.md",
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
      {:extra_command, fn value -> Map.update!(value, "commands", &(&1 ++ [List.last(&1)])) end},
      {:missing_blocking_finding,
       &update_in(&1["open_findings"], fn findings ->
         Map.delete(findings, "T-198-55-02")
       end)},
      {:extra_finding,
       &put_in(&1, ["open_findings", "T-198-extra"], %{
         "severity" => "low",
         "blocking" => false,
         "status" => "open",
         "accepted" => false,
         "receipt_evidence_reconstructed" => false
       })},
      {:closed_blocking_finding,
       &put_in(&1, ["open_findings", "T-198-55-02", "status"], "closed")},
      {:accepted_blocking_finding,
       &put_in(&1, ["open_findings", "T-198-55-02", "accepted"], true)},
      {:reclassified_blocking_severity,
       &put_in(&1, ["open_findings", "T-198-55-02", "severity"], "medium")},
      {:reclassified_blocking_flag,
       &put_in(&1, ["open_findings", "T-198-55-02", "blocking"], false)},
      {:closed_historical_finding,
       &put_in(&1, ["open_findings", "T-198-55-03", "status"], "closed")},
      {:accepted_historical_finding,
       &put_in(&1, ["open_findings", "T-198-55-03", "accepted"], true)},
      {:reclassified_historical_severity,
       &put_in(&1, ["open_findings", "T-198-55-03", "severity"], "low")},
      {:reclassified_historical_blocking,
       &put_in(&1, ["open_findings", "T-198-55-03", "blocking"], true)},
      {:reconstructed_historical_receipt,
       &put_in(
         &1,
         ["open_findings", "T-198-55-03", "receipt_evidence_reconstructed"],
         true
       )},
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
    with_git_source_fixture(fn fixture ->
      assert :ok =
               valid_sources(
                 %{fixture.path => fixture.source},
                 fixture.head,
                 fixture.root,
                 [fixture.path]
               )

      File.write!(Path.join(fixture.root, fixture.path), "post-hook replacement\n")

      assert :ok =
               valid_sources(
                 %{fixture.path => fixture.source},
                 fixture.head,
                 fixture.root,
                 [fixture.path]
               )

      mutations = [
        {:same_blob_older_ancestor, Map.put(fixture.source, "commit", fixture.older)},
        {:commit, Map.put(fixture.source, "commit", String.duplicate("0", 40))},
        {:blob, Map.put(fixture.source, "blob", String.duplicate("0", 40))},
        {:path, Map.put(fixture.source, "path", "other.txt")},
        {:digest, Map.put(fixture.source, "sha256", String.duplicate("0", 64))},
        {:missing_object, Map.put(fixture.source, "blob", String.duplicate("f", 40))},
        {:non_blob, Map.put(fixture.source, "blob", fixture.tree)},
        {:coordinated_substitution,
         fixture.source
         |> Map.put("commit", fixture.older)
         |> Map.put("blob", fixture.source["blob"])
         |> Map.put("sha256", fixture.source["sha256"])}
      ]

      for {reason, source} <- mutations do
        assert {:error, :source_identity} =
                 valid_sources(
                   %{fixture.path => source},
                   fixture.head,
                   fixture.root,
                   [fixture.path]
                 ),
               "#{reason} mutation unexpectedly validated"
      end
    end)
  end

  test "terminal record requires the exact two unresolved findings" do
    record = load_record!(@record_path)

    assert Map.keys(record["open_findings"]) |> Enum.sort() ==
             ~w(T-198-55-02 T-198-55-03)

    refute Map.has_key?(record["open_findings"], "T-198-57-04")

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

  test "source manifest fixes audited summaries at 01 through 61 with Plan 62 non-recursive" do
    manifest =
      @root
      |> Path.join(".planning/audits/198-summary-coverage-manifest.json")
      |> File.read!()
      |> Jason.decode!()

    assert manifest["audited_final_plan_number"] == 61
    assert manifest["terminal_certification_plan_number"] == 62
    assert manifest["final_state_numbers"] == Enum.map(1..61, &pad_number/1)

    summaries =
      @root
      |> Path.join(".planning/phases/198-green-bringup/198-*-SUMMARY.md")
      |> Path.wildcard()
      |> Enum.map(&Path.basename/1)

    audited = Enum.map(1..61, &"198-#{pad_number(&1)}-SUMMARY.md")
    assert Enum.all?(audited, &(&1 in summaries))
    refute "198-62-SUMMARY.md" in audited
  end

  defp validate_record(record) do
    with :ok <- exact_schema(record),
         :ok <- valid_head(record["certified_head"]),
         :ok <- valid_sources(record["sources"], record["certified_head"]),
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

      record["stage"] != "final" and
          not (record["stage"] == "bootstrap" and
                   System.get_env("PHASE198_TERMINAL_BOOTSTRAP") == "1") ->
        {:error, :stage}

      record["purpose"] != "phase-198-terminal-certification" ->
        {:error, :purpose}

      record["audited_summaries"] != Enum.map(1..61, &pad_number/1) ->
        {:error, :summary_set}

      record["certification_summary"] != %{"number" => "62", "recursive" => false} ->
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

  defp valid_sources(sources, head, root \\ @root, source_paths \\ @source_paths)

  defp valid_sources(sources, head, root, source_paths)
       when is_map(sources) and is_binary(head) do
    valid? =
      Map.keys(sources) |> Enum.sort() == Enum.sort(source_paths) and
        Enum.all?(source_paths, fn relative ->
          source = sources[relative]

          is_map(source) and
            Map.keys(source) |> Enum.sort() == Enum.sort(~w(path commit blob sha256)) and
            source["path"] == relative and source["commit"] == head and
            valid_blob_source?(root, head, source)
        end)

    if valid?, do: :ok, else: {:error, :source_identity}
  end

  defp valid_sources(_sources, _head, _root, _source_paths), do: {:error, :source_identity}

  defp valid_blob_source?(root, head, source) do
    path = source["path"]

    with true <- safe_relative_path?(path),
         {resolved, 0} <- git(root, ["rev-parse", "#{head}:#{path}"]),
         blob <- String.trim(resolved),
         true <- blob == source["blob"],
         {"blob\n", 0} <- git(root, ["cat-file", "-t", blob]),
         {bytes, 0} <- git(root, ["show", "#{head}:#{path}"]) do
      binary_digest(bytes) == source["sha256"]
    else
      _ -> false
    end
  end

  defp safe_relative_path?(path) when is_binary(path) do
    path != "" and Path.type(path) != :absolute and
      not Enum.member?(Path.split(path), "..")
  end

  defp safe_relative_path?(_path), do: false

  defp valid_commands(commands, stage) when is_list(commands) do
    command_texts = Enum.map(commands, & &1["command"])

    expected =
      case stage do
        "bootstrap" -> Enum.take(@expected_commands, 4)
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
    findings = record["open_findings"] || %{}
    blocking = findings["T-198-55-02"] || %{}
    historical = findings["T-198-55-03"] || %{}

    cond do
      Map.keys(findings) |> Enum.sort() != ~w(T-198-55-02 T-198-55-03) ->
        {:error, :finding_set}

      blocking != %{
        "severity" => "high",
        "blocking" => true,
        "status" => "open",
        "accepted" => false,
        "receipt_evidence_reconstructed" => false
      } ->
        {:error, :blocking_finding}

      Map.keys(historical) |> Enum.sort() !=
          Enum.sort(
            ~w(severity classification status blocking accepted receipt_evidence_reconstructed missing_receipt_fields)
          ) ->
        {:error, :historical_finding_schema}

      historical["severity"] != "medium" ->
        {:error, :severity}

      historical["classification"] != "irrecoverable_below_threshold" ->
        {:error, :classification}

      historical["status"] != "open" ->
        {:error, :finding_status}

      historical["blocking"] != false ->
        {:error, :finding_blocking}

      historical["accepted"] != false ->
        {:error, :finding_acceptance}

      historical["receipt_evidence_reconstructed"] != false ->
        {:error, :receipt_reconstruction}

      historical["missing_receipt_fields"] != @missing_receipt_fields ->
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

  defp with_git_source_fixture(fun) do
    root = Path.join(System.tmp_dir!(), "phase198-source-#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)

    try do
      assert {_, 0} = git(root, ["init", "--quiet"])
      File.write!(Path.join(root, "sealed.txt"), "sealed bytes\n")
      assert {_, 0} = git(root, ["add", "sealed.txt"])

      assert {_, 0} =
               git(root, [
                 "-c",
                 "user.name=Phase 198 Fixture",
                 "-c",
                 "user.email=phase198@example.invalid",
                 "commit",
                 "--quiet",
                 "-m",
                 "older"
               ])

      {older, 0} = git(root, ["rev-parse", "HEAD"])
      older = String.trim(older)
      File.write!(Path.join(root, "other.txt"), "advance head\n")
      assert {_, 0} = git(root, ["add", "other.txt"])

      assert {_, 0} =
               git(root, [
                 "-c",
                 "user.name=Phase 198 Fixture",
                 "-c",
                 "user.email=phase198@example.invalid",
                 "commit",
                 "--quiet",
                 "-m",
                 "certified head"
               ])

      {head, 0} = git(root, ["rev-parse", "HEAD"])
      {tree, 0} = git(root, ["rev-parse", "HEAD^{tree}"])
      head = String.trim(head)
      path = "sealed.txt"
      {blob, 0} = git(root, ["rev-parse", "#{head}:#{path}"])
      {bytes, 0} = git(root, ["show", "#{head}:#{path}"])

      fun.(%{
        root: root,
        path: path,
        older: older,
        head: head,
        tree: String.trim(tree),
        source: %{
          "path" => path,
          "commit" => head,
          "blob" => String.trim(blob),
          "sha256" => binary_digest(bytes)
        }
      })
    after
      File.rm_rf!(root)
    end
  end

  defp git(root, args), do: System.cmd("git", args, cd: root, stderr_to_stdout: true)

  defp binary_digest(bytes),
    do: bytes |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)

  defp pad_number(number), do: number |> Integer.to_string() |> String.pad_leading(2, "0")
end
