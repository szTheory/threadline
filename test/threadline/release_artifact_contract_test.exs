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
    # The stress/mechanical harness and the maintainer tooling are not
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

  @release_please_config "release-please-config.json"

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
    "lib/mix/tasks/release.pins.ex",
    "lib/threadline/operator_surface/live/stress_live.ex",
    "lib/threadline/operator_surface/live/stress_live/paths.ex",
    "lib/threadline/operator_surface/live/stress_live/sections.ex",
    "lib/threadline/operator_surface/stress_fixtures.ex",
    "lib/threadline/operator_surface/stress_router.ex"
  ]

  @maintainer_only_prefixes [
    "lib/threadline/operator_surface/live/stress_live/"
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
             "#{path} is maintainer-only tooling and was published in the Hex archive. Shipping " <>
               "a maintainer instrument puts repository-only code in every adopter's " <>
               "dependency tree — and nothing in a published version can be withdrawn from it. Add " <>
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

  # Unshipped tracked files that `exclude-paths` cannot cover. Release Please
  # matches entries as directory prefixes only, so a top-level file, a file
  # sitting directly in a directory that also ships files (`brandbook/`), or a
  # single module excluded from the package by `exclude_patterns` in mix.exs
  # can never be listed. A commit touching only these paths is kept out of a
  # release by its commit type instead (CONTRIBUTING "Ongoing releases"). The
  # list is pinned so that every new entry is a conscious decision.
  @exclude_paths_residue [
    ".credo.exs",
    ".dialyzer_ignore.exs",
    ".dockerignore",
    ".env.example",
    ".gitignore",
    ".release-please-manifest.json",
    ".tool-versions",
    "AGENTS.md",
    "CHANGELOG-GENERATED.md",
    "CLAUDE.md",
    "CODE_OF_CONDUCT.md",
    "DESIGN-SYSTEM.md",
    "GEMINI.md",
    "PRODUCT.md",
    "SECURITY.md",
    "brandbook/README.md",
    "brandbook/brand-book.md",
    "brandbook/index.html",
    "brandbook/logo-mark.svg",
    "brandbook/logo-monochrome.svg",
    "brandbook/logo-primary-subtitle.svg",
    "brandbook/logo-wordmark.svg",
    "brandbook/pressure-test.md",
    "brandbook/social-card.svg",
    "brandbook/tokens.css",
    "brandbook/tokens.json",
    "docker-compose.proxy.yml",
    "docker-compose.yml",
    "lib/mix/tasks/release.pins.ex",
    "lib/threadline/operator_surface/live/stress_live.ex",
    "lib/threadline/operator_surface/stress_fixtures.ex",
    "lib/threadline/operator_surface/stress_router.ex",
    "mix.lock",
    "release-please-config.json"
  ]

  # Release Please decides which commits can open a release PR. A commit whose
  # files all sit under an `exclude-paths` entry is dropped before its type is
  # read, so a `fix(ci):` that only touches CI tooling cannot cut an empty
  # release. The built archive is the ground truth for what ships: the list
  # must name exactly the tracked directories that ship nothing, and must
  # never cover a shipped file.
  test "exclude-paths names exactly the unshipped directories of the built Hex archive" do
    %{entries: entries} = built_archive()
    assert entries != [], "unpacked Hex archive contained no files"

    tracked = tracked_files()
    archived = MapSet.new(entries)
    shipped = tracked |> Enum.filter(&MapSet.member?(archived, &1)) |> MapSet.new()

    assert "lib/threadline.ex" in shipped
    assert "mix.exs" in shipped

    configured = configured_exclude_paths()
    errors = exclude_paths_errors(configured, tracked, shipped, @exclude_paths_residue)
    assert errors == [], Enum.join(errors, "\n")

    # Mutation controls: each broken list must fire its own rule. They reuse
    # the archive built above; none needs a second hex.build.
    fires? = fn errors, rule -> Enum.any?(errors, &String.starts_with?(&1, "rule=#{rule}:")) end

    covers_lib =
      exclude_paths_errors(configured ++ ["lib"], tracked, shipped, @exclude_paths_residue)

    assert fires?.(covers_lib, "sound"),
           "adding \"lib\" must fire rule=sound, got: #{inspect(covers_lib)}"

    drops_bin =
      exclude_paths_errors(configured -- ["bin"], tracked, shipped, @exclude_paths_residue)

    assert fires?.(drops_bin, "set-equal") and
             Enum.any?(drops_bin, &(&1 =~ ~s(missing ["bin"]))),
           "dropping \"bin\" must fire rule=set-equal naming bin, got: #{inspect(drops_bin)}"

    names_file =
      exclude_paths_errors(
        configured ++ ["bin/ci-test-partitions"],
        tracked,
        shipped,
        @exclude_paths_residue
      )

    assert fires?.(names_file, "shape"),
           "a file path entry must fire rule=shape, got: #{inspect(names_file)}"

    new_top_level =
      exclude_paths_errors(
        configured,
        ["NEW-NOTES.md" | tracked],
        shipped,
        @exclude_paths_residue
      )

    assert fires?.(new_top_level, "residue") and
             Enum.any?(new_top_level, &(&1 =~ "NEW-NOTES.md")),
           "a new unshipped top-level file must fire rule=residue, got: " <>
             inspect(new_top_level)
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

  defp configured_exclude_paths do
    @release_please_config
    |> File.read!()
    |> Jason.decode!()
    |> get_in(["packages", ".", "exclude-paths"])
    |> List.wrap()
  end

  # `-z` is load-bearing: without it git C-quotes names holding non-ASCII
  # characters, and a quoted name yields a bogus top-level directory.
  defp tracked_files do
    {out, 0} = System.cmd("git", ["ls-files", "-z"], cd: File.cwd!())
    String.split(out, <<0>>, trim: true)
  end

  # Every ancestor directory of every given file.
  defp dirs_of(files) do
    for file <- files,
        parts = file |> Path.split() |> Enum.drop(-1),
        n <- 1..length(parts)//1,
        into: MapSet.new(),
        do: parts |> Enum.take(n) |> Path.join()
  end

  # Release Please matches an exclude entry against a file by directory
  # prefix only: `file` starts with `entry <> "/"`.
  defp under?(file, dir), do: String.starts_with?(file, dir <> "/")

  defp ships_under?(shipped, dir), do: Enum.any?(shipped, &under?(&1, dir))

  # The maximal tracked directories with no shipped file: a directory qualifies
  # when nothing under it ships and its parent is the root or holds a shipped
  # file.
  defp expected_exclude_paths(tracked, shipped) do
    for dir <- dirs_of(tracked),
        not ships_under?(shipped, dir),
        parent = Path.dirname(dir),
        parent == "." or ships_under?(shipped, parent) do
      dir
    end
    |> Enum.sort()
  end

  # Unshipped tracked files that no entry covers.
  defp uncovered_residue(entries, tracked, shipped) do
    tracked
    |> Enum.reject(
      &(MapSet.member?(shipped, &1) or Enum.any?(entries, fn e -> under?(&1, e) end))
    )
    |> Enum.sort()
  end

  # Pure contract rules over the `exclude-paths` list, returned as
  # `rule=<id>: ...` messages (empty when the list is correct).
  defp exclude_paths_errors(entries, tracked, shipped, pinned_residue) do
    expected = MapSet.new(expected_exclude_paths(tracked, shipped))
    configured = MapSet.new(entries)
    missing = expected |> MapSet.difference(configured) |> Enum.sort()
    stale = configured |> MapSet.difference(expected) |> Enum.sort()

    set_equal_errors(missing, stale) ++
      sound_errors(entries, shipped) ++
      shape_errors(entries, dirs_of(tracked)) ++
      residue_errors(uncovered_residue(entries, tracked, shipped), pinned_residue)
  end

  defp set_equal_errors(missing, stale) do
    [
      {missing == [],
       "rule=set-equal: #{@release_please_config} `exclude-paths` is missing " <>
         "#{inspect(missing)}: these tracked directories ship nothing in the built Hex " <>
         "archive, so a commit touching only them could open a release PR. Add the " <>
         "directory to `exclude-paths` in #{@release_please_config}, or ship a file under " <>
         "it via `package()[:files]` in mix.exs"},
      {stale == [],
       "rule=set-equal: #{@release_please_config} `exclude-paths` has stale entries " <>
         "#{inspect(stale)}: each is not a maximal tracked directory that ships nothing. " <>
         "Remove the stale entry"}
    ]
    |> failed_messages()
  end

  # No entry may cover a shipped file: Release Please would then ignore a
  # commit that changes the published package.
  defp sound_errors(entries, shipped) do
    for entry <- Enum.uniq(entries),
        swallowed = Enum.filter(shipped, &(entry == "." or under?(&1, entry))) |> Enum.sort(),
        swallowed != [] do
      "rule=sound: `exclude-paths` entry #{inspect(entry)} covers #{length(swallowed)} " <>
        "shipped file(s), for example #{inspect(Enum.take(swallowed, 3))}. A real fix under " <>
        "it would never cut a release. Remove the entry"
    end
  end

  # Release Please matches entries as plain directory prefixes (`file` starts
  # with `entry <> "/"`, and `"."` excludes everything). A glob, a file path, or
  # a path with a leading or trailing slash silently matches nothing or too much.
  defp shape_errors(entries, tracked_dirs) do
    for entry <- Enum.uniq(entries),
        entry == "." or String.contains?(entry, ["*", "?", "[", "{"]) or
          String.starts_with?(entry, "/") or String.ends_with?(entry, "/") or
          not MapSet.member?(tracked_dirs, entry) do
      "rule=shape: `exclude-paths` entry #{inspect(entry)} is not a plain directory holding " <>
        "tracked files. Release Please matches entries as directory prefixes only: no " <>
        "`.`, no glob characters, no file paths, no leading or trailing slash"
    end
  end

  defp residue_errors(uncovered, pinned_residue) do
    uncovered = MapSet.new(uncovered)
    pinned = MapSet.new(pinned_residue)
    added = uncovered |> MapSet.difference(pinned) |> Enum.sort()
    removed = pinned |> MapSet.difference(uncovered) |> Enum.sort()

    remedy =
      "Either move the file under an excluded directory, or add it to " <>
        "`@exclude_paths_residue` in this test with a reason. Commits touching only " <>
        "these paths are kept out of a release by their commit type (CONTRIBUTING " <>
        "\"Ongoing releases\")"

    [
      {added == [],
       "rule=residue: unshipped tracked file(s) #{inspect(added)} are not covered by any " <>
         "`exclude-paths` entry and are not in the pinned residue. " <> remedy},
      {removed == [],
       "rule=residue: pinned residue #{inspect(removed)} is no longer an uncovered " <>
         "unshipped tracked file (shipped, covered, renamed or deleted). Remove it from " <>
         "`@exclude_paths_residue`"}
    ]
    |> failed_messages()
  end

  defp failed_messages(checks) do
    for {false, message} <- checks, do: message
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
