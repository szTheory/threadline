defmodule Threadline.ReleaseArtifactContractTest do
  @moduledoc false
  use ExUnit.Case, async: false

  alias Mix.Tasks.Release.Pins

  @banned_shapes [
    {:phase_prose, ~r/\bPhase\s+\d+(?:\.\d+)?\b/i},
    {:phase_identifier, ~r/\bphase[_-]?\d+(?:[_-][a-z0-9_]+)?\b/i},
    {:decision_id, ~r/\bD-\d{2,}\b/},
    {:requirement_id,
     ~r/\b(?:ADOPT|COMP|CRITIC|DATA|GREEN|GROUP|MECH|NAV|PROOF|SURFACE|WR)-\d{2,}\b/},
    {:milestone_literal, ~r/\bv1\.(?:3[4-9]|4[01])\b/}
  ]

  @source_owners %{
    source_vocab_core_runtime: [
      "lib/mix/tasks/threadline.health.coverage.ex",
      "lib/threadline/capture/audit_transaction.ex",
      "lib/threadline/plug.ex"
    ],
    source_vocab_core_query_policy: [
      "lib/threadline/query.ex",
      "lib/threadline/retention/policy.ex"
    ],
    # The stress/mechanical harness and the critic tooling are no longer
    # packaged (see `exclude_patterns` in mix.exs), so they cannot be archive
    # source owners — their vocabulary never reaches an adopter. The archive
    # refutations below assert their absence instead.
    source_vocab_operator_infrastructure: [
      "lib/threadline/operator_surface/components/logo.ex",
      "lib/threadline/operator_surface/controllers/export_controller/encoding.ex"
    ],
    source_vocab_operator_live_forms: [
      "lib/threadline/operator_surface/live/actor_live.ex",
      "lib/threadline/operator_surface/live/coverage_live.ex",
      "lib/threadline/operator_surface/live/evidence_live.ex",
      "lib/threadline/operator_surface/live/export_status_live.ex",
      "lib/threadline/operator_surface/live/export_status_live/components.ex",
      "lib/threadline/operator_surface/live/policy_redaction_live.ex"
    ],
    source_vocab_operator_live_records: [
      "lib/threadline/operator_surface/live/retention_history_live.ex",
      "lib/threadline/operator_surface/live/row_history_live.ex",
      "lib/threadline/operator_surface/live/start_live.ex",
      "lib/threadline/operator_surface/live/timeline_live.ex",
      "lib/threadline/operator_surface/live/timeline_live/filters.ex",
      "lib/threadline/operator_surface/live/timeline_live/helpers.ex",
      "lib/threadline/operator_surface/live/transaction_live.ex"
    ]
  }

  defp project_config, do: Threadline.MixProject.project()

  defp docs_config, do: project_config()[:docs]

  defp package_files, do: MapSet.new(project_config()[:package][:files])

  defp guide_extras do
    docs_config()[:extras]
    |> Enum.filter(&(is_binary(&1) and String.starts_with?(&1, "guides/")))
    |> MapSet.new()
  end

  defp guides_on_disk do
    Path.wildcard("guides/**/*.md")
    |> MapSet.new()
  end

  test "guides on disk match the ExDoc guide extras allowlist" do
    assert guide_extras() == guides_on_disk()
  end

  test "release package includes the shipped documentation surfaces" do
    files = package_files()
    extras = docs_config()[:extras]

    assert "guides" in files
    assert "README.md" in files
    assert "CHANGELOG.md" in files
    assert "CONTRIBUTING.md" in files
    assert "README.md" in extras
    assert "CONTRIBUTING.md" in extras
    assert "CHANGELOG.md" in extras
    assert "brandbook/logo-primary.svg" in files
    assert "brandbook/logo-primary-light.svg" in files
    assert docs_config()[:assets] == %{"brandbook" => "brandbook"}
  end

  @tag :url_extras
  test "README-led docs expose version-pinned repository resources without packaging them" do
    docs = docs_config()
    assert docs[:main] == "readme"
    assert docs[:extra_section] == "Guides"
    assert "guides/configuration-and-commands.md" in docs[:extras]

    assert Keyword.keys(docs[:groups_for_extras]) == [
             :Overview,
             :Integrations,
             :Evaluate,
             :Adopt,
             :Operate,
             :Contribute
           ]

    external = Enum.filter(docs[:extras], &is_tuple/1)
    assert length(external) == 2

    targets =
      Enum.map(external, fn {url, opts} ->
        assert opts[:url] == url
        assert is_binary(opts[:title]) and opts[:title] != ""
        assert Regex.match?(~r{/blob/v\d+\.\d+\.\d+/(.+)$}, url)
        [_, target] = Regex.run(~r{/blob/[^/]+/(.+)$}, url)
        target
      end)

    assert MapSet.new(targets) ==
             MapSet.new(["DESIGN-SYSTEM.md", "examples/threadline_phoenix/README.md"])

    refute "DESIGN-SYSTEM.md" in package_files()
    refute "examples/threadline_phoenix/README.md" in package_files()

    groups = docs[:groups_for_extras]

    example_url =
      Enum.find_value(external, fn {url, _opts} ->
        if String.ends_with?(url, "examples/threadline_phoenix/README.md"), do: url
      end)

    design_url =
      Enum.find_value(external, fn {url, _opts} ->
        if String.ends_with?(url, "DESIGN-SYSTEM.md"), do: url
      end)

    assert Regex.match?(Keyword.fetch!(groups, :Adopt), example_url)
    assert Regex.match?(Keyword.fetch!(groups, :Contribute), design_url)
  end

  test "built Hex archive excludes repository evidence" do
    %{entries: entries, readable: readable} = built_archive()

    assert entries != [], "unpacked Hex archive contained no files"
    assert map_size(readable) > 0, "unpacked Hex archive contained no readable UTF-8 files"
    assert "lib/threadline.ex" in entries
    assert "mix.exs" in entries
    assert "lib/threadline/operator_surface/style/01_tokens.css" in entries
    assert "lib/threadline/operator_surface/style/02_base_shell.css" in entries
    assert "lib/threadline/operator_surface/style/03_page_home.css" in entries
    assert "lib/threadline/operator_surface/style/04_controls.css" in entries
    assert "lib/threadline/operator_surface/style/05_feedback.css" in entries
    assert "lib/threadline/operator_surface/style/06_layout_primitives.css" in entries
    assert "lib/threadline/operator_surface/style/07_find_detail.css" in entries
    assert "lib/threadline/operator_surface/style/08_overlays_motion.css" in entries
    assert "lib/threadline/operator_surface/style/09_responsive.css" in entries
    assert Map.has_key?(readable, "lib/threadline.ex")
    assert Map.has_key?(readable, "mix.exs")
    refute Enum.any?(entries, &String.starts_with?(&1, "test/fixtures/"))
    refute Enum.any?(entries, &String.starts_with?(&1, ".planning/"))
  end

  # Maintainer-only tooling, enumerated from `git ls-files 'lib/**'` rather than
  # from any prose figure. Each path must exist in the repository (otherwise
  # this guard would pass because the file was renamed, not because it was
  # excluded) and must be absent from the built archive.
  @maintainer_only_paths [
    "lib/mix/tasks/critic.measure.ex",
    "lib/mix/tasks/critic.synth.ex",
    "lib/mix/tasks/release.pins.ex",
    "lib/threadline/critic_trust/krippendorff_alpha.ex",
    "lib/threadline/critic_trust/ledger_splice.ex",
    "lib/threadline/critic_trust/measure.ex",
    "lib/threadline/critic_trust/rank_metrics.ex",
    "lib/threadline/operator_surface/live/stress_live.ex",
    "lib/threadline/operator_surface/live/stress_live/paths.ex",
    "lib/threadline/operator_surface/live/stress_live/refute.ex",
    "lib/threadline/operator_surface/live/stress_live/sections.ex",
    "lib/threadline/operator_surface/mechanical_checker.ex",
    "lib/threadline/operator_surface/mechanical_checker/accent_hue.ex",
    "lib/threadline/operator_surface/mechanical_checker/contrast.ex",
    "lib/threadline/operator_surface/mechanical_checker/parsing.ex",
    "lib/threadline/operator_surface/mechanical_checker/ratchet_metrics.ex",
    "lib/threadline/operator_surface/mechanical_checker/scorecards.ex",
    "lib/threadline/operator_surface/mechanical_checker/token_conformance.ex",
    "lib/threadline/operator_surface/stress_fixtures.ex",
    "lib/threadline/operator_surface/stress_router.ex"
  ]

  @maintainer_only_prefixes [
    "lib/mix/tasks/critic.",
    "lib/threadline/critic_trust/",
    "lib/threadline/operator_surface/live/stress_live/",
    "lib/threadline/operator_surface/mechanical_checker/"
  ]

  test "built Hex archive excludes maintainer-only tooling" do
    %{entries: entries} = built_archive()

    # Populated-archive assertions first: a refutation over an empty archive is
    # the vacuous-gate shape this repository has already been bitten by.
    assert entries != [], "unpacked Hex archive contained no files"
    assert "lib/threadline.ex" in entries
    assert "mix.exs" in entries

    for path <- @maintainer_only_paths do
      assert File.regular?(path),
             "#{path} is enumerated as maintainer-only tooling but does not exist in the " <>
               "repository. Either it was renamed — in which case this list and the " <>
               "`exclude_patterns` in mix.exs must move with it — or this guard is asserting " <>
               "the absence of a file that could not have been present anyway."

      refute path in entries,
             "#{path} is maintainer-only tooling and was published in the Hex archive. Two of " <>
               "the critic tasks carry a `@shortdoc`, so shipping them puts maintainer " <>
               "instruments in every adopter's `mix help` under a namespace that is not this " <>
               "library's — and nothing in a published version can be withdrawn from it. Add " <>
               "the path to `exclude_patterns` in mix.exs `package/0`."
    end

    for prefix <- @maintainer_only_prefixes do
      offenders = Enum.filter(entries, &String.starts_with?(&1, prefix))

      assert offenders == [],
             "the published archive carries #{length(offenders)} file(s) under the " <>
               "maintainer-only prefix `#{prefix}`: #{Enum.join(offenders, ", ")}. A new file " <>
               "added under that prefix is excluded by pattern, not by enumeration — if these " <>
               "appear, the pattern in mix.exs `exclude_patterns` stopped matching."
    end
  end

  test "the bot-owned generated changelog is never adopter surface" do
    %{entries: entries} = built_archive()

    assert entries != [], "unpacked Hex archive contained no files"
    assert "CHANGELOG.md" in entries

    refute "CHANGELOG-GENERATED.md" in entries,
           "CHANGELOG-GENERATED.md is release-automation output — a raw commit-subject dump " <>
             "carrying internal vocabulary — and was published in the Hex archive. The file " <>
             "adopters read is the human-owned CHANGELOG.md. Keep the generated file out of " <>
             "`package[:files]`."

    refute "CHANGELOG-GENERATED.md" in docs_config()[:extras],
           "CHANGELOG-GENERATED.md is listed in the ExDoc extras, which would render " <>
             "release-automation output as a documentation page on the published docs site."
  end

  test "planning-vocabulary matcher rejects every representative offender" do
    offenders = [
      {"README.md", "Phase 200 prepared this text"},
      {"lib/sample.ex", "def phase177_gate, do: :ok"},
      {"guides/sample.md", "Decision D-14 owns this"},
      {"mix.exs", "SURFACE-07"},
      {"CHANGELOG.md", "Milestone v1.41"}
    ]

    for {path, content} <- offenders do
      assert [_ | _] = planning_vocabulary_matches(%{path => content}),
             "positive control did not flag #{path}: #{content}"
    end

    assert planning_vocabulary_matches(%{
             "lib/logo.ex" => "path d=\"M13 4 C13 8\"",
             "README.md" => "Threadline 0.9 audit data"
           }) == []
  end

  for {tag, paths} <- @source_owners do
    @tag tag
    @tag :phase200_red
    test "#{tag} is an exact nonempty archive source owner" do
      expected = unquote(Macro.escape(paths))
      assert expected != []
      assert Enum.all?(expected, &File.regular?/1)

      archive = built_archive()
      selected = Map.take(archive.readable, expected)
      assert Map.keys(selected) |> Enum.sort() == Enum.sort(expected)

      matches = planning_vocabulary_matches(selected)
      assert matches == [], format_vocab_matches(matches)

      injected = Map.put(selected, hd(expected), File.read!(hd(expected)) <> "\nD-99\n")
      assert Enum.any?(planning_vocabulary_matches(injected), &(&1.path == hd(expected)))
    end
  end

  @tag :source_module_vocabulary
  @tag :phase200_red
  @tag :phase200_aggregate
  test "all packaged source uses durable vocabulary" do
    archive = built_archive()

    source =
      archive.readable
      |> Map.filter(fn {path, _content} ->
        path == "mix.exs" or
          (String.starts_with?(path, "lib/") and String.ends_with?(path, ".ex"))
      end)

    assert map_size(source) > 0
    assert Map.has_key?(source, "lib/threadline.ex")
    matches = planning_vocabulary_matches(source)
    assert matches == [], format_vocab_matches(matches)
  end

  @tag :archive_vocabulary
  @tag :phase200_red
  @tag :phase200_aggregate
  test "the entire readable archive is free of planning vocabulary" do
    archive = built_archive()
    assert map_size(archive.readable) > 0
    matches = planning_vocabulary_matches(archive.readable)
    assert matches == [], format_vocab_matches(matches)
  end

  test "ExDoc extras keep integrations ahead of the verb routing lanes" do
    assert Keyword.keys(docs_config()[:groups_for_extras]) == [
             :Overview,
             :Integrations,
             :Evaluate,
             :Adopt,
             :Operate,
             :Contribute
           ]
  end

  test "ExDoc module groups keep integration and operator entrypoints discoverable" do
    groups = docs_config()[:groups_for_modules]

    assert Keyword.fetch!(groups, :Integrations) == [Threadline.Integrations.Sigra]

    assert Keyword.fetch!(groups, :"Operator Surface") == [
             Threadline.OperatorSurface,
             Threadline.OperatorSurface.Router,
             Threadline.OperatorSurface.Auth
           ]

    core_api = Keyword.fetch!(groups, :"Core API")

    for module <- [
          Threadline.Plug,
          Threadline.Job,
          Threadline.Health,
          Threadline.Continuity,
          Threadline.Telemetry
        ] do
      assert module in core_api
    end
  end

  test "ExDoc module groups include public evidence types and adopter Mix tasks" do
    groups = docs_config()[:groups_for_modules]

    data_types = Keyword.fetch!(groups, :"Data Types")
    assert Threadline.Evidence.Proof in data_types
    assert Threadline.Evidence.Subject in data_types

    core_api = Keyword.fetch!(groups, :"Core API")
    assert Threadline.Audit in core_api
    assert Threadline.Evidence in core_api

    mix_tasks = Keyword.fetch!(groups, :"Mix Tasks")
    assert Mix.Tasks.Threadline.Evidence.Show in mix_tasks
  end

  test "README carries only the release-scoped installer and routing literals" do
    readme = File.read!("README.md")

    # The expected pin is asked of `mix release.pins` rather than written here.
    # That task is the designated sole writer of every documented install pin,
    # so a literal in this assertion would be a second, hand-maintained copy of
    # the value the writer exists to change — the contract would go red the
    # moment the writer did its job. `release.pins.ex` rules out extracting its
    # rules into a shared module ("A shared module would be new production
    # surface for a release-time-only concern"), so the task exposes its own
    # derivation and this contract consults it: one rule, one owner, two
    # readers. Reimplementing `major.minor.0` here would be the same drift
    # footgun one step removed.
    expected_pin = ~s({:threadline, "~> #{Pins.target_pin_version()}"})

    assert String.contains?(readme, expected_pin),
           "README.md does not carry the install pin derived from mix.exs @version.\n" <>
             "  expected: #{expected_pin}\n" <>
             "  actual:   #{readme_install_pins(readme)}\n" <>
             "`mix release.pins` owns every documented pin — run it rather than " <>
             "editing the pin by hand."

    assert String.contains?(readme, "guides/how-threadline-works.md")
    assert String.contains?(readme, "guides/getting-started-saas.md")
    assert String.contains?(readme, "guides/integrations/sigra.md")
  end

  test "CONTRIBUTING carries the release pre-flight and release workflow literals" do
    doc = File.read!("CONTRIBUTING.md")

    assert String.contains?(doc, "mix verify.release")
    assert String.contains?(doc, ".github/workflows/release.yml")
    assert String.contains?(doc, "workflow_dispatch")
    assert String.contains?(doc, "v0.6.0")
  end

  # Reports what README actually says, for the failure message only. This is a
  # plain line filter, not a version matcher: the install-pin regex lives in
  # `mix release.pins` and in the version-truth contract as two deliberately
  # character-identical copies, and a third copy here would weaken that
  # self-policing pair.
  defp readme_install_pins(readme) do
    readme
    |> String.split("\n")
    |> Enum.filter(&String.contains?(&1, "{:threadline,"))
    |> Enum.map(&String.trim/1)
    |> case do
      [] -> "(README carries no `{:threadline, ...}` install snippet at all)"
      lines -> Enum.join(lines, " | ")
    end
  end

  defp built_archive do
    unpack_root =
      Path.join(
        System.tmp_dir!(),
        "threadline-hex-contract-#{System.unique_integer([:positive])}"
      )

    on_exit(fn -> File.rm_rf!(unpack_root) end)

    case System.cmd(
           System.find_executable("mix"),
           ["hex.build", "--unpack", "--output", unpack_root],
           cd: File.cwd!(),
           env: [{"MIX_ENV", "dev"}],
           stderr_to_stdout: true
         ) do
      {_output, 0} ->
        files =
          unpack_root
          |> Path.join("**/*")
          |> Path.wildcard(match_dot: true)
          |> Enum.filter(&File.regular?/1)

        entries = files |> Enum.map(&Path.relative_to(&1, unpack_root)) |> Enum.sort()

        readable =
          Enum.reduce(files, %{}, fn path, acc ->
            put_readable(acc, Path.relative_to(path, unpack_root), File.read(path))
          end)

        %{entries: entries, readable: readable}

      {output, status} ->
        flunk("mix hex.build --unpack failed (#{status}):\n#{output}")
    end
  end

  defp put_readable(acc, relative, {:ok, content}) do
    if String.valid?(content), do: Map.put(acc, relative, content), else: acc
  end

  defp put_readable(acc, _relative, {:error, _reason}), do: acc

  defp planning_vocabulary_matches(files) do
    for {path, content} <- files,
        {line, line_number} <- content |> String.split("\n") |> Enum.with_index(1),
        {shape, regex} <- @banned_shapes,
        Regex.match?(regex, path) or Regex.match?(regex, line),
        do: %{path: path, line: line_number, shape: shape, text: String.trim(line)}
  end

  defp format_vocab_matches(matches) do
    details =
      Enum.map_join(matches, "\n", fn match ->
        "#{match.path}:#{match.line}: #{match.shape}: #{match.text}"
      end)

    "packaged planning vocabulary must be rewritten as durable domain rationale:\n#{details}"
  end
end
