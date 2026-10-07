defmodule Threadline.UpgradePathContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()
  @guide_heading "## Toolchain support policy"
  @min_row "| `min` | `~> 1.15` (CI pin `1.15.8`) | `26.2.5.21` | `15` | Supported floor |"

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  defp workflow_job(yaml, id) do
    case Regex.run(~r/^  #{Regex.escape(id)}:\n([\s\S]*?)(?=^  [a-z][a-z0-9-]+:\n|\z)/m, yaml) do
      [full, _body] -> full
      nil -> ""
    end
  end

  defp lane_blocks(yaml, lane) do
    yaml
    |> workflow_job("verify-test")
    |> then(fn job ->
      Regex.scan(
        ~r/^ {10}- lane: #{Regex.escape(lane)}\n((?:^ {12}[^\n]*\n)*)/m,
        job,
        capture: :all_but_first
      )
      |> List.flatten()
    end)
  end

  defp lane_value(block, key) when is_binary(block) do
    case Regex.run(
           ~r/^ {12}#{Regex.escape(key)}:\s*"([^"]+)"\s*$/m,
           block,
           capture: :all_but_first
         ) do
      [value] -> value
      _ -> nil
    end
  end

  defp tool_version(tool_versions, tool) do
    case Regex.run(~r/^#{Regex.escape(tool)}\s+(\S+)\s*$/m, tool_versions,
           capture: :all_but_first
         ) do
      [value] -> value
      _ -> nil
    end
  end

  defp support_section(guide) do
    case String.split(guide, @guide_heading) do
      [_, section | _] -> section |> String.split(~r/^## /m, parts: 2) |> List.first()
      _ -> ""
    end
  end

  defp table_cells(line) do
    trimmed = String.trim(line)

    if String.starts_with?(trimmed, "|") and String.ends_with?(trimmed, "|") do
      trimmed
      |> String.trim_leading("|")
      |> String.trim_trailing("|")
      |> String.split("|")
      |> Enum.map(&String.trim/1)
    else
      []
    end
  end

  defp policy_rows(section) do
    section
    |> String.split("\n")
    |> Enum.map(&table_cells/1)
    |> Enum.filter(fn
      [lane | _] -> lane in ["`min`", "`current`", "`latest`"]
      _ -> false
    end)
  end

  defp lane_row(rows, lane), do: Enum.find(rows, &(cell(&1, 0) == "`#{lane}`"))

  defp cell(row, index) when is_list(row), do: Enum.at(row, index)
  defp cell(_, _index), do: nil

  defp token_cell?(actual, expected) when is_binary(actual) and is_binary(expected) do
    actual |> String.replace("`", "") |> String.trim() == expected
  end

  defp token_cell?(_, _), do: false

  defp contains_token?(actual, expected) when is_binary(actual) and is_binary(expected) do
    expected != "" and String.contains?(actual, "`#{expected}`")
  end

  defp contains_token?(_, _), do: false

  defp replace_lane_value(yaml, lane, key, value) do
    job = workflow_job(yaml, "verify-test")

    block_regex =
      Regex.compile!(
        "^ {10}- lane: #{Regex.escape(lane)}\\n(?:^ {12}[^\\n]*\\n)*",
        "m"
      )

    case Regex.run(block_regex, job) do
      [block] ->
        field_regex = Regex.compile!("^ {12}#{Regex.escape(key)}: \"[^\"]+\"\\s*$", "m")

        case Regex.run(field_regex, block) do
          [old_field] ->
            new_field = "            #{key}: \"#{value}\""
            new_block = String.replace(block, old_field, new_field, global: false)
            new_job = String.replace(job, block, new_block, global: false)
            String.replace(yaml, job, new_job, global: false)

          _ ->
            yaml
        end

      _ ->
        yaml
    end
  end

  defp policy_errors(guide, mix_exs, yaml, tool_versions) do
    job = workflow_job(yaml, "verify-test")
    blocks = Map.new(["min", "current", "latest"], &{&1, lane_blocks(yaml, &1)})
    min_block = blocks |> Map.get("min", []) |> List.first()
    current_block = blocks |> Map.get("current", []) |> List.first()
    latest_block = blocks |> Map.get("latest", []) |> List.first()

    elixir_constraint =
      case Regex.run(~r/\belixir:\s*"([^"]+)"/, mix_exs, capture: :all_but_first) do
        [value] -> value
        _ -> nil
      end

    versions = %{
      min_elixir: lane_value(min_block, "elixir"),
      min_otp: lane_value(min_block, "otp"),
      min_pg: lane_value(min_block, "pg"),
      current_elixir: tool_version(tool_versions, "elixir"),
      current_otp: tool_version(tool_versions, "erlang"),
      current_pg: lane_value(current_block, "pg"),
      latest_elixir: lane_value(latest_block, "elixir"),
      latest_otp: lane_value(latest_block, "otp"),
      latest_pg: lane_value(latest_block, "pg")
    }

    section = support_section(guide)
    rows = policy_rows(section)
    min = lane_row(rows, "min")
    current = lane_row(rows, "current")
    latest = lane_row(rows, "latest")

    checks = [
      {job != "", "ci.yml has no verify-test job to source the lane values"},
      {Enum.all?(blocks, fn {_lane, lane_blocks} -> length(lane_blocks) == 1 end),
       "verify-test must define exactly one min, current, and latest row"},
      {lane_value(current_block, "version-file") == ".tool-versions",
       "verify-test current row must source its toolchain from .tool-versions"},
      {is_binary(elixir_constraint) and elixir_constraint != "",
       "mix.exs must declare a nonempty Elixir support constraint"},
      {Enum.all?(Map.values(versions), &(is_binary(&1) and &1 != "")),
       "mix.exs, .tool-versions, and ci.yml must yield every support-policy source value"},
      {length(Regex.scan(~r/^#{Regex.escape(@guide_heading)}\s*$/m, guide)) == 1,
       "guides/upgrade-path.md must contain exactly one `#{@guide_heading}` section"},
      {rows != [], "the toolchain support-policy table must have nonempty lane rows"},
      {Enum.count(rows, &(cell(&1, 0) == "Lane")) == 0,
       "toolchain support-policy rows must be distinct from the table header"},
      {Enum.count(
         String.split(section, "\n"),
         &(table_cells(&1) == ["Lane", "Elixir", "OTP", "PostgreSQL", "Meaning"])
       ) == 1,
       "toolchain support-policy table must have the expected five-column header exactly once"},
      {Enum.all?(["min", "current", "latest"], fn lane ->
         Enum.count(rows, &(cell(&1, 0) == "`#{lane}`")) == 1
       end),
       "toolchain support-policy table must have one row each for min, current, and latest"},
      {contains_token?(cell(min, 1), elixir_constraint),
       "min row must include the exact Elixir constraint from mix.exs"},
      {contains_token?(cell(min, 1), versions.min_elixir),
       "min row must include the exact Elixir CI pin from ci.yml"},
      {token_cell?(cell(min, 2), versions.min_otp), "min row OTP must match ci.yml exactly"},
      {token_cell?(cell(min, 3), versions.min_pg),
       "min row PostgreSQL must match ci.yml exactly"},
      {token_cell?(cell(current, 1), versions.current_elixir),
       "current row Elixir must match .tool-versions exactly"},
      {token_cell?(cell(current, 2), versions.current_otp),
       "current row OTP must match .tool-versions exactly"},
      {token_cell?(cell(current, 3), versions.current_pg),
       "current row PostgreSQL must match ci.yml exactly"},
      {token_cell?(cell(latest, 1), versions.latest_elixir),
       "latest row Elixir must match ci.yml exactly"},
      {token_cell?(cell(latest, 2), versions.latest_otp),
       "latest row OTP must match ci.yml exactly"},
      {token_cell?(cell(latest, 3), versions.latest_pg),
       "latest row PostgreSQL must match ci.yml exactly"},
      {String.downcase(cell(min, 4) || "") =~ ~r/supported floor/,
       "only the min row must identify the supported floor"},
      {Enum.all?([current, latest], fn row ->
         meaning = String.downcase(cell(row, 4) || "")

         String.contains?(meaning, "tested-on") and
           String.contains?(meaning, "not a support promise")
       end), "current and latest rows must say tested-on only, not support promises"}
    ]

    checks
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end

  test "one toolchain support table matches the declared support and CI lanes (FLOOR-01/02)" do
    guide = read_rel!(["guides", "upgrade-path.md"])
    mix_exs = read_rel!(["mix.exs"])
    yaml = read_rel!([".github", "workflows", "ci.yml"])
    tool_versions = read_rel!([".tool-versions"])
    source = {guide, mix_exs, yaml, tool_versions}

    assert policy_errors(guide, mix_exs, yaml, tool_versions) == [],
           "the toolchain support-policy table must agree with mix.exs, .tool-versions, and ci.yml"

    changed_min_row = String.replace(@min_row, "| `15` |", "| `14` |")

    mutations = [
      {"the min PostgreSQL table cell",
       {String.replace(guide, @min_row, changed_min_row), mix_exs, yaml, tool_versions}},
      {"the min row",
       {String.replace(guide, @min_row <> "\n", ""), mix_exs, yaml, tool_versions}},
      {"the declared Elixir constraint",
       {guide, String.replace(mix_exs, "elixir: \"~> 1.15\"", "elixir: \"~> 1.16\""), yaml,
        tool_versions}},
      {"the minimum CI PostgreSQL source",
       {guide, mix_exs, replace_lane_value(yaml, "min", "pg", "14"), tool_versions}},
      {"the current CI PostgreSQL source",
       {guide, mix_exs, replace_lane_value(yaml, "current", "pg", "17"), tool_versions}},
      {"the latest CI OTP source",
       {guide, mix_exs, replace_lane_value(yaml, "latest", "otp", "29.1.2"), tool_versions}},
      {"the current Elixir toolchain source",
       {guide, mix_exs, yaml,
        String.replace(tool_versions, "elixir 1.17.3-otp-27", "elixir 1.17.4-otp-27")}},
      {"the current OTP toolchain source",
       {guide, mix_exs, yaml,
        String.replace(tool_versions, "erlang 27.3.4.15", "erlang 27.3.4.16")}}
    ]

    for {label, {mutated_guide, mutated_mix, mutated_yaml, mutated_tool_versions}} <- mutations do
      mutated = {mutated_guide, mutated_mix, mutated_yaml, mutated_tool_versions}
      refute mutated == source, "#{label} mutation must change its input"

      assert policy_errors(mutated_guide, mutated_mix, mutated_yaml, mutated_tool_versions) != [],
             "#{label} mutation must make the source-derived support-policy contract fail"
    end
  end
end
