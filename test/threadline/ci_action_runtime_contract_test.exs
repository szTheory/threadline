defmodule Threadline.CiActionRuntimeContractTest do
  @moduledoc false
  use ExUnit.Case, async: true
  @moduletag :repo_contract

  @repo_root File.cwd!()

  # Fail-closed allowlist of every `{action, major}` pair a workflow may use.
  #
  # Every ref is pinned as `owner/repo@<40-hex SHA> # vX.Y.Z`
  # (test/threadline/ci_action_pin_contract_test.exs); the major is read from
  # that `# vX.Y.Z` comment. Keying by major, not SHA, keeps a patch or minor
  # re-pin green while a major bump fails closed. Each entry was verified by
  # fetching the action.yml at a release of that major and reading
  # `runs.using`. To add an action or move to a new major, fetch its action.yml
  # at the pinned commit, confirm `node24`, `composite` or `docker`, then add
  # the entry here. Anything not listed (including a Node 20 major) and any ref
  # without a parseable `# vX.Y.Z` comment fails the live scan.
  @node24_or_non_js %{
    {"actions/checkout", "v5"} => :node24,
    {"erlef/setup-beam", "v1"} => :node24,
    {"actions/setup-node", "v5"} => :node24,
    {"actions/cache", "v5"} => :node24,
    {"actions/cache/restore", "v5"} => :node24,
    {"actions/cache/save", "v5"} => :node24,
    {"actions/upload-artifact", "v7"} => :node24,
    {"actions/github-script", "v8"} => :node24,
    {"googleapis/release-please-action", "v5"} => :node24,
    {"re-actors/alls-green", "v1"} => :composite
  }

  @remedy "fetch the action's action.yml at the pinned commit, confirm `runs.using` is " <>
            "node24, composite or docker, then add the {action, major} pair to " <>
            "@node24_or_non_js in this test"

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  # Globs BOTH extensions on purpose. GitHub Actions honours .yaml as well as
  # .yml, so a guard that only globbed .yml could be defeated by a rename.
  defp workflow_paths do
    paths =
      @repo_root
      |> Path.join(".github/workflows/*.{yml,yaml}")
      |> Path.wildcard()
      |> Enum.map(&Path.relative_to(&1, @repo_root))
      |> Enum.sort()

    assert paths != [],
           "no workflow files found under .github/workflows — refusing to pass vacuously"

    paths
  end

  defp live_yaml_by_path do
    Map.new(workflow_paths(), &{&1, read_rel!([&1])})
  end

  defp strip_comment_lines(block) do
    block
    |> String.split("\n")
    |> Enum.reject(&String.match?(&1, ~r/^\s*#/))
    |> Enum.join("\n")
  end

  @pinned_major ~r/uses:\s*([^\s@"']+)@[0-9a-f]{40}\s+#\s*(v\d+)\.\d+\.\d+/

  # Returns every `uses:` ref on comment-stripped lines, in both the mapping
  # form (`uses: x@y`) and the list-item form (`- uses: x@y`), quoted or not.
  # A SHA-pinned ref with a `# vX.Y.Z` comment becomes `{:pair, {action,
  # major}}`. Local (`./`), `docker://` and refs with no parseable comment
  # major come back tagged so they are reported, never silently skipped.
  defp uses_refs(yaml) do
    ~r/^\s*(?:-\s+)?uses:\s*["']?([^\s"'#]+).*$/m
    |> Regex.scan(strip_comment_lines(yaml))
    |> Enum.map(fn [line, value] -> classify_ref(line, value) end)
  end

  defp classify_ref(_line, "./" <> _ = value), do: {:needs_decision, value}
  defp classify_ref(_line, "docker://" <> _ = value), do: {:needs_decision, value}

  defp classify_ref(line, value) do
    case Regex.run(@pinned_major, line, capture: :all_but_first) do
      [action, major] -> {:pair, {action, major}}
      nil -> {:no_major, value}
    end
  end

  defp node20_errors(yaml_by_path) do
    yaml_by_path
    |> Enum.sort()
    |> Enum.flat_map(fn {path, yaml} ->
      yaml |> uses_refs() |> Enum.flat_map(&ref_error(path, &1))
    end)
  end

  defp ref_error(path, {:pair, {action, major} = pair}) do
    if Map.has_key?(@node24_or_non_js, pair) do
      []
    else
      [
        "#{path}: #{action} #{major} is not verified as a Node 24 (or non-JavaScript) " <>
          "action — #{@remedy}"
      ]
    end
  end

  defp ref_error(path, {:no_major, value}) do
    [
      "#{path}: `uses: #{value}` has no `@<40-hex SHA> # vX.Y.Z` pin, so its major " <>
        "cannot be read — pin it to a commit SHA with its exact release tag as a comment"
    ]
  end

  defp ref_error(path, {:needs_decision, value}) do
    [
      "#{path}: `uses: #{value}` is a local, docker or unpinned ref and needs an " <>
        "explicit allowlist decision before any workflow may use it"
    ]
  end

  defp used_pairs(yaml_by_path) do
    yaml_by_path
    |> Map.values()
    |> Enum.flat_map(&uses_refs/1)
    |> Enum.flat_map(fn
      {:pair, pair} -> [pair]
      _ -> []
    end)
    |> Enum.uniq()
  end

  @runbook_heading "### Upgrading the Release Please action"

  @runbook_remedy "bumping the Release Please action requires re-running the documented " <>
                    "rehearsal and updating this runbook in the same change"

  defp release_please_runbook_errors(release_yml, contributing) do
    case Regex.run(
           ~r/googleapis\/release-please-action@[0-9a-f]{40}\s+#\s*v(\d+)\.\d+\.\d+/,
           strip_comment_lines(release_yml),
           capture: :all_but_first
         ) do
      [major] ->
        runbook_section_errors(runbook_section(contributing), major)

      nil ->
        [
          "release.yml has no googleapis/release-please-action@<sha> # vN.N.N ref — " <>
            @runbook_remedy
        ]
    end
  end

  defp runbook_section(contributing) do
    case String.split(contributing, "\n" <> @runbook_heading <> "\n", parts: 2) do
      [_before, rest] -> rest |> String.split(~r/^\#{2,3} /m, parts: 2) |> List.first()
      [_] -> nil
    end
  end

  defp runbook_section_errors(nil, _major) do
    ["CONTRIBUTING.md has no \"#{@runbook_heading}\" subsection — #{@runbook_remedy}"]
  end

  defp runbook_section_errors(section, major) do
    [
      {String.contains?(section, "googleapis/release-please-action@v#{major}"),
       "the runbook does not name googleapis/release-please-action@v#{major}, the major " <>
         "release.yml uses"},
      {String.contains?(section, "--dry-run"),
       "the runbook does not give the --dry-run rehearsal"},
      {Regex.match?(~r/release-please(?: |@)\d+\.\d+\.\d+/, section),
       "the runbook does not name the bundled release-please library version"}
    ]
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(&"#{elem(&1, 1)} — #{@runbook_remedy}")
  end

  describe "release_please_runbook_errors/2" do
    setup do
      %{
        release_yml: read_rel!([".github", "workflows", "release.yml"]),
        contributing: read_rel!(["CONTRIBUTING.md"])
      }
    end

    test "the runbook matches release.yml's action major", ctx do
      assert release_please_runbook_errors(ctx.release_yml, ctx.contributing) == []
    end

    test "fails when release.yml moves to a major the runbook does not name", ctx do
      bumped =
        String.replace(
          ctx.release_yml,
          ~r/(googleapis\/release-please-action@[0-9a-f]{40}\s+#\s*)v\d+\.\d+\.\d+/,
          "\\1" <> "v6.0.0"
        )

      refute bumped == ctx.release_yml, "the control did not change the input"

      assert [message] = release_please_runbook_errors(bumped, ctx.contributing)
      assert message =~ "@v6"
      assert message =~ "re-running the documented rehearsal"
    end

    test "fails when the runbook heading is deleted", ctx do
      without = String.replace(ctx.contributing, @runbook_heading <> "\n", "")
      assert [message] = release_please_runbook_errors(ctx.release_yml, without)
      assert message =~ "no \"#{@runbook_heading}\" subsection"
    end

    test "fails when the bundled library version is removed from the runbook", ctx do
      section = runbook_section(ctx.contributing)
      stripped = Regex.replace(~r/release-please(?: |@)\d+\.\d+\.\d+/, section, "release-please")
      mutated = String.replace(ctx.contributing, section, stripped)

      assert [message] = release_please_runbook_errors(ctx.release_yml, mutated)
      assert message =~ "bundled release-please library version"
    end
  end

  describe "live workflows" do
    test "every workflow action ref is verified as Node 24 or non-JavaScript" do
      yaml_by_path = live_yaml_by_path()

      assert node20_errors(yaml_by_path) == []

      ref_count = yaml_by_path |> Map.values() |> Enum.flat_map(&uses_refs/1) |> length()

      assert ref_count > 0,
             "the workflow scan found no `uses:` refs at all — the scanner is broken, " <>
               "not the workflows clean"
    end

    test "every allowlist entry is used by at least one workflow" do
      unused = Map.keys(@node24_or_non_js) -- used_pairs(live_yaml_by_path())

      assert unused == [],
             "stale @node24_or_non_js entries (used by no workflow; remove them so the " <>
               "allowlist stays an exact record of what runs): #{inspect(Enum.sort(unused))}"
    end
  end

  @sha "0123456789abcdef0123456789abcdef01234567"

  defp pinned(action, tag), do: action <> "@" <> @sha <> " # " <> tag

  describe "node20_errors/1 mutation controls" do
    test "flags a known Node 20 cache major" do
      yaml = "      - name: Cache\n        uses: " <> pinned("actions/cache", "v4.2.0") <> "\n"
      assert [message] = node20_errors(%{"synthetic.yml" => yaml})
      assert message =~ "actions/cache v4"
      assert message =~ "synthetic.yml"
    end

    test "flags the previous Release Please action major" do
      yaml = "        uses: " <> pinned("googleapis/release-please-action", "v4.1.0") <> "\n"
      assert [_] = node20_errors(%{"synthetic.yml" => yaml})
    end

    test "fails closed on an unknown action" do
      yaml = "        uses: " <> pinned("some-org/new-action", "v1.0.0") <> "\n"
      assert [message] = node20_errors(%{"synthetic.yml" => yaml})
      assert message =~ "some-org/new-action v1"
      assert message =~ "action.yml"
    end

    test "fails closed on a major bump of an allowlisted action" do
      yaml = "        uses: " <> pinned("actions/checkout", "v7.0.1") <> "\n"
      assert [message] = node20_errors(%{"synthetic.yml" => yaml})
      assert message =~ "actions/checkout v7"
    end

    test "a patch or minor re-pin of an allowlisted major stays green" do
      yaml = "        uses: " <> pinned("actions/checkout", "v5.9.3") <> "\n"
      assert node20_errors(%{"synthetic.yml" => yaml}) == []
    end

    test "flags a tag-only ref as having no readable major" do
      yaml = "      - uses: " <> "actions/checkout@" <> "v" <> "5" <> "\n"
      assert [message] = node20_errors(%{"synthetic.yml" => yaml})
      assert message =~ "has no `@<40-hex SHA> # vX.Y.Z` pin"
    end

    test "flags a SHA pin with no version comment" do
      yaml = "      - uses: actions/checkout@" <> @sha <> "\n"
      assert [message] = node20_errors(%{"synthetic.yml" => yaml})
      assert message =~ "has no `@<40-hex SHA> # vX.Y.Z` pin"
    end

    test "flags the list-item form" do
      yaml = "      - uses: " <> pinned("actions/upload-artifact", "v4.6.0") <> "\n"
      assert [message] = node20_errors(%{"synthetic.yml" => yaml})
      assert message =~ "actions/upload-artifact v4"
    end

    test "flags a quoted ref" do
      yaml = "        uses: \"" <> "actions/cache@" <> @sha <> "\" # v4.2.0\n"
      assert [message] = node20_errors(%{"synthetic.yml" => yaml})
      assert message =~ "actions/cache@"
    end

    test "ignores a commented-out ref" do
      yaml = "        # uses: " <> pinned("actions/cache", "v4.2.0") <> "\n"
      assert node20_errors(%{"synthetic.yml" => yaml}) == []
    end

    test "reports local and docker refs as needing an explicit decision" do
      yaml = """
            - uses: ./.github/actions/setup
            - uses: docker://alpine:3.20
      """

      errors = node20_errors(%{"synthetic.yml" => yaml})
      assert length(errors) == 2
      assert Enum.all?(errors, &(&1 =~ "explicit allowlist decision"))
    end

    test "passes a benign workflow that uses only allowlisted refs" do
      yaml = """
      jobs:
        build:
          steps:
            - uses: #{pinned("actions/checkout", "v5.1.0")}
            - name: Cache
              uses: #{pinned("actions/cache", "v5.1.0")}
            - uses: #{pinned("erlef/setup-beam", "v1.24.1")}
      """

      assert node20_errors(%{"synthetic.yml" => yaml}) == []
    end
  end
end
