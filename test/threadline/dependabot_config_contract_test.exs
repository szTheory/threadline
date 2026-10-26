defmodule Threadline.DependabotConfigContractTest do
  @moduledoc """
  SUP-01 contract for `.github/dependabot.yml` (245 D-02..D-05).

  Dependabot keeps the SHA-pinned GitHub Actions refs current through one
  grouped monthly version-update pull request with a 7-day cooldown. It opens
  no Hex pull requests, because GitHub does not support Hex security updates;
  Hex advisories come from `mix verify.deps_audit` and the deps-health issue.
  This contract pins the config to that shape, so it cannot quietly grow a
  dead `mix` entry, a release-triggering commit prefix, or a label that
  collides with a CI tracking-issue stream.

  ## Representation

  `dependabot_errors/2` is a pure checker over the config text and a context
  map. It returns one `"<path> rule=<id>: ..."` string per violation, so the
  live config must produce `[]` and each mutation control must make its own
  rule id fire. Facts that live elsewhere in the repo are derived, never
  restated:

    * the releasable commit types are the `release-please-config.json`
      `changelog-sections` types whose `hidden` is not `true`, and the commit
      prefix must not be one of them (D-04);
    * the workflow labels are every `LABEL:` value in `.github/workflows/`,
      and any Dependabot label must be disjoint from them, because
      `bin/upsert-ci-issue` dedups by label and pull requests are issues;
    * the tracked files come from `git ls-files`; a composite `action.yml`
      outside `/` would not be scanned by a `directory: "/"` entry.

  A derive source that finds nothing fails closed under the rule it feeds,
  rather than letting the check pass vacuously.

  Rule ids: `yaml-parse`, `version`, `ecosystems`, `interval`, `cooldown`,
  `groups`, `prefix-releasable`, `commit-message`, `target-branch`,
  `pr-limit`, `forbidden-keys`, `labels`, `composite-outside-root`.

  ## Not covered here

  That GitHub accepted the committed config (no Dependabot config error on
  the repository, then the first grouped pull request or a "no updates"
  status) can only be observed after the file reaches `main`. It is a
  deferred-to-landing check, recorded in the 245-05 SUMMARY, not a test.
  """

  use ExUnit.Case, async: true
  @moduletag :repo_contract

  @repo_root File.cwd!()
  @path ".github/dependabot.yml"
  @release_config "release-please-config.json"
  @group_keys ["applies-to", "patterns"]
  @forbidden_entry_keys ["allow", "ignore", "rebase-strategy"]

  # --- Live sources ------------------------------------------------------------

  defp read_rel!(rel), do: File.read!(Path.join(@repo_root, rel))

  defp live_context do
    %{
      releasable: releasable_types(read_rel!(@release_config)),
      labels: workflow_labels(),
      tracked: tracked_files()
    }
  end

  defp releasable_types(json) do
    sections = json |> Jason.decode!() |> Map.get("changelog-sections", [])

    for %{"type" => type} = section <- sections, section["hidden"] != true, uniq: true do
      type |> String.trim() |> String.downcase()
    end
  end

  defp workflow_labels do
    for path <- Path.wildcard(Path.join(@repo_root, ".github/workflows/*.{yml,yaml}")),
        [_, value] <- Regex.scan(~r/LABEL:\s*(\S+)/, File.read!(path)),
        uniq: true,
        do: value |> String.trim("\"") |> String.trim("'")
  end

  defp tracked_files do
    {out, 0} = System.cmd("git", ["ls-files", "-z"], cd: @repo_root)
    String.split(out, <<0>>, trim: true)
  end

  # --- YAML helpers (private copies of ci_token_permissions_contract_test's) ---

  defp parse_yaml(text) do
    {:ok, YamlElixir.read_from_string!(text, merge_anchors: true)}
  rescue
    error -> {:error, Exception.message(error)}
  catch
    kind, reason -> {:error, inspect({kind, reason})}
  end

  defp yaml_key_string(key) when is_binary(key), do: key
  defp yaml_key_string(key) when is_atom(key) or is_number(key), do: to_string(key)
  defp yaml_key_string(key), do: inspect(key)

  # Case-folded and trimmed: Dependabot keys are case-sensitive, so this only
  # over-reports.
  defp yaml_key(key), do: key |> yaml_key_string() |> String.trim() |> String.downcase()

  defp yaml_field(%{} = map, key) do
    Enum.find_value(map, fn {k, v} -> if yaml_key(k) == key, do: {:ok, v} end) || :error
  end

  defp yaml_field(_data, _key), do: :error

  defp yaml_get(data, key) do
    case yaml_field(data, key) do
      {:ok, value} -> value
      :error -> nil
    end
  end

  defp scalar(value) when is_binary(value), do: value |> String.trim() |> String.downcase()
  defp scalar(value), do: value

  # --- The contract ------------------------------------------------------------

  defp dependabot_errors(text, ctx) do
    case parse_yaml(text) do
      {:ok, %{} = doc} ->
        entries = entries(doc)

        version_errors(doc) ++
          ecosystem_errors(doc, entries) ++
          Enum.flat_map(Enum.with_index(entries), &entry_errors(&1, ctx)) ++
          derive_errors(ctx) ++ composite_errors(ctx)

      {:ok, other} ->
        [err("yaml-parse", "the config is not a mapping (#{inspect(other)})")]

      {:error, message} ->
        [err("yaml-parse", "the config does not parse, so it cannot be checked (#{message})")]
    end
  end

  defp err(rule, message), do: "#{@path} rule=#{rule}: #{message}"
  defp err(index, rule, message), do: "#{@path} updates[#{index}] rule=#{rule}: #{message}"

  defp entries(doc) do
    case yaml_get(doc, "updates") do
      list when is_list(list) -> list
      _ -> []
    end
  end

  defp version_errors(doc) do
    case yaml_get(doc, "version") do
      2 -> []
      other -> [err("version", "`version` must be 2, got #{inspect(other)}")]
    end
  end

  defp directories(entry) do
    case {yaml_get(entry, "directory"), yaml_get(entry, "directories")} do
      {nil, list} when is_list(list) -> list
      {nil, nil} -> [nil]
      {dir, nil} -> [dir]
      {dir, list} when is_list(list) -> [dir | list]
      {dir, other} -> [dir, other]
    end
  end

  defp ecosystem_errors(doc, entries) do
    pairs =
      for entry <- entries, dir <- directories(entry) do
        {scalar(yaml_get(entry, "package-ecosystem")), dir}
      end

    if is_list(yaml_get(doc, "updates")) and Enum.sort(pairs) == [{"github-actions", "/"}],
      do: [],
      else: [
        err(
          "ecosystems",
          "the {package-ecosystem, directory} set must be exactly " <>
            ~s([{"github-actions", "/"}], got #{inspect(Enum.sort(pairs))}; Dependabot ) <>
            "does not serve Hex, and the e2e npm lock ships nothing"
        )
      ]
  end

  defp entry_errors({entry, index}, ctx) when is_map(entry) do
    interval_errors(entry, index) ++
      cooldown_errors(entry, index) ++
      group_errors(entry, index) ++
      commit_message_errors(entry, index, ctx) ++
      target_branch_errors(entry, index) ++
      pr_limit_errors(entry, index) ++
      forbidden_key_errors(entry, index) ++ label_errors(entry, index, ctx)
  end

  defp entry_errors({entry, index}, _ctx),
    do: [err(index, "ecosystems", "an update entry must be a mapping, got #{inspect(entry)}")]

  defp interval_errors(entry, index) do
    case scalar(yaml_get(yaml_get(entry, "schedule"), "interval")) do
      "monthly" ->
        []

      other ->
        [err(index, "interval", "`schedule.interval` must be monthly, got #{inspect(other)}")]
    end
  end

  defp cooldown_errors(entry, index) do
    case yaml_get(yaml_get(entry, "cooldown"), "default-days") do
      days when is_integer(days) and days >= 7 ->
        []

      other ->
        [
          err(
            index,
            "cooldown",
            "`cooldown.default-days` must be an integer >= 7, got #{inspect(other)}; a new " <>
              "pin must never adopt a release less than 7 days old"
          )
        ]
    end
  end

  defp group_errors(entry, index) do
    case yaml_get(entry, "groups") do
      %{} = groups when map_size(groups) == 1 ->
        [{name, group}] = Map.to_list(groups)
        one_group_errors(index, yaml_key_string(name), group)

      other ->
        [err(index, "groups", "exactly one group is required, got #{inspect(other)}")]
    end
  end

  defp one_group_errors(index, name, %{} = group) do
    keys = group |> Map.keys() |> Enum.map(&yaml_key/1) |> Enum.sort()
    applies = scalar(yaml_get(group, "applies-to"))
    patterns = yaml_get(group, "patterns")

    cond do
      keys != @group_keys ->
        [
          err(
            index,
            "groups",
            "group #{name} must carry exactly #{inspect(@group_keys)}, got #{inspect(keys)}"
          )
        ]

      applies != "version-updates" or patterns != ["*"] ->
        [
          err(
            index,
            "groups",
            "group #{name} must be `applies-to: version-updates` with `patterns: [\"*\"]`, " <>
              "got #{inspect(applies)} / #{inspect(patterns)}"
          )
        ]

      true ->
        []
    end
  end

  defp one_group_errors(index, name, other),
    do: [err(index, "groups", "group #{name} must be a mapping, got #{inspect(other)}")]

  defp commit_message_errors(entry, index, ctx) do
    message = yaml_get(entry, "commit-message")
    prefix = scalar(yaml_get(message, "prefix"))

    prefix_errors =
      cond do
        not is_binary(prefix) or prefix == "" ->
          [err(index, "prefix-releasable", "`commit-message.prefix` must be set")]

        prefix in ctx.releasable ->
          [
            err(
              index,
              "prefix-releasable",
              "prefix #{inspect(prefix)} is a releasable release-please type " <>
                "#{inspect(ctx.releasable)}; a Dependabot PR must never cut a release"
            )
          ]

        true ->
          []
      end

    include =
      if scalar(yaml_get(message, "include")) == "scope",
        do: [],
        else: [
          err(
            index,
            "commit-message",
            "`commit-message.include` must be scope (ci(deps): titles)"
          )
        ]

    prefix_errors ++ include
  end

  defp target_branch_errors(entry, index) do
    if yaml_field(entry, "target-branch") == :error,
      do: [],
      else: [
        err(
          index,
          "target-branch",
          "`target-branch` is banned; it stops the config applying to security updates"
        )
      ]
  end

  defp pr_limit_errors(entry, index) do
    case yaml_field(entry, "open-pull-requests-limit") do
      :error ->
        []

      {:ok, value} ->
        if value in [0, "0"],
          do: [
            err(index, "pr-limit", "`open-pull-requests-limit: 0` disables version updates")
          ],
          else: []
    end
  end

  defp forbidden_key_errors(entry, index) do
    for key <- @forbidden_entry_keys, yaml_field(entry, key) != :error do
      err(
        index,
        "forbidden-keys",
        "`#{key}` is banned; a major bump is reviewed, never ignored or filtered away"
      )
    end
  end

  defp label_errors(entry, index, ctx) do
    case yaml_field(entry, "labels") do
      :error ->
        []

      {:ok, labels} when is_list(labels) ->
        clash = for label <- labels, yaml_key_string(label) in ctx.labels, do: label

        if clash == [],
          do: [],
          else: [
            err(
              index,
              "labels",
              "labels #{inspect(clash)} collide with a workflow `LABEL:`; " <>
                "bin/upsert-ci-issue dedups by label and pull requests are issues"
            )
          ]

      {:ok, other} ->
        [err(index, "labels", "`labels` must be a list, got #{inspect(other)}")]
    end
  end

  # A derive source that finds nothing would let its rule pass vacuously.
  defp derive_errors(ctx) do
    releasable =
      if ctx.releasable == [],
        do: [
          err(
            "prefix-releasable",
            "derived no releasable type from #{@release_config} changelog-sections"
          )
        ],
        else: []

    labels =
      if ctx.labels == [],
        do: [err("labels", "derived no `LABEL:` value from .github/workflows/")],
        else: []

    releasable ++ labels
  end

  defp composite_errors(ctx) do
    for path <- ctx.tracked,
        Path.basename(path) in ["action.yml", "action.yaml"],
        Path.dirname(path) != "." do
      err(
        "composite-outside-root",
        "#{path} is a composite action outside /; a `directory: \"/\"` entry never scans it"
      )
    end
  end

  # --- Tests -----------------------------------------------------------------

  defp rule_fired?(errors, rule), do: Enum.any?(errors, &String.contains?(&1, "rule=#{rule}"))

  defp mutate!(text, from, to) do
    assert String.contains?(text, from), "control anchor not found in #{@path}: #{inspect(from)}"
    String.replace(text, from, to, global: false)
  end

  test "the live .github/dependabot.yml satisfies the contract" do
    assert dependabot_errors(read_rel!(@path), live_context()) == []
  end

  test "the commit prefix is checked against a non-empty derived releasable set" do
    ctx = live_context()
    refute ctx.releasable == [], "no releasable type derived from #{@release_config}"
    {:ok, doc} = parse_yaml(read_rel!(@path))
    [entry] = entries(doc)
    refute scalar(yaml_get(yaml_get(entry, "commit-message"), "prefix")) in ctx.releasable
  end

  describe "mutation controls" do
    setup do
      %{text: read_rel!(@path), ctx: live_context()}
    end

    @dir "    directory: \"/\"\n"
    @mix_entry "  - package-ecosystem: mix\n    directory: \"/\"\n    schedule:\n" <>
                 "      interval: monthly\n"

    for {label, from, to, rule} <- [
          {"an appended mix entry", "      include: scope\n",
           "      include: scope\n" <> @mix_entry, "ecosystems"},
          {"an npm ecosystem", "package-ecosystem: github-actions", "package-ecosystem: npm",
           "ecosystems"},
          {"a second directory", @dir, "    directories:\n      - \"/\"\n      - \"/bench\"\n",
           "ecosystems"},
          {"prefix fix", "prefix: ci\n", "prefix: fix\n", "prefix-releasable"},
          {"prefix deps", "prefix: ci\n", "prefix: deps\n", "prefix-releasable"},
          {"include scope dropped", "      include: scope\n", "", "commit-message"},
          {"a target-branch", @dir, @dir <> "    target-branch: main\n", "target-branch"},
          {"open-pull-requests-limit 0", @dir, @dir <> "    open-pull-requests-limit: 0\n",
           "pr-limit"},
          {"interval weekly", "interval: monthly", "interval: weekly", "interval"},
          {"cooldown 3", "default-days: 7", "default-days: 3", "cooldown"},
          {"a second group", "    commit-message:\n",
           "      other:\n        patterns:\n          - \"actions/*\"\n    commit-message:\n",
           "groups"},
          {"update-types on the group", "        applies-to: version-updates\n",
           "        applies-to: version-updates\n        update-types:\n          - minor\n",
           "groups"},
          {"a ci-deps label", @dir, @dir <> "    labels:\n      - ci-deps\n", "labels"},
          {"an ignore rule", @dir, @dir <> "    ignore:\n      - dependency-name: \"*\"\n",
           "forbidden-keys"},
          {"a rebase-strategy", @dir, @dir <> "    rebase-strategy: disabled\n",
           "forbidden-keys"},
          {"version 1", "version: 2\n", "version: 1\n", "version"},
          {"an unparseable config", "    schedule:\n", "    schedule: [unclosed\n", "yaml-parse"}
        ] do
      test "#{label} fires rule=#{rule}", %{text: text, ctx: ctx} do
        mutated = mutate!(text, unquote(from), unquote(to))
        refute mutated == text, "the control did not change the input"
        errors = dependabot_errors(mutated, ctx)

        assert rule_fired?(errors, unquote(rule)),
               "expected rule=#{unquote(rule)} to fire, got #{inspect(errors)}"
      end
    end

    test "a composite action outside / fires rule=composite-outside-root", %{text: text, ctx: ctx} do
      mutated = %{ctx | tracked: ["tools/setup/action.yml" | ctx.tracked]}
      refute mutated == ctx, "the control did not change the input"
      assert rule_fired?(dependabot_errors(text, mutated), "composite-outside-root")
    end

    test "an empty derived label set fails closed under rule=labels", %{text: text, ctx: ctx} do
      refute ctx.labels == []
      assert rule_fired?(dependabot_errors(text, %{ctx | labels: []}), "labels")
    end

    test "an empty derived releasable set fails closed under rule=prefix-releasable",
         %{text: text, ctx: ctx} do
      refute ctx.releasable == []
      assert rule_fired?(dependabot_errors(text, %{ctx | releasable: []}), "prefix-releasable")
    end

    test "reordering keys within the entry passes (positive control)", %{text: text, ctx: ctx} do
      mutated = text |> mutate!(@dir, "") |> Kernel.<>(@dir)
      refute mutated == text, "the control did not change the input"
      assert dependabot_errors(mutated, ctx) == []
    end
  end
end
