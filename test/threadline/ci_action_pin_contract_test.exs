defmodule Threadline.CiActionPinContractTest do
  @moduledoc """
  Every GitHub Actions `uses:` ref is immutable (SUP-02).

  A tag such as `v5` can be moved, so a compromised or force-pushed tag
  (CVE-2025-30066, tj-actions/changed-files) changes what CI runs without a
  reviewed repository commit. This contract keeps every action ref pinned to a
  full commit SHA with the exact release tag beside it, and keeps
  `actions/setup-node` reading the Node version from `.tool-versions`.

  ## Representation

  The canonical ref is one unquoted line:

      uses: owner/repo[/path]@<40 lowercase hex> # vX.Y.Z

  `pin_errors/2` takes `%{relative_path => text}` for every workflow and local
  composite action file, plus the text of `.tool-versions`, and returns sorted
  `rule=<ID>` error strings (path, then line). The rules:

    * `PIN-SCAN`: no files, or no `uses:` refs at all. The contract never
      passes vacuously.
    * `PIN-PARITY`: the multiset of `uses:` values read from parsed YAML
      (`jobs.*.uses`, `jobs.*.steps[*].uses`, `runs.steps[*].uses`, anchors
      merged) equals the multiset read from raw `uses:` lines. A ref hidden in a
      flow mapping, a quoted key, an alias or a block scalar shows up in one
      and not the other. A file that does not parse fails here too.
    * `PIN-FORM`: every raw `uses:` line is in canonical form, unless it is a
      `./` or `docker://` ref.
    * `PIN-LOCAL`: a `./` ref names a directory holding action.yml or
      action.yaml.
    * `PIN-DOCKER`: a `docker://` ref ends `@sha256:<64 hex>`.
    * `PIN-CONSISTENT`: one `{action, SHA}` carries one comment, and one
      `{owner/repo, major}` maps to one SHA across all files.
    * `NODE-FILE`: every `actions/setup-node` step sets
      `node-version-file: .tool-versions` and no `node-version` (setup-node
      prefers `node-version` when both are given).
    * `NODE-PIN`: `.tool-versions` has exactly one `nodejs X.Y.Z` line and no
      other single-token line. setup-node's `.tool-versions` regex makes the
      `nodejs` prefix optional, so the first single-token line would win.

  ## Not covered here

  This contract checks the form of each pin offline. Whether each SHA really is
  the commit its tag names upstream (an impostor commit from a fork network
  would pass the form check) is the network provenance check in
  `bin/verify-action-pins`. Which action majors may run (Node 24 or
  non-JavaScript) is `test/threadline/ci_action_runtime_contract_test.exs`.
  """

  use ExUnit.Case, async: true
  @moduletag :repo_contract

  @repo_root File.cwd!()

  @pin_form ~r/^\s*(?:-\s+)?uses: ([a-z0-9][a-z0-9-]*\/[A-Za-z0-9._-]+(?:\/[A-Za-z0-9._\/-]+)?)@([0-9a-f]{40}) # (v\d+\.\d+\.\d+)\s*$/

  @raw_uses ~r/^\s*(?:-\s+)?uses:(.*)$/

  # --- Live tree -------------------------------------------------------------

  defp live_texts do
    workflows = Path.wildcard(Path.join(@repo_root, ".github/workflows/*.{yml,yaml}"))
    actions = Path.wildcard(Path.join(@repo_root, ".github/actions/**/action.{yml,yaml}"))

    (workflows ++ actions)
    |> Enum.sort()
    |> Map.new(fn path -> {Path.relative_to(path, @repo_root), File.read!(path)} end)
  end

  defp live_tool_versions, do: File.read!(Path.join(@repo_root, ".tool-versions"))

  # --- Checker ---------------------------------------------------------------

  @doc false
  def pin_errors(texts, tool_versions) do
    raw = Enum.flat_map(Enum.sort(texts), fn {path, text} -> raw_refs(path, text) end)

    errors =
      scan_errors(texts, raw) ++
        Enum.flat_map(Enum.sort(texts), fn {path, text} -> parity_errors(path, text) end) ++
        Enum.flat_map(raw, &ref_errors/1) ++
        consistent_errors(raw) ++
        Enum.flat_map(Enum.sort(texts), fn {path, text} -> node_file_errors(path, text) end) ++
        node_pin_errors(tool_versions)

    errors
    |> Enum.sort_by(fn {path, line, message} -> {path, line, message} end)
    |> Enum.map(&elem(&1, 2))
  end

  defp scan_errors(texts, _raw) when map_size(texts) == 0 do
    [{"", 0, "rule=PIN-SCAN: no workflow or action files found; refusing to pass vacuously"}]
  end

  defp scan_errors(_texts, []) do
    [{"", 0, "rule=PIN-SCAN: zero `uses:` refs scanned; the scanner is broken, not the tree"}]
  end

  defp scan_errors(_texts, _raw), do: []

  # Raw `uses:` lines, full-line comments skipped. Each entry keeps the
  # original line (for PIN-FORM) and the YAML-equivalent value (for parity).
  defp raw_refs(path, text) do
    text
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.reject(fn {line, _} -> String.match?(line, ~r/^\s*#/) end)
    |> Enum.flat_map(fn {line, number} ->
      case Regex.run(@raw_uses, line, capture: :all_but_first) do
        [rest] -> [%{path: path, line: number, text: line, value: raw_value(rest)}]
        nil -> []
      end
    end)
  end

  defp raw_value(rest) do
    rest
    |> String.split(~r/\s+#/, parts: 2)
    |> hd()
    |> String.trim()
    |> unquote_value()
  end

  defp unquote_value(<<q, rest::binary>> = value) when q in [?", ?'] do
    if String.ends_with?(rest, <<q>>), do: String.slice(rest, 0..-2//1), else: value
  end

  defp unquote_value(value), do: value

  defp parity_errors(path, text) do
    case parse_yaml(text) do
      {:ok, doc} ->
        parsed = doc |> parsed_uses() |> Enum.frequencies()
        raw = path |> raw_refs(text) |> Enum.map(& &1.value) |> Enum.frequencies()

        if parsed == raw do
          []
        else
          [
            {path, 0,
             "#{path} rule=PIN-PARITY: parsed `uses:` values #{inspect(parsed)} differ from " <>
               "raw `uses:` lines #{inspect(raw)}; write every ref as a plain `uses:` line"}
          ]
        end

      {:error, reason} ->
        [{path, 0, "#{path} rule=PIN-PARITY: YAML does not parse (#{reason})"}]
    end
  end

  defp parsed_uses(doc) do
    job_uses =
      for {_id, job} <- map_entries(yaml_get(doc, "jobs")),
          value <- [yaml_get(job, "uses") | step_uses(yaml_get(job, "steps"))],
          value != nil,
          do: to_string(value)

    composite =
      for value <- step_uses(yaml_get(yaml_get(doc, "runs"), "steps")),
          value != nil,
          do: to_string(value)

    job_uses ++ composite
  end

  defp step_uses(steps) when is_list(steps), do: Enum.map(steps, &yaml_get(&1, "uses"))
  defp step_uses(_), do: []

  defp ref_errors(%{value: "./" <> rel = value} = ref) do
    dir = Path.join(@repo_root, rel)

    if Enum.any?(["action.yml", "action.yaml"], &File.regular?(Path.join(dir, &1))) do
      []
    else
      [
        {ref.path, ref.line,
         "#{ref.path}:#{ref.line} rule=PIN-LOCAL: `#{value}` has no action.yml or action.yaml"}
      ]
    end
  end

  defp ref_errors(%{value: "docker://" <> _ = value} = ref) do
    if String.match?(value, ~r/@sha256:[0-9a-f]{64}$/) do
      []
    else
      [
        {ref.path, ref.line,
         "#{ref.path}:#{ref.line} rule=PIN-DOCKER: `#{value}` is not pinned by @sha256:<digest>"}
      ]
    end
  end

  defp ref_errors(ref) do
    if Regex.match?(@pin_form, ref.text) do
      []
    else
      [
        {ref.path, ref.line,
         "#{ref.path}:#{ref.line} rule=PIN-FORM: #{inspect(String.trim(ref.text))} is not " <>
           "`uses: owner/repo@<40-hex commit SHA> # vX.Y.Z` (unquoted, exact tag)"}
      ]
    end
  end

  defp canonical_pins(raw) do
    Enum.flat_map(raw, fn ref ->
      case Regex.run(@pin_form, ref.text, capture: :all_but_first) do
        [action, sha, tag] ->
          [major | _] = String.split(tag, ".")
          repo = action |> String.split("/") |> Enum.take(2) |> Enum.join("/")
          [Map.merge(ref, %{action: action, sha: sha, tag: tag, repo: repo, major: major})]

        nil ->
          []
      end
    end)
  end

  defp consistent_errors(raw) do
    pins = canonical_pins(raw)

    comment_errors =
      pins
      |> Enum.group_by(&{&1.action, &1.sha})
      |> Enum.flat_map(fn {{action, sha}, group} ->
        tags = group |> Enum.map(& &1.tag) |> Enum.uniq() |> Enum.sort()
        first = Enum.min_by(group, &{&1.path, &1.line})

        if length(tags) > 1 do
          [
            {first.path, first.line,
             "#{first.path}:#{first.line} rule=PIN-CONSISTENT: #{action}@#{sha} carries " <>
               "different tag comments #{inspect(tags)}"}
          ]
        else
          []
        end
      end)

    sha_errors =
      pins
      |> Enum.group_by(&{&1.repo, &1.major})
      |> Enum.flat_map(fn {{repo, major}, group} ->
        shas = group |> Enum.map(& &1.sha) |> Enum.uniq() |> Enum.sort()
        first = Enum.min_by(group, &{&1.path, &1.line})

        if length(shas) > 1 do
          [
            {first.path, first.line,
             "#{first.path}:#{first.line} rule=PIN-CONSISTENT: #{repo} #{major} is pinned to " <>
               "more than one SHA #{inspect(shas)}; one major maps to one commit"}
          ]
        else
          []
        end
      end)

    comment_errors ++ sha_errors
  end

  defp node_file_errors(path, text) do
    case parse_yaml(text) do
      {:ok, doc} ->
        for {job_id, job} <- map_entries(yaml_get(doc, "jobs")),
            steps = yaml_get(job, "steps"),
            is_list(steps),
            {step, index} <- Enum.with_index(steps),
            uses = yaml_get(step, "uses"),
            is_binary(uses) and String.starts_with?(uses, "actions/setup-node@"),
            message = node_file_message(yaml_get(step, "with")),
            message != nil do
          {path, 0, "#{path} job=#{job_id} step=#{index} rule=NODE-FILE: #{message}"}
        end

      {:error, _} ->
        []
    end
  end

  defp node_file_message(with) do
    cond do
      not is_map(with) ->
        "setup-node has no `with:`; set `node-version-file: .tool-versions`"

      yaml_get(with, "node-version") != nil ->
        "setup-node sets `node-version`, which overrides `node-version-file`; remove it"

      to_string(yaml_get(with, "node-version-file")) != ".tool-versions" ->
        "setup-node must read `node-version-file: .tool-versions`"

      true ->
        nil
    end
  end

  defp node_pin_errors(nil) do
    [{".tool-versions", 0, ".tool-versions rule=NODE-PIN: file is missing"}]
  end

  defp node_pin_errors(tool_versions) do
    lines =
      tool_versions
      |> String.split("\n")
      |> Enum.with_index(1)
      |> Enum.reject(fn {line, _} -> String.trim(line) == "" end)

    node_lines =
      Enum.filter(lines, fn {line, _} -> String.match?(line, ~r/^nodejs \d+\.\d+\.\d+$/) end)

    count_errors =
      if length(node_lines) == 1 do
        []
      else
        [
          {".tool-versions", 0,
           ".tool-versions rule=NODE-PIN: expected exactly one `nodejs X.Y.Z` line, " <>
             "found #{length(node_lines)}"}
        ]
      end

    token_errors =
      for {line, number} <- lines, String.match?(line, ~r/^\S+$/) do
        {".tool-versions", number,
         ".tool-versions:#{number} rule=NODE-PIN: single-token line #{inspect(line)} would be " <>
           "read by setup-node as the Node version"}
      end

    count_errors ++ token_errors
  end

  # --- YAML helpers (private copies of ci_token_permissions_contract_test's) --

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

  defp yaml_key(key), do: key |> yaml_key_string() |> String.trim() |> String.downcase()

  defp yaml_get(%{} = map, key) do
    Enum.find_value(map, fn {k, v} -> if yaml_key(k) == key, do: v end)
  end

  defp yaml_get(_data, _key), do: nil

  defp map_entries(%{} = map) do
    map |> Enum.map(fn {k, v} -> {yaml_key_string(k), v} end) |> Enum.sort()
  end

  defp map_entries(_), do: []

  # --- Tests -----------------------------------------------------------------

  defp rule_fired?(errors, rule), do: Enum.any?(errors, &String.contains?(&1, "rule=#{rule}"))

  @checkout_sha "fbc6f3992d24b796d5a048ff273f7fcc4a7b6c09"
  @node_sha "a0853c24544627f65ddf259abe73b1d18a591444"
  @checkout "actions/checkout@" <> @checkout_sha <> " # v5.1.0"

  @base_workflow """
  name: Synthetic
  on: push
  jobs:
    build:
      runs-on: ubuntu-24.04
      steps:
        - uses: #{@checkout}
        - name: Setup Node
          uses: actions/setup-node@#{@node_sha} # v5.0.0
          with:
            node-version-file: .tool-versions
        - name: Second checkout
          uses: #{@checkout}
    gate:
      runs-on: ubuntu-24.04
      steps:
        - uses: re-actors/alls-green@b5b5b37504aa4183270bd3d855c52a67f212be35 # v1.3.0
  """

  @base_tool_versions "nodejs 22.14.0\nerlang 27.3.4.15\nelixir 1.17.3-otp-27\n"

  @path ".github/workflows/synthetic.yml"

  defp base, do: {%{@path => @base_workflow}, @base_tool_versions}

  defp replace_once!(text, from, to) do
    assert String.contains?(text, from), "control anchor not found: #{inspect(from)}"
    String.replace(text, from, to, global: false)
  end

  defp edit_workflow(from, to) do
    fn {texts, tv} -> {Map.update!(texts, @path, &replace_once!(&1, from, to)), tv} end
  end

  defp edit_tool_versions(fun), do: fn {texts, tv} -> {texts, fun.(tv)} end

  defp tag_ref(action, major), do: action <> "@" <> "v" <> major

  @tag :live_tree
  test "live workflows and .tool-versions satisfy every pin rule" do
    errors = pin_errors(live_texts(), live_tool_versions())
    assert errors == [], "pin contract violations:\n" <> Enum.join(errors, "\n")
  end

  describe "positive controls" do
    test "a canonical workflow and .tool-versions pass" do
      {texts, tv} = base()
      assert pin_errors(texts, tv) == []
    end

    test "identical refs merge, and step order never matters" do
      {texts, tv} = base()

      reordered =
        Map.update!(texts, @path, fn text ->
          text
          |> replace_once!("      - name: Second checkout\n        uses: #{@checkout}\n", "")
          |> replace_once!(
            "    steps:\n",
            "    steps:\n      - name: Second checkout\n        uses: #{@checkout}\n"
          )
        end)

      refute reordered == texts
      assert pin_errors(reordered, tv) == []
    end

    test "a docker ref pinned by digest passes" do
      digest = String.duplicate("a", 64)
      {texts, tv} = base()

      texts =
        Map.update!(texts, @path, &(&1 <> "      - uses: docker://alpine@sha256:#{digest}\n"))

      assert pin_errors(texts, tv) == []
    end
  end

  describe "mutation controls" do
    for {label, rule} <- [
          {"tag-only checkout ref", "PIN-FORM"},
          {"7-char short SHA", "PIN-FORM"},
          {"SHA with no comment", "PIN-FORM"},
          {"major-only `# v5` comment", "PIN-FORM"},
          {"quoted ref", "PIN-FORM"},
          {"flow-style step", "PIN-PARITY"},
          {"quoted `uses` key", "PIN-PARITY"},
          {"alias ref", "PIN-PARITY"},
          {"block-scalar ref", "PIN-PARITY"},
          {"unparseable YAML", "PIN-PARITY"},
          {"node-version beside node-version-file", "NODE-FILE"},
          {"setup-node without node-version-file", "NODE-FILE"},
          {"missing nodejs line", "NODE-PIN"},
          {"extra single-token line", "NODE-PIN"},
          {"same major, two SHAs", "PIN-CONSISTENT"},
          {"same SHA, two comments", "PIN-CONSISTENT"},
          {"missing local action", "PIN-LOCAL"},
          {"docker ref by tag", "PIN-DOCKER"},
          {"zero refs", "PIN-SCAN"},
          {"empty file list", "PIN-SCAN"}
        ] do
      test "#{label} fires rule=#{rule}" do
        base = base()
        mutated = mutation(unquote(label)).(base)
        refute mutated == base, "the control did not change the input"
        {texts, tv} = mutated
        errors = pin_errors(texts, tv)

        assert rule_fired?(errors, unquote(rule)),
               "expected rule=#{unquote(rule)}, got:\n" <> Enum.join(errors, "\n")
      end
    end
  end

  defp mutation("tag-only checkout ref"),
    do: edit_workflow(@checkout, tag_ref("actions/checkout", "5"))

  defp mutation("7-char short SHA"),
    do: edit_workflow(@checkout, "actions/checkout@fbc6f39 # v5.1.0")

  defp mutation("SHA with no comment"),
    do: edit_workflow(@checkout, "actions/checkout@" <> @checkout_sha)

  defp mutation("major-only `# v5` comment"),
    do: edit_workflow(@checkout, "actions/checkout@" <> @checkout_sha <> " # v5")

  defp mutation("quoted ref"),
    do:
      edit_workflow("uses: " <> @checkout, "uses: \"actions/checkout@#{@checkout_sha}\" # v5.1.0")

  defp mutation("flow-style step"),
    do:
      edit_workflow(
        "      - uses: #{@checkout}\n",
        "      - {uses: #{tag_ref("actions/checkout", "5")}}\n"
      )

  defp mutation("quoted `uses` key"),
    do:
      edit_workflow(
        "      - uses: #{@checkout}\n",
        "      - \"uses\": #{tag_ref("actions/checkout", "5")}\n"
      )

  defp mutation("alias ref") do
    fn {texts, tv} ->
      text =
        texts[@path]
        |> replace_once!(
          "on: push\n",
          "on: push\nenv:\n  REF: &ref #{tag_ref("actions/checkout", "5")}\n"
        )
        |> replace_once!("      - uses: #{@checkout}\n", "      - uses: *ref\n")

      {Map.put(texts, @path, text), tv}
    end
  end

  defp mutation("block-scalar ref"),
    do:
      edit_workflow(
        "      - uses: #{@checkout}\n",
        "      - uses: >-\n          #{tag_ref("actions/checkout", "5")}\n"
      )

  defp mutation("unparseable YAML"), do: edit_workflow("jobs:\n", "jobs: [\n")

  defp mutation("node-version beside node-version-file"),
    do:
      edit_workflow(
        "node-version-file: .tool-versions\n",
        "node-version-file: .tool-versions\n          node-version: \"22\"\n"
      )

  defp mutation("setup-node without node-version-file"),
    do: edit_workflow("node-version-file: .tool-versions\n", "cache: npm\n")

  defp mutation("missing nodejs line"),
    do: edit_tool_versions(&replace_once!(&1, "nodejs 22.14.0\n", ""))

  defp mutation("extra single-token line"), do: edit_tool_versions(&("#pinned\n" <> &1))

  defp mutation("same major, two SHAs"),
    do:
      edit_workflow(
        "  uses: #{@checkout}",
        "  uses: actions/checkout@#{String.duplicate("b", 40)} # v5.1.0"
      )

  defp mutation("same SHA, two comments"),
    do:
      edit_workflow("  uses: #{@checkout}", "  uses: actions/checkout@#{@checkout_sha} # v5.0.9")

  defp mutation("missing local action"),
    do: edit_workflow("      - uses: #{@checkout}\n", "      - uses: ./.github/actions/missing\n")

  defp mutation("docker ref by tag"),
    do: edit_workflow("      - uses: #{@checkout}\n", "      - uses: docker://alpine:3.20\n")

  defp mutation("zero refs") do
    fn {_texts, tv} -> {%{@path => "name: Empty\non: push\njobs: {}\n"}, tv} end
  end

  defp mutation("empty file list"), do: fn {_texts, tv} -> {%{}, tv} end
end
