defmodule Threadline.Phase198ZeroHumanUatContractTest do
  use ExUnit.Case, async: false

  @phase_dir ".planning/phases/198-green-bringup"
  @manifest ".planning/audits/198-summary-coverage-manifest.json"
  @delta ".planning/audits/198-plan46-coverage-delta.json"
  @baseline_numbers Enum.map(1..47, &Integer.to_string(&1) |> String.pad_leading(2, "0"))
  @closeout_numbers Enum.map(48..52, &Integer.to_string/1)
  @plan46_numbers Enum.map(1..45, &Integer.to_string(&1) |> String.pad_leading(2, "0"))
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
    assert manifest["allowed_closeout_numbers"] == @closeout_numbers

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
      Enum.sum(for number <- @baseline_numbers, do: summary_path(number) |> File.read!() |> coverage_entries() |> map_size())

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
    discovered = discover_numbers(@phase_dir)
    assert Enum.take(discovered, 47) == @baseline_numbers

    allowed = @baseline_numbers ++ @closeout_numbers
    assert discovered -- allowed == [], "unexpected Phase 198 summary numbers: #{inspect(discovered -- allowed)}"

    if System.get_env("PHASE198_SUMMARY_SET") == "final" do
      assert discovered == allowed,
             "final Phase 198 state must contain exactly summaries 01-52; got #{inspect(discovered)}"
    end
  end

  test "every present closeout summary is independently automated and valid" do
    for number <- @closeout_numbers,
        path = summary_path(number),
        File.regular?(path) do
      entries = path |> File.read!() |> coverage_entries()
      assert coverage_errors(entries, path) == []
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
      assert disclosure_errors(value) == [], "unsafe field in #{relative}: #{inspect(disclosure_errors(value))}"
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
      [number] = Regex.run(~r/198-(\d+)-SUMMARY\.md$/, path, capture: :all_but_first)
      number
    end)
    |> Enum.sort()
  end

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

      _ ->
        block = lines |> Enum.take_while(&(&1 == "" or String.match?(&1, ~r/^\s/))) |> Enum.join("\n")

        Regex.scan(~r/^  - id:\s*([^\s]+)\n((?:(?!^  - id:)[\s\S])*)/m, block,
          capture: :all_but_first
        )
        |> Map.new(fn [id, entry] -> {id, normalize_entry("  - id: #{id}\n" <> entry)} end)
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
      |> maybe_error(not Regex.match?(~r/^\s+human_judgment:\s*false\s*$/m, entry), "#{path}:#{id} is human")
      |> maybe_error(refs == [], "#{path}:#{id} has no verification ref")
      |> maybe_error(statuses == [] or Enum.any?(statuses, &(&1 != ["pass"])), "#{path}:#{id} is not all-pass")
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
      key_error = if key =~ ~r/(authorization|credential|password|secret|token|cookie)/i, do: [key_path], else: []
      key_error ++ disclosure_errors(value, key_path)
    end)
  end

  defp disclosure_errors(list, path) when is_list(list) do
    list |> Enum.with_index() |> Enum.flat_map(fn {value, index} -> disclosure_errors(value, path ++ [index]) end)
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
