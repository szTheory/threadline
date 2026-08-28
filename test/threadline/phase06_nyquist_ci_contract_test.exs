defmodule Threadline.Phase06NyquistCIContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  describe "CI-01 (Plan 06-01 Task 1): workflow contract" do
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

  describe "CI-02 (Plan 06-01 Task 2): local parity alias" do
    test "mix.exs ci.all matches verify-test ordering (compile strict before tests)" do
      mix = read_rel!(["mix.exs"])

      assert String.contains?(mix, ~s("ci.all": [))

      for step <- [
            "verify.format",
            "verify.credo",
            "compile --warnings-as-errors",
            "verify.test",
            "verify.threadline",
            "verify.example",
            "verify.doc_contract"
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
      {pos_dc, _} = :binary.match(ci_block, "\"verify.doc_contract\"")

      assert pos_test < pos_tl and pos_tl < pos_ex and pos_ex < pos_dc,
             "ci.all must list verify.test before verify.threadline before verify.example before verify.doc_contract"
    end
  end

  describe "CI-03 (Plan 06-02 Task 1): README discovery (D-05)" do
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

  describe "CI-03 (Plan 06-02 Task 2): CONTRIBUTING discovery" do
    test "CONTRIBUTING documents job keys and Actions URL" do
      doc = read_rel!(["CONTRIBUTING.md"])

      assert String.contains?(doc, "verify-format")
      assert String.contains?(doc, "verify-credo")
      assert String.contains?(doc, "verify-test")
      assert String.contains?(doc, "verify-pgbouncer-topology")
      assert String.contains?(doc, "https://github.com/szTheory/threadline/actions")
    end
  end

  describe "CI-02 (Plan 06-02 Task 3): maintainer verification doc literals" do
    test "06-VERIFICATION.md includes workflow, jobs, and gh audit commands" do
      # Live phase dirs may be cleared between milestones; archived v1.1 copy is canonical.
      path = [".planning", "milestones", "v1.1-phases", "06-ci-on-github", "06-VERIFICATION.md"]
      doc = read_rel!(path)

      assert String.contains?(doc, "ci.yml")
      assert String.contains?(doc, "verify-format")
      assert String.contains?(doc, "verify-credo")
      assert String.contains?(doc, "verify-test")

      assert String.contains?(
               doc,
               "gh run list --repo szTheory/threadline --workflow=ci.yml --branch=main --limit=5"
             )

      assert String.contains?(
               doc,
               "gh run view RUN_ID --repo szTheory/threadline --json conclusion,headSha,url"
             )
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

  describe "CI-03/CI-04 (Plan 192-04 Task 1, D-26): job-key parity" do
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

  describe "CI-02 (Plan 192-04 Task 1, D-26): no mutable rolling image tags" do
    test "no workflow file pins a service image to the mutable :latest tag" do
      for path <- workflow_files() do
        refute String.contains?(File.read!(path), ":latest"),
               "#{Path.relative_to(path, @repo_root)} must not pin any image to the " <>
                 "rolling :latest tag"
      end
    end
  end

  describe "CI-04 (Plan 192-04 Task 1, D-26): concurrency contracts" do
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

  describe "CI-03/CI-04 (Plan 192-04 Task 1, D-26): verify-test matrix construction" do
    test "ci.yml declares static name + lane axis [min, current] (construction A)" do
      yaml = read_rel!([".github", "workflows", "ci.yml"])

      assert Regex.match?(~r/^\s*name: Run test suite\s*$/m, yaml),
             "verify-test must declare the static `name: Run test suite` (GitHub composes the lane suffix)"

      assert Regex.match?(~r/^\s*lane:\s*\[min,\s*current\]\s*$/m, yaml),
             "verify-test matrix must declare base axis `lane: [min, current]`"
    end

    test "CONTRIBUTING List 2 carries both composed required-check names" do
      doc = read_rel!(["CONTRIBUTING.md"])

      assert String.contains?(doc, "Run test suite (min)")
      assert String.contains?(doc, "Run test suite (current)")
    end
  end

  describe "CI-02 (Plan 192-04 Task 1, D-26): dependency cache contract" do
    test "ci.yml caches deps + e2e lockfile and never caches _build" do
      yaml = read_rel!([".github", "workflows", "ci.yml"])

      assert String.contains?(yaml, "actions/cache@v4"),
             "ci.yml must use actions/cache@v4 for the deps cache"

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
end
