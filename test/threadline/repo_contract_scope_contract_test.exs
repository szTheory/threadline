defmodule Threadline.RepoContractScopeContractTest do
  @moduledoc """
  CI-03 lane scope contract (Phase 247, D-10).

  Repo-file contract tests carry the module tag `:repo_contract`: their outcome
  does not depend on the Elixir/OTP/PostgreSQL toolchain, so CI runs them on
  the current lane only. The mechanism is file filtering in
  `bin/ci-test-partitions` (`THREADLINE_TEST_SCOPE=toolchain`), routed from the
  `verify-test` matrix to the min and latest rows. It is deliberately not an
  ExUnit exclude: local `mix test` and the current lane run every test, and
  `test/test_helper.exs` keeps exactly its two sanctioned excludes
  (`Threadline.ZeroSkipsContractTest`).

  Three rules, each a pure checker with a mutation control:

    * `doc-sentence`: `CONTRIBUTING.md`'s `## CI Coverage` section states the
      scope, so the honest-default docs say which tests skip which lanes.
    * `scope-rows`: `test-scope: toolchain` sits on exactly the `min` and
      `latest` verify-test include rows, and the `Run tests` step passes it as
      `THREADLINE_TEST_SCOPE`. A `current` row with the scope would run no repo
      contract anywhere.
    * `filter-literal`: the script's tag regex is exactly the whole-line form
      of the tag this file carries, so a renamed tag cannot silently stop the
      filter (dropping nothing) or diverge from the tagged files.

  Phase 247-07 adds the D-09 classification directions beside these checkers:

    * `no-dodging` (D-09a): a tagged file may not contain an invocation-shaped
      toolchain marker (a real mix/elixir/erl process, a Mix task or project
      call, compiled-docs or code-loading calls, the test Repo or a database or
      endpoint case template, a call to or alias of a module defined under
      `lib/`, or a run of a `bin/` script that itself runs a real mix). Those
      outcomes depend on the toolchain, so the file must run on every lane.
    * `no-unclassified` (D-09b): every `test/**/*_contract_test.exs` is either
      tagged or listed in `@exempt` with a one-line reason. An exempt path that
      is missing or also tagged is an error.
    * `node-direction`: a test file that runs Node (`node_modules/.bin`, an npm
      or node process) must be tagged, because min and latest do not install
      Node.

  The needles are assembled at runtime so this file never matches itself.
  The failure direction is safe: an untagged file runs on every lane.
  """
  use ExUnit.Case, async: true
  @moduletag :repo_contract

  @repo_root File.cwd!()
  @contributing Path.join(@repo_root, "CONTRIBUTING.md")
  @ci_yml Path.join(@repo_root, ".github/workflows/ci.yml")
  @script Path.join(@repo_root, "bin/ci-test-partitions")
  @self_source Path.join(@repo_root, "test/threadline/repo_contract_scope_contract_test.exs")

  @coverage_heading "## CI Coverage"
  @scope_lanes ["latest", "min"]
  @scope_env "${{ matrix.test-scope }}"

  # Assembled at runtime: a literal tag line in a string here would be one more
  # place the tag text lives, and 247-07's classification scan reads sources.
  def tag_line, do: "@" <> "moduletag :" <> "repo_contract"

  def doc_sentence do
    "Repo-file contract tests (`#{tag_line()}`: their outcome does not depend on " <>
      "the Elixir/OTP/PostgreSQL toolchain) run only on the current lane in CI: " <>
      "`bin/ci-test-partitions` drops them on the min and latest lanes " <>
      "(`THREADLINE_TEST_SCOPE=toolchain`), while local `mix test` and the " <>
      "current lane run every test."
  end

  def expected_filter_literal, do: "^[[:space:]]*" <> tag_line() <> "[[:space:]]*$"

  # --- rule doc-sentence -------------------------------------------------------

  def coverage_section(contributing) do
    case String.split(contributing, @coverage_heading, parts: 2) do
      [_, rest] -> rest |> String.split(~r/\n## /, parts: 2) |> List.first()
      _ -> nil
    end
  end

  def doc_sentence_errors(contributing) do
    case coverage_section(contributing) do
      nil ->
        ["rule=doc-sentence: CONTRIBUTING.md has no `#{@coverage_heading}` section"]

      section ->
        if String.contains?(squish(section), doc_sentence()) do
          []
        else
          [
            "rule=doc-sentence: the `#{@coverage_heading}` section must state the lane scope: " <>
              doc_sentence()
          ]
        end
    end
  end

  defp squish(text), do: text |> String.split() |> Enum.join(" ")

  # --- rule scope-rows ---------------------------------------------------------

  def scope_rows_errors(ci_yml) do
    with {:ok, doc} <- parse_yaml(ci_yml),
         %{} = job <- get_in(doc, ["jobs", "verify-test"]) || :no_job do
      row_errors(get_in(job, ["strategy", "matrix", "include"])) ++
        env_errors(Map.get(job, "steps"))
    else
      {:error, message} -> ["rule=scope-rows: ci.yml does not parse: #{message}"]
      _ -> ["rule=scope-rows: ci.yml has no verify-test job"]
    end
  end

  defp row_errors(rows) when is_list(rows) and rows != [] do
    scoped =
      rows
      |> Enum.filter(&(is_map(&1) and Map.has_key?(&1, "test-scope")))

    bad_values =
      for row <- scoped,
          row["test-scope"] != "toolchain",
          do:
            "rule=scope-rows: lane #{inspect(row["lane"])} has test-scope #{inspect(row["test-scope"])}"

    lanes = scoped |> Enum.map(& &1["lane"]) |> Enum.sort()

    lane_errors =
      if lanes == @scope_lanes do
        []
      else
        [
          "rule=scope-rows: test-scope must sit on exactly the min and latest include rows, " <>
            "got #{inspect(lanes)}"
        ]
      end

    bad_values ++ lane_errors
  end

  defp row_errors(_), do: ["rule=scope-rows: verify-test has no matrix include rows"]

  defp env_errors(steps) when is_list(steps) do
    case Enum.filter(steps, &(is_map(&1) and &1["name"] == "Run tests")) do
      [step] ->
        if get_in(step, ["env", "THREADLINE_TEST_SCOPE"]) == @scope_env do
          []
        else
          ["rule=scope-rows: the Run tests step must set THREADLINE_TEST_SCOPE: #{@scope_env}"]
        end

      found ->
        ["rule=scope-rows: expected one verify-test `Run tests` step, found #{length(found)}"]
    end
  end

  defp env_errors(_), do: ["rule=scope-rows: verify-test has no steps"]

  defp parse_yaml(text) do
    {:ok, YamlElixir.read_from_string!(text, merge_anchors: true)}
  rescue
    error -> {:error, Exception.message(error)}
  end

  # --- rule filter-literal -----------------------------------------------------

  def filter_literal(script) do
    case Regex.run(~r/^REPO_CONTRACT_TAG_RE='([^'\n]*)'$/m, script) do
      [_, literal] -> literal
      _ -> nil
    end
  end

  def filter_literal_errors(script) do
    case filter_literal(script) do
      nil ->
        ["rule=filter-literal: bin/ci-test-partitions has no REPO_CONTRACT_TAG_RE='...' line"]

      literal ->
        if literal == expected_filter_literal() and
             String.contains?(script, ~s("$REPO_CONTRACT_TAG_RE")) do
          []
        else
          [
            "rule=filter-literal: REPO_CONTRACT_TAG_RE must be #{inspect(expected_filter_literal())} " <>
              "and be used by the filter, got #{inspect(literal)}"
          ]
        end
    end
  end

  # --- D-09 classification -------------------------------------------------------

  @test_glob "test/**/*_test.exs"
  @contract_suffix "_contract_test.exs"
  @lib_glob "lib/**/*.ex"

  # Contract files that stay untagged, so they run on every lane. Reasons are
  # one line each and say which toolchain dependency the file has.
  @toolchain_ast "parses or loads code with this toolchain (Code/Macro AST, compiled modules, lib or Mix task modules)"
  @toolchain_db "uses the test Repo, a database or endpoint case template, or compiled library calls"

  @exempt %{
    "test/threadline/clean_checkout_contract_test.exs" =>
      "runs bin/verify-clean-checkout, which runs a real mix deps.get --check-locked in a clone",
    "test/threadline/public_surface_contract_test.exs" =>
      "reads compiled docs of the library modules",
    "test/threadline/release_artifact_contract_test.exs" => "runs a real mix hex.build",
    "test/threadline/dialyzer_slice_contract_test.exs" => "runs Dialyzer through a real mix",
    "test/threadline/retry_network_contract_test.exs" => "runs a real mix help compile process",
    "test/threadline/zero_skips_contract_test.exs" =>
      "asserts the running lane's ExUnit exclude configuration",
    "test/threadline/deps_audit_gate_test.exs" =>
      "reads the running Mix project config to list runtime deps",
    "test/threadline/doc_rubric_contract_test.exs" => @toolchain_db,
    "test/threadline/readme_doc_contract_test.exs" => @toolchain_db,
    "test/threadline/operator_surface/copy_contract_test.exs" => @toolchain_db,
    "test/threadline/operator_surface/rendered_output_contract_test.exs" => @toolchain_db,
    "test/threadline/telemetry_registry_contract_test.exs" => @toolchain_db,
    "test/threadline/storage_schema_prefix_contract_test.exs" => @toolchain_db,
    "test/threadline/storage_schema_call_site_contract_test.exs" => @toolchain_db,
    "test/threadline/export_public_contract_test.exs" => @toolchain_db,
    "test/threadline/idle_transaction_reaper_contract_test.exs" => @toolchain_db,
    "test/threadline/storage_catalog_contract_test.exs" => @toolchain_db,
    "test/threadline/formatter_topology_contract_test.exs" => @toolchain_ast,
    "test/threadline/capture/public_sql_contract_test.exs" => @toolchain_ast,
    "test/threadline/source_size_contract_test.exs" => @toolchain_ast,
    "test/threadline/facade_only_references_contract_test.exs" => @toolchain_ast,
    "test/threadline/doc_spec_coverage_contract_test.exs" => @toolchain_ast,
    "test/threadline/source_comment_location_contract_test.exs" => @toolchain_ast,
    "test/threadline/test_structure_contract_test.exs" => @toolchain_ast,
    "test/threadline/optional_deps_contract_test.exs" => @toolchain_ast,
    "test/threadline/credo_config_contract_test.exs" => @toolchain_ast,
    "test/threadline/property_scale_contract_test.exs" => @toolchain_ast,
    "test/threadline/operator_surface/coverage_doc_contract_test.exs" => @toolchain_ast,
    "test/threadline/operator_surface/ui_form_policy_contract_test.exs" => @toolchain_ast,
    "test/threadline/operator_surface/component_contract_test.exs" => @toolchain_ast,
    "test/threadline/dialyzer_ignore_contract_test.exs" => @toolchain_ast,
    "test/threadline/code_walkthrough_doc_contract_test.exs" => @toolchain_ast,
    "test/threadline/no_warn_undefined_contract_test.exs" => @toolchain_ast,
    "test/threadline/layer_boundary_contract_test.exs" => @toolchain_ast,
    "test/threadline/facade_naming_contract_test.exs" => @toolchain_ast,
    "test/threadline/ci_all_dedup_contract_test.exs" => @toolchain_ast,
    "test/threadline/example_phoenix_readme_contract_test.exs" => @toolchain_ast,
    "test/threadline/health_findings_doc_contract_test.exs" => @toolchain_ast,
    "test/threadline/operator_surface/exports_doc_contract_test.exs" => @toolchain_ast,
    "test/threadline/operator_surface/policy_show_doc_contract_test.exs" => @toolchain_ast,
    "test/threadline/operator_surface/timeline_browse_doc_contract_test.exs" => @toolchain_ast,
    "test/threadline/getting_started_saas_doc_contract_test.exs" => @toolchain_ast,
    "test/threadline/storage_schema_migration_contract_test.exs" => @toolchain_ast,
    "test/threadline/lookup_return_shapes_contract_test.exs" => @toolchain_ast,
    "test/threadline/telemetry_doc_contract_test.exs" => @toolchain_ast,
    "test/threadline/ignore_advisories_contract_test.exs" => @toolchain_ast,
    "test/threadline/schema_fields_contract_test.exs" => @toolchain_ast,
    "test/threadline/operator_surface_doc_contract_test.exs" => @toolchain_ast,
    "test/threadline/actor_reads_doc_contract_test.exs" => @toolchain_ast,
    "test/threadline/adoption_pilot_doc_contract_test.exs" => @toolchain_ast,
    "test/threadline/how_threadline_works_doc_contract_test.exs" => @toolchain_ast,
    "test/threadline/integration_contracts_doc_contract_test.exs" => @toolchain_ast,
    "test/threadline/integrations/sigra_doc_contract_test.exs" => @toolchain_ast,
    "test/threadline/upgrade_path_doc_contract_test.exs" => @toolchain_ast,
    "test/threadline/integrations/phx_gen_auth_doc_contract_test.exs" => @toolchain_ast,
    "test/threadline/audit_indexing_doc_contract_test.exs" => @toolchain_ast
  }

  def exempt, do: @exempt

  def tagged?(source) do
    Regex.match?(~r/^[[:space:]]*#{Regex.escape(tag_line())}[[:space:]]*$/m, source)
  end

  def contract_path?(path), do: String.ends_with?(path, @contract_suffix)

  @doc "Repo-relative `{path, source}` pairs for every test file."
  def test_sources do
    @repo_root
    |> Path.join(@test_glob)
    |> Path.wildcard()
    |> Enum.sort()
    |> Enum.map(&{Path.relative_to(&1, @repo_root), File.read!(&1)})
  end

  @doc """
  Fully qualified modules defined under `lib/`, read from `defmodule` lines.
  Single-segment nested names (a `defmodule Inner do` inside a parent) are
  dropped: without the parent they would match unrelated text.
  """
  def lib_modules(sources \\ lib_sources()) do
    sources
    |> Enum.flat_map(fn source ->
      Regex.scan(~r/^[[:space:]]*defmodule[[:space:]]+([A-Z][A-Za-z0-9_.]*)/m, source,
        capture: :all_but_first
      )
    end)
    |> List.flatten()
    |> Enum.filter(&(String.contains?(&1, ".") or &1 == "Threadline"))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp lib_sources do
    @repo_root |> Path.join(@lib_glob) |> Path.wildcard() |> Enum.map(&File.read!/1)
  end

  # Fixed markers, every one assembled from fragments (see the zero_skips
  # precedent) so this source never contains the string it looks for.
  defp fixed_markers do
    cmd = "System" <> ".cmd("
    q = ~s(")

    plain =
      for tool <- ["mix", "elixir", "erl"],
          do: {"#{cmd}#{q}#{tool}#{q}", ~r/#{Regex.escape(cmd)}[[:space:]]*#{q}#{tool}#{q}/}

    words =
      for word <- ["Data" <> "Case", "Conn" <> "Case", "StorageSchema" <> "Case"],
          do: {word, ~r/\b#{word}\b/}

    literal =
      for needle <- [
            "Mix" <> ".Task.run(",
            "Code" <> ".fetch_docs(",
            "Code" <> ".ensure_loaded",
            "Code" <> ".ensure_compiled",
            "Code" <> ".eval_",
            "Phoenix" <> ".ConnTest",
            "Phoenix" <> ".LiveViewTest"
          ],
          do: {needle, ~r/#{Regex.escape(needle)}/}

    shaped = [
      {"Mix" <> ".Tasks.<X>.<f>(",
       ~r/#{Regex.escape("Mix" <> ".Tasks.")}[A-Z][A-Za-z0-9_.]*\.[a-z_][A-Za-z0-9_]*[!?]?\(/},
      {"Mix" <> ".Project.<f>(",
       ~r/#{Regex.escape("Mix" <> ".Project.")}[a-z_][A-Za-z0-9_]*[!?]?\(/},
      {"Re" <> "po.", ~r/\b#{"Re" <> "po"}\./}
    ]

    plain ++ words ++ literal ++ shaped
  end

  # bin/ scripts that run a real mix. A file trips this only when it runs a
  # process and a line builds or invokes the script path; a quoted path in an
  # assertion about workflow text does not count.
  defp mix_running_scripts do
    for name <- [
          "verify-clean-checkout",
          "verify-bump-rehearsal",
          "verify-dialyzer-slice",
          "with-rehearsal-registry",
          "demo-up"
        ],
        do: "bin/" <> name
  end

  defp script_offenders(source) do
    cmd = "System" <> ".cmd("

    if String.contains?(source, cmd) do
      lines = String.split(source, "\n")

      invocation =
        ~r/#{Regex.escape(cmd)}|Path\.(join|expand)\(|^[[:space:]]*@\w+[[:space:]]|^[[:space:]]*\w+[[:space:]]*=[[:space:]]/

      for script <- mix_running_scripts(),
          Enum.any?(lines, &(String.contains?(&1, script) and Regex.match?(invocation, &1))),
          do: "System.cmd on " <> script
    else
      []
    end
  end

  defp lib_module_matchers(lib_modules) do
    names =
      lib_modules
      |> Enum.sort_by(&(-String.length(&1)))
      |> Enum.map_join("|", &Regex.escape/1)

    regexes =
      if names == "" do
        nil
      else
        {~r/(?<![A-Za-z0-9_.])(#{names})\.[a-z_][A-Za-z0-9_]*[!?]?\(/,
         ~r/\b(?:alias|import|require|use)[[:space:]]+(#{names})(?![A-Za-z0-9_.])/}
      end

    {MapSet.new(lib_modules), regexes}
  end

  defp lib_module_offenders(source, {set, regexes}) do
    direct =
      case regexes do
        nil ->
          []

        {calls, aliases} ->
          Enum.map(Regex.scan(calls, source, capture: :all_but_first), fn [m] ->
            m <> ".<f>("
          end) ++
            Enum.map(Regex.scan(aliases, source, capture: :all_but_first), fn [m] ->
              "alias " <> m
            end)
      end

    multi =
      for [base, group] <-
            Regex.scan(
              ~r/\b(?:alias|import|require)[[:space:]]+([A-Z][A-Za-z0-9_.]*)\.\{([^}]*)\}/,
              source,
              capture: :all_but_first
            ),
          name <- String.split(group, ","),
          module = base <> "." <> String.trim(name),
          MapSet.member?(set, module),
          do: "alias " <> module

    direct ++ multi
  end

  @doc "D-09a: tagged files that contain an invocation-shaped toolchain marker."
  def dodging_offenders(path_source_pairs, lib_modules) do
    matchers = lib_module_matchers(lib_modules)
    markers = fixed_markers()

    for {path, source} <- path_source_pairs,
        tagged?(source),
        marker <-
          Enum.uniq(
            for({label, regex} <- markers, Regex.match?(regex, source), do: label) ++
              script_offenders(source) ++ lib_module_offenders(source, matchers)
          ),
        do: {path, marker}
  end

  @doc "D-09b: contract paths that are neither tagged nor exempt."
  def unclassified(paths, tagged, exempt) do
    tagged = MapSet.new(tagged)

    for path <- paths,
        contract_path?(path),
        not MapSet.member?(tagged, path),
        not Map.has_key?(exempt, path),
        do: path
  end

  @doc "Exempt keys that do not exist, or that are also tagged. Keys are test files; most are contracts."
  def exemption_errors(exempt, paths, tagged) do
    paths = MapSet.new(paths)
    tagged = MapSet.new(tagged)

    exempt
    |> Enum.sort()
    |> Enum.flat_map(fn {path, _reason} ->
      cond do
        not MapSet.member?(paths, path) -> [{path, :missing}]
        MapSet.member?(tagged, path) -> [{path, :also_tagged}]
        true -> []
      end
    end)
  end

  @doc "Node direction: untagged test files that run Node."
  def node_offenders(path_source_pairs, tagged) do
    tagged = MapSet.new(tagged)
    cmd = Regex.escape("System" <> ".cmd(")
    node = ~r/#{Regex.escape("node_modules" <> "/.bin")}|#{cmd}[[:space:]]*"(npm|npx|node)"/

    for {path, source} <- path_source_pairs,
        not MapSet.member?(tagged, path),
        Regex.match?(node, source),
        do: path
  end

  defp tagged_paths(pairs), do: for({path, source} <- pairs, tagged?(source), do: path)

  defp live_sources do
    pairs = test_sources()

    assert length(pairs) > 100 and Enum.any?(pairs, fn {p, _} -> contract_path?(p) end),
           "#{@test_glob} matched #{length(pairs)} files; a broken glob would pass vacuously"

    pairs
  end

  # --- live ----------------------------------------------------------------------

  test "rule doc-sentence: CONTRIBUTING CI Coverage states the lane scope" do
    assert doc_sentence_errors(File.read!(@contributing)) == []
  end

  test "rule scope-rows: test-scope toolchain on min and latest only, routed to Run tests" do
    assert scope_rows_errors(File.read!(@ci_yml)) == []
  end

  test "rule filter-literal: the script filters on exactly this tag's whole-line form" do
    script = File.read!(@script)
    assert filter_literal_errors(script) == []

    # The literal is a working regex for this file's own tag line (POSIX
    # classes read the same in grep -E and PCRE).
    regex = Regex.compile!(filter_literal(script), "m")

    assert Regex.match?(regex, File.read!(@self_source)),
           "the filter must match this file's tag line"

    refute Regex.match?(regex, "  " <> tag_line() <> "s\n")
  end

  test "rule no-dodging (D-09a): no tagged file depends on the toolchain" do
    pairs = live_sources()
    modules = lib_modules()

    assert "Threadline.Query" in modules and "Threadline.Plug" in modules and
             length(modules) > 20,
           "lib_modules/0 read #{length(modules)} modules from #{@lib_glob}; the scan is broken"

    offenders = dodging_offenders(pairs, modules)

    assert offenders == [],
           "these tagged files contain a toolchain marker: #{inspect(offenders)}. Remove " <>
             "the tag (and add an @exempt reason) rather than weakening a marker"
  end

  test "rule node-direction: every test file that runs Node is tagged" do
    pairs = live_sources()

    offenders = node_offenders(pairs, tagged_paths(pairs))

    assert offenders == [],
           "these files run Node but are untagged, and min/latest do not install Node: " <>
             inspect(offenders)
  end

  test "rule exemptions: every @exempt path exists and is not tagged" do
    pairs = live_sources()
    paths = Enum.map(pairs, &elem(&1, 0))

    assert exemption_errors(@exempt, paths, tagged_paths(pairs)) == []
    assert Enum.all?(Map.keys(@exempt), &String.ends_with?(&1, "_test.exs"))
    assert Enum.all?(Map.values(@exempt), &(is_binary(&1) and &1 != "" and not (&1 =~ "\n")))
  end

  # --- mutation controls -------------------------------------------------------
  # D-09 controls use in-memory sources with synthetic paths, so a mutation
  # string can never match a real file. Each fragment is assembled at runtime.

  defp fake(name), do: "test/fake/" <> name <> @contract_suffix

  defp tagged_source(body) do
    "defmodule Fake do\n  use ExUnit.Case, async: true\n  " <>
      tag_line() <> "\n\n" <> body <> "\nend\n"
  end

  defp untagged_source(body), do: "defmodule Fake do\n  use ExUnit.Case\n\n" <> body <> "\nend\n"

  defp flagged?(body) do
    dodging_offenders([{fake("x"), tagged_source(body)}], lib_modules()) != []
  end

  test "mutation controls no-dodging: invocation-shaped markers are flagged" do
    cmd = "System" <> ".cmd("
    lib = "Threadline" <> ".Query"

    for body <- [
          cmd <> ~s("mix", ["test"]\)),
          cmd <> ~s("elixir", ["-v"]\)),
          "Re" <> "po.all(Thing)",
          "alias " <> lib,
          "alias " <> "Threadline" <> ".{Plug, Query}",
          lib <> ".timeline([])",
          "use Threadline." <> "Data" <> "Case",
          "Code" <> ".fetch_docs(Threadline)",
          "Mix" <> ".Tasks.Threadline.Install.run([])",
          "Mix" <> ".Project.config()",
          cmd <> "Path.join(@root, " <> ~s(") <> "bin/" <> "verify-clean-checkout" <> ~s("\), [])
        ] do
      assert flagged?(body), "expected a dodging offender for: #{body}"
    end
  end

  test "mutation controls no-dodging: text and test-support references are not flagged" do
    cmd = "System" <> ".cmd("

    for body <- [
          "Threadline" <> ".Test.OperatorSurfaceFixtures.x()",
          "assert doc =~ " <> ~s(") <> "Threadline" <> ".Plug" <> ~s("),
          "@fixture ~S(defmodule X do\n  use Mix" <> ".Project\nend)",
          cmd <>
            ~s("git", ["status"]\)\n  assert ci =~ ") <>
            "bin/" <> "verify-dialyzer-slice" <> ~s(")
        ] do
      refute flagged?(body), "expected no dodging offender for: #{body}"
    end

    # An untagged file may do anything: it runs on every lane.
    untagged = untagged_source(cmd <> ~s("mix", ["test"]\)))
    assert dodging_offenders([{fake("x"), untagged}], lib_modules()) == []

    # A near-miss tag is not the tag.
    near = String.replace(tagged_source("Re" <> "po.all(X)"), ":repo_contract", ":repo_contracts")
    assert dodging_offenders([{fake("x"), near}], lib_modules()) == []
  end

  test "mutation controls no-unclassified: an untagged contract missing from @exempt is flagged" do
    tagged = fake("tagged")
    exempt = fake("exempt")
    loose = fake("loose")
    paths = [tagged, exempt, loose, "test/fake/plain_test.exs"]

    assert unclassified(paths, [tagged], %{exempt => "reason"}) == [loose]
    assert unclassified(paths, [tagged, loose], %{exempt => "reason"}) == []
  end

  test "mutation controls exemptions: a missing or also-tagged exempt path is flagged" do
    present = fake("present")
    gone = fake("gone")

    assert exemption_errors(%{gone => "r"}, [present], []) == [{gone, :missing}]
    assert exemption_errors(%{present => "r"}, [present], [present]) == [{present, :also_tagged}]
    assert exemption_errors(%{present => "r"}, [present], []) == []
  end

  test "mutation controls node-direction: an untagged Node runner is flagged" do
    cmd = "System" <> ".cmd("
    path = fake("node")

    for body <- [
          "@bin " <> ~s(") <> "node_modules" <> "/.bin/playwright" <> ~s("),
          cmd <> ~s("npm", ["ci"]\)),
          cmd <> ~s("node", ["x.js"]\))
        ] do
      assert node_offenders([{path, untagged_source(body)}], []) == [path]
      assert node_offenders([{path, tagged_source(body)}], [path]) == []
    end
  end

  test "mutation control doc-sentence: removing the sentence turns the rule red" do
    original = File.read!(@contributing)

    mutated =
      original
      |> String.split("\n\n")
      |> Enum.reject(&(squish(&1) == doc_sentence()))
      |> Enum.join("\n\n")

    refute mutated == original, "doc-sentence control did not change the input"
    assert Enum.any?(doc_sentence_errors(mutated), &String.starts_with?(&1, "rule=doc-sentence"))
  end

  test "mutation controls scope-rows: wrong lanes or a dropped env turn the rule red" do
    ci = File.read!(@ci_yml)

    controls = [
      {"test-scope added to the current row",
       String.replace(
         ci,
         "          - lane: current\n",
         "          - lane: current\n            test-scope: toolchain\n"
       )},
      {"test-scope removed from the latest row",
       String.replace(
         ci,
         ~s(            otp: "29.1.1"\n            test-scope: toolchain\n),
         ~s(            otp: "29.1.1"\n)
       )},
      {"Run tests env dropped",
       String.replace(ci, "          THREADLINE_TEST_SCOPE: #{@scope_env}\n", "")}
    ]

    for {control, mutated} <- controls do
      refute mutated == ci, "#{control} control did not change the input"

      assert Enum.any?(scope_rows_errors(mutated), &String.starts_with?(&1, "rule=scope-rows")),
             "#{control} must make rule scope-rows fail"
    end
  end

  test "mutation control filter-literal: a renamed tag in the script turns the rule red" do
    script = File.read!(@script)
    mutated = String.replace(script, ":repo_contract[[:space:]]", ":repo_contracts[[:space:]]")
    refute mutated == script, "filter-literal control did not change the input"

    assert Enum.any?(
             filter_literal_errors(mutated),
             &String.starts_with?(&1, "rule=filter-literal")
           )
  end
end
