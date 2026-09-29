defmodule Threadline.CiTopologyContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  # Assembled so this file's own text never contains the retired alias name as a literal.
  @retired_alias "verify." <> "doc_contract"

  @resolved_plt_prefix "ubuntu-24.04-${{ steps.beam.outputs.otp-version }}-elixir-" <>
                         "${{ steps.beam.outputs.elixir-version }}-dialyzer-plt-"

  @live_slice_step_name "Live Dialyzer slice proof (fails closed)"

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  test "ci.yml defines PgBouncer topology job with transaction pool and mix verify.topology" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    assert String.contains?(yaml, "verify-pgbouncer-topology:")
    assert String.contains?(yaml, "POOL_MODE: transaction")
    assert String.contains?(yaml, "AUTH_TYPE: scram-sha-256")
    assert String.contains?(yaml, "THREADLINE_PGBOUNCER_TOPOLOGY: \"1\"")
    assert String.contains?(yaml, "mix verify.topology")
    assert String.contains?(yaml, "priv/ci/topology_bootstrap.exs")
    assert String.contains?(yaml, "edoburu/pgbouncer:")
  end

  test "ci.all alias does not include verify.bench" do
    mix_exs = read_rel!(["mix.exs"])

    assert mix_exs =~ "\"ci.all\": ["

    [_, ci_all_block] = String.split(mix_exs, "\"ci.all\": [")
    [ci_all_list | _] = String.split(ci_all_block, "]")

    refute String.contains?(ci_all_list, "\"verify.bench\"")
  end

  test "ci.all alias does not include verify.release" do
    mix_exs = read_rel!(["mix.exs"])

    assert mix_exs =~ "\"ci.all\": ["

    [_, ci_all_block] = String.split(mix_exs, "\"ci.all\": [")
    [ci_all_list | _] = String.split(ci_all_block, "]")

    refute String.contains?(ci_all_list, "\"verify.release\"")
  end

  test "mix aliases expose the named support-lane proof entrypoints" do
    mix_exs = read_rel!(["mix.exs"])

    assert String.contains?(mix_exs, "\"verify.compile_no_optional\":")
    assert String.contains?(mix_exs, "\"compile --no-optional-deps --warnings-as-errors\"")
    assert String.contains?(mix_exs, "\"verify.xref_cycles\":")

    assert String.contains?(
             mix_exs,
             "\"xref graph --format cycles --label compile-connected --fail-above 0\""
           )

    assert String.contains?(mix_exs, "\"verify.test\": [\"test\"]")
    assert String.contains?(mix_exs, "\"verify.example\": &verify_example/1")
  end

  test "ci.all keeps capture-only and phoenix-surface proof steps in order" do
    mix_exs = read_rel!(["mix.exs"])

    assert [_, ci_block] =
             Regex.run(~r/"ci\.all":\s*\[\s*\n((?:.*\n)*?)\s*\]/, mix_exs),
           "expected mix.exs to declare a multiline ci.all list"

    {pos_compile_strict, _} = :binary.match(ci_block, "\"compile --warnings-as-errors\"")
    {pos_xref_cycles, _} = :binary.match(ci_block, "\"verify.xref_cycles\"")
    {pos_compile_no_optional, _} = :binary.match(ci_block, "\"verify.compile_no_optional\"")
    {pos_verify_test, _} = :binary.match(ci_block, "\"verify.test\"")
    {pos_verify_threadline, _} = :binary.match(ci_block, "\"verify.threadline\"")
    {pos_verify_example, _} = :binary.match(ci_block, "\"verify.example\"")

    {pos_verify_browser, _} =
      :binary.match(
        ci_block,
        "cmd env CI=true mix verify.example_browser --project=desktop-chromium --project=mobile-chromium"
      )

    assert pos_compile_strict < pos_xref_cycles
    assert pos_xref_cycles < pos_compile_no_optional
    assert pos_compile_strict < pos_compile_no_optional
    assert pos_compile_no_optional < pos_verify_test
    assert pos_verify_test < pos_verify_threadline
    assert pos_verify_threadline < pos_verify_example
    assert pos_verify_example < pos_verify_browser
  end

  test "ci workflow exposes the documented support-lane job ids" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    assert Regex.match?(~r/^  verify-compile-no-optional:/m, yaml)
    assert Regex.match?(~r/^  verify-test:/m, yaml)
    assert Regex.match?(~r/^  verify-bump-rehearsal:/m, yaml)
  end

  test "the sole required-check decision pins alls-green immutably" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    assert Regex.match?(
             ~r|uses: re-actors/alls-green@[0-9a-f]{40}$|m,
             yaml
           ),
           "ci-required must execute alls-green from a reviewed full commit SHA"

    refute String.contains?(yaml, "re-actors/alls-green@release/"),
           "a mutable release ref can retarget the only branch-protection decision"
  end

  test "Dialyzer is one blocking local and current-lane CI path with an exact measured PLT cache" do
    mix_exs = read_rel!(["mix.exs"])
    yaml = read_rel!([".github", "workflows", "ci.yml"])
    contributing = read_rel!(["CONTRIBUTING.md"])

    assert dialyzer_topology_errors(mix_exs, yaml, contributing) == []

    dialyzer_job = workflow_job(yaml, "verify-dialyzer")
    live_slice_step = workflow_step(yaml, @live_slice_step_name)
    assert live_slice_step != "", "the live Dialyzer slice step must exist"

    mutation_controls = [
      {"PLT timing command",
       String.replace(
         yaml,
         "/usr/bin/time -v -o \"$time_file\" mix dialyzer --plt",
         "mix dialyzer --plt"
       )},
      {"analysis timing command",
       String.replace(
         yaml,
         "/usr/bin/time -v -o \"$time_file\" mix dialyzer --no-check",
         "mix dialyzer --no-check"
       )},
      {"measured timeout", String.replace(yaml, "timeout-minutes: 12", "timeout-minutes: 11")},
      {"fail-on-unparseable guard",
       String.replace(yaml, "Unable to parse GNU time output", "Timing unavailable")},
      {"build-before-save ordering",
       String.replace(yaml, "- name: Save Dialyzer PLT", "- name: Save analyzer cache")},
      {"same-toolchain restore boundary",
       String.replace(yaml, @resolved_plt_prefix, "ubuntu-24.04-dialyzer-plt-")},
      {"literal OTP pin",
       String.replace(
         yaml,
         dialyzer_job,
         String.replace(
           dialyzer_job,
           "          version-type: strict\n",
           "          version-type: strict\n          otp-version: \"" <> "27" <> ".0\"\n"
         )
       )},
      {"no analyzer in no-optional lane",
       String.replace(
         yaml,
         "run: mix verify.compile_no_optional",
         "run: |\n          mix verify.compile_no_optional\n          mix dialyzer --no-check"
       )},
      {"live slice step deleted", String.replace(yaml, live_slice_step, "")},
      {"live slice step before the analysis",
       yaml
       |> String.replace(live_slice_step, "")
       |> String.replace(
         "      - name: Analyze and measure with Dialyzer\n",
         live_slice_step <> "      - name: Analyze and measure with Dialyzer\n"
       )},
      {"live slice alias added to verify-test",
       String.replace(
         yaml,
         "run: mix verify.test",
         "run: |\n          mix verify.test\n          mix verify.dialyzer_slice"
       )}
    ]

    for {control, mutated_yaml} <- mutation_controls do
      refute dialyzer_topology_errors(mix_exs, mutated_yaml, contributing) == [],
             "#{control} mutation must make the Dialyzer topology contract fail"
    end

    for marker <- [
          "THREADLINE_DIALYZER_PLT_CACHE=",
          "THREADLINE_DIALYZER_PLT_WALL_SECONDS=",
          "THREADLINE_DIALYZER_PLT_MAX_RSS_KB=",
          "THREADLINE_DIALYZER_ANALYSIS_WALL_SECONDS=",
          "THREADLINE_DIALYZER_ANALYSIS_MAX_RSS_KB="
        ] do
      mutated_yaml = String.replace(yaml, marker, "THREADLINE_BROKEN_MARKER=")

      refute dialyzer_topology_errors(mix_exs, mutated_yaml, contributing) == [],
             "removing stable marker #{marker} must make the topology contract fail"
    end

    hit_step = workflow_step(yaml, "Report exact PLT cache hit")

    hit_with_fabricated_plt =
      String.replace(
        yaml,
        hit_step,
        hit_step <> "          echo \"THREADLINE_DIALYZER_PLT_WALL_SECONDS=0\"\n"
      )

    refute dialyzer_topology_errors(mix_exs, hit_with_fabricated_plt, contributing) == [],
           "the exact-key hit path must never fabricate a PLT-build measurement"

    mix_without_slice =
      String.replace(mix_exs, ~s(        "cmd env MIX_ENV=test mix verify.dialyzer_slice",\n), "")

    refute mix_without_slice == mix_exs, "the ci.all live-slice entry must be present to mutate"

    refute dialyzer_topology_errors(mix_without_slice, yaml, contributing) == [],
           "dropping the ci.all live-slice entry must make the Dialyzer topology contract fail"

    evidence_without_cold_run =
      String.replace(contributing, "34642915672", "unlinked-cold-run")

    refute dialyzer_topology_errors(mix_exs, yaml, evidence_without_cold_run) == [],
           "authenticated cold-run provenance must be part of the documentation contract"
  end

  test "verify-test job runs the phoenix-surface and sigra-reference proof path" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    assert String.contains?(yaml, "- name: Run tests")
    assert String.contains?(yaml, "run: mix verify.test")
    assert String.contains?(yaml, "- name: Verify Threadline trigger coverage")
    assert String.contains?(yaml, "run: mix verify.threadline")
    assert String.contains?(yaml, "- name: Verify Threadline Phoenix example")
    assert String.contains?(yaml, "run: mix verify.example")
    refute String.contains?(yaml, "mix " <> @retired_alias)
  end

  # GitHub Actions never runs `ci.all`, so pinning the alias alone would let the
  # GATE-04 cycle gate be dropped from CI with every test still green.
  test "verify-test job runs the xref cycle gate unconditionally before the suite" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    assert [_, block] =
             Regex.run(
               ~r/^  verify-test:\n([\s\S]*?)(?=^  [a-z][a-z0-9-]+:\n)/m,
               yaml
             ),
           "verify-test job is missing"

    step = workflow_step(block, "Verify no compile-connected xref cycles")

    assert step =~ ~r/^        run: mix verify\.xref_cycles\s*$/m,
           "verify-test must run `mix verify.xref_cycles` (GATE-04)"

    refute step =~ ~r/^        if:/m, "the xref cycle gate must not be conditional"

    refute step =~ ~r/^        continue-on-error:/m,
           "the xref cycle gate must fail the job"

    assert ordered_positions?([
             position(block, "run: mix compile --warnings-as-errors"),
             position(block, "run: mix verify.xref_cycles"),
             position(block, "run: mix verify.test")
           ]),
           "the xref cycle gate must run after compile and before the test suite"
  end

  test "verify-test checkout includes complete history and annotated tags" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    assert [_, block] =
             Regex.run(
               ~r/^  verify-test:\n([\s\S]*?)(?=^  [a-z][a-z0-9-]+:\n)/m,
               yaml
             ),
           "verify-test job is missing"

    assert Regex.match?(
             ~r/^      - uses: actions\/checkout@v5\n        with:\n          fetch-depth: 0\s*$/m,
             block
           ),
           "verify-test must fetch full history so archive tag objects are present"

    refute Regex.match?(~r/^\s+fetch-tags:\s*false\s*$/m, block),
           "verify-test must not disable tag fetching"
  end

  # Globs BOTH extensions on purpose. GitHub Actions honours .yaml as well as
  # .yml, so a guard that only globbed .yml could be defeated by a rename.
  defp workflow_paths do
    @repo_root
    |> Path.join(".github/workflows/*.{yml,yaml}")
    |> Path.wildcard()
    |> Enum.map(&Path.relative_to(&1, @repo_root))
    |> Enum.sort()
  end

  # GREEN-09 / D-24 / D-25 resurrection guard.
  #
  # Globs every workflow rather than naming ui-critic.yml, so re-introducing the
  # paid lane under ANY filename is caught. The needle is built by concatenation
  # because this file is itself read by nothing that scans for it — but the
  # concatenation also keeps a naive `grep -rl ANTHROPIC .github/` gate honest if
  # this guard is ever moved under .github/.
  test "no workflow references the paid critic API key (GREEN-09 resurrection guard)" do
    needle = "ANTHROPIC" <> "_API_KEY"
    paths = workflow_paths()

    refute paths == [],
           "found no workflow files to scan — the glob is broken, and a broken glob " <>
             "would launder a false pass for this guard"

    for path <- paths do
      refute String.contains?(read_rel!([path]), needle),
             "#{path} references #{needle} — the paid critic lane must stay structurally " <>
               "unreachable from CI (GREEN-09). Deleting the workflow, not defaulting its " <>
               "score input to false, is what satisfies this requirement."
    end
  end

  # GREEN-10 / D-26 / D-25 resurrection guard.
  #
  # Asserts LIST EQUALITY against a one-element list, not a count and not a bare
  # refutation. A count would pass if the one publish path moved to the wrong
  # workflow; a refutation would pass vacuously if the glob returned nothing.
  # Both failure modes are real and both are excluded by equality.
  test "exactly one workflow invokes the Hex publish command (GREEN-10 resurrection guard)" do
    publishers =
      Enum.filter(workflow_paths(), fn path ->
        String.contains?(read_rel!([path]), "mix hex.publish")
      end)

    assert publishers == [".github/workflows/release.yml"],
           "expected exactly one publish path, release.yml, but found: " <>
             inspect(publishers) <>
             ". release.yml is the only workflow carrying the five pre-publish gates " <>
             "(CI-green poll, hard needs:, verify-release-shape + hex.build, the " <>
             "already-published idempotency skip, and post-publish verification). A second " <>
             "publish path races it and wins, because publishing is irreversible in effect " <>
             "and the gated path polls for up to 30 minutes."
  end

  test "adoption pilot backlog carries CI topology contract marker" do
    doc = read_rel!(["guides", "adoption-pilot-backlog.md"])
    assert String.contains?(doc, "CI-PGBOUNCER-TOPOLOGY-CONTRACT")
  end

  test "adoption pilot backlog carries STG host topology template marker" do
    doc = read_rel!(["guides", "adoption-pilot-backlog.md"])
    assert String.contains?(doc, "STG-HOST-TOPOLOGY-TEMPLATE")
  end

  test "adoption pilot backlog carries STG audited path rubric marker" do
    doc = read_rel!(["guides", "adoption-pilot-backlog.md"])
    assert String.contains?(doc, "STG-AUDITED-PATH-RUBRIC")
  end

  # --- Phase 198-21 / D-42 merge-gate self-guarding contracts ---------------
  #
  # `.github/rulesets/main.json` names only the single aggregate context
  # `CI required`, so it structurally cannot detect a lane quietly dropped
  # from `ci-required`'s `needs:` list — the ruleset stays byte-identical
  # while the guarantee behind it shrinks. These two tests derive the merge
  # gate's real membership and its required-context singleton from source, in
  # both directions, so that narrowing is a red test rather than an invisible
  # YAML edit.

  @ci_required_roster_heading "### `ci-required` needs: roster"

  # Isolates the `ci-required:` job block. `ci-required` is the final job in
  # `ci.yml`'s `jobs:` map, so everything after the marker belongs to it.
  defp ci_required_block do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    case String.split(yaml, "\n  ci-required:\n", parts: 2) do
      [_, tail] ->
        tail

      _ ->
        flunk(
          "could not find a \"  ci-required:\" job in .github/workflows/ci.yml — " <>
            "the derive source for the merge-gate roster contract is broken"
        )
    end
  end

  defp ci_required_needs do
    block = ci_required_block()

    case Regex.run(~r/    needs:\n((?:      - .+\n)+)/, block) do
      [_, items] ->
        items
        |> String.split("\n", trim: true)
        |> Enum.map(&(&1 |> String.trim() |> String.trim_leading("- ")))

      nil ->
        []
    end
  end

  defp dialyzer_topology_errors(mix_exs, yaml, contributing) do
    job = workflow_job(yaml, "verify-dialyzer")
    no_optional_job = workflow_job(yaml, "verify-compile-no-optional")
    hit_step = workflow_step(yaml, "Report exact PLT cache hit")
    setup_beam_step = setup_beam_step(job)

    order = [
      position(job, "mix deps.get"),
      position(job, "mix compile --warnings-as-errors"),
      position(job, "/usr/bin/time -v -o \"$time_file\" mix dialyzer --plt"),
      position(job, "THREADLINE_DIALYZER_PLT_WALL_SECONDS="),
      position(job, "- name: Save Dialyzer PLT"),
      position(job, "/usr/bin/time -v -o \"$time_file\" mix dialyzer --no-check"),
      position(job, "THREADLINE_DIALYZER_ANALYSIS_WALL_SECONDS="),
      position(job, "run: mix verify.dialyzer_slice")
    ]

    [
      {mix_exs =~ ~s("verify.dialyzer": ["dialyzer --no-check"]),
       "verify.dialyzer must be the stable local no-check command"},
      {ci_all_entries(mix_exs)
       |> Enum.count(&(&1 == "cmd env MIX_ENV=dev mix verify.dialyzer")) == 1,
       "ci.all must invoke verify.dialyzer exactly once in the CI job's dev environment"},
      {Regex.match?(~r/^# Job id contract[^\n]*\n#[^\n]*verify-dialyzer/m, yaml),
       "workflow header roster must contain verify-dialyzer"},
      {String.contains?(yaml, "branches: [main]") and
         not String.contains?(yaml, "phase-199/scroll-cost-cause-fix"),
       "the temporary measurement-branch trigger must be removed after collection"},
      {job != "", "verify-dialyzer job must exist"},
      {String.contains?(job, "runs-on: ubuntu-24.04"),
       "verify-dialyzer must run on ubuntu-24.04"},
      {committed_toolchain_step?(setup_beam_step),
       "verify-dialyzer must install exactly the committed .tool-versions build (version-file, strict)"},
      {String.contains?(job, "timeout-minutes: 12") and
         String.contains?(job, "ceil((252 + 80) * 2 / 60) = 12") and
         String.contains?(job, "36258719902"),
       "Dialyzer timeout must retain the documented cold-run plus live-slice derivation"},
      {String.contains?(job, "uses: actions/cache/restore@v5"),
       "Dialyzer PLT restore must be a separate cache action"},
      {String.contains?(job, "id: dialyzer-plt-restore"),
       "PLT restore must expose a stable cache-hit id"},
      {String.contains?(job, "path: .dialyzer"), "PLT cache must use .dialyzer"},
      {String.contains?(job, @resolved_plt_prefix),
       "PLT cache and restore must retain exact runner/OTP/Elixir identity"},
      {String.contains?(job, "${{ hashFiles('mix.lock') }}") and
         String.contains?(job, "${{ hashFiles('mix.exs') }}"),
       "PLT key must include both mix.lock and mix.exs hashes"},
      {String.contains?(job, "uses: actions/cache/save@v5"),
       "Dialyzer PLT save must be a separate cache action"},
      {String.contains?(job, "steps.dialyzer-plt-restore.outputs.cache-primary-key"),
       "PLT save must reuse the restore action's exact primary key"},
      {String.contains?(job, "steps.dialyzer-plt-restore.outputs.cache-hit != 'true'"),
       "PLT build/save must be conditional on an exact-key miss"},
      {String.contains?(job, "steps.dialyzer-plt-restore.outputs.cache-hit == 'true'"),
       "the exact-key hit path must be explicit"},
      {String.contains?(job, "/usr/bin/time -v -o \"$time_file\" mix dialyzer --plt"),
       "PLT build must be timed independently"},
      {String.contains?(job, "/usr/bin/time -v -o \"$time_file\" mix dialyzer --no-check"),
       "analysis must be timed independently"},
      {String.contains?(job, "Unable to parse GNU time output"),
       "GNU time parsing must fail closed"},
      {String.contains?(job, "[[ \"$wall_seconds\" =~ ^[0-9]+([.][0-9]+)?$ ]]") and
         String.contains?(job, "[[ \"$max_rss_kb\" =~ ^[0-9]+$ ]]"),
       "measurement values must be normalized numeric fields"},
      {Enum.all?(
         [
           "THREADLINE_DIALYZER_PLT_CACHE=miss",
           "THREADLINE_DIALYZER_PLT_CACHE=hit",
           "THREADLINE_DIALYZER_PLT_WALL_SECONDS=",
           "THREADLINE_DIALYZER_PLT_MAX_RSS_KB=",
           "THREADLINE_DIALYZER_ANALYSIS_WALL_SECONDS=",
           "THREADLINE_DIALYZER_ANALYSIS_MAX_RSS_KB="
         ],
         &String.contains?(job, &1)
       ), "all stable cache and measurement markers must be emitted"},
      {ordered_positions?(order),
       "dependency fetch/compile, PLT timing, save, and analysis timing must stay ordered"},
      {not String.contains?(hit_step, "THREADLINE_DIALYZER_PLT_WALL_SECONDS=") and
         not String.contains?(hit_step, "THREADLINE_DIALYZER_PLT_MAX_RSS_KB="),
       "exact-key hits must not synthesize PLT-build measurements"},
      {not String.contains?(no_optional_job, "dialyzer"),
       "the no-optional lane must not run Dialyzer"},
      {ci_required_needs_from(yaml) |> Enum.count(&(&1 == "verify-dialyzer")) == 1,
       "ci-required must block on verify-dialyzer exactly once"},
      {String.contains?(contributing, "- `verify-dialyzer`") and
         String.contains?(contributing, "| `verify-dialyzer` | `mix verify.dialyzer`"),
       "CONTRIBUTING must document the aggregate edge and stable job key"},
      {Enum.all?(
         [
           "THREADLINE_DIALYZER_PLT_CACHE",
           "THREADLINE_DIALYZER_PLT_WALL_SECONDS",
           "THREADLINE_DIALYZER_PLT_MAX_RSS_KB",
           "THREADLINE_DIALYZER_ANALYSIS_WALL_SECONDS",
           "THREADLINE_DIALYZER_ANALYSIS_MAX_RSS_KB"
         ],
         &String.contains?(contributing, &1)
       ), "CONTRIBUTING must document the stable measurement field contract"},
      {Enum.all?(
         [
           "34642915672",
           "34643744220",
           "a4f21e7e89ed4f958bc4ff0bb48c796225496bdd",
           "20260907.300.1",
           "f8275246d287e483bdc4bea1cc53781d9076e21403d44c887c3adfedaabbb53a",
           "1025d27a2bd55968da5682d1654a62eff358df117b8d8a52e6c8ed034c0b7861",
           "THREADLINE_DIALYZER_PLT_WALL_SECONDS=152.82",
           "THREADLINE_DIALYZER_PLT_MAX_RSS_KB=2282540",
           "THREADLINE_DIALYZER_ANALYSIS_WALL_SECONDS=9.82",
           "THREADLINE_DIALYZER_ANALYSIS_MAX_RSS_KB=1023056",
           "THREADLINE_DIALYZER_ANALYSIS_WALL_SECONDS=9.42",
           "THREADLINE_DIALYZER_ANALYSIS_MAX_RSS_KB=1009288",
           "36258719902",
           "ceil((252 + 80) seconds × 2.0 / 60)",
           "= 12 minutes",
           "mix verify.dialyzer_slice",
           "drops no real coverage"
         ],
         &String.contains?(contributing, &1)
       ), "CONTRIBUTING must link the immutable miss/hit evidence and timeout formula"}
    ]
    |> Kernel.++(live_slice_checks(mix_exs, yaml, job))
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end

  # The live Dialyzer slice proof (plan 218-03): it runs only in verify-dialyzer, under
  # MIX_ENV=test with a postgres:16 service, is excluded from default `mix test`, and
  # ci.all runs it once, after the dev PLT exists.
  defp live_slice_checks(mix_exs, yaml, job) do
    live_slice_step = workflow_step(job, @live_slice_step_name)
    test_helper = read_rel!(["test", "test_helper.exs"])
    ci_all = ci_all_entries(mix_exs)
    ci_all_dialyzer = Enum.find_index(ci_all, &(&1 == "cmd env MIX_ENV=dev mix verify.dialyzer"))

    ci_all_slice =
      Enum.find_index(ci_all, &(&1 == "cmd env MIX_ENV=test mix verify.dialyzer_slice"))

    other_jobs_running_slice =
      for id <- workflow_job_ids(yaml),
          id != "verify-dialyzer",
          body = workflow_job(yaml, id),
          String.contains?(body, "verify.dialyzer_slice") or
            String.contains?(body, "live_dialyzer"),
          do: id

    [
      {live_slice_step != "" and
         String.contains?(live_slice_step, "MIX_ENV: test") and
         String.contains?(live_slice_step, "run: mix verify.dialyzer_slice"),
       "verify-dialyzer must run mix verify.dialyzer_slice under MIX_ENV: test"},
      {String.contains?(job, "    services:\n      postgres:\n        image: postgres:16\n"),
       "verify-dialyzer must carry a postgres:16 service for the live slice proof"},
      {other_jobs_running_slice == [],
       "only verify-dialyzer may run the live_dialyzer tag or verify.dialyzer_slice, found: " <>
         inspect(other_jobs_running_slice)},
      {String.contains?(test_helper, "live_dialyzer: true"),
       "test/test_helper.exs must exclude live_dialyzer from default mix test"},
      {Enum.count(ci_all, &(&1 == "cmd env MIX_ENV=test mix verify.dialyzer_slice")) == 1 and
         is_integer(ci_all_dialyzer) and is_integer(ci_all_slice) and
         ci_all_slice > ci_all_dialyzer,
       "ci.all must invoke the live slice proof exactly once, after the dev verify.dialyzer"}
    ]
  end

  defp ci_all_entries(mix_exs) do
    case Regex.run(~r/"ci\.all":\s*\[\s*\n((?:.*\n)*?)\s*\]/, mix_exs) do
      [_, block] -> Regex.scan(~r/"([^"]+)"/, block) |> Enum.map(&List.last/1)
      nil -> []
    end
  end

  defp ci_required_needs_from(yaml) do
    case Regex.run(~r/  ci-required:\n[\s\S]*?    needs:\n((?:      - .+\n)+)/, yaml) do
      [_, items] ->
        items
        |> String.split("\n", trim: true)
        |> Enum.map(&(&1 |> String.trim() |> String.trim_leading("- ")))

      nil ->
        []
    end
  end

  defp workflow_job_ids(yaml) do
    case String.split(yaml, "\njobs:\n", parts: 2) do
      [_, jobs] -> ~r/^  ([a-z][a-z0-9-]+):\n/m |> Regex.scan(jobs) |> Enum.map(&List.last/1)
      _ -> []
    end
  end

  defp workflow_job(yaml, id) do
    case Regex.run(~r/^  #{Regex.escape(id)}:\n([\s\S]*?)(?=^  [a-z][a-z0-9-]+:\n|\z)/m, yaml) do
      [full, _body] -> full
      nil -> ""
    end
  end

  # The job's setup-beam step: from its `- uses: erlef/setup-beam@` line up to
  # the next step.
  defp setup_beam_step(job) do
    case Regex.run(~r/^      - uses: erlef\/setup-beam@[^\n]*\n[\s\S]*?(?=^      - |\z)/m, job) do
      [step] -> step
      nil -> ""
    end
  end

  defp committed_toolchain_step?(step) do
    lines = step |> strip_comment_lines() |> String.split("\n") |> Enum.map(&String.trim/1)

    step != "" and "id: beam" in lines and "version-file: .tool-versions" in lines and
      "version-type: strict" in lines and
      not Enum.any?(
        lines,
        &(String.starts_with?(&1, "otp-version:") or String.starts_with?(&1, "elixir-version:"))
      )
  end

  defp workflow_step(yaml, name) do
    case Regex.run(
           ~r/^      - name: #{Regex.escape(name)}\n([\s\S]*?)(?=^      - (?:name:|uses:)|^  [a-z][a-z0-9-]+:\n|\z)/m,
           yaml
         ) do
      [full, _body] -> full
      nil -> ""
    end
  end

  defp position(source, needle) do
    case :binary.match(source, needle) do
      {position, _length} -> position
      :nomatch -> nil
    end
  end

  defp ordered_positions?(positions) do
    Enum.all?(positions, &is_integer/1) and positions == Enum.sort(positions)
  end

  defp strip_comment_lines(block) do
    block
    |> String.split("\n")
    |> Enum.reject(&String.match?(&1, ~r/^\s*#/))
    |> Enum.join("\n")
  end

  defp documented_needs_section do
    contributing = read_rel!(["CONTRIBUTING.md"])

    assert String.contains?(contributing, @ci_required_roster_heading),
           "CONTRIBUTING.md has no \"#{@ci_required_roster_heading}\" heading — the " <>
             "documented side of the merge-gate roster contract is missing entirely."

    contributing
    |> String.split(@ci_required_roster_heading, parts: 2)
    |> List.last()
    |> String.split(~r/\n#+ /, parts: 2)
    |> List.first()
  end

  defp documented_needs_roster do
    documented_needs_section()
    |> then(&Regex.scan(~r/^- `([a-z0-9-]+)`$/m, &1))
    |> Enum.map(fn [_, id] -> id end)
  end

  test "ci-required's needs: roster matches CONTRIBUTING.md in both drift directions and stays non-vacuous" do
    actual = ci_required_needs()
    documented = documented_needs_roster()

    assert length(actual) >= 10,
           "ci-required's derived needs: list has only #{length(actual)} entr" <>
             "#{if length(actual) == 1, do: "y", else: "ies"} (#{inspect(actual)}) — fewer " <>
             "than ten is a broken derive, not a real narrowing, and must fail loudly rather " <>
             "than silently asserting nothing while still reporting success."

    missing_from_docs = actual -- documented

    assert missing_from_docs == [],
           "ci-required requires #{inspect(missing_from_docs)} but CONTRIBUTING.md's " <>
             "\"#{@ci_required_roster_heading}\" roster omits it — the docs have drifted " <>
             "behind the pipeline."

    undocumented_extra = documented -- actual

    assert undocumented_extra == [],
           "CONTRIBUTING.md's \"#{@ci_required_roster_heading}\" roster claims " <>
             "#{inspect(undocumented_extra)} but ci-required no longer requires it in " <>
             ".github/workflows/ci.yml — this is the silent-narrowing case D-42 exists to " <>
             "catch: a needs: entry was removed without a matching documented roster edit."

    stripped = strip_comment_lines(ci_required_block())

    if Regex.match?(~r/^\s*allowed-skips:/m, stripped) or
         Regex.match?(~r/^\s*allowed-failures:/m, stripped) do
      section = documented_needs_section()

      assert String.contains?(section, "allowed-skips decision:") or
               String.contains?(section, "allowed-failures decision:"),
             "ci-required's alls-green step now carries allowed-skips or allowed-failures, " <>
               "but the \"#{@ci_required_roster_heading}\" section records no decision " <>
               "citation for it — an allowed failure launders a red lane into a green gate " <>
               "(D-09) and must be documented, not silently introduced."
    end
  end

  # --- Plan 202-10: the bump-rehearsal gate cannot be silently deleted ------
  #
  # Every born-red cause Phase 202 found was GREEN at the current version and
  # observable only under a simulated bump. That is exactly why nothing else in
  # this suite would notice if `verify-bump-rehearsal` were dropped from
  # `ci.yml` or quietly moved onto an allowed-skips list: the tree would stay
  # green right up to the publish gate, which is the failure mode the job
  # exists to remove. A gate that can be deleted in one YAML edit is not a
  # gate, so its wiring is asserted from source here in every direction that
  # could weaken it.
  @bump_rehearsal_job "verify-bump-rehearsal"

  # Collects the items of every `allowed-skips:` / `allowed-failures:` list in
  # the workflow, comments stripped so a commented-out example (the
  # `ci-required` extension-point note is exactly that) is never mistaken for a
  # live entry.
  defp allowed_skip_or_failure_items(yaml) do
    yaml
    |> strip_comment_lines()
    |> then(&Regex.scan(~r/^\s*allowed-(?:skips|failures):\s*\n((?:\s*- .+\n)*)/m, &1))
    |> Enum.flat_map(fn [_, items] -> String.split(items, "\n", trim: true) end)
    |> Enum.map(&(&1 |> String.trim() |> String.trim_leading("- ")))
  end

  test "the bump-rehearsal gate is wired, required, and never skip-listed" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])
    mix_exs = read_rel!(["mix.exs"])

    job = workflow_job(yaml, @bump_rehearsal_job)

    assert job != "",
           "#{@bump_rehearsal_job} is gone from .github/workflows/ci.yml. It is the only " <>
             "check that observes the release-commit state, where every born-red cause " <>
             "Phase 202 found lives; removing it restores the four-plans-late discovery."

    assert String.contains?(job, "mix verify.bump_rehearsal"),
           "#{@bump_rehearsal_job} no longer runs `mix verify.bump_rehearsal`, so the job " <>
             "can report green without rehearsing anything."

    refute Regex.match?(~r/^    if:/m, job),
           "#{@bump_rehearsal_job} acquired a job-level `if:`. A conditionally skipped " <>
             "member of ci-required needs an allowed-skips entry to keep the aggregate " <>
             "green, which is the laundering path this contract exists to block."

    assert Regex.match?(~r/^# Job id contract[^\n]*\n#[^\n]*#{@bump_rehearsal_job}/m, yaml),
           "the job-id contract header no longer lists #{@bump_rehearsal_job}; the roster " <>
             "of stable keys has drifted from the jobs that exist."

    assert @bump_rehearsal_job in ci_required_needs(),
           "#{@bump_rehearsal_job} is not in ci-required's needs:. Outside the single " <>
             "required check it is advisory, and an advisory red is exactly what a " <>
             "contributor merges past on the way to a born-red release."

    refute @bump_rehearsal_job in allowed_skip_or_failure_items(yaml),
           "#{@bump_rehearsal_job} appears in an allowed-skips or allowed-failures list. " <>
             "That launders a red release rehearsal into a green merge gate (D-09)."

    assert String.contains?(mix_exs, "\"verify.bump_rehearsal\": &verify_bump_rehearsal/1"),
           "mix.exs no longer declares the `verify.bump_rehearsal` alias the CI job cites."

    assert String.contains?(mix_exs, "bin/verify-bump-rehearsal"),
           "the `verify.bump_rehearsal` alias no longer invokes bin/verify-bump-rehearsal."

    [_, ci_all_block] = String.split(mix_exs, "\"ci.all\": [")
    [ci_all_list | _] = String.split(ci_all_block, "]")

    refute String.contains?(ci_all_list, "\"verify.bump_rehearsal\""),
           "verify.bump_rehearsal was folded into ci.all. It is a release-lane check and " <>
             "follows verify.release's precedent of staying out of the per-change gate."
  end

  # --- Plan 218-04: removed CI proofs stay justified and dominated ---------
  #
  # A proof leaves CI only when another job catches its failure class on the same
  # triggers. Each removal carries a "still caught by" bullet in CONTRIBUTING.md,
  # and these pins keep the proof that still catches it from lapsing silently.
  @removed_proofs_heading "### Removed CI proofs and what still catches them"
  @byte_stable_step "Assert byte-stable regeneration (no drift from committed evidence)"
  @mechanical_checker_test "test/threadline/operator_surface/mechanical_checker_test.exs"
  @removed_job_ids ["verify-mechanical", "verify-docs", "verify-hex-package"]

  defp removed_proof_bullets(contributing) do
    case String.split(contributing, @removed_proofs_heading, parts: 2) do
      [_, tail] ->
        tail
        |> String.split(~r/\n#+ /, parts: 2)
        |> List.first()
        |> String.split("\n")
        |> Enum.filter(&String.starts_with?(&1, "- "))

      _ ->
        []
    end
  end

  defp justified_removal?(contributing, needle) do
    contributing
    |> removed_proof_bullets()
    |> Enum.any?(&(String.contains?(&1, "still caught by") and String.contains?(&1, needle)))
  end

  # Tags that `mix test` excludes by default, from the app-env copy test_helper
  # writes, plus the two sanctioned gates by name so a broken read cannot pass.
  defp default_excluded_tag_names do
    :threadline
    |> Application.get_env(:default_test_excludes, [])
    |> Enum.map(fn
      {tag, _value} -> tag
      tag -> tag
    end)
    |> Kernel.++([:pgbouncer_topology, :live_dialyzer])
    |> Enum.map(&Atom.to_string/1)
    |> Enum.uniq()
  end

  defp header_roster(yaml) do
    case Regex.run(~r/^# Job id contract[^\n]*\n# ([^\n]*)/m, yaml) do
      [_, line] -> String.split(line, ", ")
      nil -> []
    end
  end

  # Each removed job id is gone from every roster (job keys, header, ci-required
  # needs:) and leaves both a `# Removed:` comment in ci.yml and a "still caught
  # by" bullet in CONTRIBUTING.md.
  defp removed_job_checks(yaml, contributing) do
    job_ids = workflow_job_ids(yaml)
    header = header_roster(yaml)
    needs = ci_required_needs_from(yaml)

    Enum.flat_map(@removed_job_ids, fn id ->
      [
        {id not in job_ids and id not in header and id not in needs,
         "#{id} was removed as a dominated proof but is back in ci.yml's job keys, " <>
           "header roster or ci-required needs:"},
        {String.contains?(yaml, "# Removed: #{id}"),
         "ci.yml lost the `# Removed: #{id}` comment that says what still catches it"},
        {justified_removal?(contributing, "`#{id}`"),
         "CONTRIBUTING.md has no \"still caught by\" bullet naming `#{id}`, so its " <>
           "removal no longer says which job catches its failure class"}
      ]
    end)
  end

  defp removed_proof_errors(yaml, contributing, checker_test) do
    capture = workflow_job(yaml, "verify-capture")

    excluded_tags_in_checker =
      for tag <- default_excluded_tag_names(),
          Regex.match?(~r/@(?:module)?tag\b[^\n]*\b#{tag}\b/, checker_test),
          do: tag

    [
      {capture != "", "verify-capture is gone from ci.yml"},
      {workflow_step(capture, @byte_stable_step) != "",
       "verify-capture lost its byte-stable regeneration step. The capture lane's mechanical " <>
         "step was removed because that step proves regenerated evidence equals the committed " <>
         "evidence; without it a rule breach in regenerated evidence reaches main unseen"},
      {not String.contains?(strip_comment_lines(capture), "mix verify.mechanical"),
       "verify-capture runs mix verify.mechanical again, which duplicates what verify-test " <>
         "already runs over the committed scorecard JSON"},
      {excluded_tags_in_checker == [],
       "#{@mechanical_checker_test} carries a default-excluded tag " <>
         "#{inspect(excluded_tags_in_checker)}, so verify-test no longer runs it and a " <>
         "committed scorecard that breaches MODE-A/MODE-B is caught by nothing"},
      {String.contains?(contributing, @removed_proofs_heading),
       "CONTRIBUTING.md lost the \"#{@removed_proofs_heading}\" section, so the removed " <>
         "proofs no longer say what still catches their failure class"},
      {justified_removal?(contributing, "capture"),
       "CONTRIBUTING.md has no \"still caught by\" bullet for the capture lane's removed " <>
         "mechanical step"}
    ]
    |> Kernel.++(removed_job_checks(yaml, contributing))
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end

  defp removed_job_bullet(contributing, needle) do
    contributing
    |> removed_proof_bullets()
    |> Enum.find(
      &(String.contains?(&1, "still caught by") and String.starts_with?(&1, "- " <> needle))
    )
  end

  test "removed CI proofs stay justified and dominated" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])
    contributing = read_rel!(["CONTRIBUTING.md"])
    checker_test = read_rel!([@mechanical_checker_test])

    assert removed_proof_errors(yaml, contributing, checker_test) == []

    byte_stable_step = workflow_step(yaml, @byte_stable_step)
    assert byte_stable_step != "", "the byte-stable step must exist to mutate"

    capture_bullet =
      contributing
      |> removed_proof_bullets()
      |> Enum.find(&(String.contains?(&1, "still caught by") and String.contains?(&1, "capture")))

    assert is_binary(capture_bullet), "the capture bullet must exist to mutate"

    yaml_controls = [
      {"mechanical step re-added to verify-capture",
       String.replace(
         yaml,
         byte_stable_step,
         byte_stable_step <>
           "      - name: Assert mechanical checker clean over real evidence\n" <>
           "        run: mix verify.mechanical\n\n"
       )},
      {"byte-stable step deleted", String.replace(yaml, byte_stable_step, "")}
    ]

    for {control, mutated} <- yaml_controls do
      refute mutated == yaml, "#{control} control did not change the input"

      refute removed_proof_errors(mutated, contributing, checker_test) == [],
             "#{control} mutation must make the removed-proof contract fail"
    end

    for {label, bullet} <- [
          {"capture", capture_bullet},
          {"verify-docs", removed_job_bullet(contributing, "`verify-docs`")},
          {"verify-hex-package", removed_job_bullet(contributing, "`verify-hex-package`")},
          {"verify-mechanical", removed_job_bullet(contributing, "`verify-mechanical`")}
        ] do
      assert is_binary(bullet), "the #{label} bullet must exist to mutate"
      contributing_without_bullet = String.replace(contributing, bullet <> "\n", "")
      refute contributing_without_bullet == contributing

      refute removed_proof_errors(yaml, contributing_without_bullet, checker_test) == [],
             "dropping the #{label} bullet must make the removed-proof contract fail"
    end

    readded =
      String.replace(
        yaml,
        "      - verify-bump-rehearsal\n",
        "      - verify-bump-rehearsal\n      - verify-docs\n"
      )

    refute readded == yaml

    refute removed_proof_errors(readded, contributing, checker_test) == [],
           "re-adding a removed job to ci-required needs: must make the contract fail"

    uncommented = String.replace(yaml, "# Removed: verify-hex-package", "# verify-hex-package")
    refute uncommented == yaml

    refute removed_proof_errors(uncommented, contributing, checker_test) == [],
           "dropping a `# Removed:` comment must make the contract fail"

    excluded_checker =
      String.replace(
        checker_test,
        "use ExUnit.Case, async: true\n",
        "use ExUnit.Case, async: true\n  @moduletag :pgbouncer_topology\n",
        global: false
      )

    refute excluded_checker == checker_test

    refute removed_proof_errors(yaml, contributing, excluded_checker) == [],
           "tagging the mechanical checker test out of the default suite must fail the contract"
  end

  # --- Plan 218-04: the proofs that dominate the removed jobs stay in force ---
  #
  # verify-docs and verify-hex-package left CI because verify-bump-rehearsal
  # (through mix verify.release) and verify-hex-evaluator catch the same failure
  # classes on the same triggers. These pins make that dominance impossible to
  # lapse silently.
  @dominators ["verify-bump-rehearsal", "verify-hex-evaluator"]

  defp verify_release_body(mix_exs) do
    case Regex.run(~r/  defp verify_release\(_args\) do\n([\s\S]*?)\n  end\n/, mix_exs) do
      [_, body] -> body
      nil -> ""
    end
  end

  defp workflow_triggers(yaml) do
    case Regex.run(~r/^on:\n((?:(?:  .*|\s*)\n)+?)(?=^\S)/m, yaml) do
      [_, block] -> strip_comment_lines(block)
      nil -> ""
    end
  end

  defp dominance_errors(mix_exs, yaml, rehearsal) do
    release = verify_release_body(mix_exs)
    triggers = workflow_triggers(yaml)
    needs = ci_required_needs_from(yaml)
    skip_listed = allowed_skip_or_failure_items(yaml)

    dominator_checks =
      Enum.flat_map(@dominators, fn id ->
        job = workflow_job(yaml, id)

        [
          {job != "" and id in needs and id not in skip_listed,
           "#{id} must exist and sit in ci-required's needs: (never skip-listed). It is " <>
             "what catches the failure classes of the removed verify-docs / " <>
             "verify-hex-package jobs; outside the required gate those breaks merge unseen"},
          {job != "" and not Regex.match?(~r/^    if:/m, job),
           "#{id} acquired a job-level if:. A dominator that does not run on every " <>
             "trigger the removed job ran on no longer dominates it"}
        ]
      end)

    [
      {String.contains?(release, ~s("MIX_ENV=dev mix docs --warnings-as-errors")),
       "verify-docs was removed because verify.release builds ExDoc with " <>
         "--warnings-as-errors; without it an ExDoc break reaches release unseen"},
      {String.contains?(release, ~s("mix hex.build")),
       "verify-hex-package was removed because verify.release runs mix hex.build; " <>
         "without it a broken Hex package reaches release unseen"},
      {String.contains?(
         workflow_job(yaml, "verify-bump-rehearsal"),
         "run: mix verify.bump_rehearsal"
       ), "verify-bump-rehearsal must run mix verify.bump_rehearsal, which runs verify.release"},
      {Regex.match?(~r/^\s*run_gate\s+"[^"]*"\s+mix verify\.release\b/m, rehearsal),
       "bin/verify-bump-rehearsal must run an uncommented `run_gate ... mix verify.release` " <>
         "gate; without it the ExDoc and hex.build proofs of the removed verify-docs / " <>
         "verify-hex-package jobs leave per-PR CI while every other pin stays green"},
      {String.contains?(
         workflow_job(yaml, "verify-hex-evaluator"),
         "run: mix verify.hex_evaluator"
       ),
       "verify-hex-evaluator must run mix verify.hex_evaluator, which builds, resolves, " <>
         "compiles and tests the tarball from this tree"},
      {String.contains?(
         mix_exs,
         ~s|System.get_env("THREADLINE_HEX_EVALUATOR_MODE", "rehearsal")|
       ),
       "verify.hex_evaluator must default to rehearsal mode; the published mode resolves " <>
         "hex.pm instead of this tree, so a tarball without a usable lib/ goes unseen"},
      {not String.contains?(yaml, "THREADLINE_HEX_EVALUATOR_MODE"),
       "ci.yml must not set THREADLINE_HEX_EVALUATOR_MODE; the evaluator must test this " <>
         "tree's tarball on every CI run"},
      {String.contains?(triggers, "  push:\n    branches: [main]\n") and
         String.contains?(triggers, "  pull_request:\n    branches: [main]\n") and
         String.contains?(triggers, "  workflow_dispatch:") and
         not String.contains?(triggers, "paths"),
       "ci.yml must trigger on push to main, pull_request to main and workflow_dispatch " <>
         "with no paths: filter; the removed jobs ran on exactly that set"}
    ]
    |> Kernel.++(dominator_checks)
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end

  test "dominating proofs for removed jobs stay in force" do
    mix_exs = read_rel!(["mix.exs"])
    yaml = read_rel!([".github", "workflows", "ci.yml"])
    rehearsal = read_rel!(["bin", "verify-bump-rehearsal"])

    assert dominance_errors(mix_exs, yaml, rehearsal) == []

    mix_controls = [
      {"ExDoc build dropped from verify.release",
       String.replace(mix_exs, ~s("MIX_ENV=dev mix docs --warnings-as-errors",\n), "")},
      {"hex.build dropped from verify.release",
       String.replace(mix_exs, ~s(,\n      "mix hex.build"\n), "\n")},
      {"evaluator default mode changed",
       String.replace(
         mix_exs,
         ~s|System.get_env("THREADLINE_HEX_EVALUATOR_MODE", "rehearsal")|,
         ~s|System.get_env("THREADLINE_HEX_EVALUATOR_MODE", "published")|
       )}
    ]

    yaml_controls = [
      {"verify-bump-rehearsal dropped from ci-required needs",
       String.replace(yaml, "      - verify-bump-rehearsal\n", "")},
      {"verify-hex-evaluator dropped from ci-required needs",
       String.replace(yaml, "      - verify-hex-evaluator\n", "")},
      {"job-level if on verify-hex-evaluator",
       String.replace(
         yaml,
         "  verify-hex-evaluator:\n    name: ",
         "  verify-hex-evaluator:\n    if: github.event_name == 'push'\n    name: "
       )},
      {"job-level if on verify-bump-rehearsal",
       String.replace(
         yaml,
         "  verify-bump-rehearsal:\n    name: ",
         "  verify-bump-rehearsal:\n    if: github.event_name == 'push'\n    name: "
       )},
      {"evaluator mode forced to published in ci.yml",
       String.replace(
         yaml,
         "  verify-hex-evaluator:\n    name: ",
         "  verify-hex-evaluator:\n    env:\n      THREADLINE_HEX_EVALUATOR_MODE: published\n    name: "
       )},
      {"pull_request trigger dropped",
       String.replace(yaml, "  pull_request:\n    branches: [main]\n", "")}
    ]

    for {control, mutated} <- mix_controls do
      refute mutated == mix_exs, "#{control} control did not change the input"

      refute dominance_errors(mutated, yaml, rehearsal) == [],
             "#{control} mutation must make the dominance contract fail"
    end

    for {control, mutated} <- yaml_controls do
      refute mutated == yaml, "#{control} control did not change the input"

      refute dominance_errors(mix_exs, mutated, rehearsal) == [],
             "#{control} mutation must make the dominance contract fail"
    end

    # 218 review WR-04: the chain's third link (the rehearsal runs verify.release).
    rehearsal_controls = [
      {"verify.release gate removed from the rehearsal",
       String.replace(
         rehearsal,
         ~s(  run_gate "mix verify.release at $NEXT" mix verify.release || true\n),
         "  true\n"
       )},
      {"verify.release gate commented out",
       String.replace(
         rehearsal,
         ~s(  run_gate "mix verify.release at $NEXT" mix verify.release || true\n),
         ~s(  true # run_gate "mix verify.release at $NEXT" mix verify.release\n)
       )}
    ]

    for {control, mutated} <- rehearsal_controls do
      refute mutated == rehearsal, "#{control} control did not change the input"

      refute dominance_errors(mix_exs, yaml, mutated) == [],
             "#{control} mutation must make the dominance contract fail"
    end
  end

  # 15368 is the GitHub Actions app. A required check without an integration_id
  # accepts the context from any app or any token that can write commit statuses.
  defp pinned_required_checks?(contexts),
    do: contexts == [%{"context" => "CI required", "integration_id" => 15_368}]

  test "the ruleset's sole required status check is byte-exact with ci-required's emitted name" do
    ruleset =
      [".github", "rulesets", "main.json"]
      |> read_rel!()
      |> Jason.decode!()

    required_status_checks_rule =
      Enum.find(ruleset["rules"], fn rule -> rule["type"] == "required_status_checks" end)

    refute is_nil(required_status_checks_rule),
           ".github/rulesets/main.json has no required_status_checks rule at all"

    contexts = required_status_checks_rule["parameters"]["required_status_checks"]

    assert length(contexts) == 1,
           "expected exactly one required status check context in " <>
             ".github/rulesets/main.json, found #{length(contexts)}: #{inspect(contexts)}. " <>
             "A second required context reintroduces the enumeration hazard D-08 replaced " <>
             "with a single aggregate gate."

    assert pinned_required_checks?(contexts),
           "expected the ruleset's sole required check to be exactly " <>
             ~s(%{"context" => "CI required", "integration_id" => 15368}, got ) <>
             "#{inspect(contexts)}. 15368 is the GitHub Actions app: without the pin, any app " <>
             "or any token that can write commit statuses can satisfy `CI required`."

    # In-memory mutation control: stripping the pin must fail the same equality.
    stripped = Enum.map(contexts, &Map.delete(&1, "integration_id"))
    refute stripped == contexts, "the stripped-id control did not change the input"

    refute pinned_required_checks?(stripped),
           "an unpinned required check must not satisfy the pinned-ruleset assertion"

    [%{"context" => context}] = contexts

    assert context === "CI required",
           "expected the ruleset's required status check context to be the exact literal " <>
             "\"CI required\", got #{inspect(context)} — GitHub matches required checks on " <>
             "exact string, never case-insensitively or trimmed."

    yaml = read_rel!([".github", "workflows", "ci.yml"])

    job_name =
      case Regex.run(~r/\n  ci-required:\n    name: (.+)\n/, yaml) do
        [_, name] -> name
        nil -> flunk("could not find ci-required's \"    name:\" line in ci.yml")
      end

    assert job_name === context,
           "ci-required's emitted name: (#{inspect(job_name)}) no longer matches the " <>
             "ruleset's sole required context (#{inspect(context)}) — GitHub matches " <>
             "required checks on the exact emitted job name (D-08), so this mismatch would " <>
             "make the required check permanently unsatisfiable."
  end
end
