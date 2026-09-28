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
    test "ci.yml declares static name + lane axis [min, current, latest] (construction A)" do
      yaml = read_rel!([".github", "workflows", "ci.yml"])

      assert Regex.match?(~r/^\s*name: Run test suite\s*$/m, yaml),
             "verify-test must declare the static `name: Run test suite` (GitHub composes the lane suffix)"

      assert Regex.match?(~r/^\s*lane:\s*\[min,\s*current,\s*latest\]\s*$/m, yaml),
             "verify-test matrix must declare base axis `lane: [min, current, latest]`"
    end

    test "each lane installs one exact toolchain: the floor build or the committed .tool-versions" do
      yaml = read_rel!([".github", "workflows", "ci.yml"])
      mix_exs = read_rel!(["mix.exs"])
      tool_versions = read_rel!([".tool-versions"])

      assert verify_test_matrix_errors(yaml, mix_exs, tool_versions) == []

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
        {"a fourth matrix row",
         String.replace(
           yaml,
           current_row,
           ~s(          - lane: extra\n            version-file: ".tool-versions"\n) <>
             current_row
         )}
      ]

      for {control, mutated} <- controls do
        refute mutated == yaml, "#{control} control did not change the input"

        refute verify_test_matrix_errors(mutated, mix_exs, tool_versions) == [],
               "#{control} mutation must make the verify-test matrix contract fail"
      end

      refute verify_test_matrix_errors(
               yaml,
               String.replace(mix_exs, ~s(elixir: "~> 1.15"), ~s(elixir: "~> 1.16")),
               tool_versions
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

    test "the latest row pins an exact, strictly newer toolchain (D-14)" do
      yaml = read_rel!([".github", "workflows", "ci.yml"])
      mix_exs = read_rel!(["mix.exs"])
      tool_versions = read_rel!([".tool-versions"])

      assert verify_test_matrix_errors(yaml, mix_exs, tool_versions) == []

      by_lane =
        yaml
        |> workflow_job("verify-test")
        |> verify_test_rows()
        |> Map.new(&{&1["lane"], &1})

      latest = Map.fetch!(by_lane, "latest")
      latest_row = ~s(          - lane: latest\n)

      latest_runner =
        ~s(            pg: "#{latest["pg"]}"\n            runner: "ubuntu-24.04"\n)

      controls = [
        {"version-file added",
         String.replace(
           yaml,
           latest_row,
           latest_row <> ~s(            version-file: ".tool-versions"\n)
         ), tool_versions, ["latest row must not set version-file"]},
        {"bare OTP major", String.replace(yaml, ~s(otp: "#{latest["otp"]}"), ~s(otp: "29")),
         tool_versions, ["latest row otp must be an exact release"]},
        {"release-candidate Elixir",
         String.replace(yaml, ~s(elixir: "#{latest["elixir"]}"), ~s(elixir: "1.20.0-rc.1")),
         tool_versions, ["latest row elixir must be an exact release"]},
        {"pg not newer", String.replace(yaml, ~s(pg: "#{latest["pg"]}"), ~s(pg: "16")),
         tool_versions, ["latest row pg major must be newer"]},
        {"deprecated runner",
         String.replace(
           yaml,
           latest_runner,
           ~s(            pg: "#{latest["pg"]}"\n            runner: ") <>
             "ubuntu-" <> "22.04" <> ~s("\n)
         ), tool_versions, ["latest row must run on ubuntu-24.04"]},
        {"current lane raised above latest", yaml,
         tool_versions
         |> String.replace(~r/^elixir .*$/m, "elixir 1.99.0-otp-27")
         |> String.replace(~r/^erlang .*$/m, "erlang 99.0"),
         ["latest row Elixir must be newer", "latest row OTP major must be newer"]}
      ]

      for {control, mutated_yaml, mutated_tv, fragments} <- controls do
        refute {mutated_yaml, mutated_tv} == {yaml, tool_versions},
               "#{control} control did not change the input"

        errors = verify_test_matrix_errors(mutated_yaml, mix_exs, mutated_tv)

        for fragment <- fragments do
          assert Enum.any?(errors, &String.contains?(&1, fragment)),
                 "#{control} mutation must report #{inspect(fragment)}, got #{inspect(errors)}"
        end
      end
    end

    test "the latest lane is documented as tested-on, never a support floor (D-17)" do
      readme = read_rel!(["README.md"])
      mix_exs = read_rel!(["mix.exs"])
      contributing = read_rel!(["CONTRIBUTING.md"])
      job = workflow_job(read_rel!([".github", "workflows", "ci.yml"]), "verify-test")

      assert String.contains?(readme, "not a new support floor")
      assert String.contains?(readme, "`latest` lane")
      assert String.contains?(mix_exs, "CI `latest` lane")
      assert String.contains?(contributing, "Run test suite (latest)")
      assert String.contains?(contributing, "not a support floor")
      assert String.contains?(contributing, "Test-file warnings stay non-fatal on every lane")
      assert String.contains?(job, ~s["Run test suite (latest)"])
    end

    test "CONTRIBUTING List 2 carries every composed required-check name" do
      doc = read_rel!(["CONTRIBUTING.md"])

      assert String.contains?(doc, "Run test suite (min)")
      assert String.contains?(doc, "Run test suite (current)")
      assert String.contains?(doc, "Run test suite (latest)")
    end
  end

  describe "voting lanes and PostgreSQL images (LANE-01)" do
    @ci_path ".github/workflows/ci.yml"

    test "no voting lane can be made non-blocking (D-15)" do
      workflows = all_workflows()

      assert voting_lane_errors(workflows) == []

      refute ci_required_needs(workflows[@ci_path]) == [],
             "ci-required's needs: list parsed empty — the needs-coverage check would be vacuous"

      job_header = "    name: Run test suite\n"
      run_tests = "      - name: Run tests\n        run: mix verify.test\n"
      alls_green_jobs = "          jobs: ${{ toJSON(needs) }}\n"

      controls = [
        {"job-level continue-on-error on verify-test",
         &String.replace(&1, job_header, job_header <> "    continue-on-error: true\n"),
         "rule=continue-on-error"},
        {"step-level continue-on-error on Run tests",
         &String.replace(
           &1,
           run_tests,
           "      - name: Run tests\n        continue-on-error: true\n" <>
             "        run: mix verify.test\n"
         ), "rule=continue-on-error"},
        {"matrix-expression continue-on-error",
         &String.replace(
           &1,
           job_header,
           job_header <> "    continue-on-error: ${{ matrix.lane == 'latest' }}\n"
         ), "rule=continue-on-error"},
        {"allowed-failures in ci-required",
         &String.replace(
           &1,
           alls_green_jobs,
           alls_green_jobs <> "          allowed-failures: verify-test\n"
         ), "rule=allowed-failures"},
        {"quoted continue-on-error key on verify-test",
         &String.replace(&1, job_header, job_header <> ~s(    "continue-on-error": true\n)),
         "rule=continue-on-error"},
        {"flow-mapped step with continue-on-error",
         &String.replace(
           &1,
           run_tests,
           run_tests <> "      - { name: Extra, run: mix help, continue-on-error: true }\n"
         ), "rule=continue-on-error"},
        {"quoted allowed-failures key in ci-required",
         &String.replace(
           &1,
           alls_green_jobs,
           alls_green_jobs <> ~s(          'allowed-failures': verify-test\n)
         ), "rule=allowed-failures"},
        {"verify-test dropped from ci-required needs",
         &String.replace(&1, "      - verify-test\n", ""), "rule=needs-coverage"},
        {"Run tests skipped on the latest lane",
         &String.replace(
           &1,
           run_tests,
           "      - name: Run tests\n        if: matrix.lane != 'latest'\n" <>
             "        run: mix verify.test\n"
         ), "rule=lane-skip"},
        {"Run tests made unable to fail",
         &String.replace(
           &1,
           run_tests,
           "      - name: Run tests\n        run: mix verify.test || true\n"
         ), "rule=lane-command"},
        {"Compile step skipped on the latest lane",
         &String.replace(
           &1,
           "      - name: Compile (warnings as errors)\n",
           "      - name: Compile (warnings as errors)\n        if: matrix.lane != 'latest'\n"
         ), "rule=lane-skip"},
        {"xref cycles step removed",
         &String.replace(
           &1,
           "      - name: Verify no compile-connected xref cycles\n" <>
             "        run: mix verify.xref_cycles\n",
           ""
         ), "rule=lane-step-missing"},
        {"underscore job id missing from ci-required needs",
         &(&1 <> "\n  verify_extra:\n    runs-on: ubuntu-24.04\n"), "rule=needs-coverage"},
        {"uppercase job id with continue-on-error",
         &(&1 <>
             "\n  VerifyExtra:\n    runs-on: ubuntu-24.04\n    continue-on-error: true\n"),
         "job=VerifyExtra rule=continue-on-error"}
      ]

      for {control, mutate, fragment} <- controls do
        mutated = Map.update!(workflows, @ci_path, mutate)

        refute mutated == workflows, "#{control} control did not change the input"

        errors = voting_lane_errors(mutated)

        assert Enum.any?(errors, &String.contains?(&1, fragment)),
               "#{control} mutation must report #{fragment}, got #{inspect(errors)}"
      end

      commented =
        Map.update!(
          workflows,
          @ci_path,
          &String.replace(
            &1,
            job_header,
            job_header <> "      # continue-on-error is banned in this workflow\n"
          )
        )

      refute commented == workflows, "comment positive control did not change the input"

      assert voting_lane_errors(commented) == [],
             "the word continue-on-error inside a comment must not trip the contract"
    end

    test "no workflow or compose file runs a pre-release PostgreSQL (D-16)" do
      sources = image_sources()

      assert postgres_image_errors(sources) == []

      tags = postgres_image_tags(sources)

      for path <- [
            @ci_path,
            ".github/workflows/browser-full.yml",
            ".github/workflows/flake-detection.yml",
            ".github/workflows/release.yml",
            "docker-compose.yml"
          ] do
        assert Enum.any?(tags, &match?({^path, _job, _tag}, &1)),
               "found no postgres image in #{path} — the tag scan would be vacuous there"
      end

      rows = verify_test_rows(workflow_job(sources[@ci_path], "verify-test"))
      verify_test_tags = for {@ci_path, "verify-test", tag} <- tags, do: tag

      assert length(rows) == 3
      assert Enum.sort(verify_test_tags) == rows |> Enum.map(& &1["pg"]) |> Enum.sort()

      latest_pg = rows |> Enum.find(&(&1["lane"] == "latest")) |> Map.fetch!("pg")

      controls = [
        {"beta PostgreSQL in the latest row", @ci_path,
         &String.replace(&1, ~s(pg: "#{latest_pg}"), ~s(pg: "19beta1")), "rule=pg-tag"},
        {"release-candidate image in browser-full.yml", ".github/workflows/browser-full.yml",
         &String.replace(&1, "postgres:16", "postgres:18rc1"), "rule=pg-tag"},
        {"devel image in release.yml", ".github/workflows/release.yml",
         &String.replace(&1, "postgres:16", "postgres:devel"), "rule=pg-tag"},
        {"unresolvable matrix key", @ci_path,
         &String.replace(&1, "postgres:${{ matrix.pg }}", "postgres:${{ matrix.pg_tag }}"),
         "rule=pg-unresolved"},
        {"registry-prefixed beta image in browser-full.yml", ".github/workflows/browser-full.yml",
         &String.replace(
           &1,
           "image: postgres:16",
           "image: docker.io/library/postgres:19beta1"
         ), "rule=pg-tag"},
        {"expression with a pre-release suffix", @ci_path,
         &String.replace(&1, "postgres:${{ matrix.pg }}", "postgres:${{ matrix.pg }}rc1"),
         "rule=pg-unresolved"},
        {"untagged image (implicit latest) in docker-compose.yml", "docker-compose.yml",
         &String.replace(&1, "    image: postgres:16\n", "    image: postgres\n"), "rule=pg-tag"},
        {"digest-pinned image in flake-detection.yml", ".github/workflows/flake-detection.yml",
         &String.replace(
           &1,
           "image: postgres:16",
           "image: postgres@sha256:" <> String.duplicate("0", 64)
         ), "rule=pg-tag"},
        {"docker run of a beta image in release.yml", ".github/workflows/release.yml",
         &(&1 <> "      - run: docker run --rm postgres:19beta1\n"), "rule=pg-tag"}
      ]

      for {control, path, mutate, fragment} <- controls do
        mutated = Map.update!(sources, path, mutate)

        refute mutated == sources, "#{control} control did not change the input"

        errors = postgres_image_errors(mutated)

        assert Enum.any?(errors, &String.contains?(&1, fragment)),
               "#{control} mutation must report #{fragment}, got #{inspect(errors)}"
      end

      url_line =
        "      DATABASE_URL: postgres://postgres:postgres@postgres:5432/threadline_test\n"

      with_url =
        Map.update!(
          sources,
          "docker-compose.yml",
          &String.replace(&1, "    image: postgres:16\n", "    image: postgres:16\n" <> url_line)
        )

      refute with_url == sources, "connection-URL positive control did not change the input"
      assert postgres_image_errors(with_url) == []

      assert postgres_image_tags(with_url) == tags,
             "a postgres:// connection URL must not be read as an image reference"

      # Positive controls: a registry-prefixed, quoted or commented release tag
      # is still a release tag and must neither fail nor drop out of the scan.
      for {control, replacement} <- [
            {"registry-prefixed release tag", "    image: docker.io/library/postgres:16\n"},
            {"quoted release tag", ~s(    image: "postgres:16"\n)},
            {"trailing comment", "    image: postgres:16 # pinned\n"}
          ] do
        variant =
          Map.update!(
            sources,
            "docker-compose.yml",
            &String.replace(&1, "    image: postgres:16\n", replacement)
          )

        refute variant == sources, "#{control} positive control did not change the input"
        assert postgres_image_errors(variant) == [], "#{control} must pass"

        assert postgres_image_tags(variant) == tags,
               "#{control} must still be scanned as postgres:16"
      end
    end
  end

  # D-15: every lane that `ci-required` needs must be able to fail. A job- or
  # step-level `continue-on-error:` (any value, including a `${{ matrix.* }}`
  # expression), an `allowed-failures:` on the alls-green step, or a ci.yml job
  # missing from `needs:` would each let a red lane report green. The key match
  # also catches a quoted key (`"continue-on-error": true`) and a flow-mapped
  # step (`- { name: x, continue-on-error: true }`), both valid YAML GitHub honours.
  @continue_on_error_key ~r/(^|[\s{,])["']?continue-on-error["']?\s*:/m
  @allowed_failures_key ~r/(^|[\s{,])["']?allowed-failures["']?\s*:/m

  defp voting_lane_errors(yaml_by_path) do
    ci_path = ".github/workflows/ci.yml"
    ci_yaml = Map.get(yaml_by_path, ci_path, "")

    continue_errors =
      for {path, yaml} <- Enum.sort(yaml_by_path),
          {job_id, block} <- workflow_jobs(yaml),
          Regex.match?(@continue_on_error_key, strip_comment_lines(block)) do
        "#{path} job=#{job_id} rule=continue-on-error: a voting job or step carries " <>
          "`continue-on-error:`, so a red lane could report green (D-15)"
      end

    allowed_failures_errors =
      if Regex.match?(
           @allowed_failures_key,
           strip_comment_lines(workflow_job(ci_yaml, "ci-required"))
         ),
         do: [
           "#{ci_path} job=ci-required rule=allowed-failures: the alls-green gate must not " <>
             "tolerate any failed lane (D-15)"
         ],
         else: []

    needs = MapSet.new(ci_required_needs(ci_yaml))

    jobs =
      ci_yaml
      |> workflow_jobs()
      |> Enum.map(&elem(&1, 0))
      |> MapSet.new()
      |> MapSet.delete("ci-required")

    needs_errors =
      cond do
        MapSet.size(needs) == 0 ->
          [
            "#{ci_path} job=ci-required rule=needs-coverage: needs: list parsed empty, " <>
              "so the coverage check would be vacuous"
          ]

        needs == jobs ->
          []

        true ->
          [
            "#{ci_path} job=ci-required rule=needs-coverage: needs: must list every other " <>
              "ci.yml job; missing=#{inspect(jobs |> MapSet.difference(needs) |> Enum.sort())} " <>
              "extra=#{inspect(needs |> MapSet.difference(jobs) |> Enum.sort())}"
          ]
      end

    continue_errors ++ allowed_failures_errors ++ needs_errors ++ every_lane_step_errors(ci_yaml)
  end

  # D-15 (WR-01, 220 review): the steps that make the `latest` lane (and every
  # other verify-test lane) prove something must run on every lane. A step
  # `if:` (e.g. `matrix.lane != 'latest'`) would skip the step and leave the
  # lane green; a changed `run:` (e.g. `mix verify.test || true`) would make it
  # unable to fail. Each step must exist once, carry no `if:`, and run exactly
  # the expected command.
  @every_lane_steps [
    {"Compile (warnings as errors)", "mix compile --warnings-as-errors"},
    {"Verify no compile-connected xref cycles", "mix verify.xref_cycles"},
    {"Run tests", "mix verify.test"}
  ]

  defp every_lane_step_errors(ci_yaml) do
    steps = ci_yaml |> workflow_job("verify-test") |> strip_comment_lines() |> job_steps()

    for {name, cmd} <- @every_lane_steps,
        error <- every_lane_step_error(steps, name, cmd),
        do: ".github/workflows/ci.yml job=verify-test step=#{inspect(name)} " <> error
  end

  defp every_lane_step_error(steps, name, cmd) do
    case Enum.filter(steps, &String.starts_with?(&1, "      - name: #{name}\n")) do
      [step] ->
        lines = trimmed_lines(step)

        skip_errors =
          if Enum.any?(lines, &String.starts_with?(&1, "if:")),
            do: ["rule=lane-skip: the step carries `if:`, so a lane could skip it (D-15)"],
            else: []

        command_errors =
          if "run: #{cmd}" in lines,
            do: [],
            else: ["rule=lane-command: the step must run exactly `#{cmd}` (D-15)"]

        skip_errors ++ command_errors

      found ->
        [
          "rule=lane-step-missing: expected exactly one such step, found #{length(found)} (D-15)"
        ]
    end
  end

  # Parsed the same way ci_topology_contract_test.exs reads the roster.
  defp ci_required_needs(ci_yaml) do
    block = ci_yaml |> workflow_job("ci-required") |> strip_comment_lines()

    case Regex.run(~r/    needs:\n((?:      - .+\n)+)/, block <> "\n") do
      [_, list] ->
        ~r/^      - (\S+)\s*$/m
        |> Regex.scan(list)
        |> Enum.map(fn [_, job] -> job end)

      nil ->
        []
    end
  end

  defp image_sources do
    Map.put(all_workflows(), "docker-compose.yml", read_rel!(["docker-compose.yml"]))
  end

  # D-16: every PostgreSQL image in every workflow and docker-compose.yml must
  # be a release tag (`18` or `18.6`). `${{ matrix.pg }}` resolves through the
  # job's parsed `include` rows; anything unresolvable fails closed.
  #
  # `image:` lines are parsed whole (WR-02, 220 review), so a registry or
  # namespace prefix (`docker.io/library/postgres:…`), an untagged image
  # (implicit `latest`), a digest pin, or text around a `${{ … }}` expression
  # cannot slip past. Any image whose final path segment starts with
  # `postgres` counts (fail closed). Every other line is scanned for bare
  # `postgres:<tag>` tokens (a `docker run` or `container:` shorthand); there
  # the lookbehind skips `postgres://…@postgres:5432` connection URLs.
  @postgres_image_line ~r/^\s*image:\s*(.+?)\s*$/
  @image_value ~r/^(?:[^\s\/]+\/)*(?<name>[A-Za-z0-9._-]+)(?<rest>.*)$/
  @postgres_image_ref ~r/(?<![\w\/@:.-])postgres:(\$\{\{[^}]*\}\}|[A-Za-z0-9_.-]+)/
  @postgres_release_tag ~r/^\d+(\.\d+)?$/

  defp postgres_image_errors(sources) do
    for {path, job_id, ref} <- postgres_image_refs(sources),
        error <- postgres_ref_errors(path, job_id, ref),
        do: error
  end

  defp postgres_image_tags(sources) do
    for {path, job_id, {:ok, tag}} <- postgres_image_refs(sources), do: {path, job_id, tag}
  end

  defp postgres_ref_errors(path, job_id, {:ok, tag}) do
    if Regex.match?(@postgres_release_tag, tag),
      do: [],
      else: [
        "#{path} job=#{job_id} rule=pg-tag: postgres:#{tag} is not a release tag matching " <>
          "^\\d+(\\.\\d+)?$ (no beta, rc, devel, nightly, latest or variant suffix) (D-16)"
      ]
  end

  defp postgres_ref_errors(path, job_id, {:invalid, image}) do
    [
      "#{path} job=#{job_id} rule=pg-tag: image #{image} carries no checkable release " <>
        "tag (untagged means implicit latest; a digest pin hides the version) (D-16)"
    ]
  end

  defp postgres_ref_errors(path, job_id, {:unresolved, expr}) do
    [
      "#{path} job=#{job_id} rule=pg-unresolved: postgres:#{expr} does not resolve to " <>
        "include-row pg values, so its tag cannot be checked (D-16)"
    ]
  end

  # [{path, job_id, {:ok, tag} | {:unresolved, expr} | {:invalid, image}}]
  defp postgres_image_refs(sources) do
    for {path, text} <- Enum.sort(sources),
        {job_id, block} <- image_scan_units(text),
        line <- block |> strip_comment_lines() |> String.split("\n"),
        resolved <- postgres_line_refs(line, block),
        do: {path, job_id, resolved}
  end

  defp postgres_line_refs(line, block) do
    case Regex.run(@postgres_image_line, line) do
      [_, value] ->
        value |> strip_yaml_scalar() |> postgres_image_value_refs(block)

      nil ->
        for [_, ref] <- Regex.scan(@postgres_image_ref, line),
            resolved <- resolve_postgres_ref(ref, block),
            do: resolved
    end
  end

  # Drops a trailing ` # comment` and one layer of surrounding quotes.
  defp strip_yaml_scalar(value) do
    value
    |> String.replace(~r/\s+#.*$/, "")
    |> String.trim()
    |> String.replace(~r/^(["'])(.*)\1$/, "\\2")
  end

  defp postgres_image_value_refs(image, block) do
    with %{"name" => name, "rest" => rest} <- Regex.named_captures(@image_value, image),
         true <- String.starts_with?(String.downcase(name), "postgres") do
      postgres_image_rest_refs(image, rest, block)
    else
      _ -> []
    end
  end

  defp postgres_image_rest_refs(_image, ":" <> tag, block) do
    cond do
      not String.contains?(tag, "${{") -> [{:ok, tag}]
      Regex.match?(~r/^\$\{\{[^}]*\}\}$/, tag) -> resolve_postgres_ref(tag, block)
      true -> [{:unresolved, tag}]
    end
  end

  defp postgres_image_rest_refs(image, _rest, _block), do: [{:invalid, image}]

  # A workflow is scanned per job (matrix expressions resolve per job); a file
  # with no `jobs:` section (docker-compose.yml) is scanned whole.
  defp image_scan_units(text) do
    case workflow_jobs(text) do
      [] -> [{"(file)", text}]
      jobs -> jobs
    end
  end

  defp resolve_postgres_ref("${{" <> _ = expr, block) do
    rows = verify_test_rows(block)

    cond do
      not Regex.match?(~r/^\$\{\{\s*matrix\.pg\s*\}\}$/, expr) ->
        [{:unresolved, expr}]

      rows == [] or Enum.any?(rows, &(not Map.has_key?(&1, "pg"))) ->
        [{:unresolved, expr}]

      true ->
        Enum.map(rows, &{:ok, &1["pg"]})
    end
  end

  defp resolve_postgres_ref(tag, _block), do: [{:ok, tag}]

  describe "dependency cache contract" do
    test "ci.yml caches deps and the e2e npm lockfile" do
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
    end
  end

  # --- Deps-only build cache contract (Phase 219, CACHE-01) --------------------
  #
  # One pure function, `build_cache_errors(yaml_by_path, contributing)`, owns
  # every `_build` cache rule (D-20). It reads literal workflow text, so a rule
  # is proven by feeding it text, not by trusting a pushed run.

  # D-04: the `_build` key version, the single place this contract names it.
  # Bumping it is the durable recovery from a poisoned entry (CONTRIBUTING
  # "Poisoned-cache runbook", step 3): bump it here in the same pull request
  # that bumps every `_build` key and the CACHE KEY CONTRACT comment in ci.yml
  # and the CONTRIBUTING section. The key segments, the doc needles and the
  # fixtures below all derive from it (WR-03, 219 review).
  @build_key_version "build-v1"

  # The root `_build` restore exactly as the cached jobs carry it (`<interfaces>`
  # in 219-01-PLAN). Controls insert this literal step into jobs that must stay
  # cache-free, so they never depend on cloning another job's text.
  @root_build_restore_template ~S"""
        - name: Restore deps-only build cache
          id: build-restore
          uses: actions/cache/restore@v5
          with:
            path: _build/${{ env.MIX_ENV }}
            key: ubuntu-24.04-otp-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-__BUILD_KEY_VERSION__-root-${{ env.MIX_ENV }}-full-${{ hashFiles('mix.lock') }}-${{ hashFiles('config/**/*.exs') }}
  """
  @root_build_restore_step String.replace(
                             @root_build_restore_template,
                             "__BUILD_KEY_VERSION__",
                             @build_key_version
                           )

  @ci_workflow ".github/workflows/ci.yml"
  @flake_workflow ".github/workflows/flake-detection.yml"
  @browser_full_workflow ".github/workflows/browser-full.yml"
  @release_workflow ".github/workflows/release.yml"

  # D-11, D-20: the fail-closed `_build` cache allowlist. `{workflow, job} =>
  # {reason, mode, projects}`. A `_build` cache step in any other job is an
  # error, and each job must restore exactly its `projects`, no more and no less.
  @build_cache_jobs %{
    {@ci_workflow, "verify-test"} =>
      {"every lane compiles the root project, and the current lane also builds the example app",
       :save, [:root, :example]},
    {@ci_workflow, "verify-pgbouncer-topology"} =>
      {"reuses the current lane's root test key: restore-only adds no key and removes a save race",
       :restore_only, [:root]},
    {@ci_workflow, "verify-example-browser"} =>
      {"builds only the example app before Playwright; the root project is never compiled here",
       :save, [:example]},
    {@ci_workflow, "verify-capture"} =>
      {"builds only the example app before regenerating the Tier A capture", :save, [:example]}
  }

  # D-12, D-13: every deliberately cache-free job, each with its reason. Each
  # entry must name a job that exists, and none may carry a `_build` cache.
  @build_cache_exclusions %{
    {@ci_workflow, "verify-format"} => "compiles nothing: it only runs the formatter check",
    {@ci_workflow, "verify-credo"} =>
      "dev env, not a test job, and off the critical path (deferred by D-12)",
    {@ci_workflow, "verify-dialyzer"} =>
      "dev env, and it switches MIX_ENV mid-job, so one env-scoped key cannot describe it",
    {@ci_workflow, "verify-compile-no-optional"} =>
      "the optional-deps proof must build from source with no cache step of any kind (D-13)",
    {@ci_workflow, "verify-hex-evaluator"} =>
      "its lock is gitignored and regenerated every run, so no exact key exists",
    {@ci_workflow, "verify-release-shape"} =>
      "compiles nothing: it checks CHANGELOG and @version text",
    {@ci_workflow, "verify-bump-rehearsal"} =>
      "builds inside a throwaway clone, so a restored _build would never be read",
    {@ci_workflow, "verify-deps-audit"} => "compiles nothing: it audits the lockfiles",
    {@ci_workflow, "verify-repo-hygiene"} => "compiles nothing: it scans tracked text",
    {@flake_workflow, "verify-flake"} =>
      "off the pull-request path (weekly and on dispatch); deferred by D-12",
    {@browser_full_workflow, "verify-example-browser-full"} =>
      "off the pull-request path (push to main and nightly); deferred by D-12",
    {@release_workflow, "publish-hex"} =>
      "a published package must be built from source, never from a cache (D-17)",
    {@release_workflow, "smoke-published"} =>
      "the published-release smoke test must prove hex.pm's package on a clean build (D-17)"
  }

  # D-01..D-05: the single source of the required `_build` key segments per
  # project. The example key never carries the root lock or root config (D-02).
  @build_key_segments %{
    root: [
      "steps.beam.outputs.otp-version",
      "steps.beam.outputs.elixir-version",
      "-#{@build_key_version}-",
      "-root-",
      "${{ env.MIX_ENV }}",
      "-full-",
      "${{ hashFiles('mix.lock') }}",
      "${{ hashFiles('config/**/*.exs') }}"
    ],
    example: [
      "steps.beam.outputs.otp-version",
      "steps.beam.outputs.elixir-version",
      "-#{@build_key_version}-",
      "-example-",
      "${{ env.MIX_ENV }}",
      "-full-",
      "${{ hashFiles('examples/threadline_phoenix/mix.lock') }}",
      "${{ hashFiles('examples/threadline_phoenix/config/**/*.exs') }}"
    ]
  }

  # D-02, D-03, D-05, D-06: inputs a `_build` key must never carry. `no-optional`
  # is reserved for a job that never caches; `**/mix.lock` sweeps in the bench,
  # fixture and regenerated evaluator locks; `.tool-versions` duplicates the
  # resolved outputs. The example key must not carry the root lock or config.
  @build_key_forbidden %{
    root: ["no-optional", "**/mix.lock", ".tool-versions"],
    example: [
      "no-optional",
      "**/mix.lock",
      ".tool-versions",
      "hashFiles('mix.lock')",
      "hashFiles('config/**/*.exs')"
    ]
  }

  describe "deps-only build cache contract" do
    test "the D-17 security subset holds on every live workflow" do
      errors = build_cache_security_errors(all_workflows())

      assert errors == [],
             "the build cache security rules must hold live, got:\n" <> Enum.join(errors, "\n")
    end

    test "every live workflow and CONTRIBUTING satisfy the whole build cache contract" do
      errors = build_cache_errors(all_workflows(), read_rel!(["CONTRIBUTING.md"]))

      assert errors == [],
             "the live tree must satisfy every build cache rule, got:\n" <>
               Enum.join(errors, "\n")
    end

    test "control: every build cache fault is red on the live tree, each with its own rule" do
      assert_build_cache_controls(all_workflows(), read_rel!(["CONTRIBUTING.md"]))
    end

    test "anti-drift: the text step splitter sees every parsed step of each cached job" do
      parsed = YamlElixir.read_from_file!(Path.join(@repo_root, @ci_workflow))
      live = all_workflows()

      for {{path, job_id}, _entry} <- @build_cache_jobs do
        yaml_steps = get_in(parsed, ["jobs", job_id, "steps"]) || []
        text_steps = job_steps(workflow_job(live[path], job_id))

        refute yaml_steps == [], "#{job_id} parsed with no steps"

        assert length(yaml_steps) == length(text_steps),
               "#{job_id}: YAML has #{length(yaml_steps)} steps, " <>
                 "job_steps/1 split #{length(text_steps)}"
      end
    end

    test "security control: a cache step in release.yml publish-hex is red" do
      live = all_workflows()
      release = ".github/workflows/release.yml"

      mutated =
        Map.update!(
          live,
          release,
          &insert_step_in_job(&1, "publish-hex", @root_build_restore_step)
        )

      refute mutated == live, "the release.yml control did not change the input"

      errors = build_cache_security_errors(mutated)

      assert Enum.any?(errors, &(&1 =~ "rule=release-cache" and &1 =~ release)),
             "a cache step in publish-hex must fail with rule=release-cache, got #{inspect(errors)}"

      assert Enum.any?(build_cache_errors(mutated, ""), &(&1 =~ "rule=release-cache")),
             "build_cache_errors/2 must compose the security rules"
    end

    test "cache words in comments or `git diff --cached` are not cache steps" do
      text = """
      on:
        push:
          branches: [main]
      jobs:
        publish-hex:
          steps:
            # The toolchain lands in the runner tool cache; restore-keys: none.
            - name: Stage
              run: |
                if git diff --cached --quiet; then echo clean; fi
            - name: Poll
              run: echo "${{ github.event.workflow_run.id }} data.workflow_runs"
      """

      assert build_cache_security_errors(%{".github/workflows/release.yml" => text}) == []
    end

    test "docs: the fixture ci.yml comment and CONTRIBUTING section satisfy the doc rules" do
      fixture = build_cache_fixture()
      contributing = build_cache_fixture_contributing()

      assert build_cache_doc_errors(fixture, contributing) == []

      assert Enum.any?(
               build_cache_doc_errors(fixture, "## Contributing\n"),
               &(&1 =~ "rule=doc-contributing")
             ),
             "a CONTRIBUTING without the section must fail the doc rules"
    end

    test "the synthetic fixture satisfies every build cache rule" do
      errors = build_cache_errors(build_cache_fixture(), build_cache_fixture_contributing())

      assert errors == [],
             "the fixture is the shape plan 02 must reach; it must be clean, got:\n" <>
               Enum.join(errors, "\n")
    end

    test "control: a D-04 key-version bump that skips @build_key_version is red on each pin" do
      # The runbook's own example bump. It must not contain the old version as a
      # substring, or the doc needles would still match.
      bumped = "build-v2"
      refute String.contains?(bumped, @build_key_version)
      live = all_workflows()
      contributing = read_rel!(["CONTRIBUTING.md"])

      mutated = Map.update!(live, @ci_workflow, &String.replace(&1, @build_key_version, bumped))

      errors =
        build_cache_errors(mutated, String.replace(contributing, @build_key_version, bumped))

      refute mutated == live, "the key-version bump did not change ci.yml"

      for rule <- ["rule=key-segment", "rule=doc-ci-comment", "rule=doc-contributing"] do
        assert Enum.any?(errors, &String.contains?(&1, rule)),
               "a bump that skips @build_key_version must fail #{rule} (the CONTRIBUTING " <>
                 "runbook names the attribute), got:\n" <> Enum.join(errors, "\n")
      end
    end

    test "the build cache allowlist is exactly the D-11 set, each entry with a reason" do
      ci = ".github/workflows/ci.yml"

      assert Map.new(@build_cache_jobs, fn {key, {_reason, mode, projects}} ->
               {key, {mode, projects}}
             end) == %{
               {ci, "verify-test"} => {:save, [:root, :example]},
               {ci, "verify-pgbouncer-topology"} => {:restore_only, [:root]},
               {ci, "verify-example-browser"} => {:save, [:example]},
               {ci, "verify-capture"} => {:save, [:example]}
             }

      for {key, {reason, _mode, _projects}} <- @build_cache_jobs do
        assert is_binary(reason) and String.length(reason) > 20,
               "#{inspect(key)} needs a reason longer than 20 characters"
      end
    end

    test "every deliberately cache-free job is named with a reason (D-12, D-13)" do
      ci = ".github/workflows/ci.yml"

      assert @build_cache_exclusions |> Map.keys() |> Enum.sort() ==
               Enum.sort(
                 for(
                   job <- ~w(verify-format verify-credo verify-dialyzer verify-compile-no-optional
                     verify-hex-evaluator verify-release-shape verify-bump-rehearsal
                     verify-deps-audit verify-repo-hygiene),
                   do: {ci, job}
                 ) ++
                   [
                     {".github/workflows/flake-detection.yml", "verify-flake"},
                     {".github/workflows/browser-full.yml", "verify-example-browser-full"},
                     {".github/workflows/release.yml", "publish-hex"},
                     {".github/workflows/release.yml", "smoke-published"}
                   ]
               )

      for {key, reason} <- @build_cache_exclusions do
        assert is_binary(reason) and String.length(reason) > 20,
               "#{inspect(key)} needs a reason longer than 20 characters"
      end

      assert MapSet.disjoint?(
               MapSet.new(Map.keys(@build_cache_exclusions)),
               MapSet.new(Map.keys(@build_cache_jobs))
             )
    end

    test "control: every build cache fault is red on the fixture, each with its own rule" do
      assert_build_cache_controls(build_cache_fixture(), build_cache_fixture_contributing())
    end

    test "positive control: extra `_build` comment lines keep the fixture clean" do
      fixture = build_cache_fixture()

      commented =
        Map.update!(fixture, @ci_workflow, fn ci ->
          String.replace(
            ci,
            "\n      - ",
            "\n      # _build restore-keys actions/cache@v5\n      - "
          )
        end)

      refute commented == fixture, "the positive control did not change the input"
      assert build_cache_errors(commented, build_cache_fixture_contributing()) == []
    end

    test "control: every build cache fault is red on the hybrid map (live workflows, fixture ci.yml)" do
      hybrid = Map.put(all_workflows(), @ci_workflow, build_cache_fixture()[@ci_workflow])
      errors = build_cache_errors(hybrid, build_cache_fixture_contributing())

      assert errors == [],
             "every live workflow plus the fixture ci.yml must be clean, got:\n" <>
               Enum.join(errors, "\n")

      assert_build_cache_controls(hybrid, build_cache_fixture_contributing())
    end

    test "live needle: every control outside <interfaces> bites on the fully live workflows" do
      live = all_workflows()
      contributing = build_cache_fixture_contributing()
      baseline = build_cache_errors(live, contributing)
      controls = build_cache_live_needle_controls(live, contributing)

      refute controls == [], "the live needle control table is empty"

      for {label, mutated, mutated_contributing, fragment} <- controls do
        refute mutated == live, "#{label} control did not change the live input"
        [_, job_id] = Regex.run(~r/^\S+ (\S+):/, label)
        added = build_cache_errors(mutated, mutated_contributing) -- baseline

        assert Enum.any?(added, &(&1 =~ fragment and &1 =~ " #{job_id} ")),
               "#{label} must add a #{fragment} error for #{job_id}, got:\n" <>
                 Enum.join(added, "\n")
      end
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

  # Job headers follow GitHub's job-id grammar (letters, digits, `_`, `-`; must
  # start with a letter or `_`). A narrower pattern would fold a job such as
  # `verify_latest:` into the previous job's block and hide it from the
  # needs-coverage check (WR-03, 220 review).
  @job_id_pattern "[A-Za-z_][A-Za-z0-9_-]*"

  defp workflow_jobs(yaml) do
    case String.split(yaml, ~r/^jobs:\n/m, parts: 2) do
      [_, body] ->
        ~r/^  (#{@job_id_pattern}):[ \t]*\n[\s\S]*?(?=^  #{@job_id_pattern}:[ \t]*\n|\z)/m
        |> Regex.scan(body)
        |> Enum.map(fn [block, job_id] -> {job_id, block} end)

      _ ->
        []
    end
  end

  defp workflow_job(yaml, id) do
    case Regex.run(
           ~r/^  #{Regex.escape(id)}:[ \t]*\n([\s\S]*?)(?=^  #{@job_id_pattern}:[ \t]*\n|\z)/m,
           yaml
         ) do
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
  defp verify_test_matrix_errors(yaml, mix_exs, tool_versions) do
    rows = verify_test_rows(workflow_job(yaml, "verify-test"))
    by_lane = Map.new(rows, &{&1["lane"], &1})

    count_errors =
      if length(rows) == 3 and Map.keys(by_lane) |> Enum.sort() == ["current", "latest", "min"],
        do: [],
        else: [
          "verify-test must have exactly three include rows (min, current, latest), found " <>
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
      current_row_errors(by_lane["current"]) ++
      latest_row_errors(by_lane["latest"], current_toolchain(tool_versions, by_lane["current"]))
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

  # The current lane's committed toolchain: `.tool-versions` for OTP/Elixir (the
  # `-otp-NN` build suffix stripped) and the current row for PostgreSQL. A
  # missing value is nil, which skips the matching newer-than check.
  defp current_toolchain(tool_versions, current_row) do
    tool = fn name ->
      case Regex.run(~r/^#{name}\s+(\S+)\s*$/m, tool_versions) do
        [_, version] -> version
        nil -> nil
      end
    end

    elixir =
      case tool.("elixir") do
        nil -> nil
        version -> String.replace(version, ~r/-otp-\d+$/, "")
      end

    %{otp: tool.("erlang"), elixir: elixir, pg: current_row && current_row["pg"]}
  end

  # The latest lane is tested-on evidence, not a support promise, so unlike the
  # min row its pins are checked for shape and ordering only: an exact release,
  # strictly newer than the current lane. A literal version here would break on
  # every milestone re-pin (D-18). A shape-invalid value skips its newer-than
  # check, so a malformed pin reports the shape error and never crashes.
  defp latest_row_errors(nil, _current), do: ["verify-test has no latest row"]

  defp latest_row_errors(row, current) do
    otp = row["otp"]
    elixir = row["elixir"]
    pg = row["pg"]

    otp_ok? = is_binary(otp) and Regex.match?(~r/^\d+\.\d+(\.\d+){0,2}$/, otp)
    elixir_ok? = is_binary(elixir) and Regex.match?(~r/^\d+\.\d+\.\d+$/, elixir)
    pg_ok? = is_binary(pg) and Regex.match?(~r/^\d+(\.\d+)?$/, pg)

    [
      {not Map.has_key?(row, "version-file"), "latest row must not set version-file"},
      {row["runner"] == "ubuntu-24.04", "latest row must run on ubuntu-24.04"},
      {otp_ok?,
       "latest row otp must be an exact release matching ^\\d+\\.\\d+(\\.\\d+){0,2}$, got " <>
         inspect(otp)},
      {elixir_ok?,
       "latest row elixir must be an exact release matching ^\\d+\\.\\d+\\.\\d+$ " <>
         "(no x, -rc or -otp), got " <> inspect(elixir)},
      {pg_ok?,
       "latest row pg must be a release version matching ^\\d+(\\.\\d+)?$, got " <> inspect(pg)},
      {not otp_ok? or newer_major?(otp, current.otp),
       "latest row OTP major must be newer than the current lane's #{major(current.otp)}"},
      {not elixir_ok? or newer_elixir?(elixir, current.elixir),
       "latest row Elixir must be newer than the current lane's #{current.elixir}"},
      {not pg_ok? or newer_major?(pg, current.pg),
       "latest row pg major must be newer than the current lane's #{major(current.pg)}"}
    ]
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(&("verify-test " <> elem(&1, 1)))
  end

  defp major(nil), do: nil

  defp major(version) do
    case Integer.parse(version) do
      {n, _rest} -> n
      :error -> nil
    end
  end

  # A missing or unparseable current value cannot prove "newer", so it fails.
  defp newer_major?(latest, current) do
    case {major(latest), major(current)} do
      {l, c} when is_integer(l) and is_integer(c) -> l > c
      _ -> false
    end
  end

  defp newer_elixir?(latest, current) do
    with true <- is_binary(current),
         {:ok, _} <- Version.parse(current) do
      Version.compare(latest, current) == :gt
    else
      _ -> false
    end
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

  # D-05: every workflow, not only ci.yml. The guard used to scan ci.yml alone,
  # so another workflow could reintroduce the OS-family key context unnoticed.
  defp workflows_os_family_context_errors(yaml_by_path) do
    Enum.flat_map(yaml_by_path, fn {path, yaml} -> os_family_context_errors(path, yaml) end)
  end

  # Whole file, comments included: the CACHE KEY CONTRACT comment promises the
  # OS-family context expression appears in no workflow.
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

  # --- Deps-only build cache contract: rules (Phase 219, CACHE-01) -------------

  # Triggers that run with the default branch's cache scope and a write-capable
  # token. A cache step there can poison entries every pull request reads (D-17).
  @privileged_triggers ["pull_request_target", "workflow_run", "issue_comment"]

  # The whole CACHE-01 contract over `%{repo_rel_path => workflow_text}` plus the
  # CONTRIBUTING text. Returns one message per broken rule; `[]` means clean.
  defp build_cache_errors(yaml_by_path, contributing) do
    build_cache_security_errors(yaml_by_path) ++
      build_cache_tree_errors(yaml_by_path) ++ build_cache_doc_errors(yaml_by_path, contributing)
  end

  # Assembled so this file's own text never contains the stale sentence it
  # forbids (the `@os_family_context` idiom).
  @stale_build_cache_sentence "There is " <> "currently NO"

  @build_cache_rm_literal ~S(rm -rf "_build/${MIX_ENV:?}/lib/threadline")

  @build_cache_cached_table_header "| Job | Build cache | Saves on miss |"
  @build_cache_excluded_table_header "| Job or workflow | Why it has no build cache |"

  # What the CONTRIBUTING `### Dependency build cache` section must say (D-19):
  # the removal, the no-restore-keys rule, the key version, the poisoned-cache
  # runbook, the benign save-race warning and the per-cache log markers.
  @build_cache_doc_needles [
    @build_cache_rm_literal,
    "restore-keys",
    @build_key_version,
    "gh cache list",
    "gh cache delete",
    "actions: write",
    "Unable to reserve cache",
    "THREADLINE_BUILD_CACHE",
    "THREADLINE_EXAMPLE_BUILD_CACHE"
  ]

  # D-19, D-20: the ci.yml CACHE KEY CONTRACT comment and the CONTRIBUTING
  # section describe the live cache, pinned by the same function as the YAML.
  defp build_cache_doc_errors(yaml_by_path, contributing) do
    ci_cache_comment_errors(Map.get(yaml_by_path, @ci_workflow, "")) ++
      contributing_build_cache_errors(contributing)
  end

  defp ci_cache_comment_errors(ci) do
    comments =
      ci |> String.split("\n") |> Enum.filter(&String.match?(&1, ~r/^\s*#/)) |> Enum.join("\n")

    [
      # Pitfall 1: the OS-family control needles on this exact line.
      {Regex.match?(~r/^      # CACHE KEY CONTRACT/m, comments),
       "has no six-space `# CACHE KEY CONTRACT` heading line"},
      {String.contains?(comments, @build_key_version),
       "does not name the `#{@build_key_version}` key version"},
      {String.contains?(comments, @build_cache_rm_literal),
       "does not name `#{@build_cache_rm_literal}`"},
      {not String.contains?(comments, @stale_build_cache_sentence),
       "still says \"#{@stale_build_cache_sentence} `_build` cache\""}
    ]
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(fn {_ok, what} ->
      build_cache_error(
        {@ci_workflow, "-", "CACHE KEY CONTRACT"},
        "rule=doc-ci-comment",
        "the CACHE KEY CONTRACT comment #{what}",
        "the comment is the in-file record of the live cache design (D-19)",
        "describe the live `_build` cache in the present tense"
      )
    end)
  end

  defp contributing_build_cache_errors(contributing) do
    contributing
    |> build_cache_section()
    |> build_cache_section_failures()
    |> Enum.map(fn what ->
      build_cache_error(
        {"CONTRIBUTING.md", "-", "Dependency build cache"},
        "rule=doc-contributing",
        what,
        "maintainers debug and recover the cache from this section (D-19)",
        "update `### Dependency build cache` in CONTRIBUTING.md"
      )
    end)
  end

  defp build_cache_section_failures(nil), do: ["has no `### Dependency build cache` section"]

  defp build_cache_section_failures(section) do
    cached = for {{_path, job}, _entry} <- @build_cache_jobs, into: MapSet.new(), do: job
    excluded = for {{_path, job}, _reason} <- @build_cache_exclusions, into: MapSet.new(), do: job
    cached_doc = doc_table_ids(section, @build_cache_cached_table_header)
    excluded_doc = doc_table_ids(section, @build_cache_excluded_table_header)

    [
      {MapSet.equal?(cached_doc, cached),
       "the cached-job table lists #{inspect(Enum.sort(cached_doc))}, " <>
         "but @build_cache_jobs names #{inspect(Enum.sort(cached))}"},
      {MapSet.equal?(excluded_doc, excluded),
       "the not-cached table lists #{inspect(Enum.sort(excluded_doc))}, " <>
         "but @build_cache_exclusions names #{inspect(Enum.sort(excluded))}"}
      | for(
          needle <- @build_cache_doc_needles,
          do: {String.contains?(section, needle), "the section does not mention `#{needle}`"}
        )
    ]
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end

  # The section body between the exact heading and the next `## ` / `### `.
  defp build_cache_section(contributing) do
    case contributing
         |> String.split("\n")
         |> Enum.drop_while(&(&1 != "### Dependency build cache")) do
      [] ->
        nil

      [_heading | rest] ->
        rest |> Enum.take_while(&(not Regex.match?(~r/^###? /, &1))) |> Enum.join("\n")
    end
  end

  # Backticked ids in the first column of the table under `header`, up to the
  # first blank line, separator row skipped. A missing table yields no ids.
  defp doc_table_ids(section, header) do
    case section |> String.split("\n") |> Enum.drop_while(&(String.trim(&1) != header)) do
      [] ->
        MapSet.new()

      [_header | rows] ->
        rows
        |> Enum.take_while(&(String.trim(&1) != ""))
        |> Enum.reject(&Regex.match?(~r/^\s*\|[\s:|-]+\|\s*$/, &1))
        |> Enum.flat_map(&first_cell_ids/1)
        |> MapSet.new()
    end
  end

  defp first_cell_ids(row) do
    case String.split(row, "|") do
      [_, cell | _] ->
        ~r/`([^`]+)`/ |> Regex.scan(cell, capture: :all_but_first) |> List.flatten()

      _ ->
        []
    end
  end

  # D-07: the contiguous step sequence of each cached project, by step class.
  # A restore-only job drops `:save_build`.
  @build_cache_sequences %{
    root: [
      :restore_build,
      :deps_restore,
      :deps_get,
      :deps_compile,
      :rm_own,
      :save_build,
      :compile
    ],
    example: [:restore_build, :deps_get, :deps_compile, :rm_own, :save_build, :consumer]
  }

  # D-08: what the unconditional removal step must name, per project.
  @build_rm_targets %{
    root: [~S("_build/${MIX_ENV:?}/lib/threadline")],
    example: [
      ~S("examples/threadline_phoenix/_build/${MIX_ENV:?}/lib/threadline"),
      ~S("examples/threadline_phoenix/_build/${MIX_ENV:?}/lib/threadline_phoenix")
    ]
  }

  # D-09: the only `_build` cache path elements, env-scoped.
  @build_cache_paths [
    "_build/${{ env.MIX_ENV }}",
    "examples/threadline_phoenix/_build/${{ env.MIX_ENV }}"
  ]

  # Fail closed: without a parseable ci.yml every allowlist rule would pass
  # vacuously (T-219-05).
  defp build_cache_tree_errors(yaml_by_path) do
    ci = Map.get(yaml_by_path, @ci_workflow, "")

    if workflow_jobs(ci) == [] do
      [
        build_cache_error(
          {@ci_workflow, "-", "-"},
          "rule=allowlist",
          "ci.yml is missing or has no parseable jobs",
          "every allowlist rule would pass vacuously",
          "pass the real ci.yml text"
        )
      ]
    else
      Enum.flat_map(yaml_by_path, fn {path, yaml} ->
        Enum.flat_map(workflow_jobs(yaml), &build_cache_scope_errors(path, &1))
      end) ++
        allowlist_unused_errors(yaml_by_path) ++
        exclusion_unknown_errors(yaml_by_path) ++ no_optional_cache_errors(ci)
    end
  end

  defp build_cache_scope_errors(path, {job_id, block}) do
    steps = tagged_steps(block)

    scoped =
      case Map.fetch(@build_cache_jobs, {path, job_id}) do
        {:ok, {_reason, _mode, projects}} ->
          allowlist_project_errors(path, job_id, steps, projects) ++
            build_cache_job_errors(path, job_id, block)

        :error ->
          allowlist_errors(path, job_id, steps)
      end

    combined_action_errors(path, job_id, steps) ++ scoped
  end

  defp allowlist_errors(path, job_id, steps) do
    for {class, _project, step} <- steps,
        class in [:restore_build, :save_build, :combined_build] do
      build_cache_error(
        {path, job_id, step_label(step)},
        "rule=allowlist",
        "a `_build` cache step in a job outside @build_cache_jobs",
        "the allowlist is fail-closed; every cached job is reviewed and named (D-11, D-20)",
        "remove the step, or add the job to @build_cache_jobs and CONTRIBUTING with a reason"
      )
    end
  end

  defp allowlist_project_errors(path, job_id, steps, projects) do
    for project <- restored_projects(steps) -- projects do
      build_cache_error(
        {path, job_id, "-"},
        "rule=allowlist-project",
        "restores a #{project} `_build` cache, which is not in its allowlist entry",
        "each job caches exactly the projects D-11 lists for it",
        "remove the #{project} restore, or change the job's @build_cache_jobs entry"
      )
    end
  end

  defp allowlist_unused_errors(yaml_by_path) do
    for {{path, job_id}, {_reason, _mode, projects}} <- @build_cache_jobs,
        Map.has_key?(yaml_by_path, path),
        restored <- [
          yaml_by_path[path] |> workflow_job(job_id) |> tagged_steps() |> restored_projects()
        ],
        project <- projects -- restored do
      build_cache_error(
        {path, job_id, "-"},
        "rule=allowlist-unused",
        "has no #{project} `_build` restore, but its allowlist entry requires one",
        "every allowlist entry must be used, so a dropped cache block cannot go unnoticed (D-11)",
        "restore the #{project} cache block, or remove #{project} from the entry"
      )
    end
  end

  defp exclusion_unknown_errors(yaml_by_path) do
    for {{path, job_id}, _reason} <- @build_cache_exclusions,
        Map.has_key?(yaml_by_path, path),
        workflow_job(yaml_by_path[path], job_id) == "" do
      build_cache_error(
        {path, job_id, "-"},
        "rule=exclusion-unknown",
        "@build_cache_exclusions names a job that does not exist",
        "a stale exclusion hides which jobs are deliberately cache-free (D-12)",
        "rename or remove the exclusion entry"
      )
    end
  end

  defp no_optional_cache_errors(ci) do
    block = workflow_job(ci, "verify-compile-no-optional")

    for chunk <- Regex.split(~r/^(?=      - )/m, block),
        line <- lines_matching(chunk, &cache_line?/1) do
      build_cache_error(
        {@ci_workflow, "verify-compile-no-optional", step_label(chunk)},
        "rule=no-optional-cache",
        "carries `#{line}`",
        "the optional-deps proof must build from source with no cache step of any kind (D-13)",
        "remove the cache step"
      )
    end
  end

  defp combined_action_errors(path, job_id, steps) do
    for {:combined_build, _project, step} <- steps do
      build_cache_error(
        {path, job_id, step_label(step)},
        "rule=combined-action",
        "caches `_build` with the combined actions/cache action",
        "the combined action saves at job end, after the own build exists (CACHE-01, D-14)",
        "use actions/cache/restore@v5 and actions/cache/save@v5"
      )
    end
  end

  # Every per-job rule for one allowlisted job (D-07..D-15, D-17, D-22).
  defp build_cache_job_errors(path, job_id, block) do
    {_reason, mode, _projects} = Map.fetch!(@build_cache_jobs, {path, job_id})
    job = %{path: path, id: job_id, mode: mode, steps: tagged_steps(block)}

    Enum.flat_map(restored_projects(job.steps), &project_cache_errors(job, &1)) ++
      restore_only_errors(job) ++ inline_errors(job) ++ job_env_errors(job, block)
  end

  # The D-07 window starts at the first restore. Every restore (not just the
  # first) meets the restore rules, and the count rule pins each job to one
  # restore and at most one save per project, so no second restore or save can
  # sit outside the window (WR-01, 219 review).
  defp project_cache_errors(job, project) do
    start = Enum.find_index(job.steps, &match?({:restore_build, ^project, _}, &1))
    {_class, _project, restore} = Enum.at(job.steps, start)
    expected = expected_sequence(project, job.mode)
    window = Enum.slice(job.steps, start, length(expected))

    cache_count_errors(job, project) ++
      order_errors(job, project, restore, window, expected) ++
      Enum.flat_map(
        for({:restore_build, ^project, step} <- job.steps, do: step),
        &restore_errors(job, project, &1)
      ) ++
      save_errors(job, project, restore) ++
      compile_guard_errors(job, project, restore) ++
      continue_on_error_errors(job, window) ++
      rm_errors(job, project) ++ cache_path_env_errors(job, project)
  end

  # Exactly one restore per project, and exactly one save in a saving job. A
  # restore-only job's saves are reported by restore_only_errors/1 instead.
  # Every step past the first is named, so the message points at the extra one.
  defp cache_count_errors(job, project) do
    [
      {:restore_build, "restore", 1},
      {:save_build, "save", if(job.mode == :save, do: 1, else: nil)}
    ]
    |> Enum.flat_map(fn {class, noun, allowed} ->
      steps = for {^class, ^project, step} <- job.steps, do: step
      cache_count_step_errors(job, project, noun, allowed, steps)
    end)
  end

  defp cache_count_step_errors(_job, _project, _noun, nil, _steps), do: []

  defp cache_count_step_errors(job, project, noun, allowed, steps) do
    for step <- Enum.drop(steps, allowed) do
      build_cache_error(
        where(job, step),
        "rule=cache-count",
        "the job has #{length(steps)} #{project} `_build` #{noun} steps; exactly #{allowed} " <>
          "is allowed, inside the D-07 block",
        "a restore outside the block escapes the order rule and can serve a stale build; a " <>
          "save after the compile archives first-party BEAMs whenever the first save fails " <>
          "to reserve the key (CACHE-01, D-07)",
        "remove the extra #{noun} step"
      )
    end
  end

  defp expected_sequence(project, :save), do: @build_cache_sequences[project]

  defp expected_sequence(project, :restore_only),
    do: List.delete(@build_cache_sequences[project], :save_build)

  defp order_errors(job, project, restore, window, expected) do
    observed = Enum.map(window, fn {class, proj, _step} -> {class, proj} end)
    wanted = Enum.map(expected, &{&1, project})

    if observed == wanted do
      []
    else
      [
        build_cache_error(
          where(job, restore),
          "rule=order",
          "the #{project} cache block is out of order: observed #{inspect(observed)}, " <>
            "expected #{inspect(wanted)}",
          "the own build is removed after the dependency compile and before both the save " <>
            "and the compile, so first-party code is never cached or served stale (D-07)",
          "make the steps run #{Enum.join(expected, " -> ")} with nothing in between"
        )
      ]
    end
  end

  defp restore_errors(job, project, restore) do
    stripped = strip_comment_lines(restore)
    key = yaml_value(stripped, "key") || ""
    where = where(job, restore)

    split_action_errors(where, stripped, "uses: actions/cache/restore@v5") ++
      restore_keys_errors(where, stripped) ++
      key_segment_errors(where, project, key) ++ key_forbidden_errors(where, project, key)
  end

  defp split_action_errors(where, stripped, expected) do
    if String.contains?(stripped, expected) do
      []
    else
      [
        build_cache_error(
          where,
          "rule=combined-action",
          "a `_build` cache step must carry `#{expected}`",
          "the split restore/save pair is what lets the save run before the own build exists " <>
            "(CACHE-01, D-14)",
          "use `#{expected}`"
        )
      ]
    end
  end

  defp restore_keys_errors(where, stripped) do
    if yaml_value(stripped, "restore-keys") do
      [
        build_cache_error(
          where,
          "rule=restore-keys",
          "a `_build` restore carries `restore-keys:`",
          "a near-miss restore across a changed lock serves wrong compiled artifacts " <>
            "(CACHE-01, CargoSense/setup-elixir-project#13)",
          "delete `restore-keys:`; a cold build is cheaper than a wrong one"
        )
      ]
    else
      []
    end
  end

  defp key_segment_errors(where, project, key) do
    missing =
      for segment <- @build_key_segments[project], not String.contains?(key, segment) do
        build_cache_error(
          where,
          "rule=key-segment",
          "the #{project} `_build` key lacks `#{segment}`",
          "every input that changes compiled dependencies must be in the exact key (D-01..D-05)",
          "add `#{segment}` to the key, as @build_key_segments lists it"
        )
      end

    runner =
      for message <- key_value_errors("the #{project} `_build` restore", "key", key) do
        build_cache_error(
          where,
          "rule=key-segment",
          message,
          "the Phase 216 cache-key contract applies to every cache",
          "lead with the literal runner label and the resolved setup-beam outputs"
        )
      end

    missing ++ runner
  end

  defp key_forbidden_errors(where, project, key) do
    for input <- @build_key_forbidden[project], String.contains?(key, input) do
      build_cache_error(
        where,
        "rule=key-forbidden",
        "the #{project} `_build` key carries `#{input}`",
        "that input is reserved, redundant, or belongs to another project's lock (D-02..D-06)",
        "remove `#{input}` from the key"
      )
    end
  end

  defp save_errors(job, project, restore) do
    id = yaml_value(strip_comment_lines(restore), "id") || "<restore without id>"

    for {:save_build, ^project, save} <- job.steps,
        {rule, what, why, fix} <- save_rule_failures(job, project, id, restore, save) do
      build_cache_error(where(job, save), rule, what, why, fix)
    end
  end

  defp save_rule_failures(job, project, id, restore, save) do
    stripped = strip_comment_lines(save)
    primary = "${{ steps.#{id}.outputs.cache-primary-key }}"
    guards = cache_miss_guards(job.id, project, id)

    [
      {String.contains?(stripped, "uses: actions/cache/save@v5"),
       {"rule=combined-action", "a `_build` save must carry `uses: actions/cache/save@v5`",
        "only the split save runs before the own build exists (D-14)",
        "use actions/cache/save@v5"}},
      {yaml_value(stripped, "key") == primary,
       {"rule=save-key", "the save key must be exactly `#{primary}`",
        "a retyped or foreign key saves under a name the restore never computed (D-14)",
        "key the save on its own project's restore output"}},
      {cache_path(save) == cache_path(restore),
       {"rule=save-path", "the save path differs from the `#{id}` restore path",
        "a save that caches other paths than the restore reads poisons the key (D-14)",
        "copy the restore's `path:` byte for byte"}},
      {yaml_value(stripped, "if") in guards,
       {"rule=save-guard", "the save `if:` must be one of #{inspect(guards)}",
        "only an exact miss after a successful dependency compile may save; always(), " <>
          "failure() or || would save a failed or partial build (D-14, D-15)",
        "set `if: #{List.first(guards)}`"}}
    ]
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end

  # verify-test's example block runs on the current lane only: its restore is
  # lane-skipped on the min lane, so a bare guard would be true there and
  # compile or save an unfetched tree (IN-03, 219 review). Its root block runs
  # on every lane.
  defp cache_miss_guards("verify-test", :example, id),
    do: ["matrix.lane == 'current' && steps.#{id}.outputs.cache-hit != 'true'"]

  defp cache_miss_guards("verify-test", :root, id) do
    base = "steps.#{id}.outputs.cache-hit != 'true'"
    [base, "matrix.lane == 'current' && " <> base]
  end

  defp cache_miss_guards(_job_id, _project, id),
    do: ["steps.#{id}.outputs.cache-hit != 'true'"]

  defp compile_guard_errors(job, project, restore) do
    id = yaml_value(strip_comment_lines(restore), "id") || "<restore without id>"
    guards = cache_miss_guards(job.id, project, id)

    for {:deps_compile, ^project, step} <- job.steps,
        yaml_value(strip_comment_lines(step), "if") not in guards do
      build_cache_error(
        where(job, step),
        "rule=compile-guard",
        "the dependency compile `if:` must be one of #{inspect(guards)}",
        "dependencies compile only on an exact miss, and the save shares that guard (D-07)",
        "set `if: #{List.first(guards)}`"
      )
    end
  end

  defp continue_on_error_errors(job, window) do
    for {_class, _project, step} <- window,
        Regex.match?(~r/^\s*continue-on-error:/m, strip_comment_lines(step)) do
      build_cache_error(
        where(job, step),
        "rule=continue-on-error",
        "a step inside a cache block carries `continue-on-error:`",
        "a failed dependency compile must never reach the save (D-15)",
        "remove `continue-on-error:`"
      )
    end
  end

  defp rm_errors(job, project) do
    for {:rm_own, ^project, step} <- job.steps,
        {rule, what, why, fix} <- rm_rule_failures(project, strip_comment_lines(step)) do
      build_cache_error(where(job, step), rule, what, why, fix)
    end
  end

  defp rm_rule_failures(project, stripped) do
    guarded =
      ~r{_build/([^/"\s]*)}
      |> Regex.scan(stripped, capture: :all_but_first)
      |> List.flatten()
      |> Enum.all?(&(&1 == "${MIX_ENV:?}"))

    targets =
      for target <- @build_rm_targets[project] do
        {String.contains?(stripped, target),
         {"rule=rm-target", "the #{project} removal does not name #{target}",
          "each first-party app's build must be removed before the save and the compile (D-08)",
          "add #{target} to the `rm -rf`"}}
      end

    [
      {yaml_value(stripped, "if") == nil,
       {"rule=rm-unconditional", "the own-build removal carries an `if:`",
        "it must run on a hit and on a miss, or a restored stale copy is served (D-07)",
        "delete the `if:`"}},
      {guarded,
       {"rule=rm-env-guard", "every `_build/` in the removal must be `_build/${MIX_ENV:?}/`",
        "an unset MIX_ENV must fail loudly instead of removing nothing (D-08)",
        "write the path as `_build/${MIX_ENV:?}/lib/...`"}}
      | targets
    ]
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end

  defp cache_path_env_errors(job, project) do
    for {class, ^project, step} <- job.steps,
        class in [:restore_build, :save_build],
        element <- String.split(cache_path(step) || "", "\n"),
        String.contains?(element, "_build"),
        element not in @build_cache_paths do
      build_cache_error(
        where(job, step),
        "rule=cache-path-env",
        "`_build` path element `#{element}` is not one of #{inspect(@build_cache_paths)}",
        "the cache is env-scoped, so a test build never lands in another env's entry (D-09)",
        "use `_build/${{ env.MIX_ENV }}`"
      )
    end
  end

  defp restore_only_errors(%{mode: :restore_only} = job) do
    for {:save_build, _project, step} <- job.steps do
      build_cache_error(
        where(job, step),
        "rule=restore-only",
        "a restore-only job saves a `_build` cache",
        "restore-only jobs reuse another job's key; a second writer only adds a save race (D-11)",
        "remove the save step"
      )
    end
  end

  defp restore_only_errors(_job), do: []

  defp inline_errors(job) do
    for {:local_action, _project, step} <- job.steps do
      build_cache_error(
        where(job, step),
        "rule=inline",
        "a local `uses: ./` action inside a cached job",
        "the contract reads literal job text; a composite action would hide the cache steps (D-22)",
        "inline the steps in the job"
      )
    end
  end

  defp job_env_errors(job, block) do
    header = ~r/^(?=      - )/m |> Regex.split(block) |> hd() |> strip_comment_lines()

    mix_env =
      if Regex.match?(~r/^    env:\s*$/m, header) and
           Regex.match?(~r/^      MIX_ENV: [a-z]+\s*$/m, header),
         do: [],
         else: [
           build_cache_error(
             {job.path, job.id, "-"},
             "rule=job-mix-env",
             "the job has no literal job-level `MIX_ENV:`",
             "an unset MIX_ENV makes `_build/$MIX_ENV` collapse and preferred_envs pick the env (D-09)",
             "add `MIX_ENV: test` under the job's `env:`"
           )
         ]

    # WR-02 (219 review): the job-level MIX_ENV is the only one. A step-level
    # override builds or reads another env's tree than the key and path name.
    step_mix_env =
      for step <- job_steps(block), line <- lines_matching(step, &mix_env_line?/1) do
        build_cache_error(
          where(job, step),
          "rule=job-mix-env",
          "a step overrides MIX_ENV inside a cached job (`#{line}`)",
          "the key and the env-scoped `_build/${{ env.MIX_ENV }}` path name the job-level env; " <>
            "a step in another env compiles or reads a tree the key does not describe (D-09)",
          "delete the step-level `MIX_ENV:`; set it once under the job's `env:`"
        )
      end

    compiler =
      for line <- lines_matching(block, &compiler_env_line?/1) do
        build_cache_error(
          {job.path, job.id, "-"},
          "rule=compiler-env",
          "the job sets `#{line}`",
          "compiler flags change dependency BEAMs without changing the key (D-17)",
          "remove the variable from the cached job"
        )
      end

    mix_env ++ step_mix_env ++ compiler
  end

  defp mix_env_line?(line), do: Regex.match?(~r/^\s*MIX_ENV:/, line)

  defp compiler_env_line?(line),
    do: Regex.match?(~r/^\s*(?:ERL_COMPILER_OPTIONS|ELIXIR_ERL_OPTIONS|CC|CFLAGS):/, line)

  defp where(job, step), do: {job.path, job.id, step_label(step)}

  defp tagged_steps(block) do
    for step <- job_steps(block) do
      class = build_cache_step_class(step)
      {class, build_cache_project(step, class), step}
    end
  end

  defp restored_projects(steps),
    do: for({:restore_build, project, _step} <- steps, uniq: true, do: project)

  # Classifies one step's uncommented text. A cache step counts as `_build` when
  # any uncommented line mentions `_build`, including inside a `path: |` block.
  defp build_cache_step_class(step) do
    stripped = strip_comment_lines(step)
    uses = step_uses(stripped)

    cond do
      String.starts_with?(uses, "./") -> :local_action
      String.starts_with?(uses, "actions/cache") -> cache_step_class(uses, stripped)
      Regex.match?(~r/\brm -rf\b[^\n]*_build\//, stripped) -> :rm_own
      true -> run_step_class(stripped)
    end
  end

  defp cache_step_class(uses, stripped) do
    action = uses |> String.split("@") |> hd()

    case {action, String.contains?(stripped, "_build")} do
      {"actions/cache/restore", true} ->
        :restore_build

      {"actions/cache/save", true} ->
        :save_build

      {"actions/cache", true} ->
        :combined_build

      {"actions/cache", false} ->
        if cache_path(stripped) == "deps", do: :deps_restore, else: :other

      _ ->
        :other
    end
  end

  defp run_step_class(stripped) do
    cond do
      Regex.match?(~r/^\s*run:\s*mix deps\.get\s*$/m, stripped) ->
        :deps_get

      Regex.match?(~r/^\s*run:\s*mix deps\.compile\b/m, stripped) ->
        :deps_compile

      Regex.match?(~r/^\s*run:\s*mix compile --warnings-as-errors\s*$/m, stripped) ->
        :compile

      Regex.match?(~r/^\s*run:\s*mix verify\.(?:example|example_browser|capture)\b/m, stripped) ->
        :consumer

      true ->
        :other
    end
  end

  # Consumers (`mix verify.example`, `verify.example_browser`, `verify.capture`)
  # build the example app, whatever directory they run from.
  defp build_cache_project(_step, :consumer), do: :example

  defp build_cache_project(step, _class) do
    if String.contains?(strip_comment_lines(step), "examples/threadline_phoenix"),
      do: :example,
      else: :root
  end

  defp step_uses(stripped) do
    case Regex.run(~r/^\s*(?:-\s+)?uses:\s*(\S+)/m, stripped) do
      [_, uses] -> uses
      nil -> ""
    end
  end

  # A step's `path:` value: the scalar, or the trimmed lines of a `path: |`
  # block joined by newlines (so restore and save paths compare line by line).
  defp cache_path(step) do
    step
    |> strip_comment_lines()
    |> String.split("\n")
    |> Enum.drop_while(&(not Regex.match?(~r/^\s*path:/, &1)))
    |> path_value()
  end

  defp path_value([]), do: nil

  defp path_value([line | rest]) do
    case yaml_value(line, "path") do
      "|" ->
        indent = indent_of(line)

        rest
        |> Enum.take_while(&(String.trim(&1) != "" and indent_of(&1) > indent))
        |> Enum.map_join("\n", &String.trim/1)

      value ->
        value
    end
  end

  defp indent_of(line), do: byte_size(line) - byte_size(String.trim_leading(line))

  # D-17: the release path and default-branch-context workflows carry no cache,
  # and the only built-in `cache:` input anywhere is `cache: npm` on setup-node.
  # Key-anchored regexes over uncommented lines (Pitfall 4): release.yml says
  # "runner tool cache", `git diff --cached` and `data.workflow_runs` in text
  # that is not a cache step or a trigger.
  defp build_cache_security_errors(yaml_by_path) do
    Enum.flat_map(yaml_by_path, fn {path, yaml} ->
      release_cache_errors(path, yaml) ++
        privileged_trigger_cache_errors(path, yaml) ++ builtin_cache_errors(path, yaml)
    end)
  end

  defp release_cache_errors(@release_workflow = path, yaml) do
    for {job, chunk} <- workflow_chunks(yaml), line <- lines_matching(chunk, &cache_line?/1) do
      build_cache_error(
        {path, job, step_label(chunk)},
        "rule=release-cache",
        "release.yml carries `#{line}`",
        "a published package must be built from source, never from a cache (D-17)",
        "remove the cache step or cache input from release.yml"
      )
    end
  end

  defp release_cache_errors(_path, _yaml), do: []

  defp privileged_trigger_cache_errors(path, yaml) do
    case Enum.filter(workflow_triggers(yaml), &(&1 in @privileged_triggers)) do
      [] ->
        []

      triggers ->
        for {job, chunk} <- workflow_chunks(yaml),
            line <- lines_matching(chunk, &cache_line?/1) do
          build_cache_error(
            {path, job, step_label(chunk)},
            "rule=privileged-trigger-cache",
            "a workflow triggered by #{Enum.join(triggers, ", ")} carries `#{line}`",
            "those triggers run in the default branch's cache scope, so a cache step " <>
              "there can poison entries every pull request restores (D-17)",
            "remove the cache step, or move the work to a pull_request/push workflow"
          )
        end
    end
  end

  defp builtin_cache_errors(path, yaml) do
    for {job, chunk} <- workflow_chunks(yaml),
        line <- lines_matching(chunk, &builtin_cache_line?/1),
        not (line == "cache: npm" and setup_node_step?(chunk)) do
      build_cache_error(
        {path, job, step_label(chunk)},
        "rule=builtin-cache",
        "built-in cache input `#{line}`",
        "an action's built-in cache hides its key and restore-keys from this contract (D-20)",
        "use an explicit actions/cache/restore + save pair; only `cache: npm` on " <>
          "actions/setup-node is allowed"
      )
    end
  end

  defp cache_line?(line), do: cache_step_line?(line) or cache_input_line?(line)

  defp cache_step_line?(line), do: Regex.match?(~r/^\s*(?:-\s+)?uses:\s*actions\/cache/, line)

  defp cache_input_line?(line),
    do: Regex.match?(~r/^\s*(?:-\s+)?(?:cache|cache-dependency-path|restore-keys):/, line)

  defp builtin_cache_line?(line), do: Regex.match?(~r/^\s*(?:-\s+)?cache:/, line)

  defp setup_node_step?(chunk),
    do: Regex.match?(~r/^\s*(?:-\s+)?uses:\s*actions\/setup-node@/m, strip_comment_lines(chunk))

  # Trigger names from the `on:` block: an inline `on: [a, b]` / `on: a` value,
  # or the two-space keys (or list items) under a block `on:`.
  defp workflow_triggers(yaml) do
    lines = yaml |> strip_comment_lines() |> String.split("\n")

    case Enum.drop_while(lines, &(not Regex.match?(~r/^["']?on["']?:/, &1))) do
      [] ->
        []

      [on_line | rest] ->
        inline =
          ~r/[a-z_]+/ |> Regex.scan(Regex.replace(~r/^[^:]+:/, on_line, "")) |> List.flatten()

        block = Enum.take_while(rest, &(&1 == "" or String.starts_with?(&1, " ")))
        inline ++ Enum.flat_map(block, &trigger_key/1)
    end
  end

  defp trigger_key(line) do
    case Regex.run(~r/^  (?:-\s+)?([a-z_]+)/, line) do
      [_, trigger] -> [trigger]
      nil -> []
    end
  end

  # `{job_id, chunk}` for the text before `jobs:` (job "-"), each job header and
  # each step, so a rule can name where a line sits.
  defp workflow_chunks(yaml) do
    head = yaml |> String.split(~r/^jobs:\n/m, parts: 2) |> hd()

    [{"-", head}] ++
      for {job_id, block} <- workflow_jobs(yaml),
          chunk <- Regex.split(~r/^(?=      - )/m, block),
          do: {job_id, chunk}
  end

  defp lines_matching(text, match?) do
    text
    |> strip_comment_lines()
    |> String.split("\n")
    |> Enum.filter(match?)
    |> Enum.map(&String.trim/1)
  end

  # A step's `name:`, else its `uses:` target, else "-" (job headers, file head).
  defp step_label(chunk) do
    stripped = strip_comment_lines(chunk)

    cond do
      match = Regex.run(~r/^      (?:- |  )name:[ \t]*(.+?)[ \t]*$/m, stripped) ->
        List.last(match)

      match = Regex.run(~r/^      (?:- |  )uses:[ \t]*(\S+)/m, stripped) ->
        "uses " <> List.last(match)

      true ->
        "-"
    end
  end

  # D-20 message shape: where, a stable `rule=<id>` token, what, why and the fix.
  defp build_cache_error({path, job, step}, rule, what, why, fix) do
    step = if step == "-", do: "-", else: inspect(step)
    "#{path} #{job} #{step} #{rule}: #{what}. Why: #{why}. Fix: #{fix}"
  end

  # --- Deps-only build cache contract: text mutators for the controls ----------

  # Inserts `step` directly after the first `    steps:` line of job `job_id`.
  # Needles only on the job header line and that `steps:` line, which every
  # workflow carries, so a control never depends on another step's text. Raises
  # when either line is missing, so a vanished needle fails loudly instead of
  # returning the input unchanged.
  defp insert_step_in_job(text, job_id, step) do
    lines = String.split(text, "\n")
    at = job_line_index!(lines, job_id, "    steps:", &job_header_line?/1)
    step_lines = step |> String.trim_trailing("\n") |> String.split("\n")
    {before, rest} = Enum.split(lines, at + 1)
    Enum.join(before ++ step_lines ++ rest, "\n")
  end

  # Index of the first line equal to `target` after the `  <job_id>:` header,
  # searching only until `stop?` accepts a line.
  defp job_line_index!(lines, job_id, target, stop?) do
    header =
      Enum.find_index(lines, &(&1 == "  #{job_id}:")) ||
        raise ArgumentError, "no `  #{job_id}:` job header line"

    offset =
      lines
      |> Enum.drop(header + 1)
      |> Enum.take_while(&(not stop?.(&1)))
      |> Enum.find_index(&(&1 == target))

    if offset,
      do: header + 1 + offset,
      else: raise(ArgumentError, "job #{job_id} has no #{inspect(target)} line")
  end

  defp job_header_line?(line), do: Regex.match?(~r/^  [a-z][a-z0-9_-]*:\s*$/, line)

  defp job_header_or_steps_line?(line), do: line == "    steps:" or job_header_line?(line)

  # Inserts `line` directly after the job-level `    env:` line of `job_id`
  # (searched between the job header and its `    steps:` line). Raises when a
  # needle is missing, like insert_step_in_job/3.
  defp insert_env_line_in_job(text, job_id, line) do
    lines = String.split(text, "\n")
    at = job_line_index!(lines, job_id, "    env:", &job_header_or_steps_line?/1)
    {before, rest} = Enum.split(lines, at + 1)
    Enum.join(before ++ [line | rest], "\n")
  end

  # Removes the single `      <key>: ` line from the job-level `    env:` block
  # of `job_id`. Raises when a needle is missing.
  defp remove_env_line_in_job(text, job_id, key) do
    lines = String.split(text, "\n")
    env_at = job_line_index!(lines, job_id, "    env:", &job_header_or_steps_line?/1)

    offset =
      lines
      |> Enum.drop(env_at + 1)
      |> Enum.take_while(&String.starts_with?(&1, "      "))
      |> Enum.find_index(&String.starts_with?(&1, "      #{key}: "))

    unless offset, do: raise(ArgumentError, "job #{job_id} env has no #{key} line")

    lines |> List.delete_at(env_at + 1 + offset) |> Enum.join("\n")
  end

  # Step-name needles (`<interfaces>` names, which plan 02 reproduces in live
  # ci.yml). Each helper raises when its job or step is missing.
  defp update_job!(text, job_id, fun) do
    case workflow_job(text, job_id) do
      "" -> raise ArgumentError, "no job #{job_id}"
      block -> String.replace(text, block, fun.(block), global: false)
    end
  end

  defp map_job_steps(text, job_id, fun) do
    update_job!(text, job_id, fn block ->
      ~r/^(?=      - )/m |> Regex.split(block) |> fun.() |> Enum.join()
    end)
  end

  defp step_index!(chunks, name) do
    Enum.find_index(chunks, &(step_label(&1) == name)) ||
      raise ArgumentError, "no step #{inspect(name)}"
  end

  defp edit_step(text, job_id, name, fun),
    do: map_job_steps(text, job_id, &List.update_at(&1, step_index!(&1, name), fun))

  defp replace_in_step(text, job_id, name, from, to),
    do: edit_step(text, job_id, name, &String.replace(&1, from, to))

  defp insert_step_after(text, job_id, after_name, step),
    do: map_job_steps(text, job_id, &List.insert_at(&1, step_index!(&1, after_name) + 1, step))

  defp remove_steps(text, job_id, names) do
    map_job_steps(text, job_id, fn chunks ->
      Enum.each(names, &step_index!(chunks, &1))
      Enum.reject(chunks, &(step_label(&1) in names))
    end)
  end

  defp move_step_after(text, job_id, name, after_name) do
    map_job_steps(text, job_id, fn chunks ->
      at = step_index!(chunks, name)
      rest = List.delete_at(chunks, at)
      List.insert_at(rest, step_index!(rest, after_name) + 1, Enum.at(chunks, at))
    end)
  end

  defp add_line_after(step, prefix, line) do
    lines = String.split(step, "\n")

    at =
      Enum.find_index(lines, &String.starts_with?(&1, prefix)) ||
        raise ArgumentError, "no line starting #{inspect(prefix)}"

    lines |> List.insert_at(at + 1, line) |> Enum.join("\n")
  end

  # Rewrites only the `key:` line of a verify-test restore step, so the other
  # project's key and the step's `path:` stay untouched.
  defp edit_restore_key(text, restore_name, fun) do
    edit_step(text, "verify-test", restore_name, fn step ->
      step |> String.split("\n") |> Enum.map_join("\n", &edit_key_line(&1, fun))
    end)
  end

  defp edit_key_line(line, fun) do
    case Regex.run(~r/^(\s*key: )(.*)$/, line) do
      [_, prefix, key] -> prefix <> fun.(key)
      nil -> line
    end
  end

  defp forbidden_injection("hashFiles(" <> _ = input), do: "-${{ #{input} }}"
  defp forbidden_injection("no-optional"), do: "-no-optional"
  defp forbidden_injection(input), do: "-${{ hashFiles('#{input}') }}"

  # --- Deps-only build cache contract: mutation controls (D-21) ---------------

  @root_restore "Restore deps-only build cache"
  @root_deps_compile "Compile dependencies on build cache miss"
  @root_rm "Remove own build (never cached, never reused)"
  @root_save "Save deps-only build cache"
  @root_compile "Compile (warnings as errors)"
  @example_restore "Restore example deps and deps-only build cache"
  @example_rm "Remove example app's own build (never cached, never reused)"
  @example_save "Save example deps and deps-only build cache"
  @example_deps_compile "Compile example dependencies on cache miss"
  @example_block_steps [
    @example_restore,
    "Install example dependencies",
    @example_deps_compile,
    @example_rm,
    @example_save
  ]

  @capture_consumer "Regenerate Tier A capture"

  # WR-01 (219 review): the escaped mutations, as literal steps. Each would pass
  # every per-step rule on its own; only the count and every-restore rules
  # catch them once they sit outside the D-07 window.
  @late_root_save_step ~S"""
        - name: Save deps-only build cache again
          if: steps.build-restore.outputs.cache-hit != 'true'
          uses: actions/cache/save@v5
          with:
            path: _build/${{ env.MIX_ENV }}
            key: ${{ steps.build-restore.outputs.cache-primary-key }}

  """

  @late_example_save_step ~S"""
        - name: Save example build cache again
          if: steps.example-build-restore.outputs.cache-hit != 'true'
          uses: actions/cache/save@v5
          with:
            path: |
              examples/threadline_phoenix/deps
              examples/threadline_phoenix/_build/${{ env.MIX_ENV }}
            key: ${{ steps.example-build-restore.outputs.cache-primary-key }}

  """

  @late_root_restore_step ~S"""
        - name: Restore stale build cache
          id: stale-build-restore
          uses: actions/cache/restore@v5
          with:
            path: _build/${{ env.MIX_ENV }}
            key: ubuntu-24.04-otp-x
            restore-keys: ubuntu-24.04-

  """

  @path_block_build_cache_step ~S"""
        - name: Cache deps and build
          uses: actions/cache@v5
          with:
            path: |
              deps
              _build
            key: ubuntu-24.04-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-${{ hashFiles('mix.lock') }}
  """

  @setup_beam_cache_step ~S"""
        - uses: erlef/setup-beam@v1
          with:
            version-file: .tool-versions
            version-type: strict
            cache: true
  """

  @privileged_cache_workflow ~S"""
  name: Privileged cache
  on:
    workflow_run:
      workflows: ["CI"]
      types: [completed]
  jobs:
    poll:
      runs-on: ubuntu-24.04
      steps:
        - uses: actions/cache@v5
          with:
            path: deps
            key: ubuntu-24.04-deps
  """

  # Asserts every control changes its input and fails with its own fragment.
  defp assert_build_cache_controls(workflows, contributing) do
    controls = build_cache_controls(workflows, contributing)
    refute controls == [], "the build cache control table is empty"

    for {label, mutated, mutated_contributing, fragment} <- controls do
      refute {mutated, mutated_contributing} == {workflows, contributing},
             "#{label} control did not change its input"

      errors = build_cache_errors(mutated, mutated_contributing)

      assert Enum.any?(errors, &String.contains?(&1, fragment)),
             "#{label} must fail with #{fragment}, got:\n" <> Enum.join(errors, "\n")
    end
  end

  # `{label, mutated_workflows, mutated_contributing, fragment}` for every D-21
  # fault. ci.yml controls needle on `<interfaces>` step names; the rest go
  # through build_cache_live_needle_controls/2.
  defp build_cache_controls(workflows, contributing) do
    ctx = %{workflows: workflows, contributing: contributing}

    build_cache_order_controls(ctx) ++
      build_cache_count_controls(ctx) ++
      build_cache_step_env_controls(ctx) ++
      build_cache_lane_guard_controls(ctx) ++
      build_cache_save_controls(ctx) ++
      build_cache_key_controls(ctx) ++
      build_cache_rm_controls(ctx) ++
      build_cache_block_controls(ctx) ++
      build_cache_doc_controls(ctx) ++
      [
        {"a workflow_run workflow with a cache step",
         Map.put(workflows, ".github/workflows/privileged-cache.yml", @privileged_cache_workflow),
         contributing, "rule=privileged-trigger-cache"}
      ] ++ build_cache_live_needle_controls(workflows, contributing)
  end

  # D-19: the stale comment sentence, a runbook needle and a table row.
  defp build_cache_doc_controls(ctx) do
    [
      ci_control(
        ctx,
        "stale sentence back in the CACHE KEY CONTRACT comment",
        "rule=doc-ci-comment",
        &add_line_after(
          &1,
          "      # CACHE KEY CONTRACT",
          "      # " <> @stale_build_cache_sentence <> " `_build` cache in this workflow."
        )
      ),
      {"CONTRIBUTING without `gh cache delete`", ctx.workflows,
       String.replace(ctx.contributing, "gh cache delete", "gh cache remove"),
       "rule=doc-contributing"},
      {"CONTRIBUTING cached-job table without its verify-capture row", ctx.workflows,
       remove_build_cache_section_row(ctx.contributing, "verify-capture"),
       "rule=doc-contributing"}
    ]
  end

  # Removes the first `| `<job_id>` |` row AFTER the `### Dependency build cache`
  # heading. The live CONTRIBUTING has an earlier CI table with the same row
  # prefix, so an unscoped replace would mutate the wrong table. A missing
  # section leaves the text unchanged, which the control runner reports.
  defp remove_build_cache_section_row(contributing, job_id) do
    heading = "\n### Dependency build cache\n"

    case String.split(contributing, heading, parts: 2) do
      [head, section] ->
        row = ~r/^\| `#{Regex.escape(job_id)}` \|[^\n]*\n/m
        head <> heading <> Regex.replace(row, section, "", global: false)

      [_] ->
        contributing
    end
  end

  defp ci_control(ctx, label, fragment, fun),
    do: {label, Map.update!(ctx.workflows, @ci_workflow, fun), ctx.contributing, fragment}

  defp build_cache_order_controls(ctx) do
    [
      ci_control(
        ctx,
        "root rm dropped",
        "rule=order",
        &remove_steps(&1, "verify-test", [@root_rm])
      ),
      ci_control(
        ctx,
        "root rm moved after the compile",
        "rule=order",
        &move_step_after(&1, "verify-test", @root_rm, @root_compile)
      ),
      ci_control(
        ctx,
        "root rm moved after the save",
        "rule=order",
        &move_step_after(&1, "verify-test", @root_rm, @root_save)
      ),
      ci_control(
        ctx,
        "root save moved after the compile",
        "rule=order",
        &move_step_after(&1, "verify-test", @root_save, @root_compile)
      )
    ]
  end

  # WR-01 (219 review): a second restore or save outside the D-07 window. Each
  # names its own inserted step, so the fragment proves the rule reached THAT
  # step and not the block's first restore.
  defp build_cache_count_controls(ctx) do
    [
      ci_control(
        ctx,
        "second root save after the compile",
        ~s("Save deps-only build cache again" rule=cache-count),
        &insert_step_after(&1, "verify-test", @root_compile, @late_root_save_step)
      ),
      ci_control(
        ctx,
        "second example save after the capture",
        ~s("Save example build cache again" rule=cache-count),
        &insert_step_after(&1, "verify-capture", @capture_consumer, @late_example_save_step)
      ),
      ci_control(
        ctx,
        "second root restore with restore-keys after the compile",
        ~s("Restore stale build cache" rule=restore-keys),
        &insert_step_after(&1, "verify-test", @root_compile, @late_root_restore_step)
      ),
      ci_control(
        ctx,
        "second root restore with a non-exact key after the compile",
        ~s("Restore stale build cache" rule=key-segment),
        &insert_step_after(&1, "verify-test", @root_compile, @late_root_restore_step)
      ),
      ci_control(
        ctx,
        "second root restore after the compile",
        ~s("Restore stale build cache" rule=cache-count),
        &insert_step_after(&1, "verify-test", @root_compile, @late_root_restore_step)
      )
    ]
  end

  # WR-02 (219 review): a step-level MIX_ENV makes a step build or read another
  # env's tree than the one the key and the env-scoped path name.
  defp build_cache_step_env_controls(ctx) do
    override = "        env:\n          MIX_ENV: dev"

    [
      ci_control(
        ctx,
        "step-level MIX_ENV on the root deps compile",
        ~s("#{@root_deps_compile}" rule=job-mix-env),
        fn text ->
          edit_step(
            text,
            "verify-test",
            @root_deps_compile,
            &add_line_after(&1, "        if: ", override)
          )
        end
      ),
      ci_control(
        ctx,
        "step-level MIX_ENV on the root compile",
        ~s("#{@root_compile}" rule=job-mix-env),
        fn text ->
          edit_step(
            text,
            "verify-test",
            @root_compile,
            &add_line_after(&1, "      - name: ", override)
          )
        end
      )
    ]
  end

  # IN-03 (219 review): on the min lane the example block is lane-skipped, so a
  # bare `cache-hit != 'true'` guard is true there and compiles or saves an
  # unfetched example tree. verify-test's example guards must carry the lane.
  defp build_cache_lane_guard_controls(ctx) do
    lane = "matrix.lane == 'current' && "

    [
      ci_control(
        ctx,
        "verify-test example deps compile guard without the lane",
        ~s("#{@example_deps_compile}" rule=compile-guard),
        &replace_in_step(&1, "verify-test", @example_deps_compile, lane, "")
      ),
      ci_control(
        ctx,
        "verify-test example save guard without the lane",
        ~s("#{@example_save}" rule=save-guard),
        &replace_in_step(&1, "verify-test", @example_save, lane, "")
      )
    ]
  end

  defp build_cache_save_controls(ctx) do
    guard = "        if: steps.build-restore.outputs.cache-hit != 'true'\n"

    [
      ci_control(ctx, "restore-keys on the root restore", "rule=restore-keys", fn text ->
        edit_step(
          text,
          "verify-test",
          @root_restore,
          &add_line_after(
            &1,
            "          key: ",
            "          restore-keys: ${{ matrix.runner }}-otp-"
          )
        )
      end),
      ci_control(
        ctx,
        "literal root save key",
        "rule=save-key",
        &replace_in_step(
          &1,
          "verify-test",
          @root_save,
          "key: ${{ steps.build-restore.outputs.cache-primary-key }}",
          "key: ubuntu-24.04-#{@build_key_version}-root-test"
        )
      ),
      ci_control(
        ctx,
        "root save keyed on the example restore",
        "rule=save-key",
        &replace_in_step(
          &1,
          "verify-test",
          @root_save,
          "steps.build-restore.",
          "steps.example-build-restore."
        )
      ),
      ci_control(
        ctx,
        "root save if dropped",
        "rule=save-guard",
        &replace_in_step(&1, "verify-test", @root_save, guard, "")
      ),
      ci_control(
        ctx,
        "root save if flipped",
        "rule=save-guard",
        &replace_in_step(&1, "verify-test", @root_save, "!= 'true'", "== 'true'")
      ),
      ci_control(
        ctx,
        "root save if prefixed with always()",
        "rule=save-guard",
        &replace_in_step(&1, "verify-test", @root_save, "if: steps.", "if: always() && steps.")
      ),
      ci_control(
        ctx,
        "example save path without the deps line",
        "rule=save-path",
        &replace_in_step(
          &1,
          "verify-test",
          @example_save,
          "examples/threadline_phoenix/deps\n",
          ""
        )
      ),
      ci_control(ctx, "root cache path not env-scoped", "rule=cache-path-env", fn text ->
        text
        |> replace_in_step(
          "verify-test",
          @root_restore,
          "_build/${{ env.MIX_ENV }}",
          "_build/test"
        )
        |> replace_in_step("verify-test", @root_save, "_build/${{ env.MIX_ENV }}", "_build/test")
      end),
      ci_control(
        ctx,
        "root restore on the combined action",
        "rule=combined-action",
        &replace_in_step(
          &1,
          "verify-test",
          @root_restore,
          "actions/cache/restore@v5",
          "actions/cache@v5"
        )
      ),
      ci_control(
        ctx,
        "save added to the restore-only pgbouncer job",
        "rule=restore-only",
        &insert_step_after(&1, "verify-pgbouncer-topology", @root_rm, fixture_root_save())
      ),
      ci_control(
        ctx,
        "root deps compile without its guard",
        "rule=compile-guard",
        &replace_in_step(&1, "verify-test", @root_deps_compile, guard, "")
      )
    ] ++
      for name <- [@root_deps_compile, @root_save] do
        ci_control(ctx, "continue-on-error on #{name}", "rule=continue-on-error", fn text ->
          edit_step(
            text,
            "verify-test",
            name,
            &add_line_after(&1, "        if: ", "        continue-on-error: true")
          )
        end)
      end
  end

  # One segment-removal control per segment per project, and one injection
  # control per forbidden input per project (D-01..D-06).
  defp build_cache_key_controls(ctx) do
    restores = %{root: @root_restore, example: @example_restore}

    segments =
      for project <- [:root, :example], segment <- @build_key_segments[project] do
        ci_control(ctx, "#{project} key without #{segment}", "rule=key-segment", fn text ->
          edit_restore_key(text, restores[project], &String.replace(&1, segment, ""))
        end)
      end

    forbidden =
      for project <- [:root, :example], input <- @build_key_forbidden[project] do
        ci_control(ctx, "#{project} key with #{input}", "rule=key-forbidden", fn text ->
          edit_restore_key(text, restores[project], &(&1 <> forbidden_injection(input)))
        end)
      end

    segments ++
      forbidden ++
      [
        ci_control(ctx, "root key profile no-optional", "rule=key-forbidden", fn text ->
          edit_restore_key(text, @root_restore, &String.replace(&1, "-full-", "-no-optional-"))
        end)
      ]
  end

  defp build_cache_rm_controls(ctx) do
    [
      ci_control(
        ctx,
        "example rm without its threadline_phoenix target",
        "rule=rm-target",
        fn text ->
          edit_step(
            text,
            "verify-test",
            @example_rm,
            &Regex.replace(
              ~r{ \\\n\s*"examples/threadline_phoenix/_build/\$\{MIX_ENV:\?\}/lib/threadline_phoenix"},
              &1,
              ""
            )
          )
        end
      ),
      ci_control(ctx, "example rm without its threadline target", "rule=rm-target", fn text ->
        edit_step(
          text,
          "verify-test",
          @example_rm,
          &Regex.replace(
            ~r{"examples/threadline_phoenix/_build/\$\{MIX_ENV:\?\}/lib/threadline" \\\n\s*},
            &1,
            ""
          )
        )
      end),
      ci_control(ctx, "root rm gated on always()", "rule=rm-unconditional", fn text ->
        edit_step(
          text,
          "verify-test",
          @root_rm,
          &add_line_after(&1, "      - name: ", "        if: always()")
        )
      end),
      ci_control(
        ctx,
        "root rm without the MIX_ENV guard",
        "rule=rm-env-guard",
        &replace_in_step(&1, "verify-test", @root_rm, "${MIX_ENV:?}", "$MIX_ENV")
      )
    ]
  end

  defp build_cache_block_controls(ctx) do
    [
      ci_control(
        ctx,
        "capture example block removed",
        "rule=allowlist-unused",
        &remove_steps(&1, "verify-capture", @example_block_steps)
      ),
      ci_control(
        ctx,
        "verify-test example block removed",
        "rule=allowlist-unused: has no example",
        &remove_steps(&1, "verify-test", @example_block_steps)
      ),
      ci_control(
        ctx,
        "verify-test root block removed",
        "rule=allowlist-unused: has no root",
        &remove_steps(&1, "verify-test", [@root_restore, @root_deps_compile, @root_rm, @root_save])
      ),
      ci_control(
        ctx,
        "root restore cloned into verify-capture",
        "rule=allowlist-project",
        &insert_step_in_job(&1, "verify-capture", @root_build_restore_step)
      ),
      ci_control(
        ctx,
        "local action inside the verify-test root block",
        "rule=inline",
        &insert_step_after(
          &1,
          "verify-test",
          @root_restore,
          "      - uses: ./.github/actions/setup-elixir\n\n"
        )
      ),
      ci_control(ctx, "stale exclusion entry", "rule=exclusion-unknown", fn text ->
        update_job!(text, "verify-repo-hygiene", fn _block -> "" end)
      end)
    ]
  end

  # Controls whose needle lies outside `<interfaces>`: a job header plus its
  # first `    steps:` line, or a job-level env line. Those lines exist in the
  # live files today, and plan 02 edits none of them (it may not edit
  # release.yml, flake-detection.yml or browser-full.yml at all), so these are
  # proven against the fully live workflows now. Labels are "<file> <job>: ...".
  defp build_cache_live_needle_controls(workflows, contributing) do
    update = fn path, fun -> Map.update!(workflows, path, fun) end
    restore = @root_build_restore_step

    [
      {"ci.yml verify-format: path-block deps + _build cache",
       update.(
         @ci_workflow,
         &insert_step_in_job(&1, "verify-format", @path_block_build_cache_step)
       ), "rule=allowlist"},
      {"ci.yml verify-format: setup-beam cache: true",
       update.(@ci_workflow, &insert_step_in_job(&1, "verify-format", @setup_beam_cache_step)),
       "rule=builtin-cache"},
      {"ci.yml verify-compile-no-optional: root restore",
       update.(@ci_workflow, &insert_step_in_job(&1, "verify-compile-no-optional", restore)),
       "rule=no-optional-cache"},
      {"ci.yml verify-test: job-level MIX_ENV removed",
       update.(@ci_workflow, &remove_env_line_in_job(&1, "verify-test", "MIX_ENV")),
       "rule=job-mix-env"},
      {"ci.yml verify-capture: ERL_COMPILER_OPTIONS in the job env",
       update.(
         @ci_workflow,
         &insert_env_line_in_job(
           &1,
           "verify-capture",
           "      ERL_COMPILER_OPTIONS: +deterministic"
         )
       ), "rule=compiler-env"},
      {"release.yml publish-hex: root restore",
       update.(@release_workflow, &insert_step_in_job(&1, "publish-hex", restore)),
       "rule=release-cache"},
      {"release.yml smoke-published: root restore",
       update.(@release_workflow, &insert_step_in_job(&1, "smoke-published", restore)),
       "rule=release-cache"},
      {"flake-detection.yml verify-flake: root restore",
       update.(@flake_workflow, &insert_step_in_job(&1, "verify-flake", restore)),
       "rule=allowlist"},
      {"browser-full.yml verify-example-browser-full: root restore",
       update.(
         @browser_full_workflow,
         &insert_step_in_job(&1, "verify-example-browser-full", restore)
       ), "rule=allowlist"}
    ]
    |> Enum.map(fn {label, mutated, fragment} -> {label, mutated, contributing, fragment} end)
  end

  # --- Deps-only build cache contract: the synthetic fixture (D-21) -----------
  #
  # A correct workflow set, so every rule is proven on the shape plan 02 must
  # reach before any YAML changes. The four allowlisted jobs copy the LIVE step
  # skeletons (every live non-cache step name in live order, multi-line `run:`
  # bodies trimmed to one representative line) with the cache steps inserted
  # where plan 02 inserts them. Step names and ids are fixed by 219-01-PLAN
  # `<interfaces>`: the mutation controls needle on them.

  defp build_cache_fixture do
    ci =
      Enum.join(
        [
          fixture_workflow_head("CI"),
          Enum.map_join(fixture_stub_jobs(@ci_workflow), "\n", &fixture_stub_job/1),
          fixture_verify_test(),
          fixture_pgbouncer(),
          fixture_example_consumer_job(:browser),
          fixture_example_consumer_job(:capture)
        ],
        "\n"
      )

    other =
      for path <- [@release_workflow, @flake_workflow, @browser_full_workflow], into: %{} do
        {path,
         fixture_workflow_head(Path.basename(path)) <>
           Enum.map_join(fixture_stub_jobs(path), "\n", &fixture_stub_job/1)}
      end

    Map.put(other, @ci_workflow, ci)
  end

  defp fixture_workflow_head(name) do
    "name: #{name}\n\non:\n  push:\n    branches: [main]\n  workflow_dispatch:\n\n" <>
      "permissions:\n  contents: read\n\njobs:\n"
  end

  defp fixture_stub_jobs(path) do
    for({{^path, job_id}, _reason} <- @build_cache_exclusions, do: job_id) |> Enum.sort()
  end

  # The present-tense comment plan 02 writes into ci.yml verify-format (D-19).
  @fixture_cache_key_comment ~S"""
        # CACHE KEY CONTRACT (Phase 198 D-19, Phase 219 CACHE-01) — read before adding any cache.
        #
        # Every key leads with the literal runner label and the resolved OTP and
        # Elixir from the `beam` step outputs. The deps-only `_build` caches add
        # `__BUILD_KEY_VERSION__`, the project, MIX_ENV, the `full` profile, and the project's
        # own lock and config hashes. They carry no `restore-keys`, and every
        # cached job runs `rm -rf "_build/${MIX_ENV:?}/lib/threadline"` (the
        # example removes both of its apps) before the save and the compile.
  """

  # Each stub copies the live job header line and the live `    steps:` line,
  # so insert_step_in_job/3 finds the same needles as in the live files.
  defp fixture_stub_job(job_id) do
    comment =
      if job_id == "verify-format", do: with_key_version(@fixture_cache_key_comment), else: ""

    "  #{job_id}:\n    name: #{job_id} stub\n    runs-on: ubuntu-24.04\n    steps:\n" <>
      "      - uses: actions/checkout@v5\n\n" <>
      comment <> "      - name: Run #{job_id}\n        run: echo ok\n"
  end

  # A CONTRIBUTING-shaped text holding a correct `### Dependency build cache`
  # section, bounded by neighbouring headings like the live file.
  defp build_cache_fixture_contributing do
    excluded_rows =
      @build_cache_exclusions
      |> Enum.sort()
      |> Enum.map_join("\n", fn {{path, job}, reason} ->
        "| `#{job}` (#{Path.basename(path)}) | #{reason} |"
      end)

    (~S"""
     ## CI parity and `act`

     ### Dialyzer PLT cache and measurement contract

     The PLT cache is described here.

     ### Dependency build cache

     Test jobs restore an exact deps-only `_build` cache (key version `__BUILD_KEY_VERSION__`)
     and never use `restore-keys`. Before the save and the compile, every cached
     job runs `rm -rf "_build/${MIX_ENV:?}/lib/threadline"`.

     | Job | Build cache | Saves on miss |
     | --- | --- | --- |
     | `verify-test` | root (every lane) and example (current lane) | yes |
     | `verify-pgbouncer-topology` | root, restore-only | no |
     | `verify-example-browser` | example | yes |
     | `verify-capture` | example | yes |

     | Job or workflow | Why it has no build cache |
     | --- | --- |
     """ <>
       excluded_rows <>
       ~S"""


       A cold run can log `Unable to reserve cache` when two jobs save one key.
       Each cached job prints `THREADLINE_BUILD_CACHE=hit|miss key=...` and
       `THREADLINE_EXAMPLE_BUILD_CACHE=hit|miss key=...`. To recover from a
       poisoned entry, find it with `gh cache list --key ...`, remove it with
       `gh cache delete <key>` (needs `actions: write`), then bump `__BUILD_KEY_VERSION__`.

       ## PgBouncer topology CI parity
       """)
    |> with_key_version()
  end

  @fixture_beam_step ~S"""
        - uses: erlef/setup-beam@v1
          id: beam
          with:
            version-file: .tool-versions
            version-type: strict
  """

  @fixture_root_block ~S"""
        - name: Restore deps-only build cache
          id: build-restore
          uses: actions/cache/restore@v5
          with:
            path: _build/${{ env.MIX_ENV }}
            key: __LEAD__-otp-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-__BUILD_KEY_VERSION__-root-${{ env.MIX_ENV }}-full-${{ hashFiles('mix.lock') }}-${{ hashFiles('config/**/*.exs') }}

        - name: Cache deps
          uses: actions/cache@v5
          with:
            path: deps
            key: __LEAD__-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-mix-deps-${{ hashFiles('mix.lock') }}
            restore-keys: __LEAD__-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-mix-deps-

        - name: Install dependencies
          run: mix deps.get

        - name: Compile dependencies on build cache miss
          if: steps.build-restore.outputs.cache-hit != 'true'
          run: mix deps.compile

        - name: Remove own build (never cached, never reused)
          env:
            BUILD_KEY: ${{ steps.build-restore.outputs.cache-primary-key }}
            BUILD_HIT: ${{ steps.build-restore.outputs.cache-hit }}
          run: |
            if [ "$BUILD_HIT" = "true" ]; then state=hit; else state=miss; fi
            echo "THREADLINE_BUILD_CACHE=${state} key=${BUILD_KEY}"
            rm -rf "_build/${MIX_ENV:?}/lib/threadline"

  __SAVE__      - name: Compile (warnings as errors)
          run: mix compile --warnings-as-errors
  """

  @fixture_root_save ~S"""
        - name: Save deps-only build cache
          if: steps.build-restore.outputs.cache-hit != 'true'
          uses: actions/cache/save@v5
          with:
            path: _build/${{ env.MIX_ENV }}
            key: ${{ steps.build-restore.outputs.cache-primary-key }}

  """

  @fixture_example_block ~S"""
        - name: Restore example deps and deps-only build cache
          id: example-build-restore
  __LANE_IF__        uses: actions/cache/restore@v5
          with:
            path: |
              examples/threadline_phoenix/deps
              examples/threadline_phoenix/_build/${{ env.MIX_ENV }}
            key: __LEAD__-otp-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-__BUILD_KEY_VERSION__-example-${{ env.MIX_ENV }}-full-${{ hashFiles('examples/threadline_phoenix/mix.lock') }}-${{ hashFiles('examples/threadline_phoenix/config/**/*.exs') }}

        - name: Install example dependencies
  __LANE_IF__        working-directory: examples/threadline_phoenix
          run: mix deps.get

        - name: Compile example dependencies on cache miss
          if: __LANE_AND__steps.example-build-restore.outputs.cache-hit != 'true'
          working-directory: examples/threadline_phoenix
          run: mix deps.compile --skip-local-deps

        - name: Remove example app's own build (never cached, never reused)
          env:
            EXAMPLE_BUILD_KEY: ${{ steps.example-build-restore.outputs.cache-primary-key }}
            EXAMPLE_BUILD_HIT: ${{ steps.example-build-restore.outputs.cache-hit }}
          run: |
            if [ -n "$EXAMPLE_BUILD_KEY" ]; then
              if [ "$EXAMPLE_BUILD_HIT" = "true" ]; then state=hit; else state=miss; fi
              echo "THREADLINE_EXAMPLE_BUILD_CACHE=${state} key=${EXAMPLE_BUILD_KEY}"
            fi
            rm -rf "examples/threadline_phoenix/_build/${MIX_ENV:?}/lib/threadline" \
              "examples/threadline_phoenix/_build/${MIX_ENV:?}/lib/threadline_phoenix"

        - name: Save example deps and deps-only build cache
          if: __LANE_AND__steps.example-build-restore.outputs.cache-hit != 'true'
          uses: actions/cache/save@v5
          with:
            path: |
              examples/threadline_phoenix/deps
              examples/threadline_phoenix/_build/${{ env.MIX_ENV }}
            key: ${{ steps.example-build-restore.outputs.cache-primary-key }}
  """

  defp fixture_root_save, do: @fixture_root_save

  # The fixtures spell the key version as a placeholder, so a D-04 bump of
  # @build_key_version carries them along.
  defp with_key_version(text),
    do: String.replace(text, "__BUILD_KEY_VERSION__", @build_key_version)

  defp fixture_root_block(lead, save?) do
    @fixture_root_block
    |> with_key_version()
    |> String.replace("__LEAD__", lead)
    |> String.replace("__SAVE__", if(save?, do: @fixture_root_save, else: ""))
  end

  defp fixture_example_block(lead, lane?) do
    @fixture_example_block
    |> with_key_version()
    |> String.replace("__LEAD__", lead)
    |> String.replace(
      "__LANE_IF__",
      if(lane?, do: "        if: matrix.lane == 'current'\n", else: "")
    )
    |> String.replace("__LANE_AND__", if(lane?, do: "matrix.lane == 'current' && ", else: ""))
  end

  defp fixture_verify_test do
    ~S"""
      verify-test:
        name: Run test suite
        strategy:
          fail-fast: false
          matrix:
            lane: [min, current]
            include:
              - lane: min
                elixir: "1.15.8"
                otp: "26.2.5.21"
                pg: "14"
                runner: "ubuntu-24.04"
              - lane: current
                version-file: ".tool-versions"
                pg: "16"
                runner: "ubuntu-24.04"
        runs-on: ${{ matrix.runner }}
        timeout-minutes: 20
        env:
          DB_HOST: localhost
          MIX_ENV: test
        services:
          postgres:
            image: postgres:${{ matrix.pg }}
            ports:
              - 5432:5432
        steps:
          - uses: actions/checkout@v5
            with:
              fetch-depth: 0

          - uses: erlef/setup-beam@v1
            id: beam
            with:
              version-file: ${{ matrix.version-file }}
              otp-version: ${{ matrix.otp }}
              elixir-version: ${{ matrix.elixir }}
              version-type: strict

    """ <>
      fixture_root_block("${{ matrix.runner }}", true) <>
      ~S"""

            - name: Verify no compile-connected xref cycles
              run: mix verify.xref_cycles

            - name: Run tests
              run: mix verify.test

            - name: Verify Threadline trigger coverage
              if: matrix.lane == 'current'
              run: mix verify.threadline

            - name: Ensure threadline_phoenix_test database exists (threadline on search_path)
              if: matrix.lane == 'current'
              env:
                PGPASSWORD: postgres
              run: |
                createdb -h "$DB_HOST" -U postgres threadline_phoenix_test 2>/dev/null || true

      """ <>
      fixture_example_block("${{ matrix.runner }}", true) <>
      ~S"""

            - name: Verify Threadline Phoenix example
              if: matrix.lane == 'current'
              run: mix verify.example
      """
  end

  defp fixture_pgbouncer do
    ~S"""
      verify-pgbouncer-topology:
        name: PgBouncer transaction topology
        runs-on: ubuntu-24.04
        timeout-minutes: 20
        env:
          MIX_ENV: test
        services:
          postgres:
            image: postgres:16
          pgbouncer:
            image: edoburu/pgbouncer:v1.25.2-p0
        steps:
          - uses: actions/checkout@v5

    """ <>
      @fixture_beam_step <>
      "\n" <>
      fixture_root_block("ubuntu-24.04", false) <>
      ~S"""

            - name: Wait for Postgres and PgBouncer
              env:
                PGPASSWORD: postgres
              run: |
                until pg_isready -h localhost -p 6432 -U postgres; do sleep 1; done

            - name: Bootstrap test DB (direct Postgres, bypass pooler)
              env:
                DB_HOST: localhost
                DB_PORT: "5432"
                THREADLINE_TOPOLOGY_BOOTSTRAP: "1"
              run: mix run priv/ci/topology_bootstrap.exs

            - name: Topology tests + verify_coverage through PgBouncer
              env:
                DB_HOST: localhost
                DB_PORT: "6432"
                THREADLINE_PGBOUNCER_TOPOLOGY: "1"
              run: |
                mix verify.topology
      """
  end

  # verify-example-browser and verify-capture share their live skeleton up to
  # the example block, including the deferred root `Cache deps` and
  # `Install root dependencies` steps (out of CACHE-01 scope, kept as live).
  defp fixture_example_consumer_job(kind) do
    {header, consumer} = fixture_consumer_parts(kind)

    header <>
      ~S"""
          steps:
            - uses: actions/checkout@v5

      """ <>
      @fixture_beam_step <>
      ~S"""

            - uses: actions/setup-node@v5
              with:
                node-version: "22"
                cache: npm
                cache-dependency-path: examples/threadline_phoenix/e2e/package-lock.json

            - name: Cache deps
              uses: actions/cache@v5
              with:
                path: deps
                key: ubuntu-24.04-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-mix-deps-${{ hashFiles('mix.lock') }}
                restore-keys: ubuntu-24.04-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-mix-deps-

            - name: Cache Playwright browsers
              uses: actions/cache@v5
              with:
                path: ~/.cache/ms-playwright
                key: ubuntu-24.04-playwright-${{ hashFiles('examples/threadline_phoenix/e2e/package-lock.json') }}
                restore-keys: ubuntu-24.04-playwright-

            - name: Install root dependencies
              run: mix deps.get

            - name: Ensure threadline_phoenix_test database exists
              env:
                PGPASSWORD: postgres
              run: |
                createdb -h "$DB_HOST" -U postgres threadline_phoenix_test 2>/dev/null || true

      """ <>
      fixture_example_block("ubuntu-24.04", false) <> "\n" <> consumer
  end

  defp fixture_consumer_parts(:browser) do
    {~S"""
       verify-example-browser:
         name: Example app browser E2E (Playwright)
         runs-on: ubuntu-24.04
         timeout-minutes: 18
         env:
           DB_HOST: localhost
           DB_PORT: 5432
           MIX_ENV: test
         services:
           postgres:
             image: postgres:16
     """,
     ~S"""
           - name: Run example Playwright suite
             timeout-minutes: 14
             run: mix verify.example_browser --project=desktop-chromium --project=mobile-chromium

           - name: Upload Playwright traces and e2e boot log on failure
             if: failure()
             uses: actions/upload-artifact@v7
             with:
               name: example-browser-e2e-diagnostics
               path: |
                 examples/threadline_phoenix/e2e/test-results
                 /tmp/threadline_phoenix_e2e.log
     """}
  end

  defp fixture_consumer_parts(:capture) do
    {~S"""
       verify-capture:
         name: Tier A capture lane (byte-stable evidence)
         runs-on: ubuntu-24.04
         timeout-minutes: 35
         env:
           DB_HOST: localhost
           DB_PORT: 5432
           MIX_ENV: test
         services:
           postgres:
             image: postgres:16
     """,
     ~S"""
           - name: Regenerate Tier A capture
             run: mix verify.capture

           - name: Assert complete evidence bundle (non-empty, every aria.yml has a matching scorecard)
             run: |
               find test/fixtures/operator_surface/scorecards -maxdepth 1 -name '*.json' | wc -l

           - name: Assert byte-stable regeneration (no drift from committed evidence)
             run: |
               git status --porcelain test/fixtures/operator_surface/scorecards/
     """}
  end
end
