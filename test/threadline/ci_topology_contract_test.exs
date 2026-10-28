defmodule Threadline.CiTopologyContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  # Assembled so this file's own text never contains the retired alias name as a literal.
  @retired_alias "verify." <> "doc_contract"

  @resolved_plt_prefix "ubuntu-24.04-${{ steps.beam.outputs.otp-version }}-elixir-" <>
                         "${{ steps.beam.outputs.elixir-version }}-dialyzer-plt-"

  @live_slice_step_name "Live Dialyzer slice proof (fails closed)"

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  defp enumerated_test_files! do
    {output, status} =
      System.cmd(
        "find",
        ["test", "-type", "f", "-name", "*_test.exs", "!", "-path", "*/.*"],
        cd: @repo_root,
        stderr_to_stdout: true
      )

    if status == 0 do
      output |> String.split("\n", trim: true) |> Enum.sort()
    else
      raise "test inventory command failed with status #{status}: #{output}"
    end
  end

  defp partition_weight_inventory_errors(inventory, weights_content) do
    parsed_rows =
      weights_content
      |> String.split("\n")
      |> Enum.with_index(1)
      |> Enum.reject(fn {line, _line_number} ->
        trimmed = String.trim_leading(line)
        String.trim(line) == "" or String.starts_with?(trimmed, "#")
      end)
      |> Enum.map(fn {line, line_number} ->
        case Regex.run(~r/^\s*([1-9][0-9]*)[ \t]+(test\/[^ \t]+)\s*$/, line) do
          [_, _milliseconds, path] -> {:ok, path}
          _ -> {:error, "malformed weight row at line #{line_number}: #{inspect(line)}"}
        end
      end)

    row_errors = for {:error, error} <- parsed_rows, do: error
    paths = for {:ok, path} <- parsed_rows, do: path
    inventory_set = MapSet.new(inventory)
    weight_set = MapSet.new(paths)

    duplicate_errors =
      paths
      |> Enum.frequencies()
      |> Enum.filter(fn {_path, count} -> count > 1 end)
      |> Enum.map(fn {path, _count} -> "duplicate weight path #{path}" end)

    missing_errors =
      inventory
      |> Enum.uniq()
      |> Enum.reject(&MapSet.member?(weight_set, &1))
      |> Enum.sort()
      |> Enum.map(&"missing weight for #{&1}")

    stale_errors =
      paths
      |> Enum.uniq()
      |> Enum.reject(&MapSet.member?(inventory_set, &1))
      |> Enum.sort()
      |> Enum.map(&"weight path is not a discovered test file: #{&1}")

    sorted_errors =
      if paths == Enum.sort(paths), do: [], else: ["weight rows must be sorted by path"]

    empty_errors = if paths == [], do: ["weight inventory must not be empty"], else: []

    row_errors ++
      duplicate_errors ++ sorted_errors ++ missing_errors ++ stale_errors ++ empty_errors
  end

  test "committed partition weights cover the complete test inventory" do
    inventory = enumerated_test_files!()
    weights_content = read_rel!(["test", "partition_weights.txt"])

    errors = partition_weight_inventory_errors(inventory, weights_content)

    assert errors == [],
           "partition weight inventory is incomplete or invalid: #{Enum.join(errors, "; ")}"

    omitted_path = List.first(inventory)
    assert omitted_path, "the test inventory must not be empty"

    omitted_weights =
      weights_content
      |> String.split("\n")
      |> Enum.reject(fn line ->
        case Regex.run(~r/^\s*[0-9]+[ \t]+(test\/[^ \t]+)\s*$/, line) do
          [_, ^omitted_path] -> true
          _ -> false
        end
      end)
      |> Enum.join("\n")

    omitted_errors = partition_weight_inventory_errors(inventory, omitted_weights)

    assert "missing weight for #{omitted_path}" in omitted_errors,
           "omitting a real test file must name it in the inventory error"

    assert partition_weight_inventory_errors(["test/a_test.exs"], "1 test/a_test.exs\n") == []

    assert "malformed weight row at line 1: \"not-a-weight test/a_test.exs\"" in partition_weight_inventory_errors(
             ["test/a_test.exs"],
             "not-a-weight test/a_test.exs\n"
           )

    assert "duplicate weight path test/a_test.exs" in partition_weight_inventory_errors(
             ["test/a_test.exs"],
             "1 test/a_test.exs\n2 test/a_test.exs\n"
           )

    assert "weight rows must be sorted by path" in partition_weight_inventory_errors(
             ["test/a_test.exs", "test/b_test.exs"],
             "2 test/b_test.exs\n1 test/a_test.exs\n"
           )
  end

  defp long_async_assignment(script) do
    [_, function] = Regex.run(~r/^(assign_files\(\) \{\n.*?^\})/ms, script)

    dir =
      Path.join(System.tmp_dir!(), "threadline-async-floor-#{System.unique_integer([:positive])}")

    File.mkdir_p!(Path.join(dir, "test"))

    try do
      for name <- ["long", "short"] do
        File.write!(Path.join(dir, "test/#{name}_test.exs"), "  use ExUnit.Case, async: true\n")
      end

      File.write!(Path.join(dir, "test/sync_test.exs"), "  use ExUnit.Case\n")

      File.write!(
        Path.join(dir, "weights"),
        "80000 test/long_test.exs\n40000 test/short_test.exs\n40000 test/sync_test.exs\n"
      )

      File.write!(
        Path.join(dir, "files"),
        "test/long_test.exs\ntest/short_test.exs\ntest/sync_test.exs\n"
      )

      {output, 0} =
        System.cmd(
          "/bin/bash",
          [
            "-c",
            "set -euo pipefail\nASYNC_FACTOR_PERMILLE=292\n" <>
              function <> "\nassign_files 2 weights files /dev/null"
          ],
          cd: dir
        )

      output
      |> String.split("\n", trim: true)
      |> Map.new(fn row ->
        [bin, path, weight] = String.split(row, "\t")
        {path, {bin, weight}}
      end)
    after
      File.rm_rf!(dir)
    end
  end

  test "long async duration floors affect actual assignment and the discounted output stays stable" do
    script = read_rel!(["bin", "ci-test-partitions"])

    expected = %{
      "test/long_test.exs" => {"1", "23360"},
      "test/short_test.exs" => {"2", "11680"},
      "test/sync_test.exs" => {"2", "40000"}
    }

    assert long_async_assignment(script) == expected
    mutant = String.replace(script, "return sync + max_async", "return sync + discounted")
    refute mutant == script
    refute long_async_assignment(mutant) == expected
  end

  @export_storage_fixtures [
    "test/threadline/storage/local_test.exs",
    "test/threadline/export/orchestrator_test.exs",
    "test/threadline/export/cleanup_test.exs",
    "test/threadline/operator_surface/controllers/export_controller_test.exs"
  ]

  defp run_export_storage_partitions!(dir, colocate, extra_env) do
    File.mkdir_p!(Path.join(dir, "bin"))

    File.cp!(
      Path.join(@repo_root, "bin/ci-test-partitions"),
      Path.join(dir, "bin/ci-test-partitions")
    )

    for path <- @export_storage_fixtures do
      File.mkdir_p!(Path.dirname(Path.join(dir, path)))
      File.cp!(Path.join(@repo_root, path), Path.join(dir, path))
    end

    File.cp!(
      Path.join(@repo_root, "test/partition_weights.txt"),
      Path.join(dir, "test/partition_weights.txt")
    )

    File.write!(Path.join(dir, "test/partition_colocate.txt"), colocate)
    fake_mix = Path.join(dir, "mix")

    # The runner launches real OS processes. A shared-root fixture must never
    # overlap another partition's use of that root. Hold an atomic mkdir claim
    # until every nonempty partition has attempted it: no timing race or sleep
    # duration determines whether the negative control catches a split group.
    File.write!(fake_mix, """
    #!/usr/bin/env bash
    set -eu
    [ "$1" = compile ] && exit 0
    expected=0
    for files in logs/partition-*.files; do
      if [ -s "$files" ]; then expected=$((expected + 1)); fi
    done
    status=0
    mkdir shared-export-root 2>/dev/null || status=41
    touch "attempt-$MIX_TEST_PARTITION"
    polls=0
    while :; do
      set -- attempt-*
      [ "$#" -eq "$expected" ] && break
      polls=$((polls + 1))
      [ "$polls" -lt 100 ] || exit 42
      sleep 0.05
    done
    if [ "$status" -ne 0 ]; then echo 'export fixture overlap'; exit "$status"; fi
    rmdir shared-export-root
    """)

    File.chmod!(fake_mix, 0o755)

    System.cmd("/bin/bash", ["bin/ci-test-partitions", "4"],
      cd: dir,
      env: [
        {"MIX_BIN", fake_mix},
        {"THREADLINE_TEST_SCOPE", ""},
        {"THREADLINE_CI_LANE", ""},
        {"CI_TEST_PARTITIONS_LOG_DIR", Path.join(dir, "logs")},
        {"CI_TEST_PARTITIONS_BUDGET_S", "20"}
        | extra_env
      ],
      stderr_to_stdout: true
    )
  end

  @tag :tmp_dir
  test "shared local export fixtures never overlap across partition processes", %{tmp_dir: dir} do
    colocate = read_rel!(["test", "partition_colocate.txt"])

    # The grouped case runs at the runner's real TAIL_QUEUE_K (seam unset):
    # colocated files are never queued, so the group still shares one partition.
    {output, status} =
      run_export_storage_partitions!(Path.join(dir, "grouped"), colocate, [
        {"CI_TEST_PARTITIONS_TAIL_K", nil}
      ])

    assert status == 0, output

    # Negative control: without the ownership group, the same production runner
    # splits these four real files and the shared-root claim detects overlap.
    # It runs at CI_TEST_PARTITIONS_TAIL_K=0 (the static split): ungrouped, the
    # sync files would otherwise be lifted into the tail queue and this control
    # would stop testing the colocation rule. The control isolates the colocation
    # rule on the static split; the queue's own colocation exclusion is proven
    # separately by the runner's tq-colocate self-test and the TAIL_QUEUE_K
    # contract test below.
    {output, status} =
      run_export_storage_partitions!(Path.join(dir, "split"), "", [
        {"CI_TEST_PARTITIONS_TAIL_K", "0"}
      ])

    assert status != 0
    assert output =~ "export fixture overlap"
  end

  @tail_queue_sync_weights for n <- 1..14, do: {"test/q/s#{n}_test.exs", 150_000 - n * 10_000}

  defp tail_queue_sandbox!(dir, script, lane \\ "") do
    File.mkdir_p!(Path.join(dir, "bin"))
    File.mkdir_p!(Path.join(dir, "test/q"))
    File.write!(Path.join(dir, "bin/ci-test-partitions"), script)

    sync = "defmodule Sandbox.Q do\n  use ExUnit.Case\nend\n"
    async = "defmodule Sandbox.Q do\n  use ExUnit.Case, async: true\nend\n"

    # The async file and the colocated pair are the heaviest, so a broken
    # eligibility rule would lift them first.
    files =
      [{"test/q/async_test.exs", 900_000, async}] ++
        [{"test/q/c1_test.exs", 800_000, sync}, {"test/q/c2_test.exs", 700_000, sync}] ++
        for {path, ms} <- @tail_queue_sync_weights, do: {path, ms, sync}

    for {path, _ms, body} <- files, do: File.write!(Path.join(dir, path), body)

    weights = Enum.map_join(files, "", fn {path, ms, _body} -> "#{ms} #{path}\n" end)

    for name <- ["partition_weights", "partition_weights_min", "partition_weights_latest"],
        do: File.write!(Path.join(dir, "test/#{name}.txt"), weights)

    File.write!(
      Path.join(dir, "test/partition_colocate.txt"),
      "# sandbox group\ntest/q/c1_test.exs test/q/c2_test.exs\n"
    )

    {output, status} =
      System.cmd("/bin/bash", ["bin/ci-test-partitions", "4"],
        cd: dir,
        env: [
          {"MIX_BIN", "false"},
          {"THREADLINE_TEST_SCOPE", ""},
          {"THREADLINE_CI_LANE", lane},
          {"GITHUB_STEP_SUMMARY", nil},
          {"CI_TEST_PARTITIONS_TAIL_K", nil},
          {"CI_TEST_PARTITIONS_LOG_DIR", Path.join(dir, "logs")}
        ],
        stderr_to_stdout: true
      )

    assert status == 2 and output =~ "serial compile failed",
           "a MIX_BIN=false run must stop at the serial compile, got #{status}: #{output}"

    dir
    |> Path.join("logs/tail-queue.tsv")
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.map(fn row ->
      [_seq, path, weight] = String.split(row, "\t")
      {path, String.to_integer(weight)}
    end)
  end

  @tag :tmp_dir
  test "tail queue lifts exactly TAIL_QUEUE_K=12 ungrouped sync files and a smaller K is caught",
       %{tmp_dir: dir} do
    script = read_rel!(["bin", "ci-test-partitions"])

    assert length(Regex.scan(~r/^TAIL_QUEUE_K=12$/m, script)) == 1,
           "rule=tail-queue-k: bin/ci-test-partitions must set TAIL_QUEUE_K=12 on exactly one line (D-27)"

    expected = Enum.take(@tail_queue_sync_weights, 12)
    rows = tail_queue_sandbox!(Path.join(dir, "real"), script)

    assert rows == expected,
           "rule=tail-queue-k: the queue must be the 12 heaviest ungrouped sync files, heaviest first, got #{inspect(rows)}"

    weights = Enum.map(rows, &elem(&1, 1))
    assert weights == Enum.sort(weights, :desc)

    for {path, _ms} <- rows do
      refute path in ["test/q/async_test.exs", "test/q/c1_test.exs", "test/q/c2_test.exs"],
             "an async or colocated file was queued: #{path}"
    end

    mutant = Regex.replace(~r/^TAIL_QUEUE_K=12$/m, script, "TAIL_QUEUE_K=4")
    refute mutant == script, "the TAIL_QUEUE_K mutation did not change the script"
    mutant_rows = tail_queue_sandbox!(Path.join(dir, "mutant"), mutant)
    assert length(mutant_rows) == 4
    refute mutant_rows == expected, "a TAIL_QUEUE_K=4 mutant must be caught"
  end

  defp scoped_test_files! do
    Enum.reject(enumerated_test_files!(), fn path ->
      Regex.match?(~r/^\s*@moduletag :repo_contract\s*$/m, File.read!(path))
    end)
  end

  defp lane_route_errors(script, lane, expected) do
    # Read only the production selector; self-test literals cannot satisfy this guard.
    body =
      case Regex.run(~r/^lane_weights\(\) \{\n(.*?)^\}/ms, script) do
        [_, body] -> body
        _ -> ""
      end

    needle = "#{lane}) printf '%s\\n' '#{expected}' ;;"
    if String.contains?(body, needle), do: [], else: ["wrong weights for lane #{lane}"]
  end

  test "min weights cover the exact scoped inventory and the runner selects them" do
    inventory = scoped_test_files!()
    weights = read_rel!(["test", "partition_weights_min.txt"])
    assert partition_weight_inventory_errors(inventory, weights) == []
    script = read_rel!(["bin", "ci-test-partitions"])
    path = "test/partition_weights_min.txt"
    assert lane_route_errors(script, "min", path) == []

    mutant =
      String.replace(
        script,
        "min) printf '%s\\n' '#{path}' ;;",
        "min) printf '%s\\n' 'test/partition_weights.txt' ;;"
      )

    assert lane_route_errors(mutant, "min", path) == ["wrong weights for lane min"]
  end

  test "latest weights cover the scoped inventory and all lane routes stay explicit" do
    weights = read_rel!(["test", "partition_weights_latest.txt"])
    assert partition_weight_inventory_errors(scoped_test_files!(), weights) == []
    script = read_rel!(["bin", "ci-test-partitions"])
    path = "test/partition_weights_latest.txt"
    assert lane_route_errors(script, "latest", path) == []

    mutant =
      String.replace(
        script,
        "latest) printf '%s\\n' '#{path}' ;;",
        "latest) printf '%s\\n' 'test/partition_weights_min.txt' ;;"
      )

    assert lane_route_errors(mutant, "latest", path) == ["wrong weights for lane latest"]
    assert script =~ "''|current) printf '%s\\n' \"$WEIGHTS_REL\" ;;"
    assert script =~ "*) die \"unknown THREADLINE_CI_LANE: $1\" ;;"
  end

  test "every lane inventory rejects omitted duplicate stale and nonpositive weights" do
    for lane <- ["min", "latest"] do
      inventory = scoped_test_files!()
      weights = read_rel!(["test", "partition_weights_#{lane}.txt"])
      path = hd(inventory)
      assert partition_weight_inventory_errors(inventory, weights) == []
      rows = String.split(weights, "\n")
      without = Enum.reject(rows, &String.ends_with?(&1, " " <> path)) |> Enum.join("\n")
      assert "missing weight for #{path}" in partition_weight_inventory_errors(inventory, without)

      assert "duplicate weight path #{path}" in partition_weight_inventory_errors(
               inventory,
               weights <> "1 #{path}\n"
             )

      stale = "test/stale_test.exs"

      assert "weight path is not a discovered test file: #{stale}" in partition_weight_inventory_errors(
               inventory,
               weights <> "1 #{stale}\n"
             )

      for invalid <- ["0", "-1"] do
        assert partition_weight_inventory_errors([path], "#{invalid} #{path}\n") != []
      end
    end
  end

  defp lane_rule_errors(script) do
    # Read only the production lane_rule; self-test literals cannot satisfy this guard.
    body =
      case Regex.run(~r/^lane_rule\(\) \{\n(.*?)^\}/ms, script) do
        [_, body] -> body
        _ -> ""
      end

    for {arm, rule} <- [{"''|current", "median"}, {"min", "max"}, {"latest", "median"}],
        not String.contains?(body, "#{arm}) printf '%s\\n' '#{rule}' ;;"),
        do: "wrong rule for lane #{arm}"
  end

  defp lane_tail_k_errors(script) do
    # Read only the production lane_tail_k; self-test literals cannot satisfy this guard.
    body =
      case Regex.run(~r/^lane_tail_k\(\) \{\n(.*?)^\}/ms, script) do
        [_, body] -> body
        _ -> ""
      end

    arms =
      for {arm, k} <- [{"''|current", ~s("$TAIL_QUEUE_K")}, {"min", "'0'"}, {"latest", "'0'"}],
          not String.contains?(body, "#{arm}) printf '%s\\n' #{k} ;;"),
          do: "wrong tail K for lane #{arm}"

    seam =
      if String.contains?(script, ~s(lane_tail_k "${THREADLINE_CI_LANE:-}")),
        do: [],
        else: ["run_partitions must default the tail-K seam to lane_tail_k"]

    arms ++ seam
  end

  # The runner's --self-test ok line must name tq-lane-k (D-32), so the case
  # cannot be dropped without the contract noticing.
  defp tq_lane_k_ok_token?(script) do
    Regex.match?(
      ~r/^  printf 'ci-test-partitions self-test: ok \(.*, tq-lane-k[,)].*\\n'$/m,
      script
    )
  end

  # A sandbox with the given runner text, two plain test files, R1-headed
  # weights and three runs x four partitions of min and current TSVs:
  # test/a_test.exs is 100/300/200 ms (median 200, max 300), b is 100 throughout.
  defp lane_rule_sandbox!(dir, script) do
    File.mkdir_p!(Path.join(dir, "bin"))
    File.mkdir_p!(Path.join(dir, "test"))
    runner = Path.join(dir, "bin/ci-test-partitions")
    File.write!(runner, script)
    File.chmod!(runner, 0o755)

    for name <- ["a", "b"],
        do: File.write!(Path.join(dir, "test/#{name}_test.exs"), "  use ExUnit.Case\n")

    header =
      read_rel!(["test", "partition_weights_min.txt"])
      |> String.split("\n")
      |> Enum.filter(&String.starts_with?(&1, "#"))
      |> Enum.join("\n")

    for path <- ["test/partition_weights.txt", "test/partition_weights_min.txt"],
        do:
          File.write!(Path.join(dir, path), header <> "\n1 test/a_test.exs\n1 test/b_test.exs\n")

    for lane <- ["min", "current"], {run, ms} <- [{"301", 100}, {"302", 300}, {"303", 200}] do
      run_dir = Path.join([dir, "ing-#{lane}", run, lane])
      File.mkdir_p!(run_dir)

      for part <- 1..4 do
        File.write!(
          Path.join(run_dir, "partition-timings-#{part}.tsv"),
          "# threadline.partition-timings/1 partition=#{part} lane=#{lane} boot_ms=1 wall_ms=1000\n" <>
            lane_rule_rows(part, ms)
        )
      end
    end

    dir
  end

  defp lane_rule_rows(1, ms), do: "test/a_test.exs\t#{ms}\t90\n"
  defp lane_rule_rows(2, _ms), do: "test/b_test.exs\t100\t90\n"
  defp lane_rule_rows(_part, _ms), do: ""

  defp strict_ingest(dir, lane, output, extra \\ []) do
    System.cmd(
      "/bin/bash",
      [
        "bin/ci-test-partitions",
        "--ingest-weights",
        Path.join(dir, "ing-#{lane}"),
        "--lane",
        lane
      ] ++
        extra ++ ["--output", output],
      cd: dir,
      stderr_to_stdout: true
    )
  end

  @tag :tmp_dir
  test "lane weight rules: current and latest take the median, min the maximum, and a strict mismatch exits 2",
       %{tmp_dir: tmp} do
    script = read_rel!(["bin", "ci-test-partitions"])
    assert lane_rule_errors(script) == []

    dir = lane_rule_sandbox!(Path.join(tmp, "prod"), script)
    min_path = Path.join(dir, "test/partition_weights_min.txt")

    {output, status} = strict_ingest(dir, "min", "test/partition_weights_min.txt")
    assert status == 0, output
    assert output =~ "ingest-weights: rule max"
    min_weights = File.read!(min_path)
    assert min_weights =~ ~r/^300 test\/a_test\.exs$/m
    assert min_weights =~ ~r/^100 test\/b_test\.exs$/m

    {output, status} = strict_ingest(dir, "current", "test/partition_weights.txt")
    assert status == 0, output

    assert File.read!(Path.join(dir, "test/partition_weights.txt")) =~
             ~r/^200 test\/a_test\.exs$/m

    {output, status} =
      strict_ingest(dir, "min", "test/partition_weights_min.txt", ["--rule", "median"])

    assert status == 2, output
    assert output =~ "requires --rule max, got median"
    assert File.read!(min_path) == min_weights

    # Mutant: the min lane mapped back to the median must lose the maximum.
    mutant =
      String.replace(script, "min) printf '%s\\n' 'max' ;;", "min) printf '%s\\n' 'median' ;;")

    refute mutant == script
    assert lane_rule_errors(mutant) == ["wrong rule for lane min"]
    mutant_dir = lane_rule_sandbox!(Path.join(tmp, "mutant"), mutant)
    {output, status} = strict_ingest(mutant_dir, "min", "test/partition_weights_min.txt")
    assert status == 0, output

    refute File.read!(Path.join(mutant_dir, "test/partition_weights_min.txt")) =~
             "300 test/a_test.exs"
  end

  @tag :tmp_dir
  test "lane_tail_k queues TAIL_QUEUE_K on the current lane and nothing on min or latest, and a min mutant is caught",
       %{tmp_dir: dir} do
    script = read_rel!(["bin", "ci-test-partitions"])

    assert lane_tail_k_errors(script) == [],
           "rule=lane-tail-k: lane_tail_k must queue TAIL_QUEUE_K on current and 0 on min and latest, and default the seam (D-32)"

    expected = Enum.take(@tail_queue_sync_weights, 12)

    assert tail_queue_sandbox!(Path.join(dir, "current"), script, "current") == expected,
           "rule=lane-tail-k: the current lane must queue the 12 heaviest ungrouped sync files"

    for lane <- ["min", "latest"] do
      assert tail_queue_sandbox!(Path.join(dir, lane), script, lane) == [],
             "rule=lane-tail-k: the #{lane} lane must queue nothing (D-32)"
    end

    # Mutant: the min lane queuing TAIL_QUEUE_K again.
    mutant =
      String.replace(
        script,
        "min) printf '%s\\n' '0' ;;",
        ~s(min\) printf '%s\\n' "$TAIL_QUEUE_K" ;;)
      )

    refute mutant == script, "rule=lane-tail-k: the min mutation did not change the script"

    assert lane_tail_k_errors(mutant) == ["wrong tail K for lane min"],
           "rule=lane-tail-k: the textual rule must catch a min lane that queues TAIL_QUEUE_K"

    assert length(tail_queue_sandbox!(Path.join(dir, "min-mutant"), mutant, "min")) == 12,
           "rule=lane-tail-k: the min mutant must queue 12 files in the sandbox"

    assert tq_lane_k_ok_token?(script),
           "rule=lane-tail-k: the --self-test ok line must name tq-lane-k"

    token_mutant = String.replace(script, ", tq-lane-k)\\n'", ")\\n'")

    refute token_mutant == script,
           "rule=lane-tail-k: the ok-token mutation did not change the script"

    refute tq_lane_k_ok_token?(token_mutant),
           "rule=lane-tail-k: an ok line without tq-lane-k must be caught"
  end

  test "ci.yml defines PgBouncer topology job with transaction pool and mix verify.topology" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    assert String.contains?(yaml, "verify-pgbouncer-topology:")
    assert String.contains?(yaml, "POOL_MODE: transaction")
    assert String.contains?(yaml, "AUTH_TYPE: scram-sha-256")
    assert String.contains?(yaml, "THREADLINE_PGBOUNCER_TOPOLOGY: \"1\"")
    assert String.contains?(yaml, "mix verify.topology")
    assert String.contains?(yaml, "priv/ci/topology_bootstrap.exs")
    assert String.contains?(yaml, "edoburu/pgbouncer:")
  end

  test "ci.all alias does not include verify.bench" do
    mix_exs = read_rel!(["mix.exs"])

    assert mix_exs =~ "\"ci.all\": ["

    [_, ci_all_block] = String.split(mix_exs, "\"ci.all\": [")
    [ci_all_list | _] = String.split(ci_all_block, "]")

    refute String.contains?(ci_all_list, "\"verify.bench\"")
  end

  test "ci.all alias does not include verify.release" do
    mix_exs = read_rel!(["mix.exs"])

    assert mix_exs =~ "\"ci.all\": ["

    [_, ci_all_block] = String.split(mix_exs, "\"ci.all\": [")
    [ci_all_list | _] = String.split(ci_all_block, "]")

    refute String.contains?(ci_all_list, "\"verify.release\"")
  end

  test "mix aliases expose the named support-lane proof entrypoints" do
    mix_exs = read_rel!(["mix.exs"])

    assert String.contains?(mix_exs, "\"verify.compile_no_optional\":")
    assert String.contains?(mix_exs, "\"compile --no-optional-deps --warnings-as-errors\"")
    assert String.contains?(mix_exs, "\"verify.xref_cycles\":")

    assert String.contains?(
             mix_exs,
             "\"xref graph --format cycles --label compile-connected --fail-above 0\""
           )

    assert String.contains?(mix_exs, "\"verify.test\": [\"test\"]")
    assert String.contains?(mix_exs, "\"verify.example\": &verify_example/1")
  end

  test "ci.all keeps capture-only and phoenix-surface proof steps in order" do
    mix_exs = read_rel!(["mix.exs"])

    assert [_, ci_block] =
             Regex.run(~r/"ci\.all":\s*\[\s*\n((?:.*\n)*?)\s*\]/, mix_exs),
           "expected mix.exs to declare a multiline ci.all list"

    {pos_compile_strict, _} = :binary.match(ci_block, "\"compile --warnings-as-errors\"")
    {pos_xref_cycles, _} = :binary.match(ci_block, "\"verify.xref_cycles\"")
    {pos_compile_no_optional, _} = :binary.match(ci_block, "\"verify.compile_no_optional\"")
    {pos_verify_test, _} = :binary.match(ci_block, "\"verify.test\"")
    {pos_verify_threadline, _} = :binary.match(ci_block, "\"verify.threadline\"")
    {pos_verify_example, _} = :binary.match(ci_block, "\"verify.example\"")

    {pos_verify_browser, _} =
      :binary.match(
        ci_block,
        "cmd env CI=true mix verify.example_browser --project=desktop-chromium --project=mobile-chromium"
      )

    assert pos_compile_strict < pos_xref_cycles
    assert pos_xref_cycles < pos_compile_no_optional
    assert pos_compile_strict < pos_compile_no_optional
    assert pos_compile_no_optional < pos_verify_test
    assert pos_verify_test < pos_verify_threadline
    assert pos_verify_threadline < pos_verify_example
    assert pos_verify_example < pos_verify_browser
  end

  test "ci workflow exposes the documented support-lane job ids" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    assert Regex.match?(~r/^  verify-compile-no-optional:/m, yaml)
    assert Regex.match?(~r/^  verify-test:/m, yaml)
    assert Regex.match?(~r/^  verify-bump-rehearsal:/m, yaml)
  end

  test "the verify-test minimum lane pins PostgreSQL 15 exactly (FLOOR-01)" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    assert minimum_postgres_errors(yaml) == []

    contract_reference =
      "# The PostgreSQL 15 support floor is pinned by " <>
        "test/threadline/ci_topology_contract_test.exs.\n"

    unlinked_yaml = String.replace(yaml, contract_reference, "")

    assert "verify-test min row must identify its PostgreSQL support-floor contract" in minimum_postgres_errors(
             unlinked_yaml
           )

    for pg <- ["14", "16"] do
      mutated_yaml = replace_minimum_postgres(yaml, pg)
      refute mutated_yaml == yaml, "the min-lane PostgreSQL #{pg} mutation must change ci.yml"

      assert minimum_postgres_errors(mutated_yaml) != [],
             "changing only the min-lane PostgreSQL value to #{pg} must fail the floor contract"
    end
  end

  test "the sole required-check decision pins alls-green immutably" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    assert Regex.match?(
             ~r|uses: re-actors/alls-green@[0-9a-f]{40} # v\d+\.\d+\.\d+$|m,
             yaml
           ),
           "ci-required must execute alls-green from a reviewed full commit SHA"

    refute String.contains?(yaml, "re-actors/alls-green@release/"),
           "a mutable release ref can retarget the only branch-protection decision"
  end

  test "Dialyzer is one blocking local and current-lane CI path with an exact measured PLT cache" do
    mix_exs = read_rel!(["mix.exs"])
    yaml = read_rel!([".github", "workflows", "ci.yml"])
    contributing = read_rel!(["CONTRIBUTING.md"])

    assert dialyzer_topology_errors(mix_exs, yaml, contributing) == []

    dialyzer_job = workflow_job(yaml, "verify-dialyzer")
    live_slice_step = workflow_step(yaml, @live_slice_step_name)
    assert live_slice_step != "", "the live Dialyzer slice step must exist"

    mutation_controls = [
      {"PLT timing command",
       String.replace(
         yaml,
         "/usr/bin/time -v -o \"$time_file\" mix dialyzer --plt",
         "mix dialyzer --plt"
       )},
      {"analysis timing command",
       String.replace(
         yaml,
         "/usr/bin/time -v -o \"$time_file\" mix dialyzer --no-check",
         "mix dialyzer --no-check"
       )},
      # Scoped to the Dialyzer job: Run tests also sets timeout-minutes: 12.
      {"measured timeout",
       String.replace(
         yaml,
         dialyzer_job,
         String.replace(dialyzer_job, "timeout-minutes: 12", "timeout-minutes: 11")
       )},
      {"fail-on-unparseable guard",
       String.replace(yaml, "Unable to parse GNU time output", "Timing unavailable")},
      {"build-before-save ordering",
       String.replace(yaml, "- name: Save Dialyzer PLT", "- name: Save analyzer cache")},
      {"same-toolchain restore boundary",
       String.replace(yaml, @resolved_plt_prefix, "ubuntu-24.04-dialyzer-plt-")},
      {"literal OTP pin",
       String.replace(
         yaml,
         dialyzer_job,
         String.replace(
           dialyzer_job,
           "          version-type: strict\n",
           "          version-type: strict\n          otp-version: \"" <> "27" <> ".0\"\n"
         )
       )},
      {"no analyzer in no-optional lane",
       String.replace(
         yaml,
         "run: mix verify.compile_no_optional",
         "run: |\n          mix verify.compile_no_optional\n          mix dialyzer --no-check"
       )},
      {"live slice step deleted", String.replace(yaml, live_slice_step, "")},
      {"live slice step before the analysis",
       yaml
       |> String.replace(live_slice_step, "")
       |> String.replace(
         "      - name: Analyze and measure with Dialyzer\n",
         live_slice_step <> "      - name: Analyze and measure with Dialyzer\n"
       )},
      {"live slice alias added to verify-test",
       String.replace(
         yaml,
         "run: mix verify.test_partitioned\n",
         "run: |\n          mix verify.test_partitioned\n          mix verify.dialyzer_slice\n"
       )}
    ]

    for {control, mutated_yaml} <- mutation_controls do
      refute dialyzer_topology_errors(mix_exs, mutated_yaml, contributing) == [],
             "#{control} mutation must make the Dialyzer topology contract fail"
    end

    for marker <- [
          "THREADLINE_DIALYZER_PLT_CACHE=",
          "THREADLINE_DIALYZER_PLT_WALL_SECONDS=",
          "THREADLINE_DIALYZER_PLT_MAX_RSS_KB=",
          "THREADLINE_DIALYZER_ANALYSIS_WALL_SECONDS=",
          "THREADLINE_DIALYZER_ANALYSIS_MAX_RSS_KB="
        ] do
      mutated_yaml = String.replace(yaml, marker, "THREADLINE_BROKEN_MARKER=")

      refute dialyzer_topology_errors(mix_exs, mutated_yaml, contributing) == [],
             "removing stable marker #{marker} must make the topology contract fail"
    end

    hit_step = workflow_step(yaml, "Report exact PLT cache hit")

    hit_with_fabricated_plt =
      String.replace(
        yaml,
        hit_step,
        hit_step <> "          echo \"THREADLINE_DIALYZER_PLT_WALL_SECONDS=0\"\n"
      )

    refute dialyzer_topology_errors(mix_exs, hit_with_fabricated_plt, contributing) == [],
           "the exact-key hit path must never fabricate a PLT-build measurement"

    mix_without_slice =
      String.replace(mix_exs, ~s(        "cmd env MIX_ENV=test mix verify.dialyzer_slice",\n), "")

    refute mix_without_slice == mix_exs, "the ci.all live-slice entry must be present to mutate"

    refute dialyzer_topology_errors(mix_without_slice, yaml, contributing) == [],
           "dropping the ci.all live-slice entry must make the Dialyzer topology contract fail"

    evidence_without_cold_run =
      String.replace(contributing, "34642915672", "unlinked-cold-run")

    refute dialyzer_topology_errors(mix_exs, yaml, evidence_without_cold_run) == [],
           "authenticated cold-run provenance must be part of the documentation contract"
  end

  test "verify-test job runs the phoenix-surface and sigra-reference proof path" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    assert String.contains?(yaml, "- name: Run tests")
    assert String.contains?(yaml, "run: mix verify.test_partitioned")
    assert String.contains?(yaml, "- name: Verify Threadline trigger coverage")
    assert String.contains?(yaml, "run: mix verify.threadline")
    assert String.contains?(yaml, "- name: Verify Threadline Phoenix example")
    assert String.contains?(yaml, "run: mix verify.example")
    refute String.contains?(yaml, "mix " <> @retired_alias)
  end

  # GitHub Actions never runs `ci.all`, so pinning the alias alone would let the
  # GATE-04 cycle gate be dropped from CI with every test still green.
  test "verify-test job runs the xref cycle gate unconditionally before the suite" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    assert [_, block] =
             Regex.run(
               ~r/^  verify-test:\n([\s\S]*?)(?=^  [a-z][a-z0-9-]+:\n)/m,
               yaml
             ),
           "verify-test job is missing"

    step = workflow_step(block, "Verify no compile-connected xref cycles")

    assert step =~ ~r/^        run: mix verify\.xref_cycles\s*$/m,
           "verify-test must run `mix verify.xref_cycles` (GATE-04)"

    refute step =~ ~r/^        if:/m, "the xref cycle gate must not be conditional"

    refute step =~ ~r/^        continue-on-error:/m,
           "the xref cycle gate must fail the job"

    assert ordered_positions?([
             position(block, "run: mix compile --warnings-as-errors"),
             position(block, "run: mix verify.xref_cycles"),
             position(block, "run: mix verify.test_partitioned")
           ]),
           "the xref cycle gate must run after compile and before the test suite"
  end

  @tail_queue_seams [
    "CI_TEST_PARTITIONS_TAIL_K",
    "CI_TEST_PARTITIONS_LOCK_WAIT_S",
    "CI_TEST_PARTITIONS_FAKE_FILE_PLAN"
  ]

  @canonical_invocation ~S("$MIX_BIN" test --no-compile --no-deps-check --timeout="$PARTITION_TEST_TIMEOUT_MS" "${files[@]}")

  defp partition_topology_errors(yaml, mix_exs, script) do
    job = workflow_job(yaml, "verify-test")
    run_tests_step = workflow_step(job, "Run tests")
    self_test_step = workflow_step(job, "Prove the gate goes red (failing partition)")

    verify_test_partitioned_def =
      case Regex.run(~r/defp verify_test_partitioned.*?\n  end\n/s, mix_exs) do
        [def_text] -> def_text
        nil -> ""
      end

    [
      {String.contains?(mix_exs, "\"verify.test_partitioned\": &verify_test_partitioned/1"),
       "mix.exs must map verify.test_partitioned to a function alias"},
      {verify_test_partitioned_def != "" and
         String.contains?(verify_test_partitioned_def, "bin/ci-test-partitions"),
       "verify_test_partitioned/1 must shell to bin/ci-test-partitions"},
      {"verify.test" in ci_all_entries(mix_exs) and
         "verify.test_partitioned" not in ci_all_entries(mix_exs),
       "ci.all must keep running verify.test, not verify.test_partitioned"},
      {run_tests_step != "", "the Run tests step is missing from verify-test"},
      {run_tests_step =~ ~r/^        run: mix verify\.test_partitioned\s*$/m,
       "Run tests must run exactly `mix verify.test_partitioned`"},
      {not (run_tests_step =~ ~r/^        if:/m),
       "the Run tests step must not carry an `if:` key"},
      {not (run_tests_step =~ ~r/^        continue-on-error:/m),
       "the Run tests step must not carry `continue-on-error:`"},
      {self_test_step != "",
       "a step named \"Prove the gate goes red (failing partition)\" is missing from verify-test"},
      {self_test_step =~ ~r/^        run: bin\/ci-test-partitions --self-test\s*$/m,
       "the self-test step must run exactly `bin/ci-test-partitions --self-test`"},
      {not (self_test_step =~ ~r/^        if:/m),
       "the self-test step must not carry an `if:` key"},
      {not (self_test_step =~ ~r/^        continue-on-error:/m),
       "the self-test step must not carry `continue-on-error:`"},
      {ordered_positions?([
         position(job, "run: mix compile --warnings-as-errors"),
         position(job, "run: bin/ci-test-partitions --self-test"),
         position(job, "run: mix verify.test_partitioned")
       ]), "compile, then the self-test step, then Run tests must run in that order"},
      {String.contains?(job, "MIX_TEST_PARTITION: \"1\""),
       "the Verify Threadline trigger coverage step must set MIX_TEST_PARTITION: \"1\" (D-07)"},
      {not String.contains?(yaml, "MIX_BIN"),
       "MIX_BIN (the test-only seam) must never appear in ci.yml"},
      {Enum.all?(@tail_queue_seams, &(not String.contains?(yaml, &1))),
       "rule=tail-queue-seams: the tail-queue test-only seams (#{Enum.join(@tail_queue_seams, ", ")}) must never appear in ci.yml (D-27)"},
      {length(String.split(script, @canonical_invocation)) == 2,
       "rule=single-invocation-site: bin/ci-test-partitions must hold the canonical mix test invocation exactly once, shared by static sets and tail-queue claims (D-27)"},
      {String.contains?(script, "|| fail=1") and
         not Regex.match?(~r/^\s*wait\s*$/m, script),
       "bin/ci-test-partitions must wait on each recorded PID individually, never a bare wait"},
      {String.contains?(
         script,
         "\"$MIX_BIN\" test --no-compile --no-deps-check --timeout=\"$PARTITION_TEST_TIMEOUT_MS\" \"${files[@]}\""
       ),
       "bin/ci-test-partitions must run each partition on its assigned files with --no-compile, --no-deps-check and the partition test timeout"},
      {not Regex.match?(~r/"\$MIX_BIN" test[^\n]*--partitions/, script),
       "bin/ci-test-partitions must not fall back to Mix's round-robin --partitions (files are assigned by weight)"},
      {Regex.match?(
         ~r/^\s+verify_assignment "\$n" "\$enumerated" "\$assignment" \|\| \{$/m,
         script
       ),
       "bin/ci-test-partitions must check that every test file is assigned exactly once before running"},
      {String.contains?(script, "WEIGHTS_REL=\"test/partition_weights.txt\"") and
         File.exists?(Path.join(@repo_root, "test/partition_weights.txt")),
       "bin/ci-test-partitions must read the committed test/partition_weights.txt"}
    ]
    |> Enum.concat(partition_hang_wiring_checks(job, run_tests_step, script))
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end

  # D-14/D-15/D-11: the budget watchdog, the monitor formatter args, the
  # timeout layering and the two partition artifacts.
  defp partition_hang_wiring_checks(job, run_tests_step, script) do
    [
      {timeout_layered?(job, run_tests_step, script),
       timeout_layering_message(job, run_tests_step, script)},
      {watchdog_wired?(script),
       "rule=watchdog: bin/ci-test-partitions must run watch_partitions right before the per-PID wait loop (D-14)"},
      {monitor_args_wired?(script),
       "rule=monitor-args: every partition's mix test must get the CLI and PartitionMonitor formatters after its files (D-13)"},
      {partition_upload?(
         job,
         "Upload partition timings",
         "always()",
         "partition-timings-${{ matrix.lane }}-${{ github.run_id }}",
         "tmp/ci-test-partitions/partition-timings-*.tsv"
       ),
       "rule=timings-upload: verify-test must always upload partition-timings-<lane>-<run> after Run tests (D-11)"},
      {partition_upload?(
         job,
         "Upload partition logs on failure",
         "failure()",
         "partition-logs-${{ matrix.lane }}-${{ github.run_id }}",
         "tmp/ci-test-partitions/"
       ),
       "rule=logs-upload: verify-test must upload partition-logs-<lane>-<run> on failure, after Run tests (D-15)"}
    ]
  end

  # Partition budget < Run tests step < job, so the script's watchdog fires
  # first and the failure-log upload still runs (D-15).
  defp timeout_layering(job, run_tests_step, script) do
    {first_integer(~r/^  local budget_s="\$\{CI_TEST_PARTITIONS_BUDGET_S:-(\d+)\}"$/m, script),
     first_integer(~r/^        timeout-minutes: (\d+)\s*$/m, run_tests_step),
     first_integer(~r/^    timeout-minutes: (\d+)\s*$/m, job)}
  end

  defp timeout_layered?(job, run_tests_step, script) do
    case timeout_layering(job, run_tests_step, script) do
      {budget_s, step, job_min}
      when is_integer(budget_s) and is_integer(step) and is_integer(job_min) ->
        budget_s < step * 60 and step < job_min

      _ ->
        false
    end
  end

  defp timeout_layering_message(job, run_tests_step, script) do
    {budget_s, step, job_min} = timeout_layering(job, run_tests_step, script)

    "rule=run-tests-step-timeout: Run tests must set timeout-minutes below the job's and above " <>
      "the partition budget (budget #{inspect(budget_s)} s, step #{inspect(step)} min, " <>
      "job #{inspect(job_min)} min)"
  end

  defp watchdog_wired?(script) do
    Regex.match?(~r/^watch_partitions\(\) \{$/m, script) and
      String.contains?(script, "  watch_partitions \"$n\" \"$log_dir\"\n  local fail=0\n")
  end

  defp monitor_args_wired?(script) do
    String.contains?(script, "\"${files[@]}\" ${monitor_args[@]+\"${monitor_args[@]}\"}") and
      String.contains?(
        script,
        "monitor_args=(--formatter ExUnit.CLIFormatter --formatter Threadline.Test.PartitionMonitor)"
      )
  end

  defp partition_upload?(job, step_name, condition, artifact, path) do
    step = workflow_step(job, step_name)

    Enum.all?([
      String.contains?(step, "        if: #{condition}\n"),
      String.contains?(step, "uses: actions/upload-artifact@"),
      String.contains?(step, "          name: #{artifact}\n"),
      String.contains?(step, "          path: #{path}\n"),
      ordered_positions?([
        position(job, "run: mix verify.test_partitioned"),
        position(job, "- name: #{step_name}\n")
      ])
    ])
  end

  defp first_integer(regex, text) do
    case Regex.run(regex, text, capture: :all_but_first) do
      [digits] -> String.to_integer(digits)
      nil -> nil
    end
  end

  defp minimum_postgres_errors(yaml) do
    job = workflow_job(yaml, "verify-test")
    min_headers = Regex.scan(~r/^ {10}- lane: min\s*$/m, job)

    min_blocks =
      Regex.scan(
        ~r/^ {10}- lane: min\n((?:^ {12}[^\n]*\n)*)/m,
        job,
        capture: :all_but_first
      )
      |> List.flatten()

    pg_values =
      case min_blocks do
        [block] ->
          Regex.scan(~r/^ {12}pg:\s*"([^"]+)"\s*$/m, block, capture: :all_but_first)
          |> List.flatten()

        _ ->
          []
      end

    [
      {job != "", "verify-test job is missing"},
      {length(min_headers) == 1, "verify-test must define exactly one min matrix row"},
      {length(min_blocks) == 1, "verify-test min row must have one parseable matrix block"},
      {length(min_blocks) == 1 and
         String.contains?(
           List.first(min_blocks),
           "# The PostgreSQL 15 support floor is pinned by " <>
             "test/threadline/ci_topology_contract_test.exs."
         ), "verify-test min row must identify its PostgreSQL support-floor contract"},
      {pg_values == ["15"],
       "verify-test min row must set pg to the exact token \"15\", found #{inspect(pg_values)}"}
    ]
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end

  defp replace_minimum_postgres(yaml, pg) do
    job = workflow_job(yaml, "verify-test")

    case Regex.run(~r/^ {10}- lane: min\n(?:^ {12}[^\n]*\n)*/m, job) do
      [block] ->
        [old_line] = Regex.run(~r/^ {12}pg:\s*"[^"]+"\s*$/m, block)
        new_block = String.replace(block, old_line, "            pg: \"#{pg}\"")
        new_job = String.replace(job, block, new_block, global: false)
        String.replace(yaml, job, new_job, global: false)

      _ ->
        yaml
    end
  end

  @partition_paragraph_lead "**CI runs the suite as N concurrent partitions.**"

  # D-27 doc parity: CONTRIBUTING's partition paragraph names the tail queue
  # and the runner's own TAIL_QUEUE_K, so neither can change alone.
  defp tail_queue_doc_errors(script, contributing) do
    k =
      case Regex.scan(~r/^TAIL_QUEUE_K=(\d+)$/m, script) do
        [[_, k]] -> k
        _ -> nil
      end

    paragraph =
      case String.split(contributing, @partition_paragraph_lead, parts: 2) do
        [_, rest] ->
          rest |> String.split(~r/\n\s*\n/, parts: 2) |> hd() |> String.replace(~r/\s+/, " ")

        _ ->
          ""
      end

    [
      {k != nil, "bin/ci-test-partitions must set TAIL_QUEUE_K on exactly one line"},
      {paragraph != "", "CONTRIBUTING.md has no partition paragraph"},
      {String.contains?(paragraph, "tail queue"),
       "CONTRIBUTING's partition paragraph must describe the tail queue"},
      {k != nil and String.contains?(paragraph, "the #{k} heaviest"),
       "CONTRIBUTING's partition paragraph must name the runner's K (the #{k} heaviest)"},
      {String.contains?(paragraph, "lane_tail_k") and
         String.contains?(paragraph, "min and latest lanes queue none"),
       "CONTRIBUTING's partition paragraph must say the min and latest lanes queue none (lane_tail_k)"},
      {lane_tail_k_errors(script) == [],
       "the runner's lane_tail_k must queue none on min and latest, as CONTRIBUTING says"}
    ]
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(&("rule=tail-queue-doc: " <> elem(&1, 1)))
  end

  test "CONTRIBUTING documents the tail queue with the runner's K" do
    script = read_rel!(["bin", "ci-test-partitions"])
    contributing = read_rel!(["CONTRIBUTING.md"])

    assert tail_queue_doc_errors(script, contributing) == []

    k_mutant = Regex.replace(~r/^TAIL_QUEUE_K=12$/m, script, "TAIL_QUEUE_K=13")
    doc_mutant = String.replace(contributing, "the 12 heaviest", "the 13 heaviest")
    refute k_mutant == script, "mutation anchor missing"
    refute doc_mutant == contributing, "mutation anchor missing"

    assert tail_queue_doc_errors(k_mutant, contributing) != [],
           "changing TAIL_QUEUE_K alone must fail the doc-parity rule"

    assert tail_queue_doc_errors(script, doc_mutant) != [],
           "changing the documented K alone must fail the doc-parity rule"

    lane_doc_mutant =
      String.replace(
        contributing,
        "min and latest lanes queue none",
        "min and latest lanes queue too"
      )

    lane_k_mutant =
      String.replace(
        script,
        "min) printf '%s\\n' '0' ;;",
        ~s(min\) printf '%s\\n' "$TAIL_QUEUE_K" ;;)
      )

    refute lane_doc_mutant == contributing, "mutation anchor missing"
    refute lane_k_mutant == script, "mutation anchor missing"

    assert tail_queue_doc_errors(script, lane_doc_mutant) != [],
           "removing the min/latest no-queue sentence alone must fail the doc-parity rule"

    assert tail_queue_doc_errors(lane_k_mutant, contributing) != [],
           "a runner whose min lane queues again must fail the doc-parity rule"
  end

  test "verify-test runs the suite in fail-closed partitions after compile (SUITE-02)" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])
    mix_exs = read_rel!(["mix.exs"])
    script = read_rel!(["bin", "ci-test-partitions"])

    assert partition_topology_errors(yaml, mix_exs, script) == []

    run_tests_step_text = "      - name: Run tests\n        run: mix verify.test_partitioned\n"

    self_test_step_text =
      "      - name: Prove the gate goes red (failing partition)\n        run: bin/ci-test-partitions --self-test\n"

    assert String.contains?(yaml, run_tests_step_text), "mutation anchor missing"
    assert String.contains?(yaml, self_test_step_text), "mutation anchor missing"

    mutation_controls = [
      {"Run tests reverted to mix verify.test",
       String.replace(
         yaml,
         "        run: mix verify.test_partitioned\n",
         "        run: mix verify.test\n"
       ), mix_exs, script},
      {"Run tests replaced by inline background-and-wait shell",
       String.replace(
         yaml,
         "        run: mix verify.test_partitioned\n",
         "        run: |\n" <>
           "          MIX_TEST_PARTITION=1 mix test --partitions 3 &\n" <>
           "          MIX_TEST_PARTITION=2 mix test --partitions 3 &\n" <>
           "          wait\n"
       ), mix_exs, script},
      {"Run tests moved before the compile step",
       yaml
       |> String.replace(run_tests_step_text, "")
       |> String.replace(
         "      - name: Compile (warnings as errors)\n",
         run_tests_step_text <> "      - name: Compile (warnings as errors)\n"
       ), mix_exs, script},
      {"self-test step renamed",
       String.replace(
         yaml,
         "Prove the gate goes red (failing partition)",
         "Prove the gate goes red"
       ), mix_exs, script},
      {"self-test step deleted", String.replace(yaml, self_test_step_text, ""), mix_exs, script},
      {"continue-on-error added to Run tests",
       String.replace(
         yaml,
         run_tests_step_text,
         "      - name: Run tests\n        continue-on-error: true\n        run: mix verify.test_partitioned\n"
       ), mix_exs, script},
      {"if added to Run tests",
       String.replace(
         yaml,
         run_tests_step_text,
         "      - name: Run tests\n        if: matrix.lane == 'current'\n        run: mix verify.test_partitioned\n"
       ), mix_exs, script},
      {"if added to the self-test step",
       String.replace(
         yaml,
         self_test_step_text,
         "      - name: Prove the gate goes red (failing partition)\n        if: matrix.lane == 'current'\n        run: bin/ci-test-partitions --self-test\n"
       ), mix_exs, script},
      {"MIX_BIN env added to verify-test",
       String.replace(
         yaml,
         "  verify-test:\n",
         "  verify-test:\n    env:\n      MIX_BIN: /bin/true\n"
       ), mix_exs, script},
      {"the D-07 env line removed",
       String.replace(yaml, "          MIX_TEST_PARTITION: \"1\"\n", ""), mix_exs, script},
      {"ci.all switched to the partitioned alias", yaml,
       String.replace(mix_exs, "\"verify.test\",\n", "\"verify.test_partitioned\",\n"), script},
      {"the script's per-PID wait replaced by a bare wait", yaml, mix_exs,
       String.replace(
         script,
         "  local fail=0\n  for i in $(seq 1 \"$n\"); do\n    wait \"${pids[i]}\" || fail=1\n  done\n",
         "  local fail=0\n  wait\n"
       )},
      {"--no-compile removed from the script", yaml, mix_exs,
       String.replace(script, " --no-compile --no-deps-check", " --no-deps-check")},
      {"the runner flipped back to Mix's round-robin --partitions", yaml, mix_exs,
       String.replace(
         script,
         "\"$MIX_BIN\" test --no-compile --no-deps-check --timeout=\"$PARTITION_TEST_TIMEOUT_MS\" \"${files[@]}\"",
         "\"$MIX_BIN\" test --partitions \"$n\" --no-compile --no-deps-check"
       )},
      {"--partitions added alongside the assigned files", yaml, mix_exs,
       String.replace(
         script,
         "\"$MIX_BIN\" test --no-compile --no-deps-check --timeout=\"$PARTITION_TEST_TIMEOUT_MS\" \"${files[@]}\"",
         "\"$MIX_BIN\" test --no-compile --no-deps-check --partitions \"$n\" \"${files[@]}\""
       )},
      {"the partition test timeout dropped", yaml, mix_exs,
       String.replace(script, " --timeout=\"$PARTITION_TEST_TIMEOUT_MS\"", "")},
      {"the exactly-once assignment check dropped", yaml, mix_exs,
       String.replace(
         script,
         "  verify_assignment \"$n\" \"$enumerated\" \"$assignment\" || {\n",
         "  true || {\n"
       )},
      {"the weights file path changed", yaml, mix_exs,
       String.replace(
         script,
         "WEIGHTS_REL=\"test/partition_weights.txt\"",
         "WEIGHTS_REL=\"test/missing_weights.txt\""
       )}
    ]

    for {label, y, mexs, s} <- mutation_controls do
      refute {y, mexs, s} == {yaml, mix_exs, script},
             "#{label} control did not change the input"

      assert partition_topology_errors(y, mexs, s) != [],
             "#{label} mutation must make the partition topology contract fail"
    end

    # D-14/D-15/D-11: each control must trip its own rule.
    step_timeout_text = run_tests_step_text <> "        timeout-minutes: 12\n"
    watchdog_text = "  watch_partitions \"$n\" \"$log_dir\"\n  local fail=0\n"
    monitor_args_text = " ${monitor_args[@]+\"${monitor_args[@]}\"}"
    timings_step = workflow_step(workflow_job(yaml, "verify-test"), "Upload partition timings")

    logs_step =
      workflow_step(workflow_job(yaml, "verify-test"), "Upload partition logs on failure")

    for text <- [step_timeout_text, watchdog_text, monitor_args_text] do
      assert String.contains?(yaml <> script, text), "mutation anchor missing"
    end

    assert timings_step != "", "mutation anchor missing"
    assert logs_step != "", "mutation anchor missing"

    rule_controls =
      [
        {"the Run tests step timeout removed",
         String.replace(yaml, step_timeout_text, run_tests_step_text), script,
         "rule=run-tests-step-timeout"},
        {"the Run tests step timeout raised to the job's",
         String.replace(
           yaml,
           step_timeout_text,
           run_tests_step_text <> "        timeout-minutes: 20\n"
         ), script, "rule=run-tests-step-timeout"},
        {"the partition budget raised past the step timeout", yaml,
         String.replace(
           script,
           "  local budget_s=\"${CI_TEST_PARTITIONS_BUDGET_S:-480}\"",
           "  local budget_s=\"${CI_TEST_PARTITIONS_BUDGET_S:-900}\""
         ), "rule=run-tests-step-timeout"},
        {"the watchdog call removed", yaml,
         String.replace(script, watchdog_text, "  local fail=0\n"), "rule=watchdog"},
        {"the monitor formatter args dropped", yaml,
         String.replace(script, monitor_args_text, ""), "rule=monitor-args"},
        {"the partition timings upload removed", String.replace(yaml, timings_step, ""), script,
         "rule=timings-upload"},
        {"the partition logs upload removed", String.replace(yaml, logs_step, ""), script,
         "rule=logs-upload"},
        {"a second canonical invocation site added", yaml,
         String.replace(
           script,
           @canonical_invocation,
           @canonical_invocation <> "\n    " <> @canonical_invocation,
           global: false
         ), "rule=single-invocation-site"}
      ]
      |> Enum.concat(
        for seam <- @tail_queue_seams do
          {"#{seam} env added to verify-test",
           String.replace(
             yaml,
             "  verify-test:\n",
             "  verify-test:\n    env:\n      #{seam}: \"0\"\n"
           ), script, "rule=tail-queue-seams"}
        end
      )

    for {label, y, s, rule} <- rule_controls do
      refute {y, s} == {yaml, script}, "#{label} control did not change the input"

      errors = partition_topology_errors(y, mix_exs, s)

      assert Enum.any?(errors, &String.contains?(&1, rule)),
             "#{label} mutation must report #{rule}, got #{inspect(errors)}"
    end
  end

  test "verify-test checkout includes complete history and annotated tags" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    assert [_, block] =
             Regex.run(
               ~r/^  verify-test:\n([\s\S]*?)(?=^  [a-z][a-z0-9-]+:\n)/m,
               yaml
             ),
           "verify-test job is missing"

    assert Regex.match?(
             ~r/^      - uses: actions\/checkout@[0-9a-f]{40} # v\d+\.\d+\.\d+\n        with:\n          fetch-depth: 0\s*$/m,
             block
           ),
           "verify-test must fetch full history so archive tag objects are present"

    refute Regex.match?(~r/^\s+fetch-tags:\s*false\s*$/m, block),
           "verify-test must not disable tag fetching"
  end

  # Globs BOTH extensions on purpose. GitHub Actions honours .yaml as well as
  # .yml, so a guard that only globbed .yml could be defeated by a rename.
  defp workflow_paths do
    @repo_root
    |> Path.join(".github/workflows/*.{yml,yaml}")
    |> Path.wildcard()
    |> Enum.map(&Path.relative_to(&1, @repo_root))
    |> Enum.sort()
  end

  # GREEN-09 / D-24 / D-25 resurrection guard.
  #
  # Globs every workflow rather than naming the deleted workflow file, so re-introducing the
  # retired paid UI scoring lane under ANY filename is caught. The needle is built by concatenation
  # because this file is itself read by nothing that scans for it — but the
  # concatenation also keeps a naive `grep -rl ANTHROPIC .github/` gate honest if
  # this guard is ever moved under .github/.
  test "no workflow references a paid LLM API key (GREEN-09 resurrection guard; retired UI loop, tag archive/ui-critic-loop)" do
    needle = "ANTHROPIC" <> "_API_KEY"
    paths = workflow_paths()

    refute paths == [],
           "found no workflow files to scan — the glob is broken, and a broken glob " <>
             "would launder a false pass for this guard"

    for path <- paths do
      refute String.contains?(read_rel!([path]), needle),
             "#{path} references #{needle} — the retired paid UI scoring loop (tag " <>
               "archive/ui-critic-loop) must stay structurally unreachable from CI " <>
               "(GREEN-09). Deleting the workflow, not defaulting its score input to " <>
               "false, is what satisfies this requirement."
    end
  end

  # GREEN-10 / D-26 / D-25 resurrection guard.
  #
  # Asserts LIST EQUALITY against a one-element list, not a count and not a bare
  # refutation. A count would pass if the one publish path moved to the wrong
  # workflow; a refutation would pass vacuously if the glob returned nothing.
  # Both failure modes are real and both are excluded by equality.
  test "exactly one workflow invokes the Hex publish command (GREEN-10 resurrection guard)" do
    publishers =
      Enum.filter(workflow_paths(), fn path ->
        String.contains?(read_rel!([path]), "mix hex.publish")
      end)

    assert publishers == [".github/workflows/release.yml"],
           "expected exactly one publish path, release.yml, but found: " <>
             inspect(publishers) <>
             ". release.yml is the only workflow carrying the five pre-publish gates " <>
             "(CI-green poll, hard needs:, verify-release-shape + hex.build, the " <>
             "already-published idempotency skip, and post-publish verification). A second " <>
             "publish path races it and wins, because publishing is irreversible in effect " <>
             "and the gated path polls for up to 30 minutes."
  end

  test "adoption pilot backlog carries CI topology contract marker" do
    doc = read_rel!(["guides", "adoption-pilot-backlog.md"])
    assert String.contains?(doc, "CI-PGBOUNCER-TOPOLOGY-CONTRACT")
  end

  test "adoption pilot backlog carries STG host topology template marker" do
    doc = read_rel!(["guides", "adoption-pilot-backlog.md"])
    assert String.contains?(doc, "STG-HOST-TOPOLOGY-TEMPLATE")
  end

  test "adoption pilot backlog carries STG audited path rubric marker" do
    doc = read_rel!(["guides", "adoption-pilot-backlog.md"])
    assert String.contains?(doc, "STG-AUDITED-PATH-RUBRIC")
  end

  # --- Phase 198-21 / D-42 merge-gate self-guarding contracts ---------------
  #
  # `.github/rulesets/main.json` names only the single aggregate context
  # `CI required`, so it structurally cannot detect a lane quietly dropped
  # from `ci-required`'s `needs:` list — the ruleset stays byte-identical
  # while the guarantee behind it shrinks. These two tests derive the merge
  # gate's real membership and its required-context singleton from source, in
  # both directions, so that narrowing is a red test rather than an invisible
  # YAML edit.

  @ci_required_roster_heading "### `ci-required` needs: roster"

  # Isolates the `ci-required:` job block. `ci-required` is the final job in
  # `ci.yml`'s `jobs:` map, so everything after the marker belongs to it.
  defp ci_required_block do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    case String.split(yaml, "\n  ci-required:\n", parts: 2) do
      [_, tail] ->
        tail

      _ ->
        flunk(
          "could not find a \"  ci-required:\" job in .github/workflows/ci.yml — " <>
            "the derive source for the merge-gate roster contract is broken"
        )
    end
  end

  defp ci_required_needs do
    block = ci_required_block()

    case Regex.run(~r/    needs:\n((?:      - .+\n)+)/, block) do
      [_, items] ->
        items
        |> String.split("\n", trim: true)
        |> Enum.map(&(&1 |> String.trim() |> String.trim_leading("- ")))

      nil ->
        []
    end
  end

  defp dialyzer_topology_errors(mix_exs, yaml, contributing) do
    job = workflow_job(yaml, "verify-dialyzer")
    no_optional_job = workflow_job(yaml, "verify-compile-no-optional")
    hit_step = workflow_step(yaml, "Report exact PLT cache hit")
    setup_beam_step = setup_beam_step(job)

    order = [
      position(job, "mix deps.get"),
      position(job, "mix compile --warnings-as-errors"),
      position(job, "/usr/bin/time -v -o \"$time_file\" mix dialyzer --plt"),
      position(job, "THREADLINE_DIALYZER_PLT_WALL_SECONDS="),
      position(job, "- name: Save Dialyzer PLT"),
      position(job, "/usr/bin/time -v -o \"$time_file\" mix dialyzer --no-check"),
      position(job, "THREADLINE_DIALYZER_ANALYSIS_WALL_SECONDS="),
      position(job, "run: mix verify.dialyzer_slice")
    ]

    [
      {mix_exs =~ ~s("verify.dialyzer": ["dialyzer --no-check"]),
       "verify.dialyzer must be the stable local no-check command"},
      {ci_all_entries(mix_exs)
       |> Enum.count(&(&1 == "cmd env MIX_ENV=dev mix verify.dialyzer")) == 1,
       "ci.all must invoke verify.dialyzer exactly once in the CI job's dev environment"},
      {Regex.match?(~r/^# Job id contract[^\n]*\n#[^\n]*verify-dialyzer/m, yaml),
       "workflow header roster must contain verify-dialyzer"},
      {String.contains?(yaml, "branches: [main]") and
         not String.contains?(yaml, "phase-199/scroll-cost-cause-fix"),
       "the temporary measurement-branch trigger must be removed after collection"},
      {job != "", "verify-dialyzer job must exist"},
      {String.contains?(job, "runs-on: ubuntu-24.04"),
       "verify-dialyzer must run on ubuntu-24.04"},
      {committed_toolchain_step?(setup_beam_step),
       "verify-dialyzer must install exactly the committed .tool-versions build (version-file, strict)"},
      {String.contains?(job, "timeout-minutes: 12") and
         String.contains?(job, "ceil((252 + 80) * 2 / 60) = 12") and
         String.contains?(job, "36258719902"),
       "Dialyzer timeout must retain the documented cold-run plus live-slice derivation"},
      {String.contains?(job, "uses: actions/cache/restore@"),
       "Dialyzer PLT restore must be a separate cache action"},
      {String.contains?(job, "id: dialyzer-plt-restore"),
       "PLT restore must expose a stable cache-hit id"},
      {String.contains?(job, "path: .dialyzer"), "PLT cache must use .dialyzer"},
      {String.contains?(job, @resolved_plt_prefix),
       "PLT cache and restore must retain exact runner/OTP/Elixir identity"},
      {String.contains?(job, "${{ hashFiles('mix.lock') }}") and
         String.contains?(job, "${{ hashFiles('mix.exs') }}"),
       "PLT key must include both mix.lock and mix.exs hashes"},
      {String.contains?(job, "uses: actions/cache/save@"),
       "Dialyzer PLT save must be a separate cache action"},
      {String.contains?(job, "steps.dialyzer-plt-restore.outputs.cache-primary-key"),
       "PLT save must reuse the restore action's exact primary key"},
      {String.contains?(job, "steps.dialyzer-plt-restore.outputs.cache-hit != 'true'"),
       "PLT build/save must be conditional on an exact-key miss"},
      {String.contains?(job, "steps.dialyzer-plt-restore.outputs.cache-hit == 'true'"),
       "the exact-key hit path must be explicit"},
      {String.contains?(job, "/usr/bin/time -v -o \"$time_file\" mix dialyzer --plt"),
       "PLT build must be timed independently"},
      {String.contains?(job, "/usr/bin/time -v -o \"$time_file\" mix dialyzer --no-check"),
       "analysis must be timed independently"},
      {String.contains?(job, "Unable to parse GNU time output"),
       "GNU time parsing must fail closed"},
      {String.contains?(job, "[[ \"$wall_seconds\" =~ ^[0-9]+([.][0-9]+)?$ ]]") and
         String.contains?(job, "[[ \"$max_rss_kb\" =~ ^[0-9]+$ ]]"),
       "measurement values must be normalized numeric fields"},
      {Enum.all?(
         [
           "THREADLINE_DIALYZER_PLT_CACHE=miss",
           "THREADLINE_DIALYZER_PLT_CACHE=hit",
           "THREADLINE_DIALYZER_PLT_WALL_SECONDS=",
           "THREADLINE_DIALYZER_PLT_MAX_RSS_KB=",
           "THREADLINE_DIALYZER_ANALYSIS_WALL_SECONDS=",
           "THREADLINE_DIALYZER_ANALYSIS_MAX_RSS_KB="
         ],
         &String.contains?(job, &1)
       ), "all stable cache and measurement markers must be emitted"},
      {ordered_positions?(order),
       "dependency fetch/compile, PLT timing, save, and analysis timing must stay ordered"},
      {not String.contains?(hit_step, "THREADLINE_DIALYZER_PLT_WALL_SECONDS=") and
         not String.contains?(hit_step, "THREADLINE_DIALYZER_PLT_MAX_RSS_KB="),
       "exact-key hits must not synthesize PLT-build measurements"},
      {not String.contains?(no_optional_job, "dialyzer"),
       "the no-optional lane must not run Dialyzer"},
      {ci_required_needs_from(yaml) |> Enum.count(&(&1 == "verify-dialyzer")) == 1,
       "ci-required must block on verify-dialyzer exactly once"},
      {String.contains?(contributing, "- `verify-dialyzer`") and
         String.contains?(contributing, "| `verify-dialyzer` | `mix verify.dialyzer`"),
       "CONTRIBUTING must document the aggregate edge and stable job key"},
      {Enum.all?(
         [
           "THREADLINE_DIALYZER_PLT_CACHE",
           "THREADLINE_DIALYZER_PLT_WALL_SECONDS",
           "THREADLINE_DIALYZER_PLT_MAX_RSS_KB",
           "THREADLINE_DIALYZER_ANALYSIS_WALL_SECONDS",
           "THREADLINE_DIALYZER_ANALYSIS_MAX_RSS_KB"
         ],
         &String.contains?(contributing, &1)
       ), "CONTRIBUTING must document the stable measurement field contract"},
      {Enum.all?(
         [
           "34642915672",
           "34643744220",
           "a4f21e7e89ed4f958bc4ff0bb48c796225496bdd",
           "20260907.300.1",
           "f8275246d287e483bdc4bea1cc53781d9076e21403d44c887c3adfedaabbb53a",
           "1025d27a2bd55968da5682d1654a62eff358df117b8d8a52e6c8ed034c0b7861",
           "THREADLINE_DIALYZER_PLT_WALL_SECONDS=152.82",
           "THREADLINE_DIALYZER_PLT_MAX_RSS_KB=2282540",
           "THREADLINE_DIALYZER_ANALYSIS_WALL_SECONDS=9.82",
           "THREADLINE_DIALYZER_ANALYSIS_MAX_RSS_KB=1023056",
           "THREADLINE_DIALYZER_ANALYSIS_WALL_SECONDS=9.42",
           "THREADLINE_DIALYZER_ANALYSIS_MAX_RSS_KB=1009288",
           "36258719902",
           "ceil((252 + 80) seconds × 2.0 / 60)",
           "= 12 minutes",
           "mix verify.dialyzer_slice",
           "drops no real coverage"
         ],
         &String.contains?(contributing, &1)
       ), "CONTRIBUTING must link the immutable miss/hit evidence and timeout formula"}
    ]
    |> Kernel.++(live_slice_checks(mix_exs, yaml, job))
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end

  # The live Dialyzer slice proof (plan 218-03): it runs only in verify-dialyzer, under
  # MIX_ENV=test with a postgres:16 service, is excluded from default `mix test`, and
  # ci.all runs it once, after the dev PLT exists.
  defp live_slice_checks(mix_exs, yaml, job) do
    live_slice_step = workflow_step(job, @live_slice_step_name)
    test_helper = read_rel!(["test", "test_helper.exs"])
    ci_all = ci_all_entries(mix_exs)
    ci_all_dialyzer = Enum.find_index(ci_all, &(&1 == "cmd env MIX_ENV=dev mix verify.dialyzer"))

    ci_all_slice =
      Enum.find_index(ci_all, &(&1 == "cmd env MIX_ENV=test mix verify.dialyzer_slice"))

    other_jobs_running_slice =
      for id <- workflow_job_ids(yaml),
          id != "verify-dialyzer",
          body = workflow_job(yaml, id),
          String.contains?(body, "verify.dialyzer_slice") or
            String.contains?(body, "live_dialyzer"),
          do: id

    [
      {live_slice_step != "" and
         String.contains?(live_slice_step, "MIX_ENV: test") and
         String.contains?(live_slice_step, "run: mix verify.dialyzer_slice"),
       "verify-dialyzer must run mix verify.dialyzer_slice under MIX_ENV: test"},
      {String.contains?(job, "    services:\n      postgres:\n        image: postgres:16\n"),
       "verify-dialyzer must carry a postgres:16 service for the live slice proof"},
      {other_jobs_running_slice == [],
       "only verify-dialyzer may run the live_dialyzer tag or verify.dialyzer_slice, found: " <>
         inspect(other_jobs_running_slice)},
      {String.contains?(test_helper, "live_dialyzer: true"),
       "test/test_helper.exs must exclude live_dialyzer from default mix test"},
      {Enum.count(ci_all, &(&1 == "cmd env MIX_ENV=test mix verify.dialyzer_slice")) == 1 and
         is_integer(ci_all_dialyzer) and is_integer(ci_all_slice) and
         ci_all_slice > ci_all_dialyzer,
       "ci.all must invoke the live slice proof exactly once, after the dev verify.dialyzer"}
    ]
  end

  defp ci_all_entries(mix_exs) do
    case Regex.run(~r/"ci\.all":\s*\[\s*\n((?:.*\n)*?)\s*\]/, mix_exs) do
      [_, block] -> Regex.scan(~r/"([^"]+)"/, block) |> Enum.map(&List.last/1)
      nil -> []
    end
  end

  defp ci_required_needs_from(yaml) do
    case Regex.run(~r/  ci-required:\n[\s\S]*?    needs:\n((?:      - .+\n)+)/, yaml) do
      [_, items] ->
        items
        |> String.split("\n", trim: true)
        |> Enum.map(&(&1 |> String.trim() |> String.trim_leading("- ")))

      nil ->
        []
    end
  end

  defp workflow_job_ids(yaml) do
    case String.split(yaml, "\njobs:\n", parts: 2) do
      [_, jobs] -> ~r/^  ([a-z][a-z0-9-]+):\n/m |> Regex.scan(jobs) |> Enum.map(&List.last/1)
      _ -> []
    end
  end

  defp workflow_job(yaml, id) do
    case Regex.run(~r/^  #{Regex.escape(id)}:\n([\s\S]*?)(?=^  [a-z][a-z0-9-]+:\n|\z)/m, yaml) do
      [full, _body] -> full
      nil -> ""
    end
  end

  # The job's setup-beam step: from its `- uses: erlef/setup-beam@` line up to
  # the next step.
  defp setup_beam_step(job) do
    case Regex.run(~r/^      - uses: erlef\/setup-beam@[^\n]*\n[\s\S]*?(?=^      - |\z)/m, job) do
      [step] -> step
      nil -> ""
    end
  end

  defp committed_toolchain_step?(step) do
    lines = step |> strip_comment_lines() |> String.split("\n") |> Enum.map(&String.trim/1)

    step != "" and "id: beam" in lines and "version-file: .tool-versions" in lines and
      "version-type: strict" in lines and
      not Enum.any?(
        lines,
        &(String.starts_with?(&1, "otp-version:") or String.starts_with?(&1, "elixir-version:"))
      )
  end

  defp workflow_step(yaml, name) do
    case Regex.run(
           ~r/^      - name: #{Regex.escape(name)}\n([\s\S]*?)(?=^      - (?:name:|uses:)|^  [a-z][a-z0-9-]+:\n|\z)/m,
           yaml
         ) do
      [full, _body] -> full
      nil -> ""
    end
  end

  defp position(source, needle) do
    case :binary.match(source, needle) do
      {position, _length} -> position
      :nomatch -> nil
    end
  end

  defp ordered_positions?(positions) do
    Enum.all?(positions, &is_integer/1) and positions == Enum.sort(positions)
  end

  defp strip_comment_lines(block) do
    block
    |> String.split("\n")
    |> Enum.reject(&String.match?(&1, ~r/^\s*#/))
    |> Enum.join("\n")
  end

  defp documented_needs_section do
    contributing = read_rel!(["CONTRIBUTING.md"])

    assert String.contains?(contributing, @ci_required_roster_heading),
           "CONTRIBUTING.md has no \"#{@ci_required_roster_heading}\" heading — the " <>
             "documented side of the merge-gate roster contract is missing entirely."

    contributing
    |> String.split(@ci_required_roster_heading, parts: 2)
    |> List.last()
    |> String.split(~r/\n#+ /, parts: 2)
    |> List.first()
  end

  defp documented_needs_roster do
    documented_needs_section()
    |> then(&Regex.scan(~r/^- `([a-z0-9-]+)`$/m, &1))
    |> Enum.map(fn [_, id] -> id end)
  end

  test "ci-required's needs: roster matches CONTRIBUTING.md in both drift directions and stays non-vacuous" do
    actual = ci_required_needs()
    documented = documented_needs_roster()

    assert length(actual) >= 10,
           "ci-required's derived needs: list has only #{length(actual)} entr" <>
             "#{if length(actual) == 1, do: "y", else: "ies"} (#{inspect(actual)}) — fewer " <>
             "than ten is a broken derive, not a real narrowing, and must fail loudly rather " <>
             "than silently asserting nothing while still reporting success."

    missing_from_docs = actual -- documented

    assert missing_from_docs == [],
           "ci-required requires #{inspect(missing_from_docs)} but CONTRIBUTING.md's " <>
             "\"#{@ci_required_roster_heading}\" roster omits it — the docs have drifted " <>
             "behind the pipeline."

    undocumented_extra = documented -- actual

    assert undocumented_extra == [],
           "CONTRIBUTING.md's \"#{@ci_required_roster_heading}\" roster claims " <>
             "#{inspect(undocumented_extra)} but ci-required no longer requires it in " <>
             ".github/workflows/ci.yml — this is the silent-narrowing case D-42 exists to " <>
             "catch: a needs: entry was removed without a matching documented roster edit."

    stripped = strip_comment_lines(ci_required_block())

    if Regex.match?(~r/^\s*allowed-skips:/m, stripped) or
         Regex.match?(~r/^\s*allowed-failures:/m, stripped) do
      section = documented_needs_section()

      assert String.contains?(section, "allowed-skips decision:") or
               String.contains?(section, "allowed-failures decision:"),
             "ci-required's alls-green step now carries allowed-skips or allowed-failures, " <>
               "but the \"#{@ci_required_roster_heading}\" section records no decision " <>
               "citation for it — an allowed failure launders a red lane into a green gate " <>
               "(D-09) and must be documented, not silently introduced."
    end
  end

  # --- Plan 202-10: the bump-rehearsal gate cannot be silently deleted ------
  #
  # Every born-red cause Phase 202 found was GREEN at the current version and
  # observable only under a simulated bump. That is exactly why nothing else in
  # this suite would notice if `verify-bump-rehearsal` were dropped from
  # `ci.yml` or quietly moved onto an allowed-skips list: the tree would stay
  # green right up to the publish gate, which is the failure mode the job
  # exists to remove. A gate that can be deleted in one YAML edit is not a
  # gate, so its wiring is asserted from source here in every direction that
  # could weaken it.
  @bump_rehearsal_job "verify-bump-rehearsal"

  defp candidate_rehearsal_result(subject, message_body, bump_minor_pre_major \\ false) do
    config_path =
      Path.join(
        System.tmp_dir!(),
        "threadline-release-config-#{System.unique_integer([:positive, :monotonic])}.json"
      )

    File.write!(
      config_path,
      Jason.encode!(%{"bump-minor-pre-major" => bump_minor_pre_major})
    )

    on_exit(fn -> File.rm(config_path) end)

    command =
      ~s(source "$REHEARSAL_SCRIPT"; candidate_release_target "$SUBJECT" "$MESSAGE_BODY" "$RELEASE_CONFIG")

    System.cmd(
      "bash",
      ["-c", command],
      env: [
        {"REHEARSAL_SCRIPT", Path.join(@repo_root, "bin/verify-bump-rehearsal")},
        {"SUBJECT", subject},
        {"MESSAGE_BODY", message_body},
        {"RELEASE_CONFIG", config_path}
      ],
      cd: @repo_root,
      stderr_to_stdout: true
    )
  end

  # Collects the items of every `allowed-skips:` / `allowed-failures:` list in
  # the workflow, comments stripped so a commented-out example (the
  # `ci-required` extension-point note is exactly that) is never mistaken for a
  # live entry.
  defp allowed_skip_or_failure_items(yaml) do
    yaml
    |> strip_comment_lines()
    |> then(&Regex.scan(~r/^\s*allowed-(?:skips|failures):\s*\n((?:\s*- .+\n)*)/m, &1))
    |> Enum.flat_map(fn [_, items] -> String.split(items, "\n", trim: true) end)
    |> Enum.map(&(&1 |> String.trim() |> String.trim_leading("- ")))
  end

  test "the bump-rehearsal gate is wired, required, and never skip-listed" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])
    mix_exs = read_rel!(["mix.exs"])
    rehearsal = read_rel!(["bin", "verify-bump-rehearsal"])

    job = workflow_job(yaml, @bump_rehearsal_job)

    assert job != "",
           "#{@bump_rehearsal_job} is gone from .github/workflows/ci.yml. It is the only " <>
             "check that observes the release-commit state, where every born-red cause " <>
             "Phase 202 found lives; removing it restores the four-plans-late discovery."

    assert String.contains?(job, "mix verify.bump_rehearsal"),
           "#{@bump_rehearsal_job} no longer runs `mix verify.bump_rehearsal`, so the job " <>
             "can report green without rehearsing anything."

    refute String.contains?(job, "THREADLINE_BUMP_REHEARSAL_MODE"),
           "ordinary pull-request CI must leave candidate mode unset so the generic " <>
             "next-minor rehearsal remains runnable before the 1.0 candidate exists."

    assert String.contains?(rehearsal, "THREADLINE_BUMP_REHEARSAL_MODE:-generic"),
           "the rehearsal must default to generic mode for ordinary CI invocations."

    refute Regex.match?(~r/^    if:/m, job),
           "#{@bump_rehearsal_job} acquired a job-level `if:`. A conditionally skipped " <>
             "member of ci-required needs an allowed-skips entry to keep the aggregate " <>
             "green, which is the laundering path this contract exists to block."

    assert Regex.match?(~r/^# Job id contract[^\n]*\n#[^\n]*#{@bump_rehearsal_job}/m, yaml),
           "the job-id contract header no longer lists #{@bump_rehearsal_job}; the roster " <>
             "of stable keys has drifted from the jobs that exist."

    assert @bump_rehearsal_job in ci_required_needs(),
           "#{@bump_rehearsal_job} is not in ci-required's needs:. Outside the single " <>
             "required check it is advisory, and an advisory red is exactly what a " <>
             "contributor merges past on the way to a born-red release."

    refute @bump_rehearsal_job in allowed_skip_or_failure_items(yaml),
           "#{@bump_rehearsal_job} appears in an allowed-skips or allowed-failures list. " <>
             "That launders a red release rehearsal into a green merge gate (D-09)."

    assert String.contains?(mix_exs, "\"verify.bump_rehearsal\": &verify_bump_rehearsal/1"),
           "mix.exs no longer declares the `verify.bump_rehearsal` alias the CI job cites."

    assert String.contains?(mix_exs, "bin/verify-bump-rehearsal"),
           "the `verify.bump_rehearsal` alias no longer invokes bin/verify-bump-rehearsal."

    [_, ci_all_block] = String.split(mix_exs, "\"ci.all\": [")
    [ci_all_list | _] = String.split(ci_all_block, "]")

    refute String.contains?(ci_all_list, "\"verify.bump_rehearsal\""),
           "verify.bump_rehearsal was folded into ci.all. It is a release-lane check and " <>
             "follows verify.release's precedent of staying out of the per-change gate."
  end

  test "strict candidate parser accepts one 1.0.0 footer only with a feat! subject and JSON false" do
    assert {"1.0.0\n", 0} =
             candidate_rehearsal_result(
               "feat!: establish the 1.0 API contract",
               "Candidate release notes.\n\nRelease-As: 1.0.0"
             )

    assert {"1.0.0\n", 0} =
             candidate_rehearsal_result(
               "feat!: establish the 1.0 API contract",
               "Release-As: 1.0.0"
             )

    assert {"1.0.0\n", 0} =
             candidate_rehearsal_result(
               "feat(api)!: establish the 1.0 API contract",
               "Candidate release notes.\n\nRelease-As: 1.0.0"
             )

    invalid_candidates = [
      {"non-feat subject", "fix!: correct release metadata", "Release-As: 1.0.0", false},
      {"missing footer", "feat!: establish the 1.0 API contract", "Candidate release notes.",
       false},
      {
        "duplicate footer",
        "feat!: establish the 1.0 API contract",
        "Release-As: 1.0.0\nRelease-As: 1.0.0",
        false
      },
      {
        "malformed footer",
        "feat!: establish the 1.0 API contract",
        "Release-As: 1.0.0 extra",
        false
      },
      {
        "Release-As-looking body prose before later text",
        "feat!: establish the 1.0 API contract",
        "Candidate notes.\n\nRelease-As: 1.0.0\n\nThis is more body prose, not a trailer.",
        false
      },
      {
        "0.13.0 target",
        "feat!: establish the 1.0 API contract",
        "Release-As: 0.13.0",
        false
      },
      {
        "pre-major config still true",
        "feat!: establish the 1.0 API contract",
        "Release-As: 1.0.0",
        true
      },
      {
        "pre-major config is not a JSON boolean",
        "feat!: establish the 1.0 API contract",
        "Release-As: 1.0.0",
        "false"
      }
    ]

    for {case_name, subject, body, config_value} <- invalid_candidates do
      {output, status} = candidate_rehearsal_result(subject, body, config_value)

      assert status != 0,
             "candidate parser accepted #{case_name}; expected a fail-closed result, got #{inspect(output)}"
    end
  end

  # --- Plan 218-04: removed CI proofs stay justified and dominated ---------
  #
  # A proof leaves CI only when another job catches its failure class on the same
  # triggers, or as a deliberate, recorded coverage cut (246 D-02: verify-capture
  # and the mechanical floor). Each removal carries a "still caught by" bullet in
  # CONTRIBUTING.md and a `# Removed:` comment in ci.yml, so no cut is silent.
  @removed_proofs_heading "### Removed CI proofs and what still catches them"
  @removed_job_ids ["verify-mechanical", "verify-docs", "verify-hex-package", "verify-capture"]

  defp removed_proof_bullets(contributing) do
    case String.split(contributing, @removed_proofs_heading, parts: 2) do
      [_, tail] ->
        tail
        |> String.split(~r/\n#+ /, parts: 2)
        |> List.first()
        |> String.split("\n")
        |> Enum.filter(&String.starts_with?(&1, "- "))

      _ ->
        []
    end
  end

  defp justified_removal?(contributing, needle) do
    contributing
    |> removed_proof_bullets()
    |> Enum.any?(&(String.contains?(&1, "still caught by") and String.contains?(&1, needle)))
  end

  defp header_roster(yaml) do
    case Regex.run(~r/^# Job id contract[^\n]*\n# ([^\n]*)/m, yaml) do
      [_, line] -> String.split(line, ", ")
      nil -> []
    end
  end

  # Each removed job id is gone from every roster (job keys, header, ci-required
  # needs:) and leaves both a `# Removed:` comment in ci.yml and a "still caught
  # by" bullet in CONTRIBUTING.md.
  defp removed_job_checks(yaml, contributing) do
    job_ids = workflow_job_ids(yaml)
    header = header_roster(yaml)
    needs = ci_required_needs_from(yaml)

    Enum.flat_map(@removed_job_ids, fn id ->
      [
        {id not in job_ids and id not in header and id not in needs,
         "#{id} was removed as a dominated proof but is back in ci.yml's job keys, " <>
           "header roster or ci-required needs:"},
        {String.contains?(yaml, "# Removed: #{id}"),
         "ci.yml lost the `# Removed: #{id}` comment that says what still catches it"},
        {justified_removal?(contributing, "`#{id}`"),
         "CONTRIBUTING.md has no \"still caught by\" bullet naming `#{id}`, so its " <>
           "removal no longer says which job catches its failure class"}
      ]
    end)
  end

  defp removed_proof_errors(yaml, contributing) do
    [
      {String.contains?(contributing, @removed_proofs_heading),
       "CONTRIBUTING.md lost the \"#{@removed_proofs_heading}\" section, so the removed " <>
         "proofs no longer say what still catches their failure class"}
    ]
    |> Kernel.++(removed_job_checks(yaml, contributing))
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end

  defp removed_job_bullet(contributing, needle) do
    contributing
    |> removed_proof_bullets()
    |> Enum.find(
      &(String.contains?(&1, "still caught by") and String.starts_with?(&1, "- " <> needle))
    )
  end

  test "removed CI proofs stay justified and dominated" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])
    contributing = read_rel!(["CONTRIBUTING.md"])

    assert removed_proof_errors(yaml, contributing) == []

    for {label, bullet} <- [
          {"verify-docs", removed_job_bullet(contributing, "`verify-docs`")},
          {"verify-hex-package", removed_job_bullet(contributing, "`verify-hex-package`")},
          {"verify-mechanical", removed_job_bullet(contributing, "`verify-mechanical`")},
          {"verify-capture", removed_job_bullet(contributing, "`verify-capture`")}
        ] do
      assert is_binary(bullet), "the #{label} bullet must exist to mutate"
      contributing_without_bullet = String.replace(contributing, bullet <> "\n", "")
      refute contributing_without_bullet == contributing

      refute removed_proof_errors(yaml, contributing_without_bullet) == [],
             "dropping the #{label} bullet must make the removed-proof contract fail"
    end

    readded =
      String.replace(
        yaml,
        "      - verify-bump-rehearsal\n",
        "      - verify-bump-rehearsal\n      - verify-docs\n"
      )

    refute readded == yaml

    refute removed_proof_errors(readded, contributing) == [],
           "re-adding a removed job to ci-required needs: must make the contract fail"

    capture_readded =
      String.replace(
        yaml,
        "      - verify-example-browser\n",
        "      - verify-example-browser\n      - verify-capture\n"
      )

    refute capture_readded == yaml

    refute removed_proof_errors(capture_readded, contributing) == [],
           "re-adding verify-capture to ci-required needs: must make the contract fail"

    for id <- ["verify-hex-package", "verify-capture"] do
      uncommented = String.replace(yaml, "# Removed: #{id}", "# #{id}")
      refute uncommented == yaml, "the `# Removed: #{id}` comment must exist to mutate"

      refute removed_proof_errors(uncommented, contributing) == [],
             "dropping the `# Removed: #{id}` comment must make the contract fail"
    end
  end

  # --- Plan 218-04: the proofs that dominate the removed jobs stay in force ---
  #
  # verify-docs and verify-hex-package left CI because verify-bump-rehearsal
  # (through mix verify.release) and verify-hex-evaluator catch the same failure
  # classes on the same triggers. These pins make that dominance impossible to
  # lapse silently.
  @dominators ["verify-bump-rehearsal", "verify-hex-evaluator"]

  defp verify_release_body(mix_exs) do
    case Regex.run(~r/  defp verify_release\(_args\) do\n([\s\S]*?)\n  end\n/, mix_exs) do
      [_, body] -> body
      nil -> ""
    end
  end

  defp workflow_triggers(yaml) do
    case Regex.run(~r/^on:\n((?:(?:  .*|\s*)\n)+?)(?=^\S)/m, yaml) do
      [_, block] -> strip_comment_lines(block)
      nil -> ""
    end
  end

  defp dominance_errors(mix_exs, yaml, rehearsal) do
    release = verify_release_body(mix_exs)
    triggers = workflow_triggers(yaml)
    needs = ci_required_needs_from(yaml)
    skip_listed = allowed_skip_or_failure_items(yaml)

    dominator_checks =
      Enum.flat_map(@dominators, fn id ->
        job = workflow_job(yaml, id)

        [
          {job != "" and id in needs and id not in skip_listed,
           "#{id} must exist and sit in ci-required's needs: (never skip-listed). It is " <>
             "what catches the failure classes of the removed verify-docs / " <>
             "verify-hex-package jobs; outside the required gate those breaks merge unseen"},
          {job != "" and not Regex.match?(~r/^    if:/m, job),
           "#{id} acquired a job-level if:. A dominator that does not run on every " <>
             "trigger the removed job ran on no longer dominates it"}
        ]
      end)

    [
      {String.contains?(release, ~s("MIX_ENV=dev mix docs --warnings-as-errors")),
       "verify-docs was removed because verify.release builds ExDoc with " <>
         "--warnings-as-errors; without it an ExDoc break reaches release unseen"},
      {String.contains?(release, ~s("mix hex.build")),
       "verify-hex-package was removed because verify.release runs mix hex.build; " <>
         "without it a broken Hex package reaches release unseen"},
      {String.contains?(
         workflow_job(yaml, "verify-bump-rehearsal"),
         "run: mix verify.bump_rehearsal"
       ), "verify-bump-rehearsal must run mix verify.bump_rehearsal, which runs verify.release"},
      {Regex.match?(~r/^\s*run_gate\s+"[^"]*"\s+mix verify\.release\b/m, rehearsal),
       "bin/verify-bump-rehearsal must run an uncommented `run_gate ... mix verify.release` " <>
         "gate; without it the ExDoc and hex.build proofs of the removed verify-docs / " <>
         "verify-hex-package jobs leave per-PR CI while every other pin stays green"},
      {String.contains?(
         workflow_job(yaml, "verify-hex-evaluator"),
         "run: mix verify.hex_evaluator"
       ),
       "verify-hex-evaluator must run mix verify.hex_evaluator, which builds, resolves, " <>
         "compiles and tests the tarball from this tree"},
      {String.contains?(
         mix_exs,
         ~s|System.get_env("THREADLINE_HEX_EVALUATOR_MODE", "rehearsal")|
       ),
       "verify.hex_evaluator must default to rehearsal mode; the published mode resolves " <>
         "hex.pm instead of this tree, so a tarball without a usable lib/ goes unseen"},
      {not String.contains?(yaml, "THREADLINE_HEX_EVALUATOR_MODE"),
       "ci.yml must not set THREADLINE_HEX_EVALUATOR_MODE; the evaluator must test this " <>
         "tree's tarball on every CI run"},
      {String.contains?(triggers, "  push:\n    branches: [main]\n") and
         String.contains?(triggers, "  pull_request:\n    branches: [main]\n") and
         String.contains?(triggers, "  workflow_dispatch:") and
         not String.contains?(triggers, "paths"),
       "ci.yml must trigger on push to main, pull_request to main and workflow_dispatch " <>
         "with no paths: filter; the removed jobs ran on exactly that set"}
    ]
    |> Kernel.++(dominator_checks)
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end

  test "dominating proofs for removed jobs stay in force" do
    mix_exs = read_rel!(["mix.exs"])
    yaml = read_rel!([".github", "workflows", "ci.yml"])
    rehearsal = read_rel!(["bin", "verify-bump-rehearsal"])

    assert dominance_errors(mix_exs, yaml, rehearsal) == []

    mix_controls = [
      {"ExDoc build dropped from verify.release",
       String.replace(mix_exs, ~s("MIX_ENV=dev mix docs --warnings-as-errors",\n), "")},
      {"hex.build dropped from verify.release",
       String.replace(mix_exs, ~s(,\n      "mix hex.build"\n), "\n")},
      {"evaluator default mode changed",
       String.replace(
         mix_exs,
         ~s|System.get_env("THREADLINE_HEX_EVALUATOR_MODE", "rehearsal")|,
         ~s|System.get_env("THREADLINE_HEX_EVALUATOR_MODE", "published")|
       )}
    ]

    yaml_controls = [
      {"verify-bump-rehearsal dropped from ci-required needs",
       String.replace(yaml, "      - verify-bump-rehearsal\n", "")},
      {"verify-hex-evaluator dropped from ci-required needs",
       String.replace(yaml, "      - verify-hex-evaluator\n", "")},
      {"job-level if on verify-hex-evaluator",
       String.replace(
         yaml,
         "  verify-hex-evaluator:\n    name: ",
         "  verify-hex-evaluator:\n    if: github.event_name == 'push'\n    name: "
       )},
      {"job-level if on verify-bump-rehearsal",
       String.replace(
         yaml,
         "  verify-bump-rehearsal:\n    name: ",
         "  verify-bump-rehearsal:\n    if: github.event_name == 'push'\n    name: "
       )},
      {"evaluator mode forced to published in ci.yml",
       String.replace(
         yaml,
         "  verify-hex-evaluator:\n    name: ",
         "  verify-hex-evaluator:\n    env:\n      THREADLINE_HEX_EVALUATOR_MODE: published\n    name: "
       )},
      {"pull_request trigger dropped",
       String.replace(yaml, "  pull_request:\n    branches: [main]\n", "")}
    ]

    for {control, mutated} <- mix_controls do
      refute mutated == mix_exs, "#{control} control did not change the input"

      refute dominance_errors(mutated, yaml, rehearsal) == [],
             "#{control} mutation must make the dominance contract fail"
    end

    for {control, mutated} <- yaml_controls do
      refute mutated == yaml, "#{control} control did not change the input"

      refute dominance_errors(mix_exs, mutated, rehearsal) == [],
             "#{control} mutation must make the dominance contract fail"
    end

    # 218 review WR-04: the chain's third link (the rehearsal runs verify.release).
    rehearsal_controls = [
      {"verify.release gate removed from the rehearsal",
       String.replace(
         rehearsal,
         ~s(  run_gate "mix verify.release at $NEXT" mix verify.release || true\n),
         "  true\n"
       )},
      {"verify.release gate commented out",
       String.replace(
         rehearsal,
         ~s(  run_gate "mix verify.release at $NEXT" mix verify.release || true\n),
         ~s(  true # run_gate "mix verify.release at $NEXT" mix verify.release\n)
       )}
    ]

    for {control, mutated} <- rehearsal_controls do
      refute mutated == rehearsal, "#{control} control did not change the input"

      refute dominance_errors(mix_exs, yaml, mutated) == [],
             "#{control} mutation must make the dominance contract fail"
    end
  end

  # 15368 is the GitHub Actions app. A required check without an integration_id
  # accepts the context from any app or any token that can write commit statuses.
  defp pinned_required_checks?(contexts),
    do: contexts == [%{"context" => "CI required", "integration_id" => 15_368}]

  test "the ruleset's sole required status check is byte-exact with ci-required's emitted name" do
    ruleset =
      [".github", "rulesets", "main.json"]
      |> read_rel!()
      |> Jason.decode!()

    required_status_checks_rule =
      Enum.find(ruleset["rules"], fn rule -> rule["type"] == "required_status_checks" end)

    refute is_nil(required_status_checks_rule),
           ".github/rulesets/main.json has no required_status_checks rule at all"

    contexts = required_status_checks_rule["parameters"]["required_status_checks"]

    assert length(contexts) == 1,
           "expected exactly one required status check context in " <>
             ".github/rulesets/main.json, found #{length(contexts)}: #{inspect(contexts)}. " <>
             "A second required context reintroduces the enumeration hazard D-08 replaced " <>
             "with a single aggregate gate."

    assert pinned_required_checks?(contexts),
           "expected the ruleset's sole required check to be exactly " <>
             ~s(%{"context" => "CI required", "integration_id" => 15368}, got ) <>
             "#{inspect(contexts)}. 15368 is the GitHub Actions app: without the pin, any app " <>
             "or any token that can write commit statuses can satisfy `CI required`."

    # In-memory mutation control: stripping the pin must fail the same equality.
    stripped = Enum.map(contexts, &Map.delete(&1, "integration_id"))
    refute stripped == contexts, "the stripped-id control did not change the input"

    refute pinned_required_checks?(stripped),
           "an unpinned required check must not satisfy the pinned-ruleset assertion"

    [%{"context" => context}] = contexts

    assert context === "CI required",
           "expected the ruleset's required status check context to be the exact literal " <>
             "\"CI required\", got #{inspect(context)} — GitHub matches required checks on " <>
             "exact string, never case-insensitively or trimmed."

    yaml = read_rel!([".github", "workflows", "ci.yml"])

    job_name =
      case Regex.run(~r/\n  ci-required:\n    name: (.+)\n/, yaml) do
        [_, name] -> name
        nil -> flunk("could not find ci-required's \"    name:\" line in ci.yml")
      end

    assert job_name === context,
           "ci-required's emitted name: (#{inspect(job_name)}) no longer matches the " <>
             "ruleset's sole required context (#{inspect(context)}) — GitHub matches " <>
             "required checks on the exact emitted job name (D-08), so this mismatch would " <>
             "make the required check permanently unsatisfiable."
  end

  # --- Plan 224-03: bench compiles bare via preferred_envs, proven in an existing
  # per-PR CI job (SUITE-05, D-13..D-17) ---

  defp bench_compile_errors(bench_mix, mix_exs, yaml) do
    ci_all = ci_all_entries(mix_exs)
    no_optional_idx = Enum.find_index(ci_all, &(&1 == "verify.compile_no_optional"))
    bench_idx = Enum.find_index(ci_all, &(&1 == "verify.bench_compile"))
    bench_count = Enum.count(ci_all, &(&1 == "verify.bench_compile"))

    job = workflow_job(yaml, "verify-compile-no-optional")
    no_optional_run_pos = position(job, "run: mix verify.compile_no_optional")
    bench_run_pos = position(job, "run: mix verify.bench_compile")

    other_jobs_with_bench_step =
      for id <- workflow_job_ids(yaml),
          id != "verify-compile-no-optional",
          String.contains?(workflow_job(yaml, id), "mix verify.bench_compile"),
          do: id

    verify_bench_compile_def =
      case Regex.run(~r/defp verify_bench_compile.*?\n  end\n/s, mix_exs) do
        [def_text] -> strip_comment_lines(def_text)
        nil -> ""
      end

    [
      {String.contains?(bench_mix, "def cli") and
         String.contains?(bench_mix, "preferred_envs: [compile: :test, run: :test]"),
       "bench/mix.exs must define def cli with preferred_envs: [compile: :test, run: :test]"},
      {bench_count == 1,
       "ci.all must contain \"verify.bench_compile\" exactly once, found #{bench_count}"},
      {not is_nil(no_optional_idx) and not is_nil(bench_idx) and
         bench_idx == no_optional_idx + 1,
       "\"verify.bench_compile\" must directly follow \"verify.compile_no_optional\" in ci.all"},
      {job != "", "the verify-compile-no-optional job is missing from ci.yml"},
      {not is_nil(no_optional_run_pos) and not is_nil(bench_run_pos) and
         bench_run_pos > no_optional_run_pos,
       "verify-compile-no-optional must run mix verify.bench_compile after " <>
         "mix verify.compile_no_optional"},
      {other_jobs_with_bench_step == [],
       "mix verify.bench_compile must not run in any other job, found: " <>
         inspect(other_jobs_with_bench_step)},
      {verify_bench_compile_def != "", "verify_bench_compile/1 is missing from mix.exs"},
      {String.contains?(verify_bench_compile_def, "unset MIX_ENV"),
       "verify_bench_compile/1 must unset MIX_ENV"},
      {not String.contains?(verify_bench_compile_def, "MIX_ENV="),
       "verify_bench_compile/1 must not set MIX_ENV= anywhere in its command"}
    ]
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end

  test "bench compiles bare via preferred_envs and is proven in the no-optional CI job (SUITE-05)" do
    bench_mix = read_rel!(["bench", "mix.exs"])
    mix_exs = read_rel!(["mix.exs"])
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    assert bench_compile_errors(bench_mix, mix_exs, yaml) == []

    other_job_anchor = "      - name: Ensure hex_evaluator_test database exists\n"
    assert String.contains?(yaml, other_job_anchor), "the mutation anchor must exist to mutate"

    mutation_controls = [
      {"preferred_envs removed from bench/mix.exs",
       String.replace(
         bench_mix,
         "def cli, do: [preferred_envs: [compile: :test, run: :test]]\n",
         ""
       ), mix_exs, yaml},
      {"verify.bench_compile removed from ci.all", bench_mix,
       String.replace(mix_exs, "\"verify.bench_compile\",\n", ""), yaml},
      {"verify.bench_compile moved after verify.test in ci.all", bench_mix,
       String.replace(
         mix_exs,
         "\"verify.bench_compile\",\n        \"verify.test\",\n",
         "\"verify.test\",\n        \"verify.bench_compile\",\n"
       ), yaml},
      {"run: mix verify.bench_compile removed from the CI step", bench_mix, mix_exs,
       String.replace(
         yaml,
         "      - name: Compile bench project (bare mix compile)\n        run: mix verify.bench_compile\n\n",
         ""
       )},
      {"the bench compile step also runs in another job", bench_mix, mix_exs,
       String.replace(
         yaml,
         other_job_anchor,
         "      - name: Compile bench project (bare mix compile)\n        run: mix verify.bench_compile\n\n" <>
           other_job_anchor
       )},
      {"MIX_ENV= appears in verify_bench_compile/1's command", bench_mix,
       String.replace(mix_exs, "unset MIX_ENV", "MIX_ENV=dev"), yaml}
    ]

    for {control, bmix, mexs, y} <- mutation_controls do
      refute {bmix, mexs, y} == {bench_mix, mix_exs, yaml},
             "#{control} control did not change the input"

      errors = bench_compile_errors(bmix, mexs, y)

      assert errors != [],
             "#{control} mutation must make the bench_compile_errors contract fail, got: " <>
               inspect(errors)
    end
  end
end
