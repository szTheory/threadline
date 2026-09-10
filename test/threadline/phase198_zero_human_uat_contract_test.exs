defmodule Threadline.Phase198ZeroHumanUatContractTest do
  use ExUnit.Case, async: false

  @phase_dir ".planning/phases/198-green-bringup"
  @manifest ".planning/audits/198-summary-coverage-manifest.json"
  @delta ".planning/audits/198-plan46-coverage-delta.json"
  @baseline_numbers Enum.map(1..47, &(Integer.to_string(&1) |> String.pad_leading(2, "0")))
  @closeout_start 48
  @audited_final_plan_number 61
  @terminal_certification_plan_number 62
  @closeout_numbers Enum.map(@closeout_start..@audited_final_plan_number, &Integer.to_string/1)
  @final_state_numbers @baseline_numbers ++ @closeout_numbers
  @terminal_certification_number Integer.to_string(@terminal_certification_plan_number)
  @post_terminal_numbers ~w(63 64 65)
  @policy_repair_number "66"
  @plan46_numbers Enum.map(1..45, &(Integer.to_string(&1) |> String.pad_leading(2, "0")))
  @exact_delta MapSet.new([
                 "198-01:D4",
                 "198-03:D7",
                 "198-04:D8",
                 "198-05:D2",
                 "198-05:D5",
                 "198-05:D7",
                 "198-06:D3",
                 "198-06:D4",
                 "198-07:D3",
                 "198-12:D5",
                 "198-18:D3",
                 "198-27:D3",
                 "198-29:D3",
                 "198-31:D4",
                 "198-37:D4"
               ])

  test "immutable summaries 01-47 match the repository-owned manifest" do
    manifest = read_json!(@manifest)
    assert manifest["scope"] == "phase-198-only"
    assert manifest["general_classifier_owner"] == "phase-199"
    assert @audited_final_plan_number == 61
    assert @terminal_certification_plan_number == 62
    assert manifest["baseline_numbers"] == @baseline_numbers
    assert manifest["audited_final_plan_number"] == @audited_final_plan_number
    assert manifest["terminal_certification_plan_number"] == @terminal_certification_plan_number
    assert manifest["allowed_closeout_numbers"] == @closeout_numbers
    assert manifest["final_state_numbers"] == @final_state_numbers

    assert_manifest_namespace!(manifest)

    assert manifest["baseline_counts"] == %{
             "automated_passes" => 192,
             "coverage_entries" => 192,
             "errors" => 0,
             "present" => 0,
             "summaries" => 47
           }

    expected = Map.new(manifest["summaries"], &{&1["number"], &1})
    assert expected |> Map.keys() |> Enum.sort() == @baseline_numbers

    actual_entry_count =
      Enum.sum(
        for number <- @baseline_numbers,
            do: summary_path(number) |> File.read!() |> coverage_entries() |> map_size()
      )

    assert actual_entry_count == manifest["baseline_counts"]["coverage_entries"]
    assert actual_entry_count == 192

    for number <- @baseline_numbers do
      relative = summary_path(number)
      body = File.read!(relative)
      entries = coverage_entries(body)
      record = Map.fetch!(expected, number)

      assert record["path"] == relative
      assert record["sha256"] == digest(body), "#{relative} changed"
      assert record["coverage_ids"] == entries |> Map.keys() |> Enum.sort()
      assert record["verification_state_sha256"] == verification_digest(entries)
      assert coverage_errors(entries, relative) == []
    end
  end

  test "manifest declares the exact content-bound post-terminal repair policy" do
    manifest = read_json!(@manifest)
    assert_post_terminal_policy!(manifest)

    assert Map.keys(manifest) |> Enum.sort() ==
             Enum.sort([
               "schema_version",
               "scope",
               "general_classifier_owner",
               "audited_final_plan_number",
               "terminal_certification_plan_number",
               "baseline_numbers",
               "allowed_closeout_numbers",
               "final_state_numbers",
               "baseline_counts",
               "summaries",
               "post_terminal_policy"
             ])
  end

  test "summary discovery rejects missing, renamed, modified, and out-of-namespace files" do
    mode = if System.get_env("PHASE198_SUMMARY_SET") == "final", do: :final, else: :normal
    assert validate_summary_set!(@phase_dir, mode) == :ok
  end

  test "every present closeout summary is independently automated and valid" do
    for number <- @closeout_numbers ++ [@terminal_certification_number],
        path = summary_path(number),
        File.regular?(path) do
      entries = path |> File.read!() |> coverage_entries()
      assert coverage_errors(entries, path) == []
    end
  end

  test "summaries 53 through 55 are valid members of the exact closeout namespace" do
    assert Enum.all?(~w(53 54 55), &(&1 in @closeout_numbers))

    for number <- ~w(53 54 55) do
      path = summary_path(number)
      assert File.regular?(path)
      assert path |> File.read!() |> coverage_entries() |> coverage_errors(path) == []
    end
  end

  test "isolated discovery fixtures enforce audited final timing and the sole Plan 62 exception" do
    root = phase_fixture!()
    on_exit(fn -> File.rm_rf!(root) end)

    assert validate_summary_set!(root, :normal) == :ok

    assert_raise ExUnit.AssertionError, ~r/missing audited.*56.*57.*58.*59.*60.*61/s, fn ->
      validate_summary_set!(root, :final)
    end

    for number <- 56..61, do: write_summary!(root, Integer.to_string(number), "[]")
    write_repair_summary!(root)
    assert validate_summary_set!(root, :final) == :ok

    File.rm!(Path.join(root, "198-58-SUMMARY.md"))

    assert_raise ExUnit.AssertionError, ~r/missing audited.*58/s, fn ->
      validate_summary_set!(root, :final)
    end

    write_summary!(root, "58", "[]")
    malformed = Path.join(root, "198-58-copy-SUMMARY.md")
    File.write!(malformed, summary_body("[]"))

    assert_raise ExUnit.AssertionError, ~r/198-58-copy-SUMMARY\.md/, fn ->
      validate_summary_set!(root, :final)
    end

    File.rm!(malformed)

    for illegal <- ~w(00 048 67) do
      write_summary!(root, illegal, "[]")

      assert_raise ExUnit.AssertionError, ~r/#{illegal}/, fn ->
        validate_summary_set!(root, :normal)
      end

      File.rm!(Path.join(root, "198-#{illegal}-SUMMARY.md"))
    end

    write_summary!(root, @terminal_certification_number, "[]")
    assert validate_summary_set!(root, :final) == :ok
  end

  test "Plan 62 remains outside the audited set and must carry mechanical passing coverage" do
    root = phase_fixture!()
    on_exit(fn -> File.rm_rf!(root) end)
    for number <- 56..61, do: write_summary!(root, Integer.to_string(number), "[]")

    invalid_entries = [
      "  - id: D1\n    human_judgment: false\n    verification:\n      - kind: integration",
      "  - id: D1\n    human_judgment: false\n    verification:\n      - kind: integration\n        ref: \"focused test\"\n        status: fail",
      "  - id: D1\n    human_judgment: true\n    verification:\n      - kind: integration\n        ref: \"focused test\"\n        status: pass"
    ]

    for entry <- invalid_entries do
      write_summary!(root, @terminal_certification_number, "\n" <> entry)

      assert_raise ExUnit.AssertionError, ~r/198-62-SUMMARY\.md:D1/, fn ->
        validate_summary_set!(root, :normal)
      end
    end

    passing =
      "\n  - id: D1\n    human_judgment: false\n    verification:\n      - kind: integration\n        ref: \"focused test\"\n        status: pass"

    write_summary!(root, @terminal_certification_number, passing)
    write_repair_summary!(root)
    assert validate_summary_set!(root, :final) == :ok

    assert discover_numbers(root) --
             (@final_state_numbers ++ @post_terminal_numbers ++ [@policy_repair_number]) ==
             [@terminal_certification_number]
  end

  test "coverage accepts only an explicit empty list or structurally valid entries" do
    assert coverage_entries(summary_body("[]")) == %{}

    assert_raise ExUnit.AssertionError, ~r/malformed coverage block/, fn ->
      coverage_entries(summary_body("\n  this is not a coverage entry"))
    end
  end

  test "Plan 46 changed exactly the literal 15-entry coverage allowlist" do
    delta = read_json!(@delta)
    assert MapSet.new(delta["allowlist"]) == @exact_delta
    assert length(delta["allowlist"]) == 15

    pre = coverage_at_tree(delta["pre_plan46_tree"])
    post = coverage_at_tree(delta["post_plan46_tree"])
    changed = changed_keys(pre, post)

    assert changed == @exact_delta,
           "Plan 46 coverage delta mismatch: missing=#{inspect(MapSet.difference(@exact_delta, changed))} " <>
             "extra=#{inspect(MapSet.difference(changed, @exact_delta))}"
  end

  test "manifest data and copied evidence stay repository-relative and secret-free" do
    for relative <- [@manifest, @delta] do
      value = read_json!(relative)

      assert disclosure_errors(value) == [],
             "unsafe field in #{relative}: #{inspect(disclosure_errors(value))}"
    end

    unsafe = %{
      "authorization" => "Bearer example",
      "path" => "/private/workstation/path",
      "cookie" => "session=example"
    }

    for {key, value} <- unsafe do
      assert disclosure_errors(%{key => value}) != []
    end
  end

  defp discover_numbers(dir) do
    dir
    |> Path.join("198-*-SUMMARY.md")
    |> Path.wildcard()
    |> Enum.map(fn path ->
      case Regex.run(~r/198-(\d+)-SUMMARY\.md$/, path, capture: :all_but_first) do
        [number] -> number
        _ -> flunk("malformed Phase 198 summary path: #{path}")
      end
    end)
    |> Enum.sort()
  end

  defp validate_summary_set!(dir, mode) do
    manifest = read_json!(@manifest)
    assert_manifest_namespace!(manifest)
    policy = assert_post_terminal_policy!(manifest)
    discovered = discover_numbers(dir)

    allowed =
      @final_state_numbers ++
        [@terminal_certification_number] ++ policy["numbers"] ++ [@policy_repair_number]

    unexpected = discovered -- allowed
    missing_baseline = @baseline_numbers -- discovered

    assert unexpected == [], "unexpected Phase 198 summary numbers: #{inspect(unexpected)}"

    assert missing_baseline == [],
           "missing immutable Phase 198 summaries: #{inspect(missing_baseline)}"

    if mode == :final do
      audited = Enum.filter(discovered, &(&1 in @final_state_numbers))
      missing = @final_state_numbers -- audited
      extra = audited -- @final_state_numbers

      assert missing == [] and extra == [],
             "final Phase 198 state has missing audited summaries #{inspect(missing)} and extra audited summaries #{inspect(extra)}"

      assert @policy_repair_number in discovered,
             "final Phase 198 state is missing policy repair summary #{@policy_repair_number}"
    end

    for number <- @closeout_numbers ++ [@terminal_certification_number],
        number in discovered,
        path = Path.join(dir, "198-#{number}-SUMMARY.md") do
      entries = path |> File.read!() |> coverage_entries()
      assert coverage_errors(entries, path) == []
    end

    validate_post_terminal_summaries!(dir, discovered, policy)

    if @policy_repair_number in discovered do
      validate_repair_summary!(Path.join(dir, "198-#{@policy_repair_number}-SUMMARY.md"))
    end

    :ok
  end

  defp assert_manifest_namespace!(manifest) do
    assert manifest["audited_final_plan_number"] == @audited_final_plan_number
    assert manifest["terminal_certification_plan_number"] == @terminal_certification_plan_number

    assert manifest["terminal_certification_plan_number"] ==
             manifest["audited_final_plan_number"] + 1

    assert manifest["baseline_numbers"] == @baseline_numbers
    assert manifest["allowed_closeout_numbers"] == @closeout_numbers
    assert manifest["final_state_numbers"] == @final_state_numbers
    assert Enum.uniq(manifest["final_state_numbers"]) == manifest["final_state_numbers"]
    assert Enum.all?(manifest["final_state_numbers"], &String.match?(&1, ~r/^\d{2}$/))
    assert List.first(manifest["allowed_closeout_numbers"]) == Integer.to_string(@closeout_start)
  end

  defp assert_post_terminal_policy!(manifest) do
    expected = %{
      "policy" => "explicit-content-bound-repair-summaries",
      "audited_final_state_unchanged" => true,
      "terminal_certification_unchanged" => true,
      "numbers" => @post_terminal_numbers,
      "summaries" => [
        %{
          "number" => "63",
          "path" => ".planning/phases/198-green-bringup/198-63-SUMMARY.md",
          "sha256" => "12fc1b775f7822b74bbc5d8648e15eb37ae5387dff726dded9ca6bc7e2e2c23c"
        },
        %{
          "number" => "64",
          "path" => ".planning/phases/198-green-bringup/198-64-SUMMARY.md",
          "sha256" => "76e9ed1735d3885114c7de09cdb721bac2ce34a5f9cc7d3696eb46d2ef0fe4da"
        },
        %{
          "number" => "65",
          "path" => ".planning/phases/198-green-bringup/198-65-SUMMARY.md",
          "sha256" => "9542156d7a2aaf0209a7e48920fed1b581163e5fd2e07b8ce4248eb2ed5d87b0"
        }
      ],
      "policy_repair_summary" => %{
        "number" => "66",
        "path" => ".planning/phases/198-green-bringup/198-66-SUMMARY.md",
        "role" => "post-terminal-policy-repair-execution-summary",
        "required_in_final_mode" => true,
        "excluded_from_audited_final_state" => true,
        "terminal_certification" => false
      }
    }

    assert manifest["post_terminal_policy"] == expected,
           "manifest post_terminal_policy does not match the normative contract"

    expected
  end

  defp validate_post_terminal_summaries!(dir, discovered, policy) do
    for record <- policy["summaries"] do
      number = record["number"]
      assert number in discovered, "missing post-terminal summary #{number}"

      path = Path.join(dir, Path.basename(record["path"]))
      body = File.read!(path)
      assert Path.basename(path) == Path.basename(record["path"])
      assert digest(body) == record["sha256"], "#{path} changed"
      validate_summary_semantics!(body, path, number, ["complete", "halted"])
    end
  end

  defp validate_repair_summary!(path) do
    body = File.read!(path)
    validate_summary_semantics!(body, path, @policy_repair_number, ["complete"])
  end

  defp validate_summary_semantics!(body, path, number, allowed_statuses) do
    yaml = frontmatter(body)
    assert Regex.match?(~r/^phase:\s*198-green-bringup\s*$/m, yaml), "#{path} has wrong phase"
    assert Regex.match?(~r/^plan:\s*#{Regex.escape(number)}\s*$/m, yaml), "#{path} has wrong plan"

    [_, status] = Regex.run(~r/^status:\s*([^\s]+)\s*$/m, yaml)
    assert status in allowed_statuses, "#{path} has invalid status #{status}"

    entries = coverage_entries(body)
    assert coverage_errors(entries, path) == []
  end

  defp phase_fixture! do
    root = Path.join(System.tmp_dir!(), "phase198-summary-#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)

    for number <- @baseline_numbers ++ ~w(48 49 50 51 52 53 54 55 63 64 65) do
      File.cp!(summary_path(number), Path.join(root, "198-#{number}-SUMMARY.md"))
    end

    root
  end

  defp write_summary!(dir, number, coverage) do
    File.write!(Path.join(dir, "198-#{number}-SUMMARY.md"), summary_body(coverage))
  end

  defp write_repair_summary!(dir) do
    File.write!(
      Path.join(dir, "198-#{@policy_repair_number}-SUMMARY.md"),
      "---\nphase: 198-green-bringup\nplan: 66\ncoverage: []\nstatus: complete\n---\n# Fixture\n"
    )
  end

  defp summary_body(coverage),
    do: "---\ncoverage: #{coverage}\nstatus: complete\n---\n# Fixture\n"

  defp summary_path(number), do: Path.join(@phase_dir, "198-#{number}-SUMMARY.md")

  defp read_json!(relative) do
    raw = File.read!(relative)
    assert {:ok, value} = decode_unique_ordered_json(raw)
    value
  end

  defp decode_unique_ordered_json(raw) when is_binary(raw) do
    with {:ok, ordered} <- Jason.decode(raw, objects: :ordered_objects),
         :ok <- reject_duplicate_members(ordered) do
      {:ok, ordered_to_plain(ordered)}
    end
  end

  defp reject_duplicate_members(%Jason.OrderedObject{values: members}) do
    keys = Enum.map(members, &elem(&1, 0))

    case duplicate_key(keys) do
      nil -> Enum.reduce_while(members, :ok, &reject_member_duplicates/2)
      key -> {:error, {:duplicate_member, key}}
    end
  end

  defp reject_duplicate_members(values) when is_list(values) do
    Enum.reduce_while(values, :ok, fn value, :ok ->
      case reject_duplicate_members(value) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp reject_duplicate_members(_scalar), do: :ok

  defp reject_member_duplicates({_key, value}, :ok) do
    case reject_duplicate_members(value) do
      :ok -> {:cont, :ok}
      error -> {:halt, error}
    end
  end

  defp duplicate_key(keys) do
    keys
    |> Enum.reduce_while(MapSet.new(), fn key, seen ->
      if MapSet.member?(seen, key),
        do: {:halt, key},
        else: {:cont, MapSet.put(seen, key)}
    end)
    |> case do
      %MapSet{} -> nil
      key -> key
    end
  end

  defp ordered_to_plain(%Jason.OrderedObject{values: members}) do
    Map.new(members, fn {key, value} -> {key, ordered_to_plain(value)} end)
  end

  defp ordered_to_plain(values) when is_list(values), do: Enum.map(values, &ordered_to_plain/1)
  defp ordered_to_plain(scalar), do: scalar

  defp frontmatter(body) do
    case String.split(body, "---", parts: 3) do
      [_, yaml, _] -> yaml
      _ -> flunk("summary has no YAML frontmatter")
    end
  end

  defp coverage_entries(body) do
    yaml = frontmatter(body)
    [_, coverage_tail] = String.split(yaml, ~r/^coverage:[ \t]*/m, parts: 2)
    [head | lines] = String.split(coverage_tail, "\n")

    case String.trim(head) do
      "[]" ->
        %{}

      "" ->
        block =
          lines |> Enum.take_while(&(&1 == "" or String.match?(&1, ~r/^\s/))) |> Enum.join("\n")

        assert String.match?(block, ~r/^  - id:/m), "malformed coverage block"

        Regex.scan(~r/^  - id:\s*([^\s]+)\n((?:(?!^  - id:)[\s\S])*)/m, block,
          capture: :all_but_first
        )
        |> Map.new(fn [id, entry] -> {id, normalize_entry("  - id: #{id}\n" <> entry)} end)

      _ ->
        flunk("malformed coverage block")
    end
  end

  defp normalize_entry(entry) do
    entry
    |> String.replace(
      ~r/verification:\s*\[\{kind:\s*([^,]+),\s*ref:\s*("[^"]*"),\s*status:\s*([^}\]]+)\}\]/,
      "verification:\n      - kind: \\1\n        ref: \\2\n        status: \\3"
    )
    |> String.replace(
      ~r/- \{kind:\s*([^,]+),\s*ref:\s*("[^"]*"),\s*status:\s*([^}]+)\}/,
      "- kind: \\1\n        ref: \\2\n        status: \\3"
    )
    |> String.replace("\r\n", "\n")
    |> String.split("\n")
    |> Enum.map(&String.trim_trailing/1)
    |> Enum.join("\n")
    |> String.trim()
  end

  defp coverage_errors(entries, path) do
    Enum.flat_map(entries, fn {id, entry} ->
      statuses = Regex.scan(~r/^\s+status:\s*([^\s]+)\s*$/m, entry, capture: :all_but_first)
      refs = Regex.scan(~r/^\s+ref:\s*(.+?)\s*$/m, entry, capture: :all_but_first)

      []
      |> maybe_error(
        not Regex.match?(~r/^\s+human_judgment:\s*false\s*$/m, entry),
        "#{path}:#{id} is human"
      )
      |> maybe_error(refs == [], "#{path}:#{id} has no verification ref")
      |> maybe_error(
        statuses == [] or Enum.any?(statuses, &(&1 != ["pass"])),
        "#{path}:#{id} is not all-pass"
      )
    end)
  end

  defp maybe_error(errors, true, message), do: [message | errors]
  defp maybe_error(errors, false, _message), do: errors

  defp verification_digest(entries) do
    entries
    |> Enum.sort()
    |> Enum.map_join("\n", fn {id, entry} -> "#{id}\n#{entry}" end)
    |> digest()
  end

  defp coverage_at_tree(tree) do
    @plan46_numbers
    |> Enum.flat_map(fn number ->
      path = summary_path(number)
      {body, 0} = System.cmd("git", ["show", "#{tree}:#{path}"], stderr_to_stdout: true)

      for {id, entry} <- coverage_entries(body), into: %{} do
        {"198-#{number}:#{id}", entry}
      end
    end)
    |> Map.new()
  end

  defp changed_keys(left, right) do
    (Map.keys(left) ++ Map.keys(right))
    |> MapSet.new()
    |> Enum.filter(&(Map.get(left, &1) != Map.get(right, &1)))
    |> MapSet.new()
  end

  defp disclosure_errors(value), do: disclosure_errors(value, [])

  defp disclosure_errors(map, path) when is_map(map) do
    Enum.flat_map(map, fn {key, value} ->
      key_path = path ++ [key]

      key_error =
        if key =~ ~r/(authorization|credential|password|secret|token|cookie)/i,
          do: [key_path],
          else: []

      key_error ++ disclosure_errors(value, key_path)
    end)
  end

  defp disclosure_errors(list, path) when is_list(list) do
    list
    |> Enum.with_index()
    |> Enum.flat_map(fn {value, index} -> disclosure_errors(value, path ++ [index]) end)
  end

  defp disclosure_errors(value, path) when is_binary(value) do
    unsafe =
      String.starts_with?(value, "/") or
        value =~ ~r/(authorization:|bearer\s+|password=|token=|cookie:)/i or
        value =~ ~r/^([A-Z][A-Z0-9_]+)=/

    if unsafe, do: [path], else: []
  end

  defp disclosure_errors(_value, _path), do: []
  defp digest(value), do: :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)
end
