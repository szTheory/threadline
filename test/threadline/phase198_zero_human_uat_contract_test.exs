defmodule Threadline.Phase198ZeroHumanUatContractTest do
  use ExUnit.Case, async: false

  @phase_dir ".planning/phases/198-green-bringup"
  @manifest ".planning/audits/198-summary-coverage-manifest.json"
  @delta ".planning/audits/198-plan46-coverage-delta.json"
  @baseline_numbers Enum.map(1..47, &(Integer.to_string(&1) |> String.pad_leading(2, "0")))
  @closeout_start 48
  @audited_final_plan_number 59
  @terminal_certification_plan_number 60
  @closeout_numbers Enum.map(@closeout_start..@audited_final_plan_number, &Integer.to_string/1)
  @final_state_numbers @baseline_numbers ++ @closeout_numbers
  @terminal_certification_number Integer.to_string(@terminal_certification_plan_number)
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

  test "isolated discovery fixtures enforce audited final timing and the sole Plan 60 exception" do
    root = phase_fixture!()
    on_exit(fn -> File.rm_rf!(root) end)

    assert_raise ExUnit.AssertionError, ~r/missing audited.*56.*57.*58.*59/s, fn ->
      validate_summary_set!(root, :final)
    end

    for number <- 56..59, do: write_summary!(root, Integer.to_string(number), "[]")
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

    for illegal <- ~w(00 048 61) do
      write_summary!(root, illegal, "[]")

      assert_raise ExUnit.AssertionError, ~r/#{illegal}/, fn ->
        validate_summary_set!(root, :normal)
      end

      File.rm!(Path.join(root, "198-#{illegal}-SUMMARY.md"))
    end

    write_summary!(root, @terminal_certification_number, "[]")
    assert validate_summary_set!(root, :final) == :ok
  end

  test "Plan 60 remains outside the audited set and must carry mechanical passing coverage" do
    root = phase_fixture!()
    on_exit(fn -> File.rm_rf!(root) end)
    for number <- 56..59, do: write_summary!(root, Integer.to_string(number), "[]")

    invalid_entries = [
      "  - id: D1\n    human_judgment: false\n    verification:\n      - kind: integration",
      "  - id: D1\n    human_judgment: false\n    verification:\n      - kind: integration\n        ref: \"focused test\"\n        status: fail",
      "  - id: D1\n    human_judgment: true\n    verification:\n      - kind: integration\n        ref: \"focused test\"\n        status: pass"
    ]

    for entry <- invalid_entries do
      write_summary!(root, @terminal_certification_number, "\n" <> entry)

      assert_raise ExUnit.AssertionError, ~r/198-60-SUMMARY\.md:D1/, fn ->
        validate_summary_set!(root, :normal)
      end
    end

    passing =
      "\n  - id: D1\n    human_judgment: false\n    verification:\n      - kind: integration\n        ref: \"focused test\"\n        status: pass"

    write_summary!(root, @terminal_certification_number, passing)
    assert validate_summary_set!(root, :final) == :ok
    assert discover_numbers(root) -- @final_state_numbers == [@terminal_certification_number]
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
    discovered = discover_numbers(dir)
    allowed = @final_state_numbers ++ [@terminal_certification_number]
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
    end

    for number <- @closeout_numbers ++ [@terminal_certification_number],
        number in discovered,
        path = Path.join(dir, "198-#{number}-SUMMARY.md") do
      entries = path |> File.read!() |> coverage_entries()
      assert coverage_errors(entries, path) == []
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

  defp phase_fixture! do
    root = Path.join(System.tmp_dir!(), "phase198-summary-#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)

    for number <- @baseline_numbers ++ ~w(48 49 50 51 52 53 54 55) do
      File.cp!(summary_path(number), Path.join(root, "198-#{number}-SUMMARY.md"))
    end

    root
  end

  defp write_summary!(dir, number, coverage) do
    File.write!(Path.join(dir, "198-#{number}-SUMMARY.md"), summary_body(coverage))
  end

  defp summary_body(coverage),
    do: "---\ncoverage: #{coverage}\nstatus: complete\n---\n# Fixture\n"

  defp summary_path(number), do: Path.join(@phase_dir, "198-#{number}-SUMMARY.md")
  defp read_json!(relative), do: relative |> File.read!() |> Jason.decode!()

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
