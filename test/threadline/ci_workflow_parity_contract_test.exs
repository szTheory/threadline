defmodule Threadline.CIWorkflowParityContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  describe "workflow triggers and stable job keys" do
    test "ci.yml exposes stable job keys and main-only triggers" do
      yaml = read_rel!([".github", "workflows", "ci.yml"])

      assert Regex.match?(~r/^  verify-format:/m, yaml)
      assert Regex.match?(~r/^  verify-credo:/m, yaml)
      assert Regex.match?(~r/^  verify-test:/m, yaml)
      assert Regex.match?(~r/^  verify-pgbouncer-topology:/m, yaml)

      assert Regex.match?(
               ~r/^  push:\n(?:.*\n)*?    branches: \[main\]/m,
               yaml
             )

      assert Regex.match?(
               ~r/^  pull_request:\n(?:.*\n)*?    branches: \[main\]/m,
               yaml
             )
    end
  end

  describe "local CI parity alias" do
    test "mix.exs ci.all matches verify-test ordering (compile strict before tests)" do
      mix = read_rel!(["mix.exs"])

      assert String.contains?(mix, ~s("ci.all": [))

      for step <- [
            "verify.format",
            "verify.credo",
            "compile --warnings-as-errors",
            "verify.test",
            "verify.threadline",
            "verify.example"
          ] do
        assert String.contains?(mix, step),
               "expected ci.all to include #{inspect(step)}"
      end

      assert [_, ci_block] =
               Regex.run(~r/"ci\.all":\s*\[\s*\n((?:.*\n)*?)\s*\]/, mix),
             "expected mix.exs to declare a multiline ci.all list"

      {pos_test, _} = :binary.match(ci_block, "\"verify.test\"")
      {pos_tl, _} = :binary.match(ci_block, "\"verify.threadline\"")
      {pos_ex, _} = :binary.match(ci_block, "\"verify.example\"")

      assert pos_test < pos_tl and pos_tl < pos_ex,
             "ci.all must list verify.test before verify.threadline before verify.example"
    end
  end

  describe "README CI discovery" do
    test "HexDocs badge line is immediately followed by **CI:** paragraph" do
      lines = read_rel!(["README.md"]) |> String.split("\n")

      idx =
        lines
        |> Enum.find_index(fn line -> String.starts_with?(String.trim(line), "[![HexDocs") end)

      assert is_integer(idx), "expected a HexDocs badge line in README.md"

      rest = Enum.drop(lines, idx + 1)
      assert rest != []

      first_after = rest |> hd() |> String.trim()

      assert String.starts_with?(first_after, "**CI:**"),
             "D-05: line after HexDocs badge must start with **CI:**, got: #{inspect(Enum.take(rest, 3))}"
    end

    test "README still carries CI paragraph marker and Actions hub URL" do
      readme = read_rel!(["README.md"])
      assert String.contains?(readme, "**CI:** Runs on")
      assert String.contains?(readme, "github.com/szTheory/threadline/actions")
    end
  end

  describe "contributor CI discovery" do
    test "CONTRIBUTING documents job keys and Actions URL" do
      doc = read_rel!(["CONTRIBUTING.md"])

      assert String.contains?(doc, "verify-format")
      assert String.contains?(doc, "verify-credo")
      assert String.contains?(doc, "verify-test")
      assert String.contains?(doc, "verify-pgbouncer-topology")
      assert String.contains?(doc, "https://github.com/szTheory/threadline/actions")
    end
  end

  # --- Phase 192 Plan 04 Task 1 (D-26): additive alignment assertions ---------
  # These lock the Wave-2 constructs (matrix, caches, concurrency, pins,
  # doc alignment) with static-parse guards. Green-by-construction: they land
  # AFTER the Wave-2 workflow/doc edits, so no test is born red (D-27).

  # Derived by glob, not hardcoded. The previous literal list broke the moment
  # Phase 198 deleted ui-critic.yml and hex-publish.yml (File.Error on a missing
  # path), and it had silently never covered browser-full.yml at all — so the
  # :latest guard below was not actually checking every workflow it claimed to.
  # A hardcoded filename list rots in both directions: it fails when a file goes
  # away and under-asserts when one appears. Globbing fixes both.
  defp workflow_files do
    paths =
      @repo_root
      |> Path.join(".github/workflows/*.{yml,yaml}")
      |> Path.wildcard()
      |> Enum.sort()

    refute paths == [],
           "found no workflow files to scan — a broken glob would launder a false pass here"

    paths
  end

  # Every workflow file, keyed by its repo-relative path.
  defp all_workflows do
    Map.new(workflow_files(), &{Path.relative_to(&1, @repo_root), File.read!(&1)})
  end

  # The canonical stable job keys, derived from ci.yml (order-independent set).
  defp ci_job_keys do
    read_rel!([".github", "workflows", "ci.yml"])
    |> String.split("\n")
    |> Enum.flat_map(fn line ->
      case Regex.run(~r/^  (verify-[a-z0-9-]+):\s*$/, line) do
        [_, key] -> [key]
        _ -> []
      end
    end)
    |> Enum.uniq()
    |> MapSet.new()
  end

  # verify-* tokens named in the ci.yml leading `#` comment header (lines 1-2).
  defp ci_header_comment_keys do
    read_rel!([".github", "workflows", "ci.yml"])
    |> String.split("\n")
    |> Enum.take_while(&String.starts_with?(&1, "#"))
    |> Enum.join("\n")
    |> then(&Regex.scan(~r/verify-[a-z0-9-]+/, &1))
    |> List.flatten()
    |> MapSet.new()
  end

  # verify-* tokens in CONTRIBUTING List 1 (the "Job key | Purpose" table).
  defp contributing_list1_keys do
    lines = read_rel!(["CONTRIBUTING.md"]) |> String.split("\n")

    start = Enum.find_index(lines, &String.contains?(&1, "| Job key | Purpose |"))
    assert is_integer(start), "expected a '| Job key | Purpose |' table in CONTRIBUTING.md"

    lines
    |> Enum.drop(start + 1)
    |> Enum.take_while(&String.starts_with?(String.trim(&1), "|"))
    |> Enum.join("\n")
    |> then(&Regex.scan(~r/verify-[a-z0-9-]+/, &1))
    |> List.flatten()
    |> MapSet.new()
  end

  describe "workflow documentation job-key parity" do
    test "ci.yml jobs == header comment == CONTRIBUTING List 1" do
      jobs = ci_job_keys()
      header = ci_header_comment_keys()
      list1 = contributing_list1_keys()

      # Phase 198 (D-05): this assertion used to hardcode `== 10`. That literal
      # rotted the moment ci.yml legitimately grew jobs, and it failed for a
      # reason unrelated to the invariant actually worth guarding — three-way
      # parity between the workflow, its header comment, and CONTRIBUTING List 1.
      # The count is derived from ci.yml rather than restated, so the guard tracks
      # the source of truth instead of drifting away from it. Non-emptiness is
      # still asserted so a broken scan cannot pass vacuously.
      assert MapSet.size(jobs) > 0,
             "no verify-* job keys found in ci.yml — the scan is broken, which would " <>
               "let this parity guard pass vacuously."

      assert MapSet.equal?(jobs, header),
             "ci.yml jobs vs header comment drift: " <>
               "only-in-jobs=#{inspect(MapSet.difference(jobs, header) |> Enum.sort())} " <>
               "only-in-header=#{inspect(MapSet.difference(header, jobs) |> Enum.sort())}"

      assert MapSet.equal?(jobs, list1),
             "ci.yml jobs vs CONTRIBUTING List 1 drift: " <>
               "only-in-jobs=#{inspect(MapSet.difference(jobs, list1) |> Enum.sort())} " <>
               "only-in-list1=#{inspect(MapSet.difference(list1, jobs) |> Enum.sort())}"
    end

    test "verify-compile-no-optional is a standalone job key (not folded into the matrix)" do
      assert MapSet.member?(ci_job_keys(), "verify-compile-no-optional")
    end
  end

  describe "workflow image pinning" do
    test "no workflow file pins a service image to the mutable :latest tag" do
      for path <- workflow_files() do
        refute String.contains?(File.read!(path), ":latest"),
               "#{Path.relative_to(path, @repo_root)} must not pin any image to the " <>
                 "rolling :latest tag"
      end
    end
  end

  describe "workflow concurrency" do
    test "ci.yml has a top-level concurrency block gated on pull_request" do
      yaml = read_rel!([".github", "workflows", "ci.yml"])

      assert Regex.match?(
               ~r/^concurrency:\n\s*group:[^\n]*\n\s*cancel-in-progress:\s*\$\{\{\s*github\.event_name == 'pull_request'\s*\}\}/m,
               yaml
             ),
             "ci.yml must declare a PR-scoped concurrency block whose cancel-in-progress is gated on github.event_name == 'pull_request'"
    end

    test "release.yml publish-hex concurrency group is present and free of run_id" do
      yaml = read_rel!([".github", "workflows", "release.yml"])

      assert [_, group] =
               Regex.run(~r/concurrency:\s*\n\s*group:\s*(release-publish-[^\n]*)\n/, yaml),
             "release.yml publish-hex must declare a `release-publish-` concurrency group"

      refute String.contains?(group, "run_id"),
             "publish concurrency group must NOT contain run_id (would defeat serialization): #{inspect(group)}"
    end
  end

  describe "verify-test matrix construction" do
    test "ci.yml declares static name + lane axis [min, current] (construction A)" do
      yaml = read_rel!([".github", "workflows", "ci.yml"])

      assert Regex.match?(~r/^\s*name: Run test suite\s*$/m, yaml),
             "verify-test must declare the static `name: Run test suite` (GitHub composes the lane suffix)"

      assert Regex.match?(~r/^\s*lane:\s*\[min,\s*current\]\s*$/m, yaml),
             "verify-test matrix must declare base axis `lane: [min, current]`"
    end

    test "each lane installs one exact toolchain: the floor build or the committed .tool-versions" do
      yaml = read_rel!([".github", "workflows", "ci.yml"])
      mix_exs = read_rel!(["mix.exs"])

      assert verify_test_matrix_errors(yaml, mix_exs) == []

      min_row = ~s(          - lane: min\n)
      current_row = ~s(          - lane: current\n)
      min_runner = ~s(            runner: "ubuntu-24.04"\n          - lane: current)

      controls = [
        {"min row also given version-file",
         String.replace(
           yaml,
           min_row,
           min_row <> ~s(            version-file: ".tool-versions"\n)
         )},
        {"current row also given an OTP pin",
         String.replace(yaml, current_row, current_row <> ~s(            otp: "27.3.4.15"\n))},
        {"min row with neither pins nor version-file",
         yaml
         |> String.replace(~s(            otp: "26.2.5.21"\n), "")
         |> String.replace(~s(            elixir: "1.15.8"\n), "")},
        {"min runner on the deprecated image",
         String.replace(
           yaml,
           min_runner,
           ~s(            runner: ") <> "ubuntu-" <> "22.04" <> ~s("\n          - lane: current)
         )},
        {"min OTP on a 25 build",
         String.replace(yaml, ~s(otp: "26.2.5.21"), ~s(otp: "25.3.2.21"))},
        {"min Elixir above the declared floor",
         String.replace(yaml, ~s(elixir: "1.15.8"), ~s(elixir: "1.16.3"))},
        {"a third matrix row",
         String.replace(
           yaml,
           current_row,
           ~s(          - lane: extra\n            version-file: ".tool-versions"\n) <>
             current_row
         )}
      ]

      for {control, mutated} <- controls do
        refute mutated == yaml, "#{control} control did not change the input"

        refute verify_test_matrix_errors(mutated, mix_exs) == [],
               "#{control} mutation must make the verify-test matrix contract fail"
      end

      refute verify_test_matrix_errors(
               yaml,
               String.replace(mix_exs, ~s(elixir: "~> 1.15"), ~s(elixir: "~> 1.16"))
             ) ==
               [],
             "a raised mix.exs floor must no longer match the min row"
    end

    test "the verify-test setup-beam step is strict and fed only by matrix values" do
      yaml = read_rel!([".github", "workflows", "ci.yml"])
      path = ".github/workflows/ci.yml"
      job = workflow_job(yaml, "verify-test")

      assert String.contains?(job, "uses: erlef/setup-beam@"),
             "verify-test must contain a setup-beam step, or this contract is vacuous"

      assert toolchain_contract_errors(%{path => "jobs:\n" <> job}) == []

      beam_step =
        case Enum.filter(job_steps(job), &String.contains?(&1, "uses: erlef/setup-beam@")) do
          [step] ->
            step

          steps ->
            flunk("verify-test must carry exactly one setup-beam step, found #{length(steps)}")
        end

      credo_job = workflow_job(yaml, "verify-credo")

      credo_beam_step =
        case Enum.filter(job_steps(credo_job), &String.contains?(&1, "uses: erlef/setup-beam@")) do
          [step] ->
            step

          steps ->
            flunk("verify-credo must carry exactly one setup-beam step, found #{length(steps)}")
        end

      controls = [
        {"strict version type removed",
         String.replace(job, "          version-type: strict\n", "")},
        {"id beam removed", String.replace(job, "        id: beam\n", "")},
        {"version-file input removed",
         String.replace(job, "          version-file: ${{ matrix.version-file }}\n", "")},
        {"extra rebar3 input",
         String.replace(
           job,
           "          version-type: strict\n",
           "          version-type: strict\n          rebar3-version: ${{ matrix.rebar3 }}\n"
         )},
        {"literal OTP input instead of the matrix value",
         String.replace(job, "otp-version: ${{ matrix.otp }}", ~s(otp-version: "26"))},
        {"legacy matrix-value deps key",
         String.replace(
           job,
           "key: ${{ matrix.runner }}-${{ steps.beam.outputs.otp-version }}-elixir-" <>
             "${{ steps.beam.outputs.elixir-version }}-mix-deps-",
           "key: ${{ matrix.runner }}-otp${{ matrix.otp }}-elixir${{ matrix.elixir }}-mix-deps-"
         )}
      ]

      for {control, mutated} <- controls do
        refute mutated == job, "#{control} control did not change the input"

        refute toolchain_contract_errors(%{path => "jobs:\n" <> mutated}) == [],
               "#{control} mutation must make the toolchain pin contract fail"
      end

      moved = String.replace(credo_job, credo_beam_step, beam_step)

      refute moved == credo_job,
             "matrix step moved into verify-credo control did not change the input"

      refute toolchain_contract_errors(%{path => "jobs:\n" <> moved}) == [],
             "a matrix-fed setup-beam step outside verify-test must fail the toolchain contract"
    end

    test "CONTRIBUTING List 2 carries both composed required-check names" do
      doc = read_rel!(["CONTRIBUTING.md"])

      assert String.contains?(doc, "Run test suite (min)")
      assert String.contains?(doc, "Run test suite (current)")
    end
  end

  describe "dependency cache contract" do
    test "ci.yml caches deps + e2e lockfile and never caches _build" do
      yaml = read_rel!([".github", "workflows", "ci.yml"])

      assert String.contains?(yaml, "actions/cache@v5"),
             "ci.yml must use actions/cache@v5 for the deps cache"

      assert Regex.match?(~r/^\s*path:\s*deps\s*$/m, yaml),
             "ci.yml must cache the `deps` directory"

      assert String.contains?(
               yaml,
               "cache-dependency-path: examples/threadline_phoenix/e2e/package-lock.json"
             ),
             "ci.yml must key the e2e node cache off the example lockfile"

      refute Regex.match?(~r/^\s*path:\s*_build\s*$/m, yaml),
             "ci.yml must NOT cache _build (compile artifacts are not shared across matrix lanes)"
    end
  end

  # --- Toolchain pin contract -------------------------------------------------
  #
  # `.tool-versions` is the single source of the CI current-lane toolchain. Every
  # setup-beam step reads it through `version-file` in strict mode, and every
  # BEAM-dependent cache key names the toolchain setup-beam actually resolved
  # (its `otp-version` / `elixir-version` outputs), never a requested literal.
  #
  # Cache paths that do not depend on the BEAM are exempt only by being named
  # here with a reason. Any other cache path fails closed unless its key carries
  # both resolved outputs.
  @beam_independent_cache_paths %{
    "~/.cache/ms-playwright" =>
      "Playwright browser binaries are keyed by the e2e npm lockfile and do not depend on the BEAM"
  }

  # Assembled so this file's own text never contains the needles it forbids.
  @os_family_context "runner" <> ".os"
  @deprecated_runner_image "ubuntu-" <> "22.04"
  @legacy_otp_segment "otp" <> "27"
  @legacy_otp_value "27" <> ".0"

  # Release jobs read the pin into this directory so its sparse checkout never
  # shares a git repository with the workspace-root checkout of the target ref.
  @toolchain_pin_dir ".toolchain-pin"

  @resolved_otp "${{ steps.beam.outputs.otp-version }}"
  @resolved_elixir "${{ steps.beam.outputs.elixir-version }}"
  @resolved_deps_prefix "ubuntu-24.04-#{@resolved_otp}-elixir-#{@resolved_elixir}-mix-deps-"

  describe "toolchain pin contract" do
    test ".tool-versions is tracked and names one consistent erlang/elixir build" do
      text = read_rel!([".tool-versions"])

      assert tool_versions_errors(text) == []

      {output, status} =
        System.cmd("git", ["ls-files", "--error-unmatch", "--", ".tool-versions"],
          cd: @repo_root,
          stderr_to_stdout: true
        )

      assert status == 0,
             ".tool-versions must be tracked so CI and a fresh clone read the same pins: " <>
               output

      controls = [
        {"missing erlang line", String.replace(text, ~r/^erlang .*\n?/m, "")},
        {"missing elixir line", String.replace(text, ~r/^elixir .*\n?/m, "")},
        {"duplicated erlang line", text <> "\nerlang 27.3.4.15\n"},
        {"elixir built for another OTP major",
         String.replace(text, "elixir 1.17.3-otp-27", "elixir 1.17.3-otp-26")}
      ]

      for {control, mutated} <- controls do
        refute mutated == text, "#{control} control did not change the input"

        refute tool_versions_errors(mutated) == [],
               "#{control} mutation must make the toolchain pin contract fail"
      end
    end

    test "verify-format installs the committed toolchain and keys its deps cache on it" do
      ci_yml = read_rel!([".github", "workflows", "ci.yml"])
      job = workflow_job(ci_yml, "verify-format")
      path = ".github/workflows/ci.yml"

      assert String.contains?(job, "uses: erlef/setup-beam@"),
             "verify-format must contain a setup-beam step, or this contract is vacuous"

      assert toolchain_contract_errors(%{path => "jobs:\n" <> job}) == []

      cache_step =
        case Regex.run(~r/^      - name: Cache deps\n[\s\S]*?(?=^      - |\z)/m, job) do
          [step] -> step
          nil -> flunk("verify-format must carry a `Cache deps` step")
        end

      setup_line = "      - uses: erlef/setup-beam@v1"

      controls = [
        {"id beam removed", String.replace(job, "        id: beam\n", "")},
        {"strict version type removed",
         String.replace(job, "          version-type: strict\n", "")},
        {"version file pointing elsewhere",
         String.replace(
           job,
           "version-file: .tool-versions",
           "version-file: " <> "elsewhere/.tool-versions"
         )},
        {"literal OTP input re-added",
         String.replace(
           job,
           "          version-type: strict\n",
           "          version-type: strict\n          otp-version: \"#{@legacy_otp_value}\"\n"
         )},
        {"legacy literal-segment deps key",
         String.replace(
           job,
           "key: " <> @resolved_deps_prefix,
           "key: ubuntu-24.04-" <> @legacy_otp_segment <> ".0-elixir1.17.3-mix-deps-"
         )},
        {"restore-keys missing the elixir output",
         String.replace(
           job,
           "restore-keys: " <> @resolved_deps_prefix,
           "restore-keys: ubuntu-24.04-#{@resolved_otp}-mix-deps-"
         )},
        {"key led by the OS-family context value",
         String.replace(
           job,
           "key: ubuntu-24.04-",
           "key: ${{ " <> @os_family_context <> " }}-"
         )},
        {"deps cache moved above setup-beam",
         job
         |> String.replace(cache_step, "")
         |> String.replace(setup_line, cache_step <> setup_line)},
        {"duplicated id beam",
         String.replace(
           job,
           "      - name: Cache deps\n",
           "      - name: Cache deps\n        id: beam\n"
         )}
      ]

      for {control, mutated} <- controls do
        refute mutated == job, "#{control} control did not change the input"

        refute toolchain_contract_errors(%{path => "jobs:\n" <> mutated}) == [],
               "#{control} mutation must make the toolchain pin contract fail"
      end
    end

    test "every workflow job installs an exact toolchain and keys caches on it" do
      live = read_rel!([".github", "workflows", "ci.yml"])
      path = ".github/workflows/ci.yml"
      release_path = ".github/workflows/release.yml"
      release = read_rel!([".github", "workflows", "release.yml"])

      setup_beam_steps =
        live |> strip_comment_lines() |> String.split("uses: erlef/setup-beam@") |> length()

      assert setup_beam_steps - 1 == 11,
             "expected 11 setup-beam steps (10 file-fed, 1 matrix-fed) under the toolchain " <>
               "contract, found #{setup_beam_steps - 1}"

      assert toolchain_contract_errors(%{path => live, release_path => release}) == []

      assert toolchain_contract_errors(all_workflows()) == []

      credo_job = workflow_job(live, "verify-credo")

      controls = [
        {"verify-credo id beam removed",
         String.replace(live, credo_job, String.replace(credo_job, "        id: beam\n", ""))}
      ]

      for {control, mutated} <- controls do
        refute mutated == live, "#{control} control did not change the input"

        refute toolchain_contract_errors(%{path => mutated}) == [],
               "#{control} mutation must make the toolchain pin contract fail"
      end
    end

    test "the browser and scheduled workflows install the committed toolchain" do
      live = all_workflows()
      flake = ".github/workflows/flake-detection.yml"
      deps_health = ".github/workflows/deps-health.yml"
      browser = ".github/workflows/browser-full.yml"

      for path <- [flake, deps_health, browser] do
        assert String.contains?(live[path], "uses: erlef/setup-beam@"),
               "#{path} must contain a setup-beam step, or this contract is vacuous"
      end

      mutate = fn path, from, to -> Map.update!(live, path, &String.replace(&1, from, to)) end

      unknown_cache =
        "jobs:\n  some-job:\n    steps:\n      - uses: actions/checkout@v5\n" <>
          "      - uses: erlef/setup-beam@v1\n        id: beam\n        with:\n" <>
          "          version-file: .tool-versions\n          version-type: strict\n" <>
          "      - uses: actions/cache@v4\n        with:\n          path: ~/.cache/something\n" <>
          "          key: ubuntu-24.04-${{ hashFiles('x.lock') }}\n"

      controls = [
        {"flake-detection deps key led by the OS-family context value",
         mutate.(flake, "key: ubuntu-24.04-", "key: ${{ " <> @os_family_context <> " }}-")},
        {"deps-health setup-beam with a literal OTP input",
         mutate.(
           deps_health,
           "          version-type: strict\n",
           "          version-type: strict\n          otp-version: \"#{@legacy_otp_value}\"\n"
         )},
        {"browser-full deps key missing the elixir output",
         mutate.(
           browser,
           "key: " <> @resolved_deps_prefix,
           "key: ubuntu-24.04-#{@resolved_otp}-mix-deps-"
         )},
        {"a new workflow caching an unknown path on a lockfile-only key",
         Map.put(live, ".github/workflows/new.yml", unknown_cache)}
      ]

      for {control, mutated} <- controls do
        refute mutated == live, "#{control} control did not change the input"

        refute toolchain_contract_errors(mutated) == [],
               "#{control} mutation must make the toolchain pin contract fail"
      end
    end

    test "release jobs read the toolchain pin from the workflow's own commit" do
      path = ".github/workflows/release.yml"
      release = read_rel!([".github", "workflows", "release.yml"])
      ci = read_rel!([".github", "workflows", "ci.yml"])

      for {file, yaml} <- [{".github/workflows/ci.yml", ci}, {path, release}],
          {job_id, block} <- workflow_jobs(yaml) do
        assert toolchain_source_errors(file, job_id, block) == []
      end

      ref_switching = ["sync-release-pr-pins", "publish-hex", "smoke-published"]

      for job_id <- ref_switching do
        job = workflow_job(release, job_id)

        assert String.contains?(job, "sparse-checkout: .tool-versions"),
               "#{job_id} must check out .tool-versions from the workflow commit, " <>
                 "or this contract is vacuous"

        assert String.contains?(job, "path: #{@toolchain_pin_dir}\n"),
               "#{job_id} must read the pin into #{@toolchain_pin_dir}, or its sparse " <>
                 "config reaches the workspace-root checkout (main Release run 36319430805)"
      end

      publish = workflow_job(release, "publish-hex")
      smoke = workflow_job(release, "smoke-published")
      sync = workflow_job(release, "sync-release-pr-pins")

      [toolchain_checkout, beam_step | _] =
        smoke |> job_steps() |> Enum.drop_while(&(not String.contains?(&1, "sparse-checkout:")))

      target_checkout =
        smoke
        |> job_steps()
        |> Enum.find(&String.contains?(&1, "ref: ${{ needs.release-ref.outputs.checkout_ref }}"))

      publish_toolchain_checkout =
        publish |> job_steps() |> Enum.find(&String.contains?(&1, "sparse-checkout:"))

      controls = [
        {"publish-hex", publish, "toolchain checkout removed",
         String.replace(publish, publish_toolchain_checkout, "")},
        {"smoke-published", smoke, "setup-beam moved below the target-ref checkout",
         String.replace(
           smoke,
           toolchain_checkout <> beam_step <> target_checkout,
           toolchain_checkout <> target_checkout <> beam_step
         )},
        {"sync-release-pr-pins", sync, "toolchain checkout without persist-credentials: false",
         String.replace(
           sync,
           "          sparse-checkout-cone-mode: false\n          persist-credentials: false\n",
           "          sparse-checkout-cone-mode: false\n"
         )},
        {"publish-hex", publish, "toolchain checkout naming a different file",
         String.replace(
           publish,
           "sparse-checkout: .tool-versions",
           "sparse-checkout: " <> "mix.exs"
         )},
        # The shape that broke on main Release run 36319430805: the sparse pin
        # checkout at the workspace root, followed by the release-branch checkout.
        {"sync-release-pr-pins", sync, "toolchain checkout without its own path",
         sync
         |> String.replace("          path: #{@toolchain_pin_dir}\n", "")
         |> String.replace(
           "version-file: #{@toolchain_pin_dir}/.tool-versions",
           "version-file: .tool-versions"
         )},
        {"smoke-published", smoke, "version-file at the root while the pin sits in its own path",
         String.replace(
           smoke,
           "version-file: #{@toolchain_pin_dir}/.tool-versions",
           "version-file: .tool-versions"
         )}
      ]

      for {job_id, job, control, mutated} <- controls do
        refute mutated == job, "#{control} control did not change the input"

        refute toolchain_source_errors(path, job_id, mutated) == [],
               "#{control} mutation must make the toolchain source contract fail"
      end
    end

    test "no workflow runs a job on the deprecated runner image" do
      for {file, text} <- all_workflows() do
        assert runner_image_errors(file, text) == []
      end

      path = ".github/workflows/ci.yml"
      yaml = read_rel!([".github", "workflows", "ci.yml"])

      controls = [
        {"runs-on value on the deprecated image",
         String.replace(
           yaml,
           "    runs-on: ubuntu-24.04\n",
           "    runs-on: " <> @deprecated_runner_image <> "\n",
           global: false
         )},
        {"matrix runner value on the deprecated image",
         String.replace(
           yaml,
           ~s(runner: "ubuntu-24.04"),
           ~s(runner: ") <> @deprecated_runner_image <> ~s("),
           global: false
         )}
      ]

      for {control, mutated} <- controls do
        refute mutated == yaml, "#{control} control did not change the input"

        refute runner_image_errors(path, mutated) == [],
               "#{control} mutation must make the runner image contract fail"
      end
    end

    test "no workflow names the OS-family runner context, comments included" do
      live = all_workflows()
      ci = ".github/workflows/ci.yml"
      flake = ".github/workflows/flake-detection.yml"

      for path <- [ci, flake] do
        assert Map.has_key?(live, path), "#{path} missing from all_workflows()"
      end

      for {path, yaml} <- all_workflows() do
        assert os_family_context_errors(path, yaml) == []
      end

      mutate = fn path, from, to ->
        Map.update!(live, path, &String.replace(&1, from, to, global: false))
      end

      controls = [
        {ci, "cache key built on the OS-family context",
         mutate.(
           ci,
           "key: ${{ matrix.runner }}-",
           "key: ${{ " <> @os_family_context <> " }}-${{ matrix.runner }}-"
         )},
        {ci, "OS-family context named only in a comment",
         mutate.(
           ci,
           "      # CACHE KEY CONTRACT",
           "      # e.g. " <> @os_family_context <> "\n      # CACHE KEY CONTRACT"
         )},
        {flake, "OS-family context named only in a flake-detection.yml comment",
         mutate.(
           flake,
           "      # Key shape follows the CACHE KEY CONTRACT",
           "      # e.g. " <>
             @os_family_context <> "\n      # Key shape follows the CACHE KEY CONTRACT"
         )}
      ]

      for {path, control, mutated} <- controls do
        refute mutated == live, "#{control} control did not change the input"

        errors = workflows_os_family_context_errors(mutated)

        assert Enum.any?(errors, &String.starts_with?(&1, path <> ":")),
               "#{control} mutation must make the OS-family context check fail for #{path}, " <>
                 "got #{inspect(errors)}"
      end
    end

    test "the Playwright exemption is the only BEAM-independent cache path, with a reason" do
      assert Map.keys(@beam_independent_cache_paths) == ["~/.cache/ms-playwright"]

      for {_path, reason} <- @beam_independent_cache_paths do
        assert is_binary(reason) and String.length(reason) > 20
      end

      unknown =
        "jobs:\n  some-job:\n    steps:\n      - uses: erlef/setup-beam@v1\n        id: beam\n" <>
          "        with:\n          version-file: .tool-versions\n          version-type: strict\n" <>
          "      - uses: actions/cache@v4\n        with:\n          path: ~/.cache/something\n" <>
          "          key: ubuntu-24.04-${{ hashFiles('x.lock') }}\n"

      refute toolchain_contract_errors(%{"w.yml" => unknown}) == [],
             "an unknown cache path without resolved toolchain outputs must fail closed"
    end
  end

  defp tool_versions_errors(text) do
    entries =
      text
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == "" or String.starts_with?(&1, "#")))
      |> Enum.map(fn line ->
        case String.split(line, ~r/\s+/, parts: 2) do
          [tool, version] -> {tool, String.trim(version)}
          [tool] -> {tool, ""}
        end
      end)

    erlang = for {"erlang", version} <- entries, do: version
    elixir = for {"elixir", version} <- entries, do: version

    count_errors =
      for {tool, versions} <- [{"erlang", erlang}, {"elixir", elixir}],
          length(versions) != 1 do
        ".tool-versions must carry exactly one #{tool} line, found #{length(versions)}"
      end

    count_errors ++ otp_suffix_errors(erlang, elixir)
  end

  defp otp_suffix_errors([erlang], [elixir]) do
    erlang_major = erlang |> String.split(".") |> hd()

    case Regex.run(~r/-otp-(\d+)$/, elixir) do
      [_, ^erlang_major] ->
        []

      [_, other] ->
        [
          "elixir #{elixir} is built for OTP #{other}, but erlang #{erlang} is OTP #{erlang_major}"
        ]

      nil ->
        ["elixir #{elixir} must end in -otp-N naming the erlang major (#{erlang_major})"]
    end
  end

  defp otp_suffix_errors(_erlang, _elixir), do: []

  defp workflow_jobs(yaml) do
    case String.split(yaml, ~r/^jobs:\n/m, parts: 2) do
      [_, body] ->
        ~r/^  ([a-z][a-z0-9-]+):\n[\s\S]*?(?=^  [a-z][a-z0-9-]+:\n|\z)/m
        |> Regex.scan(body)
        |> Enum.map(fn [block, job_id] -> {job_id, block} end)

      _ ->
        []
    end
  end

  defp workflow_job(yaml, id) do
    case Regex.run(~r/^  #{Regex.escape(id)}:\n([\s\S]*?)(?=^  [a-z][a-z0-9-]+:\n|\z)/m, yaml) do
      [full, _body] -> full
      nil -> ""
    end
  end

  # Step texts of a job block, split at every 6-space-indented list item. The
  # leading chunk (job header up to the first step) is dropped.
  defp job_steps(block) do
    case Regex.split(~r/^(?=      - )/m, block) do
      [_header | steps] -> steps
      [] -> []
    end
  end

  defp strip_comment_lines(block) do
    block
    |> String.split("\n")
    |> Enum.reject(&String.match?(&1, ~r/^\s*#/))
    |> Enum.join("\n")
  end

  defp trimmed_lines(text) do
    text |> strip_comment_lines() |> String.split("\n") |> Enum.map(&String.trim/1)
  end

  defp setup_beam_errors(path, job_id, step, pin_dir) do
    stripped = strip_comment_lines(step)

    cond do
      not String.contains?(stripped, "uses: erlef/setup-beam@") ->
        []

      String.contains?(stripped, "${{ matrix.") ->
        matrix_setup_beam_errors(path, job_id, stripped)

      true ->
        file_setup_beam_errors(path, job_id, stripped, pin_dir)
    end
  end

  # FILE form: the step installs exactly the committed `.tool-versions` build,
  # read from the workspace root, or from the job's toolchain checkout `path:`
  # when the job isolates that checkout in a subdirectory.
  defp file_setup_beam_errors(path, job_id, step, pin_dir) do
    lines = trimmed_lines(step)
    where = "#{path} #{job_id} setup-beam step"
    version_file = "version-file: " <> pin_file(pin_dir)

    required =
      for line <- ["id: beam", version_file, "version-type: strict"],
          line not in lines do
        "#{where} must declare `#{line}`"
      end

    forbidden =
      for key <- ["otp-version:", "elixir-version:", "gleam-version:", "rebar3-version:"],
          Enum.any?(lines, &String.starts_with?(&1, key)) do
        "#{where} must not carry a `#{key}` input (setup-beam strict mode reads .tool-versions)"
      end

    required ++ forbidden
  end

  # MATRIX form: only the verify-test matrix may feed setup-beam from matrix
  # values, and only through exactly these inputs. Each matrix row sets either
  # `version-file` or the `otp`/`elixir` pins (see verify_test_matrix_errors/2);
  # an absent matrix key renders as an empty input, which setup-beam ignores.
  @matrix_beam_inputs [
    "version-file: ${{ matrix.version-file }}",
    "otp-version: ${{ matrix.otp }}",
    "elixir-version: ${{ matrix.elixir }}",
    "version-type: strict"
  ]

  defp matrix_setup_beam_errors(path, job_id, step) do
    lines = trimmed_lines(step)
    where = "#{path} #{job_id} setup-beam step"

    job_errors =
      if job_id == "verify-test",
        do: [],
        else: ["#{where} reads matrix values, which only the verify-test matrix may do"]

    id_errors = if "id: beam" in lines, do: [], else: ["#{where} must declare `id: beam`"]

    inputs =
      lines
      |> Enum.drop_while(&(&1 != "with:"))
      |> Enum.drop(1)
      |> Enum.filter(&Regex.match?(~r/^[a-z0-9-]+:/, &1))

    input_errors =
      if Enum.sort(inputs) == Enum.sort(@matrix_beam_inputs),
        do: [],
        else: [
          "#{where} must carry exactly the inputs #{inspect(@matrix_beam_inputs)}, " <>
            "found #{inspect(inputs)}"
        ]

    job_errors ++ id_errors ++ input_errors
  end

  # The verify-test `include:` rows: the min row pins the exact floor build the
  # mix.exs `elixir:` requirement promises; the current row reads .tool-versions.
  defp verify_test_matrix_errors(yaml, mix_exs) do
    rows = verify_test_rows(workflow_job(yaml, "verify-test"))
    by_lane = Map.new(rows, &{&1["lane"], &1})

    count_errors =
      if length(rows) == 2 and Map.keys(by_lane) |> Enum.sort() == ["current", "min"],
        do: [],
        else: [
          "verify-test must have exactly two include rows (min, current), found " <>
            inspect(Enum.map(rows, & &1["lane"]))
        ]

    source_errors =
      for row <- rows,
          file? = Map.has_key?(row, "version-file"),
          pins? = Map.has_key?(row, "otp") or Map.has_key?(row, "elixir"),
          file? == pins? do
        "verify-test #{row["lane"]} row must set exactly one toolchain source " <>
          "(version-file, or otp/elixir pins)"
      end

    count_errors ++
      source_errors ++
      min_row_errors(by_lane["min"], elixir_floor(mix_exs)) ++
      current_row_errors(by_lane["current"])
  end

  defp min_row_errors(nil, _floor), do: ["verify-test has no min row"]

  defp min_row_errors(row, floor) do
    otp_major = row |> Map.get("otp", "") |> String.split(".") |> hd()
    elixir_minor = row |> Map.get("elixir", "") |> String.split(".") |> Enum.take(2)

    [
      {row["otp"] == "26.2.5.21", "min row must pin otp: \"26.2.5.21\""},
      {row["elixir"] == "1.15.8", "min row must pin elixir: \"1.15.8\""},
      {row["runner"] == "ubuntu-24.04", "min row must run on ubuntu-24.04"},
      {row["pg"] == "14", "min row must use pg 14"},
      {not Map.has_key?(row, "version-file"), "min row must not set version-file"},
      {otp_major == "26", "min row OTP major must be 26, got #{inspect(otp_major)}"},
      {floor != nil and elixir_minor == floor,
       "min row Elixir #{inspect(row["elixir"])} must match the mix.exs floor #{inspect(floor)}"}
    ]
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(&("verify-test " <> elem(&1, 1)))
  end

  defp current_row_errors(nil), do: ["verify-test has no current row"]

  defp current_row_errors(row) do
    [
      {row["version-file"] == ".tool-versions",
       "current row must set version-file: \".tool-versions\""},
      {row["runner"] == "ubuntu-24.04", "current row must run on ubuntu-24.04"},
      {row["pg"] == "16", "current row must use pg 16"},
      {not Map.has_key?(row, "otp") and not Map.has_key?(row, "elixir"),
       "current row must not carry otp/elixir pins"}
    ]
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(&("verify-test " <> elem(&1, 1)))
  end

  defp verify_test_rows(job) do
    case Regex.run(
           ~r/^        include:\n((?:          .*\n)+)/m,
           strip_comment_lines(job) <> "\n"
         ) do
      [_, body] ->
        body
        |> String.split(~r/^          - /m, trim: true)
        |> Enum.map(&parse_matrix_row/1)

      nil ->
        []
    end
  end

  defp parse_matrix_row(text) do
    text
    |> String.split("\n", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.flat_map(fn line ->
      case Regex.run(~r/^([a-z0-9-]+):\s*"?([^"]*)"?\s*$/, line) do
        [_, key, value] -> [{key, value}]
        nil -> []
      end
    end)
    |> Map.new()
  end

  defp elixir_floor(mix_exs) do
    case Regex.run(~r/^\s*elixir: "~> (\d+)\.(\d+)"/m, mix_exs) do
      [_, major, minor] -> [major, minor]
      nil -> nil
    end
  end

  # setup-beam reads `.tool-versions` from the workspace, so the checkout that
  # precedes it decides which commit's pin is installed. It must be the workflow's
  # own commit (no `ref:`): a release branch or recovery tag may predate the file.
  # A checkout that narrows the workspace to the pin must be exactly that narrow
  # and must not persist the job token. When a checkout of another ref follows it,
  # the pin checkout must live in its own `path:`: git 2.55 leaves
  # `core.sparseCheckout=true` in place after `git sparse-checkout disable` when
  # sparse was enabled through plain config (actions/checkout's non-cone path),
  # so a shared repository hands the target checkout a `.tool-versions`-only tree
  # (main Release run 36319430805). setup-beam then reads the pin from that path.
  defp toolchain_source_errors(path, job_id, block) do
    steps = block |> strip_comment_lines() |> job_steps()
    where = "#{path} #{job_id}"
    checkout? = &String.contains?(&1, "uses: actions/checkout@")

    source_errors =
      case Enum.find_index(steps, &String.contains?(&1, "uses: erlef/setup-beam@")) do
        nil ->
          []

        beam_at ->
          steps |> Enum.take(beam_at) |> Enum.filter(checkout?) |> pin_checkout_errors(where)
      end

    sparse_errors =
      for step <- steps,
          checkout?.(step),
          yaml_value(step, "sparse-checkout") != nil,
          lines = trimmed_lines(step),
          line <- [
            "sparse-checkout: .tool-versions",
            "sparse-checkout-cone-mode: false",
            "persist-credentials: false"
          ],
          line not in lines do
        "#{where} toolchain checkout must declare `#{line}`"
      end

    source_errors ++ sparse_errors ++ pin_isolation_errors(steps, where)
  end

  defp pin_isolation_errors(steps, where) do
    checkout? = &String.contains?(&1, "uses: actions/checkout@")

    for {step, at} <- Enum.with_index(steps),
        checkout?.(step),
        yaml_value(step, "sparse-checkout") != nil,
        later = Enum.drop(steps, at + 1),
        error <- pin_path_errors(step, later, where) ++ pin_reader_errors(step, later, where) do
      error
    end
  end

  defp pin_path_errors(pin_checkout, later, where) do
    pin_dir = checkout_dir(pin_checkout)

    for target <- later,
        String.contains?(target, "uses: actions/checkout@"),
        yaml_value(target, "ref") != nil,
        checkout_dir(target) == pin_dir do
      "#{where} toolchain checkout must declare a `path:` that differs from the " <>
        "later `ref:` checkout's path, or its sparse config reaches that checkout"
    end
  end

  defp pin_reader_errors(pin_checkout, later, where) do
    expected = pin_file(checkout_dir(pin_checkout))

    case Enum.find(later, &String.contains?(&1, "uses: erlef/setup-beam@")) do
      nil ->
        []

      beam ->
        if yaml_value(beam, "version-file") == expected,
          do: [],
          else: [
            "#{where} setup-beam must read `version-file: #{expected}` from the pin checkout"
          ]
    end
  end

  # The directory a checkout step writes into; the workspace root when no `path:`.
  defp checkout_dir(step) do
    case yaml_value(step, "path") do
      value when value in [nil, "", ".", "./"] -> "."
      value -> value |> String.trim_leading("./") |> String.trim_trailing("/")
    end
  end

  defp pin_file("."), do: ".tool-versions"
  defp pin_file(nil), do: ".tool-versions"
  defp pin_file(dir), do: dir <> "/.tool-versions"

  # The `path:` of the job's toolchain (sparse) checkout, or nil when it has none.
  defp toolchain_pin_dir(steps) do
    steps
    |> Enum.find(fn step ->
      String.contains?(step, "uses: actions/checkout@") and
        yaml_value(step, "sparse-checkout") != nil
    end)
    |> case do
      nil -> nil
      step -> checkout_dir(step)
    end
  end

  defp pin_checkout_errors([], where),
    do: ["#{where} has no checkout before setup-beam, so .tool-versions is absent"]

  defp pin_checkout_errors(checkouts, where) do
    if yaml_value(List.last(checkouts), "ref"),
      do: [
        "#{where} checks out another ref right before setup-beam; read " <>
          ".tool-versions from the workflow's own commit first"
      ],
      else: []
  end

  # An output read before setup-beam runs is empty, which would collapse every
  # toolchain onto one cache key.
  defp beam_ordering_errors(path, job_id, block) do
    block = strip_comment_lines(block)
    where = "#{path} #{job_id}"

    if String.contains?(block, "uses: erlef/setup-beam@") or
         String.contains?(block, "steps.beam.outputs") do
      case Enum.filter(job_steps(block), &("id: beam" in trimmed_lines(&1))) do
        [beam_step] ->
          early_output_errors(where, block, beam_step)

        beam_steps ->
          ["#{where} must have exactly one `id: beam` step, found #{length(beam_steps)}"]
      end
    else
      []
    end
  end

  defp early_output_errors(where, block, beam_step) do
    {beam_at, _} = :binary.match(block, beam_step)

    early = for {at, _} <- :binary.matches(block, "steps.beam.outputs"), at < beam_at, do: at

    if early == [],
      do: [],
      else: ["#{where} reads steps.beam.outputs before the `id: beam` step runs"]
  end

  defp cache_key_errors(path, job_id, step) do
    step = strip_comment_lines(step)

    if Regex.match?(~r{uses: actions/cache(?:/restore|/save)?@}, step) do
      cache_path = yaml_value(step, "path")
      where = "#{path} #{job_id} cache step for #{inspect(cache_path)}"

      cond do
        Map.has_key?(@beam_independent_cache_paths, cache_path) ->
          []

        String.contains?(step, "uses: actions/cache/save@") and
            Regex.match?(
              ~r/^\s*key: \$\{\{ steps\.[a-z0-9_-]+\.outputs\.cache-primary-key \}\}\s*$/m,
              step
            ) ->
          []

        true ->
          resolved_key_errors(where, yaml_value(step, "key"), yaml_value(step, "restore-keys"))
      end
    else
      []
    end
  end

  defp resolved_key_errors(where, nil, _restore_keys), do: ["#{where} has no `key:`"]

  defp resolved_key_errors(where, key, restore_keys) do
    key_value_errors(where, "key", key) ++
      if restore_keys, do: key_value_errors(where, "restore-keys", restore_keys), else: []
  end

  defp key_value_errors(where, field, value) do
    [
      {String.contains?(value, "steps.beam.outputs.otp-version"),
       "#{where} #{field} must carry the resolved OTP (steps.beam.outputs.otp-version)"},
      {String.contains?(value, "steps.beam.outputs.elixir-version"),
       "#{where} #{field} must carry the resolved Elixir (steps.beam.outputs.elixir-version)"},
      {String.starts_with?(value, "ubuntu-24.04-") or
         String.starts_with?(value, "${{ matrix.runner }}-"),
       "#{where} #{field} must lead with the literal runner label"},
      {not String.contains?(value, @os_family_context),
       "#{where} #{field} must not use the OS-family context value"},
      {not String.contains?(value, @legacy_otp_segment) and
         not String.contains?(value, @legacy_otp_value),
       "#{where} #{field} must not carry a literal OTP segment"}
    ]
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end

  defp yaml_value(step, key) do
    case Regex.run(~r/^\s*#{Regex.escape(key)}:[ \t]*(.*?)[ \t]*$/m, step) do
      [_, value] -> value
      nil -> nil
    end
  end

  # No `runs-on:` or matrix `runner:` value may name the deprecated image,
  # which GitHub is retiring; a job pinned to it would stop being scheduled.
  defp runner_image_errors(path, yaml) do
    yaml
    |> strip_comment_lines()
    |> String.split("\n")
    |> Enum.map(&Regex.run(~r/^\s*(?:-\s+)?(runs-on|runner):\s*(.*?)\s*$/, &1))
    |> Enum.reject(&is_nil/1)
    |> Enum.filter(fn [_, _key, value] -> String.contains?(value, @deprecated_runner_image) end)
    |> Enum.map(fn [_, key, value] ->
      "#{path} #{key}: #{value} names the deprecated runner image"
    end)
  end

  # Every workflow's OS-family context errors (D-05).
  defp workflows_os_family_context_errors(yaml_by_path) do
    yaml_by_path
    |> Map.take([".github/workflows/ci.yml"])
    |> Enum.flat_map(fn {path, yaml} -> os_family_context_errors(path, yaml) end)
  end

  # Whole file, comments included: the CACHE KEY CONTRACT comment promises the
  # OS-family context expression appears nowhere in ci.yml.
  defp os_family_context_errors(path, yaml) do
    yaml
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.filter(fn {line, _n} -> String.contains?(line, @os_family_context) end)
    |> Enum.map(fn {_line, n} -> "#{path}:#{n} names the OS-family runner context" end)
  end

  defp toolchain_contract_errors(yaml_by_path) do
    Enum.flat_map(yaml_by_path, fn {path, yaml} ->
      jobs = workflow_jobs(yaml)

      cond do
        jobs == [] ->
          ["#{path} has no parseable jobs — the toolchain contract would pass vacuously"]

        Enum.any?(jobs, fn {_id, block} ->
          String.contains?(strip_comment_lines(block), "uses: erlef/setup-beam@")
        end) ->
          Enum.flat_map(jobs, &job_toolchain_errors(path, &1))

        true ->
          []
      end
    end)
  end

  defp job_toolchain_errors(path, {job_id, block}) do
    steps = job_steps(block)
    pin_dir = block |> strip_comment_lines() |> job_steps() |> toolchain_pin_dir()

    Enum.flat_map(steps, &setup_beam_errors(path, job_id, &1, pin_dir)) ++
      toolchain_source_errors(path, job_id, block) ++
      beam_ordering_errors(path, job_id, block) ++
      Enum.flat_map(steps, &cache_key_errors(path, job_id, &1))
  end
end
